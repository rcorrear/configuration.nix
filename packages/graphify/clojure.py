from __future__ import annotations

import importlib
from pathlib import Path
from typing import Any

from graphify.extractors.base import _file_stem, _make_id, _read_text


_DEF_FORMS = {
    "def": "symbol",
    "defonce": "symbol",
    "defn": "function",
    "defn-": "function",
    "defmacro": "function",
    "defmulti": "function",
    "defmethod": "function",
}

_TYPE_FORMS = {
    "definterface",
    "defprotocol",
    "defrecord",
    "defstruct",
    "deftype",
}

_SPECIAL_FORMS = {
    ".",
    "..",
    "->",
    "->>",
    "as->",
    "case",
    "catch",
    "cond",
    "cond->",
    "cond->>",
    "def",
    "definterface",
    "defmacro",
    "defmethod",
    "defmulti",
    "defn",
    "defn-",
    "defonce",
    "defprotocol",
    "defrecord",
    "defstruct",
    "deftype",
    "do",
    "doseq",
    "dotimes",
    "fn",
    "for",
    "if",
    "if-let",
    "if-not",
    "import",
    "let",
    "letfn",
    "loop",
    "ns",
    "proxy",
    "quote",
    "recur",
    "require",
    "set!",
    "try",
    "use",
    "when",
    "when-first",
    "when-let",
    "when-not",
    "while",
    "with-open",
}


def _sym_text(node, source: bytes) -> str | None:
    if node is None or node.type != "sym_lit":
        return None
    text = _read_text(node, source).strip()
    return text or None


def _kw_text(node, source: bytes) -> str | None:
    if node is None or node.type != "kwd_lit":
        return None
    text = _read_text(node, source).strip()
    return text or None


def _named_children(node) -> list:
    return [child for child in node.children if child.is_named]


def _form_head(node, source: bytes) -> str | None:
    if node.type != "list_lit":
        return None
    children = _named_children(node)
    return _sym_text(children[0], source) if children else None


def _definition_name(node, source: bytes) -> str | None:
    for child in _named_children(node)[1:]:
        name = _sym_text(child, source)
        if name:
            return name
    return None


def _module_node(module: str, line: int, str_path: str) -> dict:
    return {
        "id": _make_id(module.replace(".", "/")),
        "label": module,
        "type": "module",
        "file_type": "code",
        "source_file": str_path,
        "source_location": f"L{line}",
    }


def _edge(
    source: str,
    target: str,
    relation: str,
    line: int,
    str_path: str,
    context: str | None = None,
    confidence: str = "EXTRACTED",
    confidence_score: float = 1.0,
) -> dict:
    edge = {
        "source": source,
        "target": target,
        "relation": relation,
        "confidence": confidence,
        "confidence_score": confidence_score,
        "source_file": str_path,
        "source_location": f"L{line}",
        "weight": 1.0,
    }
    if context is not None:
        edge["context"] = context
    return edge


def _clj_symbol_key(symbol: str) -> str:
    return symbol.rsplit("/", 1)[-1]


def _require_specs(require_node, source: bytes) -> list[dict[str, Any]]:
    specs: list[dict[str, Any]] = []
    children = _named_children(require_node)
    if not children:
        return specs

    for child in children[1:]:
        if child.type == "vec_lit":
            parts = _named_children(child)
            if not parts:
                continue
            module = _sym_text(parts[0], source)
            if not module:
                continue
            spec: dict[str, Any] = {
                "module": module,
                "alias": None,
                "refer": [],
                "refer_all": False,
                "line": parts[0].start_point[0] + 1,
            }
            idx = 1
            while idx < len(parts):
                key = _kw_text(parts[idx], source)
                value = parts[idx + 1] if idx + 1 < len(parts) else None
                if key == ":as":
                    spec["alias"] = _sym_text(value, source)
                    idx += 2
                elif key == ":refer":
                    if value is not None and value.type == "vec_lit":
                        spec["refer"] = [
                            name
                            for item in _named_children(value)
                            if (name := _sym_text(item, source))
                        ]
                    elif _kw_text(value, source) == ":all":
                        spec["refer_all"] = True
                    idx += 2
                else:
                    idx += 1
            specs.append(spec)
        elif child.type == "sym_lit":
            module = _sym_text(child, source)
            if module:
                specs.append({
                    "module": module,
                    "alias": None,
                    "refer": [],
                    "refer_all": False,
                    "line": child.start_point[0] + 1,
                })
        elif child.type == "list_lit":
            specs.extend(_require_specs(child, source))
    return specs


def _ns_require_specs(ns_node, source: bytes) -> list[dict[str, Any]]:
    specs: list[dict[str, Any]] = []
    for child in _named_children(ns_node)[2:]:
        if child.type != "list_lit":
            continue
        children = _named_children(child)
        if not children or _kw_text(children[0], source) != ":require":
            continue
        specs.extend(_require_specs(child, source))
    return specs


def _iter_lists(node):
    if node.type == "list_lit":
        yield node
    for child in node.children:
        if child.is_named:
            yield from _iter_lists(child)


