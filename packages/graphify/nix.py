from __future__ import annotations

import importlib
from pathlib import Path

from graphify.extractors.base import _file_stem, _make_id, _read_text


def _named_children(node) -> list:
    return [child for child in node.children if child.is_named]


def _line(node) -> int:
    return node.start_point[0] + 1


def _edge(
    source: str,
    target: str,
    relation: str,
    line: int,
    str_path: str,
    context: str | None = None,
) -> dict:
    edge = {
        "source": source,
        "target": target,
        "relation": relation,
        "confidence": "EXTRACTED",
        "confidence_score": 1.0,
        "source_file": str_path,
        "source_location": f"L{line}",
        "weight": 1.0,
    }
    if context is not None:
        edge["context"] = context
    return edge


def _node(node_id: str, label: str, node_type: str, line: int, str_path: str) -> dict:
    return {
        "id": node_id,
        "label": label,
        "type": node_type,
        "file_type": "code",
        "source_file": str_path,
        "source_location": f"L{line}",
    }


def _attrpath_text(node, source: bytes) -> str | None:
    if node is None:
        return None
    text = _read_text(node, source).strip()
    return text or None


def _binding_attrpath(binding, source: bytes) -> str | None:
    attrpath = binding.child_by_field_name("attrpath")
    if attrpath is None:
        attrpath = next((child for child in _named_children(binding) if child.type == "attrpath"), None)
    return _attrpath_text(attrpath, source)


def _binding_expression(binding):
    expression = binding.child_by_field_name("expression")
    if expression is not None:
        return expression
    children = _named_children(binding)
    return children[-1] if len(children) >= 2 else None


def _is_function_expression(node) -> bool:
    return node is not None and node.type == "function_expression"


def _walk(node):
    yield node
    for child in node.children:
        if child.is_named:
            yield from _walk(child)


def _path_text(node, source: bytes) -> str | None:
    text = _read_text(node, source).strip()
    return text or None


def _path_node(path_text: str, base_path: Path, line: int, str_path: str) -> dict:
    if path_text.startswith(("./", "../")):
        target_path = (base_path.parent / path_text).resolve()
        node_id = _make_id(_file_stem(target_path))
    else:
        node_id = _make_id(path_text)
    return _node(node_id, path_text, "file", line, str_path)


def _select_text(node, source: bytes) -> str | None:
    text = _read_text(node, source).strip()
    if "." not in text:
        return None
    return text


def _reference_worth_emitting(text: str) -> bool:
    return (
        text.startswith("pkgs.")
        or text.startswith("lib.")
        or text.startswith("den.")
        or text.startswith("inputs.")
        or text.startswith("self.")
    )


def _add_unique_node(nodes: list[dict], seen_nodes: set[str], node: dict) -> None:
    if node["id"] in seen_nodes:
        return
    seen_nodes.add(node["id"])
    nodes.append(node)


def _add_unique_edge(edges: list[dict], seen_edges: set[tuple[str, str, str, str | None]], edge: dict) -> None:
    key = (
        str(edge.get("source")),
        str(edge.get("target")),
        str(edge.get("relation")),
        edge.get("source_location"),
    )
    if key in seen_edges:
        return
    seen_edges.add(key)
    edges.append(edge)


def extract_nix(path: Path) -> dict:
    try:
        mod = importlib.import_module("tree_sitter_nix")
        from tree_sitter import Language, Parser

        language = Language(mod.language())
    except ImportError:
        return {"nodes": [], "edges": [], "error": "tree_sitter_nix not installed"}
    except Exception as e:
        return {"nodes": [], "edges": [], "error": str(e)}

    try:
        source = path.read_bytes()
        tree = Parser(language).parse(source)
        root = tree.root_node
    except Exception as e:
        return {"nodes": [], "edges": [], "error": str(e)}

    stem = _file_stem(path)
    str_path = str(path)
    file_nid = _make_id(stem)
    nodes = [
        {
            "id": file_nid,
            "label": path.name,
            "type": "file",
            "file_type": "code",
            "source_file": str_path,
        }
    ]
    edges: list[dict] = []
    seen_nodes = {file_nid}
    seen_edges: set[tuple[str, str, str, str | None]] = set()
    bindings: dict[str, str] = {}
    function_bodies: list[tuple[str, object]] = []

    for item in _walk(root):
        if item.type != "binding":
            continue
        attrpath = _binding_attrpath(item, source)
        if not attrpath:
            continue
        expression = _binding_expression(item)
        node_type = "function" if _is_function_expression(expression) else "symbol"
        nid = _make_id(stem, attrpath)
        label = f"{attrpath}()" if node_type == "function" else attrpath
        _add_unique_node(nodes, seen_nodes, _node(nid, label, node_type, _line(item), str_path))
        _add_unique_edge(edges, seen_edges, _edge(file_nid, nid, "contains", _line(item), str_path))
        bindings[attrpath.rsplit(".", 1)[-1]] = nid
        bindings[attrpath] = nid
        if node_type == "function":
            function_bodies.append((nid, expression))

    for item in _walk(root):
        if item.type == "path_expression":
            target_text = _path_text(item, source)
            if not target_text:
                continue
            target = _path_node(target_text, path, _line(item), str_path)
            _add_unique_node(nodes, seen_nodes, target)
            _add_unique_edge(edges, seen_edges, _edge(file_nid, target["id"], "imports", _line(item), str_path, "path"))
        elif item.type == "select_expression":
            ref_text = _select_text(item, source)
            if not ref_text or not _reference_worth_emitting(ref_text):
                continue
            ref = _node(_make_id(ref_text), ref_text, "reference", _line(item), str_path)
            _add_unique_node(nodes, seen_nodes, ref)
            _add_unique_edge(edges, seen_edges, _edge(file_nid, ref["id"], "references", _line(item), str_path, "attrpath"))

    for caller_nid, body in function_bodies:
        for item in _walk(body):
            if item.type != "apply_expression":
                continue
            function = item.child_by_field_name("function")
            if function is None:
                children = _named_children(item)
                function = children[0] if children else None
            if function is None or function.type != "variable_expression":
                continue
            callee = _read_text(function, source).strip()
            target = bindings.get(callee)
            if not target or target == caller_nid:
                continue
            _add_unique_edge(edges, seen_edges, _edge(caller_nid, target, "calls", _line(item), str_path, "call"))

    return {"nodes": nodes, "edges": edges, "raw_calls": []}
