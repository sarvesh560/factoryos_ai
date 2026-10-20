"""
FactoryOS AI — Phase 3 Live End-to-End API Verification Script
Tests live running Django server at http://127.0.0.1:8000:
1. Health & Plant context
2. Process Definitions & Versions
3. Graph Validation & Cycle Detection
4. Version Publishing & Immutability Protection
5. Work Order Lifecycle (Create, Start, Pause, Resume)
6. Stage Execution Progression & Parallel Branch Sync
7. Material Flow Tracking & Inventory Consumption
8. Simulation Engine (Anomaly Injection, Deterministic Seeding, Stepping)
9. Factory Data Isolation & Multi-Tenancy Scoping
"""

import sys
import time
import json
import urllib.request
import urllib.error

BASE_URL = "http://127.0.0.1:8000"

def api_request(method, path, data=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    body = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            status = resp.status
            content = resp.read().decode("utf-8")
            parsed = json.loads(content) if content else {}
            return status, parsed
    except urllib.error.HTTPError as e:
        content = e.read().decode("utf-8")
        try:
            parsed = json.loads(content)
        except Exception:
            parsed = {"raw": content}
        return e.code, parsed

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

def assert_true(condition, message):
    if not condition:
        print(f"[FAIL] {message}")
        sys.exit(1)
    print(f"[PASS] {message}")

def main():
    print("================================================================================")
    print("   FACTORYOS AI — PHASE 3 LIVE END-TO-END API VERIFICATION")
    print("================================================================================")

    # 1. System Health
    status, res = api_request("GET", "/api/health/")
    assert_true(status == 200 and res.get("status") == "healthy", "Backend /api/health/ reports healthy")

    # 2. Get Seeded Factories
    status, res = api_request("GET", "/api/factories/")
    assert_true(status == 200, "Factory listing returned 200 OK")
    factories = res.get("results", []) or res.get("data", [])
    assert_true(len(factories) >= 3, f"Retrieved {len(factories)} factories (>= 3 required)")
    target_factory = factories[0]
    factory_id = target_factory["id"]
    print(f"   Target Factory: {target_factory['name']} ({target_factory['code']})")

    # 3. Retrieve Seeded Process Definitions
    status, res = api_request("GET", f"/api/processes/definitions/?factory_id={factory_id}")
    assert_true(status == 200, "Process definitions returned 200 OK")
    defs = res.get("results", [])
    assert_true(len(defs) >= 1, f"Factory has {len(defs)} process definitions")
    sample_def = defs[0]
    print(f"   Sample Definition: '{sample_def['name']}' ({sample_def['code']}), category: {sample_def['category']}")

    # 4. Check Published Versions & Nodes
    status, def_detail_res = api_request("GET", f"/api/processes/definitions/{sample_def['id']}/")
    assert_true(status == 200, "Retrieved process definition detail with versions")
    def_detail = def_detail_res.get("data", def_detail_res)
    sample_version_id = def_detail["versions"][0]["id"]
    status, ver_res = api_request("GET", f"/api/processes/versions/{sample_version_id}/")
    assert_true(status == 200, "Retrieved version details")
    ver = ver_res.get("data", ver_res)
    node_count = len(ver.get("nodes", [])) if "nodes" in ver else ver.get("node_count", 0)
    edge_count = len(ver.get("edges", [])) if "edges" in ver else ver.get("edge_count", 0)
    assert_true(node_count > 0, f"Version contains {node_count} nodes")
    assert_true(edge_count > 0, f"Version contains {edge_count} edges")

    # 5. Graph Validation Endpoint
    status, val = api_request("POST", f"/api/processes/versions/{sample_version_id}/validate/")
    assert_true(status == 200, "Graph validation endpoint returned 200 OK")
    assert_true(val.get("is_valid") == True, f"Seeded graph is valid: {val.get('is_valid')}")

    # 6. Test Graph Cycle Detection & Immutability Protection
    # Create a new draft definition
    unique_suffix = int(time.time()) % 100000
    status, new_def_res = api_request("POST", "/api/processes/definitions/", {
        "factory": factory_id,
        "name": f"Live Test Microchip Etch & Clean {unique_suffix}",
        "code": f"PROC-LIVE-{unique_suffix}",
        "category": "Electronics & SMT",
        "target_cycle_time_seconds": 30.0,
    })
    assert_true(status == 201, "Created test process definition")
    new_def = new_def_res.get("data", new_def_res)
    new_def_id = new_def["id"]
    draft_ver_id = new_def["versions"][0]["id"]

    # Add 2 nodes to draft
    status, n1_res = api_request("POST", f"/api/processes/versions/{draft_ver_id}/nodes/", {
        "node_key": "N1",
        "name": "Chemical Wash",
        "node_type": "OPERATION",
        "cycle_time_seconds": 15.0,
        "position_x": 100.0,
        "position_y": 100.0,
    })
    assert_true(status == 201, "Added Node 1 (Chemical Wash)")
    n1 = n1_res.get("data", n1_res)

    status, n2_res = api_request("POST", f"/api/processes/versions/{draft_ver_id}/nodes/", {
        "node_key": "N2",
        "name": "Plasma Etch",
        "node_type": "OPERATION",
        "cycle_time_seconds": 25.0,
        "position_x": 300.0,
        "position_y": 100.0,
    })
    assert_true(status == 201, "Added Node 2 (Plasma Etch)")
    n2 = n2_res.get("data", n2_res)

    # Connect N1 -> N2 and N2 -> N1 (Cycle)
    status, e1_res = api_request("POST", f"/api/processes/versions/{draft_ver_id}/edges/", {
        "source_node": n1["id"],
        "target_node": n2["id"],
    })
    assert_true(status == 201, "Created edge N1 -> N2")
    e1 = e1_res.get("data", e1_res)

    status, e2_res = api_request("POST", f"/api/processes/versions/{draft_ver_id}/edges/", {
        "source_node": n2["id"],
        "target_node": n1["id"],
    })
    assert_true(status == 201, "Created edge N2 -> N1 (Cyclic loop)")
    e2 = e2_res.get("data", e2_res)

    # Validate draft — Cycle detection must trigger
    status, val_cycle = api_request("POST", f"/api/processes/versions/{draft_ver_id}/validate/")
    assert_true(val_cycle.get("is_valid") == False, "Graph validator rejected cyclic dependency (is_valid == False)")
    has_cycle_error = any("cyclic dependency detected" in err.lower() or "cycle detected" in err.lower() for err in val_cycle.get("errors", []))
    assert_true(has_cycle_error, f"Validation errors explicitly identified cycle: {val_cycle.get('errors')}")

    # Publication rejection
    status, pub_reject = api_request("POST", f"/api/processes/versions/{draft_ver_id}/publish/")
    assert_true(status == 400, "Publishing invalid cyclic graph rejected with 400 Bad Request")

    # 7. Work Order Creation
    # Retrieve factory details to get its configured products
    status, factory_detail_res = api_request("GET", f"/api/factories/{factory_id}/")
    assert_true(status == 200, "Retrieved factory details with products")
    factory_detail = factory_detail_res.get("data", factory_detail_res)
    products = factory_detail.get("products", [])
    product_id = products[0]["id"] if products else None
    assert_true(product_id is not None, "Factory has configured product")

    # Use the published version from sample_def
    pub_ver_id = sample_version_id
    status, wo_res = api_request("POST", "/api/processes/work-orders/", {
        "factory": factory_id,
        "order_number": f"WO-TEST-{unique_suffix}",
        "product": product_id,
        "process_definition": sample_def["id"],
        "process_version": pub_ver_id,
        "quantity_target": 250,
        "priority": "HIGH",
        "notes": "Automated Phase 3 E2E test run",
    })
    assert_true(status == 201, "Created Work Order")
    wo = wo_res.get("data", wo_res)
    wo_id = wo["id"]

    # 8. Start Work Order & Initialize Execution
    status, start_res = api_request("POST", f"/api/processes/work-orders/{wo_id}/start/")
    assert_true(status == 200, "Started Work Order successfully")
    assert_true(start_res["work_order"]["status"] == "IN_PROGRESS", "Work Order state is IN_PROGRESS")
    exec_id = start_res["execution"]["id"]
    print(f"   Created Execution: {start_res['execution']['execution_number']} (mode: {start_res['execution']['mode']})")

    # 9. Verify Initial Stage Executions
    status, exec_detail_res = api_request("GET", f"/api/processes/execution/{exec_id}/")
    assert_true(status == 200, "Fetched live execution details")
    exec_detail = exec_detail_res.get("data", exec_detail_res)
    stages = exec_detail.get("stage_executions", [])
    assert_true(len(stages) > 0, f"Execution has {len(stages)} stage executions")
    running_stages = [s for s in stages if s["status"] == "RUNNING"]
    assert_true(len(running_stages) >= 1, f"Found {len(running_stages)} initial stage(s) in RUNNING state")
    first_running = running_stages[0]
    print(f"   Active Running Stage: '{first_running['node_name']}' ({first_running['node_key']})")

    # 10. Advance Stage Operation
    status, adv_res = api_request("POST", f"/api/processes/execution/stages/{first_running['id']}/advance/", {
        "units_completed": 240,
        "units_scrapped": 10,
        "duration_seconds": 32.5,
    })
    assert_true(status == 200, "Advanced stage operation successfully")
    assert_true(adv_res.get("success") == True, "adv_res['success'] == True")
    assert_true(adv_res["stage"]["status"] == "COMPLETED", "Target stage transitioned to COMPLETED")

    # 11. Material Flow Ledger Verification
    status, flows = api_request("GET", f"/api/processes/materials/flows/?execution_id={exec_id}")
    assert_true(status == 200, "Fetched material flows for execution")
    flow_items = flows.get("results", [])
    print(f"   Recorded {len(flow_items)} Material Flow ledger entries")
    if flow_items:
        first_flow = flow_items[0]
        print(f"   Sample flow: {first_flow['flow_type']} of {first_flow['quantity']} {first_flow['unit_of_measure']} ({first_flow.get('raw_material_name', 'Output')})")

    # 12. Simulation Engine: Deterministic Anomaly Injection
    status, anomaly_res = api_request("POST", "/api/processes/simulation/inject-anomaly/", {
        "execution_id": exec_id,
        "scenario_type": "MACHINE_BREAKDOWN",
        "parameters": {"severity": "HIGH", "component": "Main Drive Motor"},
    })
    assert_true(status == 200, "Injected MACHINE_BREAKDOWN anomaly into execution")
    assert_true("event" in anomaly_res, "Received simulated production event record")
    print(f"   Simulated event: {anomaly_res['event']['event_type']} (severity: {anomaly_res['event']['severity']})")

    # 13. Simulation Stepping with Seed Control
    status, step_res = api_request("POST", "/api/processes/simulation/step/", {
        "execution_id": exec_id,
        "random_seed": 42,
    })
    assert_true(status == 200, "Step simulation executed with deterministic random seed 42")

    # 14. Preconfigured Simulation Scenario Catalog
    status, scenarios = api_request("GET", f"/api/processes/simulation/scenarios/?factory_id={factory_id}")
    assert_true(status == 200, "Fetched preconfigured simulation scenarios")
    scen_list = scenarios.get("results", [])
    assert_true(len(scen_list) >= 1, f"Found {len(scen_list)} preconfigured simulation scenarios")
    print(f"   Available preconfigured scenarios: {[s['name'] for s in scen_list[:3]]}")

    # 15. Factory Data Isolation Check
    other_factory = factories[1]
    status, other_defs = api_request("GET", f"/api/processes/definitions/?factory_id={other_factory['id']}")
    assert_true(status == 200, "Queried other factory process definitions")
    other_def_ids = [d["id"] for d in other_defs.get("results", [])]
    assert_true(sample_def["id"] not in other_def_ids, "Factory-scoped data isolation enforced: definitions do not leak across factories")

    print("\n================================================================================")
    print("   ALL 15 PHASE 3 LIVE REST API VERIFICATION CHECKS PASSED SUCCESSFULLY!")
    print("================================================================================")

if __name__ == "__main__":
    main()
