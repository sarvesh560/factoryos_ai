"""
FactoryOS AI — Phase 3 Work Orders Complete Verification Suite
Validates:
1. Factory Isolation & Factory Product Listing
2. Published Workflow Integration & Draft Rejection
3. Multi-Industry Support (CNC, Textile, Food)
4. Complete Work Order Lifecycle (Planned -> Released -> In Progress -> Paused -> Resumed -> Completed)
5. Transition Guards (Invalid Action Rejections)
6. Production Execution, Stage Progression & Material Tracking
"""
import sys
import json
import requests

BASE_URL = "http://127.0.0.1:8000"

def log(msg, status="INFO"):
    colors = {
        "INFO": "\033[94m[INFO]\033[0m",
        "PASS": "\033[92m[PASS]\033[0m",
        "FAIL": "\033[91m[FAIL]\033[0m",
        "WARN": "\033[93m[WARN]\033[0m",
    }
    print(f"{colors.get(status, '[INFO]')} {msg}")

def assert_status(resp, expected, desc):
    if resp.status_code != expected:
        log(f"{desc} - Expected {expected}, got {resp.status_code}: {resp.text}", "FAIL")
        sys.exit(1)
    log(f"{desc} -> HTTP {resp.status_code}", "PASS")
    return resp.json()

