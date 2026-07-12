from __future__ import annotations

import re
from typing import Any


_CLJ_SUFFIXES = (".clj", ".cljs", ".cljc")


def _symbol_key(label: object) -> str:
    text = str(label or "").strip()
    text = text.strip("()").lstrip(".")
    return re.sub(r"\s+", "", text).lower()


def _clojure_raw_calls(per_file: list[dict]) -> list[dict]:
    calls: list[dict] = []
    for result in per_file:
        if not isinstance(result, dict):
            continue
        for rc in result.get("raw_calls", []):
            if isinstance(rc, dict) and rc.get("lang") == "clojure":
                calls.append(rc)
    return calls


def _clojure_source_file(value: object) -> bool:
    return str(value or "").endswith(_CLJ_SUFFIXES)


def resolve_clojure_calls(
    per_file: list[dict],
    all_nodes: list[dict],
    all_edges: list[dict],
) -> None:
    namespace_files: dict[str, set[str]] = {}
    file_namespaces: dict[str, str] = {}
    for result in per_file:
        if not isinstance(result, dict):
            continue
        namespace = result.get("clojure_namespace")
        if not namespace:
            continue
        files = {
            str(node.get("source_file", ""))
            for node in result.get("nodes", [])
            if _clojure_source_file(node.get("source_file"))
        }
        for source_file in files:
            file_namespaces[source_file] = str(namespace)
            namespace_files.setdefault(str(namespace), set()).add(source_file)

    definitions_by_namespace: dict[str, dict[str, list[str]]] = {}
    definitions_global: dict[str, list[str]] = {}
    for node in all_nodes:
        source_file = str(node.get("source_file", ""))
        namespace = file_namespaces.get(source_file)
        if not namespace:
            continue
        node_type = node.get("type")
        if node_type not in {"function", "symbol", "class"}:
            continue
        node_id = node.get("id")
        if not node_id:
            continue
        key = _symbol_key(node.get("label"))
        if not key:
            continue
        definitions_by_namespace.setdefault(namespace, {}).setdefault(key, []).append(str(node_id))
        definitions_global.setdefault(key, []).append(str(node_id))

    for namespace in list(definitions_by_namespace):
        for key in list(definitions_by_namespace[namespace]):
            definitions_by_namespace[namespace][key] = sorted(set(definitions_by_namespace[namespace][key]))
    for key in list(definitions_global):
        definitions_global[key] = sorted(set(definitions_global[key]))

    existing_edges: dict[tuple[str, str, str], dict] = {}
    for edge in all_edges:
        if edge.get("source") and edge.get("target"):
            existing_edges[
                (str(edge.get("source")), str(edge.get("target")), str(edge.get("relation", "")))
            ] = edge

    def resolve_target(raw_call: dict[str, Any]) -> str | None:
        key = _symbol_key(raw_call.get("callee"))
        if not key:
            return None

        target_namespace = raw_call.get("target_namespace")
        if target_namespace:
            namespace_defs = definitions_by_namespace.get(str(target_namespace), {})
            candidates = namespace_defs.get(key, [])
            return candidates[0] if len(candidates) == 1 else None

        namespace = raw_call.get("namespace")
        if namespace:
            candidates = definitions_by_namespace.get(str(namespace), {}).get(key, [])
            if len(candidates) == 1:
                return candidates[0]

        candidates = definitions_global.get(key, [])
        return candidates[0] if len(candidates) == 1 else None

    for raw_call in _clojure_raw_calls(per_file):
        caller = str(raw_call.get("caller_nid", ""))
        if not caller:
            continue
        target = resolve_target(raw_call)
        if not target or target == caller:
            continue
        pair = (caller, target, "calls")
        imported = raw_call.get("target_namespace") is not None
        if pair in existing_edges:
            if imported:
                edge = existing_edges[pair]
                edge["confidence"] = "EXTRACTED"
                edge["confidence_score"] = 1.0
                edge["context"] = edge.get("context") or "call"
            continue
        all_edges.append({
            "source": caller,
            "target": target,
            "relation": "calls",
            "context": "call",
            "confidence": "EXTRACTED" if imported else "INFERRED",
            "confidence_score": 1.0 if imported else 0.8,
            "source_file": raw_call.get("source_file", ""),
            "source_location": raw_call.get("source_location"),
            "weight": 1.0,
        })
