"""
FactoryOS AI — Universal Process Graph Validator
Phase 3: Graph Topology Validation, Cycle Detection, and Semantic Integrity
"""
from typing import List, Dict, Set, Tuple
from collections import defaultdict, deque

class ProcessGraphValidator:
    """
    Validates manufacturing process graph definitions before publication.
    Enforces:
    - Directed graph structure
    - Start and End node constraints
    - Forward reachability (from Start) and backward reachability (to End)
    - Cycle detection (disallowing unbounded cyclic graphs)
    - Parallel split/join matching semantics
    - Conditional branch rules
    - Factory resource isolation
    """

    @classmethod
    def validate_version(cls, version) -> Tuple[bool, List[str], List[str]]:
        """
        Validates a ProcessVersion instance.
        Returns:
            (is_valid: bool, errors: List[str], warnings: List[str])
        """
        errors: List[str] = []
        warnings: List[str] = []

        nodes = list(version.nodes.all())
        edges = list(version.edges.all())

        if not nodes:
            errors.append("Process graph contains no nodes. At least one START and one END node are required.")
            return False, errors, warnings

        node_keys = {n.node_key for n in nodes}
        node_map = {n.id: n for n in nodes}
        key_to_node = {n.node_key: n for n in nodes}

        # 1. Start and End node validation
        start_nodes = [n for n in nodes if n.node_type == "START"]
        end_nodes = [n for n in nodes if n.node_type == "END"]

        if not start_nodes:
            errors.append("Process graph must have at least one START node.")
        if not end_nodes:
            errors.append("Process graph must have at least one END node.")

        # Build adjacency maps
        outgoing: Dict[str, List[ProcessEdge]] = defaultdict(list)
        incoming: Dict[str, List[ProcessEdge]] = defaultdict(list)

        for edge in edges:
            if edge.source_node_id not in node_map or edge.target_node_id not in node_map:
                errors.append(f"Edge '{edge.edge_key}' references non-existent nodes.")
                continue

            src = node_map[edge.source_node_id]
            tgt = node_map[edge.target_node_id]

            # Disallow self-loops
            if src.id == tgt.id:
                errors.append(f"Edge '{edge.edge_key}' forms an invalid self-loop on node '{src.node_key}'.")

            outgoing[src.node_key].append(edge)
            incoming[tgt.node_key].append(edge)

        # 2. Start and End connections
        for start in start_nodes:
            if len(incoming[start.node_key]) > 0:
                errors.append(f"START node '{start.node_key}' cannot have incoming edges.")
            if len(outgoing[start.node_key]) == 0:
                errors.append(f"START node '{start.node_key}' must have at least one outgoing edge.")

        for end in end_nodes:
            if len(outgoing[end.node_key]) > 0:
                errors.append(f"END node '{end.node_key}' cannot have outgoing edges.")
            if len(incoming[end.node_key]) == 0:
                errors.append(f"END node '{end.node_key}' must have at least one incoming edge.")

        # 3. Intermediate nodes connectivity
        for node in nodes:
            if node.node_type not in ("START", "END"):
                if len(incoming[node.node_key]) == 0:
                    errors.append(f"Operation node '{node.node_key}' has no incoming connections (unreachable).")
                if len(outgoing[node.node_key]) == 0:
                    errors.append(f"Operation node '{node.node_key}' has no outgoing connections (dead end).")

            # Parallel Split / Join validation
            if node.node_type == "PARALLEL_SPLIT":
                if len(outgoing[node.node_key]) < 2:
                    warnings.append(f"PARALLEL_SPLIT node '{node.node_key}' should fork into at least 2 parallel branches.")
            elif node.node_type == "PARALLEL_JOIN":
                if len(incoming[node.node_key]) < 2:
                    warnings.append(f"PARALLEL_JOIN node '{node.node_key}' should merge at least 2 incoming branches.")

            # Conditional Branch validation
            elif node.node_type == "CONDITION_BRANCH":
                out_edges = outgoing[node.node_key]
                if len(out_edges) < 2:
                    warnings.append(f"CONDITION_BRANCH node '{node.node_key}' should have at least 2 outgoing paths.")
                has_default = any(e.edge_type in ("DEFAULT", "STANDARD") for e in out_edges)
                if not has_default:
                    warnings.append(f"CONDITION_BRANCH node '{node.node_key}' is missing a DEFAULT fallback route.")

        # 4. Forward Reachability from START nodes
        reachable_from_start: Set[str] = set()
        queue = deque([s.node_key for s in start_nodes])
        while queue:
            curr = queue.popleft()
            if curr not in reachable_from_start:
                reachable_from_start.add(curr)
                for edge in outgoing[curr]:
                    target_key = edge.target_node.node_key
                    if target_key not in reachable_from_start:
                        queue.append(target_key)

        unreachable_nodes = node_keys - reachable_from_start
        if unreachable_nodes:
            errors.append(f"The following nodes are unreachable from any START node: {', '.join(sorted(unreachable_nodes))}")

        # 5. Backward Reachability to END nodes
        can_reach_end: Set[str] = set()
        rev_queue = deque([e.node_key for e in end_nodes])
        while rev_queue:
            curr = rev_queue.popleft()
            if curr not in can_reach_end:
                can_reach_end.add(curr)
                for edge in incoming[curr]:
                    source_key = edge.source_node.node_key
                    if source_key not in can_reach_end:
                        rev_queue.append(source_key)

        cannot_reach_end = node_keys - can_reach_end
        if cannot_reach_end:
            errors.append(f"The following nodes cannot reach any END node: {', '.join(sorted(cannot_reach_end))}")

        # 6. Cycle Detection (DFS)
        visited: Dict[str, int] = {k: 0 for k in node_keys} # 0: unvisited, 1: visiting, 2: visited
        cycles: List[List[str]] = []

        def dfs_detect_cycles(curr_key: str, path: List[str]):
            visited[curr_key] = 1
            path.append(curr_key)

            for edge in outgoing[curr_key]:
                # Exception/Rework edges can optionally be tagged, but unbounded cycles are prohibited
                if edge.edge_type == "EXCEPTION":
                    continue # Explicit controlled rework route

                nxt_key = edge.target_node.node_key
                if visited[nxt_key] == 1:
                    cycle_start_idx = path.index(nxt_key)
                    cycle_nodes = path[cycle_start_idx:] + [nxt_key]
                    cycles.append(cycle_nodes)
                elif visited[nxt_key] == 0:
                    dfs_detect_cycles(nxt_key, path)

            path.pop()
            visited[curr_key] = 2

        for start in start_nodes:
            if visited[start.node_key] == 0:
                dfs_detect_cycles(start.node_key, [])

        for k in sorted(node_keys):
            if visited[k] == 0:
                dfs_detect_cycles(k, [])

        if cycles:
            cycle_desc = " -> ".join(cycles[0])
            errors.append(f"Unbounded cyclic dependency detected in workflow: {cycle_desc}. Standard production graphs must be acyclic.")

        # 7. Resource & Factory Scoping Checks
        factory_id = version.process_definition.factory_id
        for node in nodes:
            if node.assigned_line and node.assigned_line.factory_id != factory_id:
                errors.append(f"Node '{node.node_key}' assigns Production Line '{node.assigned_line.code}' belonging to a different factory.")
            if node.assigned_machine and node.assigned_machine.production_line.factory_id != factory_id:
                errors.append(f"Node '{node.node_key}' assigns Machine '{node.assigned_machine.code}' belonging to a different factory.")

        is_valid = len(errors) == 0
        return is_valid, errors, warnings