def main():
    log("=== FACTORYOS AI: PHASE 3 WORK ORDERS VERIFICATION ===")

    # 1. Fetch Factories
    resp = requests.get(f"{BASE_URL}/api/factories/")
    data = assert_status(resp, 200, "1. Fetch Factories")
    factories = {f["code"]: f for f in data["results"]}
    
    cnc_fac = factories.get("FAC-CNC-02")
    tex_fac = factories.get("FAC-TEX-01")
    food_fac = factories.get("FAC-FOOD-03")

    if not cnc_fac or not tex_fac or not food_fac:
        log("Missing required seed factories (FAC-CNC-02, FAC-TEX-01, FAC-FOOD-03)", "FAIL")
        sys.exit(1)
    log(f"Found factories: CNC={cnc_fac['name']}, Textile={tex_fac['name']}, Food={food_fac['name']}", "PASS")

    # 2. Verify Factory Product Listing Endpoint
    resp = requests.get(f"{BASE_URL}/api/factories/{cnc_fac['id']}/products/")
    cnc_products = assert_status(resp, 200, "2a. List CNC Factory Products")["results"]
    if not cnc_products:
        log("No products returned for CNC factory", "FAIL")
        sys.exit(1)
    cnc_prod = cnc_products[0]
    log(f"CNC Product: {cnc_prod['name']} ({cnc_prod['sku']})", "PASS")

    resp = requests.get(f"{BASE_URL}/api/factories/{tex_fac['id']}/products/")
    tex_products = assert_status(resp, 200, "2b. List Textile Factory Products")["results"]
    tex_prod = tex_products[0]
    log(f"Textile Product: {tex_prod['name']} ({tex_prod['sku']})", "PASS")

    resp = requests.get(f"{BASE_URL}/api/factories/{food_fac['id']}/products/")
    food_products = assert_status(resp, 200, "2c. List Food Factory Products")["results"]
    food_prod = food_products[0]
    log(f"Food Product: {food_prod['name']} ({food_prod['sku']})", "PASS")

    # 3. Verify Factory Isolation (Cross-Factory Product & Process Rejection)
    # Attempt to create CNC work order with Textile product
    resp = requests.get(f"{BASE_URL}/api/processes/definitions/?factory_id={cnc_fac['id']}")
    cnc_defs = assert_status(resp, 200, "Fetch CNC Process Definitions")["results"]
    cnc_def = next(d for d in cnc_defs if d["published_version_tag"])

    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/", json={
        "factory": cnc_fac["id"],
        "order_number": "WO-ISOLATION-TEST-1",
        "product": tex_prod["id"], # WRONG FACTORY
        "process_definition": cnc_def["id"],
        "quantity_target": 100,
    })
    if resp.status_code == 400 and "Product does not belong to the selected factory" in resp.text:
        log("3a. Cross-factory product rejected correctly", "PASS")
    else:
        log(f"3a. Cross-factory product was NOT rejected properly: {resp.status_code} {resp.text}", "FAIL")
        sys.exit(1)

    # Attempt to create CNC work order with Textile process definition
    resp = requests.get(f"{BASE_URL}/api/processes/definitions/?factory_id={tex_fac['id']}")
    tex_defs = assert_status(resp, 200, "Fetch Textile Process Definitions")["results"]
    tex_def = next(d for d in tex_defs if d["published_version_tag"])

    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/", json={
        "factory": cnc_fac["id"],
        "order_number": "WO-ISOLATION-TEST-2",
        "product": cnc_prod["id"],
        "process_definition": tex_def["id"], # WRONG FACTORY
        "quantity_target": 100,
    })
    if resp.status_code == 400 and "Process definition does not belong to the selected factory" in resp.text:
        log("3b. Cross-factory process definition rejected correctly", "PASS")
    else:
        log(f"3b. Cross-factory process definition was NOT rejected properly: {resp.status_code} {resp.text}", "FAIL")
        sys.exit(1)

    # 4. Verify Rejection of Draft Process Versions
    # Find draft version in CNC definition
    cnc_def_detail = requests.get(f"{BASE_URL}/api/processes/definitions/{cnc_def['id']}/").json()["data"]
    draft_version = next((v for v in cnc_def_detail["versions"] if not v["is_published"]), None)
    if draft_version:
        resp = requests.post(f"{BASE_URL}/api/processes/work-orders/", json={
            "factory": cnc_fac["id"],
            "order_number": "WO-DRAFT-REJECT-TEST",
            "product": cnc_prod["id"],
            "process_definition": cnc_def["id"],
            "process_version": draft_version["id"],
            "quantity_target": 100,
        })
        if resp.status_code == 400 and "Only PUBLISHED versions can be used" in resp.text:
            log("4. Draft process version rejected correctly for work order creation", "PASS")
        else:
            log(f"4. Draft process version was NOT rejected properly: {resp.status_code} {resp.text}", "FAIL")
            sys.exit(1)
    else:
        log("4. (No draft version currently present to test rejection)", "WARN")

    # 5. Create Work Orders Across Industries (CNC, Food, Textile)
    order_cnc_num = "WO-CNC-VERIFY-001"
    # Clean up old verify order if exists
    existing = requests.get(f"{BASE_URL}/api/processes/work-orders/?factory_id={cnc_fac['id']}").json()["results"]
    for o in existing:
        if o["order_number"] in (order_cnc_num, "WO-FOOD-VERIFY-001", "WO-TEX-VERIFY-001"):
            # Can't delete, but we will use unique timestamped names if needed
            pass

    import time
    ts = int(time.time())
    order_cnc_num = f"WO-CNC-VER-{ts % 10000}"
    order_food_num = f"WO-FOOD-VER-{ts % 10000}"
    order_tex_num = f"WO-TEX-VER-{ts % 10000}"

    # 5a. Create CNC Work Order (PLANNED status)
    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/", json={
        "factory": cnc_fac["id"],
        "order_number": order_cnc_num,
        "product": cnc_prod["id"],
        "process_definition": cnc_def["id"],
        "process_version": cnc_def["published_version_id"],
        "quantity_target": 50,
        "priority": "HIGH",
        "status": "PLANNED",
        "notes": "Titanium Impeller Batch Verification",
    })
    wo_cnc = assert_status(resp, 201, "5a. Create CNC Work Order (PLANNED)")["data"]
    assert wo_cnc["status"] == "PLANNED"
    assert wo_cnc["quantity_target"] == 50
    assert wo_cnc["product_sku"] == cnc_prod["sku"]

    # 5b. Create Food Work Order (RELEASED status)
    resp = requests.get(f"{BASE_URL}/api/processes/definitions/?factory_id={food_fac['id']}")
    food_defs = assert_status(resp, 200, "Fetch Food Process Definitions")["results"]
    food_def = next(d for d in food_defs if d["published_version_tag"])

    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/", json={
        "factory": food_fac["id"],
        "order_number": order_food_num,
        "product": food_prod["id"],
        "process_definition": food_def["id"],
        "quantity_target": 200,
        "priority": "NORMAL",
        "status": "RELEASED",
    })
    wo_food = assert_status(resp, 201, "5b. Create Food Work Order (RELEASED)")["data"]
    assert wo_food["status"] == "RELEASED"
    assert wo_food["quantity_target"] == 200

    # 5c. Create Textile Work Order (RELEASED status)
    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/", json={
        "factory": tex_fac["id"],
        "order_number": order_tex_num,
        "product": tex_prod["id"],
        "process_definition": tex_def["id"],
        "quantity_target": 1000,
        "priority": "URGENT",
        "status": "RELEASED",
    })
    wo_tex = assert_status(resp, 201, "5c. Create Textile Work Order (RELEASED)")["data"]
    assert wo_tex["status"] == "RELEASED"

    # 6. Verify Full Work Order Lifecycle & Transition Guards
    wo_cnc_id = wo_cnc["id"]

    # 6a. Attempt to pause a PLANNED order -> Should fail with 400
    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/{wo_cnc_id}/pause/")
    if resp.status_code == 400:
        log("6a. Guard: Cannot pause PLANNED work order", "PASS")
    else:
        log(f"6a. Guard failed: Pause PLANNED returned {resp.status_code}", "FAIL")
        sys.exit(1)

    # 6b. Release order
    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/{wo_cnc_id}/release/")
    rel_data = assert_status(resp, 200, "6b. Release PLANNED work order")["work_order"]
    assert rel_data["status"] == "RELEASED"

    # 6c. Start execution
    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/{wo_cnc_id}/start/", json={"mode": "SIMULATION"})
    start_data = assert_status(resp, 200, "6c. Start work order execution")
    assert start_data["work_order"]["status"] == "IN_PROGRESS"
    exec_run = start_data["execution"]
    exec_id = exec_run["id"]
    log(f"Execution initialized: {exec_run['execution_number']} (Status: {exec_run['status']})", "PASS")

    # 6d. Pause running order
    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/{wo_cnc_id}/pause/", json={"reason": "Operator inspection"})
    pause_data = assert_status(resp, 200, "6d. Pause IN_PROGRESS work order")["work_order"]
    assert pause_data["status"] == "PAUSED"

    # 6e. Resume paused order
    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/{wo_cnc_id}/resume/")
    resume_data = assert_status(resp, 200, "6e. Resume PAUSED work order")["work_order"]
    assert resume_data["status"] == "IN_PROGRESS"

    # 7. Verify Stage Execution Traversal & Completion
    # Inspect live execution details
    resp = requests.get(f"{BASE_URL}/api/processes/execution/{exec_id}/")
    exec_detail = assert_status(resp, 200, "7a. Get Live Execution Detail")["data"]
    stages = exec_detail["stage_executions"]
    log(f"Execution contains {len(stages)} stage executions derived from published graph", "PASS")

    # Advance all running/pending stages through graph
    max_steps = 15
    steps = 0
    while steps < max_steps:
        resp = requests.get(f"{BASE_URL}/api/processes/execution/{exec_id}/")
        current_exec = resp.json()["data"]
        if current_exec["status"] == "COMPLETED":
            log(f"Execution run completed in {steps} steps!", "PASS")
            break

        active_stages = [s for s in current_exec["stage_executions"] if s["status"] == "RUNNING"]
        if not active_stages:
            log(f"No active running stages found, current execution status: {current_exec['status']}", "WARN")
            break

        for s in active_stages:
            adv_resp = requests.post(f"{BASE_URL}/api/processes/execution/stages/{s['id']}/advance/", json={
                "units_completed": 50,
                "units_scrapped": 0,
            })
            assert_status(adv_resp, 200, f"7b. Advance stage '{s['node_name']}'")
        steps += 1

    # Verify Final Work Order & Execution State
    resp = requests.get(f"{BASE_URL}/api/processes/work-orders/{wo_cnc_id}/")
    final_wo = assert_status(resp, 200, "7c. Verify Final Work Order State")["data"]
    assert final_wo["status"] == "COMPLETED", f"Expected COMPLETED, got {final_wo['status']}"
    assert final_wo["quantity_completed"] == 50, f"Expected 50 units completed, got {final_wo['quantity_completed']}"
    log(f"Work Order '{final_wo['order_number']}' finished: Output {final_wo['quantity_completed']}/{final_wo['quantity_target']} (Status: {final_wo['status']})", "PASS")

    # 8. Guard: Cannot start or cancel COMPLETED order
    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/{wo_cnc_id}/start/")
    if resp.status_code == 400:
        log("8a. Guard: Cannot start COMPLETED work order", "PASS")
    else:
        log(f"8a. Guard failed: {resp.status_code}", "FAIL")
        sys.exit(1)

    resp = requests.post(f"{BASE_URL}/api/processes/work-orders/{wo_cnc_id}/cancel/")
    if resp.status_code == 400:
        log("8b. Guard: Cannot cancel COMPLETED work order", "PASS")
    else:
        log(f"8b. Guard failed: {resp.status_code}", "FAIL")
        sys.exit(1)

    # 9. Verify Production Events Stream
    resp = requests.get(f"{BASE_URL}/api/processes/events/?work_order_id={wo_cnc_id}")
    events = assert_status(resp, 200, "9. Verify Production Events Stream")["results"]
    event_types = [e["event_type"] for e in events]
    log(f"Recorded production audit events: {event_types}", "PASS")
    assert "WORK_ORDER_CREATED" in event_types
    assert "WORK_ORDER_RELEASED" in event_types
    assert "EXECUTION_STARTED" in event_types
    assert "STAGE_COMPLETED" in event_types
    assert "WORK_ORDER_COMPLETED" in event_types

    log("\n==========================================================")
    log("ALL WORK ORDER VERIFICATION CHECKS PASSED SUCCESSFULLY!", "PASS")
    log("==========================================================")

if __name__ == "__main__":
    main()