def _raw_call(
    caller_nid: str,
    callee: str,
    line: int,
    str_path: str,
    *,
    namespace: str | None = None,
    receiver: str | None = None,
    target_namespace: str | None = None,
    import_kind: str | None = None,
) -> dict:
    rc = {
        "lang": "clojure",
        "caller_nid": caller_nid,
        "callee": _clj_symbol_key(callee),
        "is_member_call": receiver is not None,
        "source_file": str_path,
        "source_location": f"L{line}",
    }
    if namespace:
        rc["namespace"] = namespace
    if receiver:
        rc["receiver"] = receiver
    if target_namespace:
        rc["target_namespace"] = target_namespace
    if import_kind:
        rc["import_kind"] = import_kind
    return rc


def extract_clojure(path: Path) -> dict:
    try:
        mod = importlib.import_module("tree_sitter_clojure")
        from tree_sitter import Language, Parser

        language = Language(mod.language())
    except ImportError:
        return {"nodes": [], "edges": [], "error": "tree_sitter_clojure not installed"}
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
    raw_calls: list[dict] = []
    seen_nodes = {file_nid}
    definitions: dict[str, str] = {}
    definition_bodies: list[tuple[str, object]] = []
    namespace: str | None = None
    aliases: dict[str, str] = {}
    refers: dict[str, str] = {}
    refer_all: list[str] = []

    def add_node(node: dict) -> None:
        if node["id"] in seen_nodes:
            return
        seen_nodes.add(node["id"])
        nodes.append(node)

    for form in _named_children(root):
        if form.type != "list_lit":
            continue
        head = _form_head(form, source)
        line = form.start_point[0] + 1

        if head == "ns":
            name = _definition_name(form, source)
            if name:
                namespace = name
                module = _module_node(name, line, str_path)
                add_node(module)
                edges.append(_edge(file_nid, module["id"], "declares", line, str_path, "namespace"))
            for spec in _ns_require_specs(form, source):
                module_name = spec["module"]
                module_line = spec["line"]
                module = _module_node(module_name, module_line, str_path)
                add_node(module)
                edges.append(_edge(file_nid, module["id"], "imports", module_line, str_path, "require"))
                if spec.get("alias"):
                    aliases[str(spec["alias"])] = module_name
                for symbol in spec.get("refer", []):
                    refers[str(symbol)] = module_name
                if spec.get("refer_all"):
                    refer_all.append(module_name)
            continue

        kind = _DEF_FORMS.get(head or "")
        if kind:
            name = _definition_name(form, source)
            if not name:
                continue
            nid = _make_id(stem, name)
            label = f"{name}()" if kind == "function" else name
            add_node({
                "id": nid,
                "label": label,
                "type": kind,
                "file_type": "code",
                "source_file": str_path,
                "source_location": f"L{line}",
            })
            definitions[name] = nid
            edges.append(_edge(file_nid, nid, "contains", line, str_path))
            if kind == "function":
                definition_bodies.append((nid, form))
            continue

        if head in _TYPE_FORMS:
            name = _definition_name(form, source)
            if not name:
                continue
            nid = _make_id(stem, name)
            add_node({
                "id": nid,
                "label": name,
                "type": "class",
                "file_type": "code",
                "source_file": str_path,
                "source_location": f"L{line}",
            })
            definitions[name] = nid
            edges.append(_edge(file_nid, nid, "contains", line, str_path))

    seen_calls: set[tuple[str, str, int]] = set()
    for caller_nid, body in definition_bodies:
        for form in _iter_lists(body):
            if form is body:
                continue
            callee = _form_head(form, source)
            if not callee or callee in _SPECIAL_FORMS:
                continue
            line = form.start_point[0] + 1
            target_namespace = None
            import_kind = None
            receiver = None
            call_name = callee

            if "/" in callee:
                receiver, call_name = callee.rsplit("/", 1)
                target_namespace = aliases.get(receiver, receiver if "." in receiver else None)
                import_kind = "alias" if receiver in aliases else "qualified"
            elif callee in refers:
                target_namespace = refers[callee]
                import_kind = "refer"
            elif len(refer_all) == 1:
                target_namespace = refer_all[0]
                import_kind = "refer-all"

            target_nid = definitions.get(call_name) if target_namespace in (None, namespace) else None
            if target_nid and target_nid != caller_nid:
                key = (caller_nid, target_nid, line)
                if key not in seen_calls:
                    seen_calls.add(key)
                    edges.append(_edge(caller_nid, target_nid, "calls", line, str_path, "call"))

            raw_calls.append(
                _raw_call(
                    caller_nid,
                    call_name,
                    line,
                    str_path,
                    namespace=namespace,
                    receiver=receiver,
                    target_namespace=target_namespace,
                    import_kind=import_kind,
                )
            )

    return {
        "nodes": nodes,
        "edges": edges,
        "raw_calls": raw_calls,
        "clojure_namespace": namespace,
        "clojure_aliases": aliases,
        "clojure_refers": refers,
        "clojure_refer_all": refer_all,
    }
