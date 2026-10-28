#!/usr/bin/env python3
"""Validate a level, quest or puzzle graph.

Usage: python3 validate_graph.py <graph.json> [--json]

Graph format:
  {
    "nodes": [{"id": "a", "type": "start"}, {"id": "b"}, {"id": "c", "type": "end"}],
    "edges": [{"from": "a", "to": "b"}, {"from": "b", "to": "c", "gated_by": "ITM-key"}],
    "directed": true,                      # optional, default true
    "grants": {"a": ["ITM-key"]}           # optional: items obtained at a node
  }

Checks:
  G01 exactly one or more start nodes and at least one end node
  G02 every edge references existing nodes
  G03 every node is reachable from a start (considering gates)
  G04 every reachable node can reach an end (no soft-locks)
  G05 dead ends: non-end nodes with no outgoing edges
  G06 gates: items required by a gate must be obtainable before the gate
  G07 duplicate node ids

Gate handling: a node's `grants` are acquired on arrival; an edge with `gated_by`
can be traversed only if the item is held. Reachability is computed as a fixed
point over (node, items) states, so item order is respected.

Exit code 0 when no errors, 1 on errors, 2 on usage or parse problems.
"""
import json
import sys
from collections import defaultdict, deque
from pathlib import Path


def load(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def analyze(graph):
    errors, warnings = [], []
    nodes = graph.get("nodes", [])
    edges = graph.get("edges", [])
    directed = graph.get("directed", True)
    grants = graph.get("grants", {})

    ids = [n["id"] for n in nodes]
    seen = set()
    for i in ids:
        if i in seen:
            errors.append(f"G07 duplicate node id: {i}")
        seen.add(i)
    node_set = set(ids)

    starts = [n["id"] for n in nodes if n.get("type") == "start"]
    ends = [n["id"] for n in nodes if n.get("type") == "end"]
    if not starts:
        errors.append("G01 no start node (type: start)")
    if not ends:
        errors.append("G01 no end node (type: end)")

    adj = defaultdict(list)
    for e in edges:
        a, b = e.get("from"), e.get("to")
        if a not in node_set or b not in node_set:
            errors.append(f"G02 edge references unknown node: {a} -> {b}")
            continue
        adj[a].append((b, e.get("gated_by")))
        if not directed:
            adj[b].append((a, e.get("gated_by")))

    # Reachability with items: states are (node, frozenset(items)).
    reachable_nodes = set()
    held_at = {}
    if starts:
        queue = deque()
        visited = set()
        for s in starts:
            items = frozenset(grants.get(s, []))
            st = (s, items)
            visited.add(st)
            queue.append(st)
        while queue:
            node, items = queue.popleft()
            reachable_nodes.add(node)
            held_at.setdefault(node, set()).update(items)
            for nxt, gate in adj[node]:
                if gate and gate not in items:
                    continue
                new_items = items | frozenset(grants.get(nxt, []))
                st = (nxt, new_items)
                if st not in visited:
                    visited.add(st)
                    queue.append(st)

    for n in ids:
        if n not in reachable_nodes:
            errors.append(f"G03 node unreachable from start: {n}")

    # Reverse reachability to an end, ignoring gates (soft-lock detection uses
    # forward state exploration below, this catches structural dead regions).
    radj = defaultdict(list)
    for a, outs in adj.items():
        for b, _ in outs:
            radj[b].append(a)
    can_finish = set()
    queue = deque(ends)
    can_finish.update(ends)
    while queue:
        cur = queue.popleft()
        for prev in radj[cur]:
            if prev not in can_finish:
                can_finish.add(prev)
                queue.append(prev)
    for n in sorted(reachable_nodes):
        if n not in can_finish:
            errors.append(f"G04 soft-lock: {n} is reachable but cannot reach an end")

    for n in nodes:
        nid = n["id"]
        if n.get("type") != "end" and not adj.get(nid):
            if nid in reachable_nodes:
                warnings.append(f"G05 dead end (no exits, not an end node): {nid}")

    # Gate sanity: item must be granted somewhere reachable.
    granted_anywhere = set()
    for nid, items in grants.items():
        if nid in reachable_nodes:
            granted_anywhere.update(items)
    for e in edges:
        gate = e.get("gated_by")
        if gate and gate not in granted_anywhere:
            errors.append(
                f"G06 gate {e.get('from')} -> {e.get('to')} needs {gate}, "
                "which is never obtainable from a reachable node"
            )

    return errors, warnings


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    as_json = "--json" in argv
    if len(args) != 1:
        print(__doc__)
        return 2
    path = Path(args[0])
    if not path.exists():
        print(f"error: {path} not found", file=sys.stderr)
        return 2
    try:
        graph = load(path)
    except (json.JSONDecodeError, KeyError) as exc:
        print(f"error: cannot parse {path}: {exc}", file=sys.stderr)
        return 2
    try:
        errors, warnings = analyze(graph)
    except KeyError as exc:
        print(f"error: malformed graph, missing key {exc}", file=sys.stderr)
        return 2
    if as_json:
        print(json.dumps({"errors": errors, "warnings": warnings}, indent=2))
    else:
        for e in errors:
            print(f"ERROR   {e}")
        for w in warnings:
            print(f"WARNING {w}")
        if not errors and not warnings:
            print("OK: graph is valid")
        elif not errors:
            print(f"\nOK with {len(warnings)} warning(s)")
        else:
            print(f"\n{len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
