"""
FactoryOS AI — Live Production Execution Multi-Industry Verification Script
Phase 3: Universal Manufacturing Process Engine (UMPE) Live Verification

Verifies:
1. Factory Isolation & Published Process Linkage across CNC, Textile, and Food & Beverage.
2. Stage sequence enforcement: cannot bypass preceding operations (PENDING stage advancement rejection).
3. Permitted quantity limits: rejection of negative or excessive completion quantities.
4. Paused execution guard: rejection of stage progression while execution is PAUSED.
5. Direct Execution Action API: pause, resume, complete endpoints on /api/processes/execution/<id>/<action>/.
6. Realistic Manufacturing Scenario 1: Vanguard Precision CNC (5-Axis Turbine Blisk Machining).
7. Realistic Manufacturing Scenario 2: Apex Precision Textiles (High-Speed Ring Spinning & Parallel Weaving/Inspection).
8. Realistic Manufacturing Scenario 3: Nordic Pure BioFoods (Continuous UHT Flash Pasteurization & Aseptic Bottling).
9. Live Event Audit Logging & Material Flow Records.
"""
import sys
import json
import urllib.request
import urllib.error
from typing import Dict, Any, Optional

BASE_URL = "http://127.0.0.1:8000"

def make_request(path: str, method: str = "GET", data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"} if data is not None else {}
    body = json.dumps(data).encode("utf-8") if data is not None else None

    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read().decode("utf-8")
            return json.loads(content) if content else {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            parsed = json.loads(err_body)
            return {"_http_status": e.code, **parsed}
        except Exception:
            return {"_http_status": e.code, "error": err_body}

def log_check(check_num: int, title: str, success: bool, details: str = ""):
    tag = "[PASS]" if success else "[FAIL]"
    print(f"{tag} Check {check_num}: {title}")
    if details:
        print(f"       -> {details}")
    if not success:
        sys.exit(1)

def run_verification():
    print("=" * 80)
    print("FACTORYOS AI — PHASE 3 LIVE PRODUCTION EXECUTION VERIFICATION")
    print("=" * 80)

    # --------------------------------------------------------------------------
    # 1. Inspect Seeded Factories & Retrieve Published Processes
    # --------------------------------------------------------------------------
    factories_resp = make_request("/api/factories/")
    factories = {f["code"]: f for f in factories_resp.get("results", [])}
    has_all_factories = all(c in factories for c in ("FAC-CNC-02", "FAC-TEX-01", "FAC-FOOD-03"))
    log_check(1, "Retrieve seeded multi-industry factories", has_all_factories,
              f"Found {len(factories)} factories (CNC, Textile, Food present)")

    cnc_factory = factories["FAC-CNC-02"]
    tex_factory = factories["FAC-TEX-01"]
    food_factory = factories["FAC-FOOD-03"]

    # --------------------------------------------------------------------------
    # 2. Dependency Sequence Guard: Attempt to Advance PENDING Stage
    # --------------------------------------------------------------------------
    import time
    ts = int(time.time())

    # Create isolated CNC test order
    wo_cnc_data = make_request("/api/processes/work-orders/", method="POST", data={
        "factory_id": cnc_factory["id"],
        "order_number": f"WO-CNC-GUARD-{ts}",
        "product_id": make_request(f"/api/factories/{cnc_factory['id']}/products/")["results"][0]["id"],
        "process_definition_id": make_request(f"/api/processes/definitions/?factory_id={cnc_factory['id']}")["results"][0]["id"],
        "quantity_target": 25,
        "status": "RELEASED",
        "priority": "HIGH",
    })
    cnc_wo_id = wo_cnc_data.get("data", {}).get("id")
    log_check(2, "Create CNC Work Order for guard verification", bool(cnc_wo_id), f"Created {cnc_wo_id}")

    # Start execution
    start_resp = make_request(f"/api/processes/work-orders/{cnc_wo_id}/start/", method="POST")
    exec_id = start_resp.get("execution", {}).get("id")
    log_check(3, "Start CNC execution run", bool(exec_id) and start_resp.get("execution", {}).get("status") == "RUNNING",
              f"Execution: {start_resp.get('execution', {}).get('execution_number')}")

    # Get stages: find a PENDING stage (e.g. CMM-01 or CLEAN-01)
    exec_details = make_request(f"/api/processes/execution/{exec_id}/")
    stages = exec_details.get("data", {}).get("stage_executions", [])
    pending_stage = next((s for s in stages if s["status"] == "PENDING"), None)
    running_stage = next((s for s in stages if s["status"] == "RUNNING"), None)

    log_check(4, "Identify initial running and pending stages", bool(pending_stage and running_stage),
              f"Active: {running_stage['node_key']} ({running_stage['node_name']}), Pending: {pending_stage['node_key']}")

    # Try advancing the PENDING stage directly (bypassing preceding operations)
    bypass_resp = make_request(f"/api/processes/execution/stages/{pending_stage['id']}/advance/", method="POST", data={
        "units_completed": 25
    })
    bypass_rejected = bypass_resp.get("_http_status") == 400 and "PENDING status" in bypass_resp.get("error", {}).get("message", "")
    log_check(5, "Reject advancing PENDING stage (Strict Graph Dependency Guard)", bypass_rejected,
              f"HTTP 400: {bypass_resp.get('error', {}).get('message')}")

    # --------------------------------------------------------------------------
    # 3. Permitted Quantity Boundary Checks
    # --------------------------------------------------------------------------
    excess_resp = make_request(f"/api/processes/execution/stages/{running_stage['id']}/advance/", method="POST", data={
        "units_completed": 99999
    })
    excess_rejected = excess_resp.get("_http_status") == 400 and "exceeds available" in excess_resp.get("error", {}).get("message", "")
    log_check(6, "Reject stage advancement with excessive completed quantity", excess_rejected,
              f"HTTP 400: {excess_resp.get('error', {}).get('message')}")

    neg_resp = make_request(f"/api/processes/execution/stages/{running_stage['id']}/advance/", method="POST", data={
        "units_completed": -10
    })
    neg_rejected = neg_resp.get("_http_status") == 400 and "cannot be negative" in neg_resp.get("error", {}).get("message", "")
    log_check(7, "Reject stage advancement with negative completed quantity", neg_rejected,
              f"HTTP 400: {neg_resp.get('error', {}).get('message')}")

    # --------------------------------------------------------------------------
    # 4. Paused Execution Guard & Direct Execution Action API
    # --------------------------------------------------------------------------
    # Pause via direct execution action API
    pause_resp = make_request(f"/api/processes/execution/{exec_id}/pause/", method="POST", data={"reason": "Audit hold"})
    exec_paused = pause_resp.get("success") is True and pause_resp.get("execution", {}).get("status") == "PAUSED"
    log_check(8, "Pause execution via direct execution endpoint", exec_paused, f"Status: {pause_resp.get('execution', {}).get('status')}")

    # Attempt to advance active stage while paused -> must be rejected
    paused_advance_resp = make_request(f"/api/processes/execution/stages/{running_stage['id']}/advance/", method="POST", data={
        "units_completed": 25
    })
    paused_advance_rejected = paused_advance_resp.get("_http_status") == 400 and "PAUSED" in paused_advance_resp.get("error", {}).get("message", "")
    log_check(9, "Reject stage progression while execution is PAUSED", paused_advance_rejected,
              f"HTTP 400: {paused_advance_resp.get('error', {}).get('message')}")

    # Resume via direct execution action API
    resume_resp = make_request(f"/api/processes/execution/{exec_id}/resume/", method="POST")
    exec_resumed = resume_resp.get("success") is True and resume_resp.get("execution", {}).get("status") == "RUNNING"
    log_check(10, "Resume execution via direct execution endpoint", exec_resumed, f"Status: {resume_resp.get('execution', {}).get('status')}")

    # Complete this guard test order cleanly
    complete_resp = make_request(f"/api/processes/execution/{exec_id}/complete/", method="POST")
    exec_completed = complete_resp.get("success") is True and complete_resp.get("execution", {}).get("status") == "COMPLETED"
    log_check(11, "Complete execution run cleanly", exec_completed, f"Progress: {complete_resp.get('execution', {}).get('current_progress_percent')}%")

    # --------------------------------------------------------------------------
    # 5. Realistic Manufacturing Scenario 1: Vanguard Precision CNC
    # --------------------------------------------------------------------------
    # Full multi-stage traversal: START -> FACE -> MILL -> EDM -> CMM -> CLEAN -> END
    print("\n--- Running Scenario 1: Vanguard Precision CNC (Aerospace Turbine Machining) ---")
    wo_cnc_full = make_request("/api/processes/work-orders/", method="POST", data={
        "factory_id": cnc_factory["id"],
        "order_number": f"WO-CNC-FULL-{ts}",
        "product_id": make_request(f"/api/factories/{cnc_factory['id']}/products/")["results"][0]["id"],
        "process_definition_id": make_request(f"/api/processes/definitions/?factory_id={cnc_factory['id']}")["results"][0]["id"],
        "quantity_target": 20,
        "status": "RELEASED",
        "priority": "URGENT",
    })
    cnc_full_id = wo_cnc_full["data"]["id"]
    cnc_start = make_request(f"/api/processes/work-orders/{cnc_full_id}/start/", method="POST")
    cnc_exec_id = cnc_start["execution"]["id"]

    # Step through stages sequentially
    steps_completed = 0
    while True:
        curr = make_request(f"/api/processes/execution/{cnc_exec_id}/")["data"]
        if curr["status"] == "COMPLETED":
            break
        running = [s for s in curr["stage_executions"] if s["status"] == "RUNNING"]
        if not running:
            # Check if all completed
            if all(s["status"] == "COMPLETED" for s in curr["stage_executions"]):
                break
            break
        for st in running:
            adv = make_request(f"/api/processes/execution/stages/{st['id']}/advance/", method="POST", data={
                "units_completed": 20,
                "units_scrapped": 0,
            })
            if adv.get("success"):
                steps_completed += 1

    final_cnc = make_request(f"/api/processes/execution/{cnc_exec_id}/")["data"]
    cnc_passed = final_cnc["status"] == "COMPLETED" and final_cnc["total_units_output"] == 20
    log_check(12, "Full CNC Aerospace manufacturing traversal to completion", cnc_passed,
              f"Status: {final_cnc['status']}, Output: {final_cnc['total_units_output']}/20, Steps: {steps_completed}")

    # --------------------------------------------------------------------------
    # 6. Realistic Manufacturing Scenario 2: Apex Precision Textiles (Parallel Graph)
    # --------------------------------------------------------------------------
    # Tests PARALLEL_SPLIT and PARALLEL_JOIN synchronization:
    # START -> CARD -> DRAW -> SPIN -> SPLIT -> (WEAV & INSP parallel) -> JOIN -> WIND -> END
    print("\n--- Running Scenario 2: Apex Precision Textiles (Parallel Ring Spinning & Weaving) ---")
    wo_tex = make_request("/api/processes/work-orders/", method="POST", data={
        "factory_id": tex_factory["id"],
        "order_number": f"WO-TEX-PARALLEL-{ts}",
        "product_id": make_request(f"/api/factories/{tex_factory['id']}/products/")["results"][0]["id"],
        "process_definition_id": make_request(f"/api/processes/definitions/?factory_id={tex_factory['id']}")["results"][0]["id"],
        "quantity_target": 100,
        "status": "RELEASED",
        "priority": "NORMAL",
    })
    tex_wo_id = wo_tex["data"]["id"]
    tex_start = make_request(f"/api/processes/work-orders/{tex_wo_id}/start/", method="POST")
    tex_exec_id = tex_start["execution"]["id"]

    # 1. Advance CARD-01
    curr = make_request(f"/api/processes/execution/{tex_exec_id}/")["data"]
    st_card = next(s for s in curr["stage_executions"] if s["node_key"] == "CARD-01")
    make_request(f"/api/processes/execution/stages/{st_card['id']}/advance/", method="POST", data={"units_completed": 100})

    # 2. Advance DRAW-01
    curr = make_request(f"/api/processes/execution/{tex_exec_id}/")["data"]
    st_draw = next(s for s in curr["stage_executions"] if s["node_key"] == "DRAW-01")
    make_request(f"/api/processes/execution/stages/{st_draw['id']}/advance/", method="POST", data={"units_completed": 100})

    # 3. Advance SPIN-01 -> this triggers SPLIT-01, which activates BOTH WEAV-01 and INSP-01
    curr = make_request(f"/api/processes/execution/{tex_exec_id}/")["data"]
    st_spin = next(s for s in curr["stage_executions"] if s["node_key"] == "SPIN-01")
    make_request(f"/api/processes/execution/stages/{st_spin['id']}/advance/", method="POST", data={"units_completed": 100})

    # Verify both WEAV-01 and INSP-01 are running concurrently
    curr = make_request(f"/api/processes/execution/{tex_exec_id}/")["data"]
    st_weav = next(s for s in curr["stage_executions"] if s["node_key"] == "WEAV-01")
    st_insp = next(s for s in curr["stage_executions"] if s["node_key"] == "INSP-01")
    st_join = next(s for s in curr["stage_executions"] if s["node_key"] == "JOIN-01")

    parallel_active = st_weav["status"] == "RUNNING" and st_insp["status"] == "RUNNING" and st_join["status"] == "PENDING"
    log_check(13, "Parallel Split activation: Weaving and AI Inspection running concurrently", parallel_active,
              f"Weaving: {st_weav['status']}, Inspection: {st_insp['status']}, Join: {st_join['status']}")

    # Complete ONLY Weaving: Join should remain PENDING waiting for Inspection
    make_request(f"/api/processes/execution/stages/{st_weav['id']}/advance/", method="POST", data={"units_completed": 98, "units_scrapped": 2})
    curr = make_request(f"/api/processes/execution/{tex_exec_id}/")["data"]
    st_join_after_one = next(s for s in curr["stage_executions"] if s["node_key"] == "JOIN-01")
    join_still_pending = st_join_after_one["status"] == "PENDING"
    log_check(14, "Parallel Join synchronization: JOIN remains PENDING until all parallel branches complete", join_still_pending,
              f"Join Status: {st_join_after_one['status']}")

    # Complete Inspection: Now Join should unlock to RUNNING
    make_request(f"/api/processes/execution/stages/{st_insp['id']}/advance/", method="POST", data={"units_completed": 100})
    curr = make_request(f"/api/processes/execution/{tex_exec_id}/")["data"]
    st_join_unlocked = next(s for s in curr["stage_executions"] if s["node_key"] == "JOIN-01")
    join_running = st_join_unlocked["status"] == "RUNNING"
    log_check(15, "Parallel Join unlocks to RUNNING upon all branches completing", join_running,
              f"Join Status: {st_join_unlocked['status']}")

    # Advance JOIN -> WIND -> END
    make_request(f"/api/processes/execution/stages/{st_join_unlocked['id']}/advance/", method="POST", data={"units_completed": 98})
    curr = make_request(f"/api/processes/execution/{tex_exec_id}/")["data"]
    st_wind = next(s for s in curr["stage_executions"] if s["node_key"] == "WIND-01")
    make_request(f"/api/processes/execution/stages/{st_wind['id']}/advance/", method="POST", data={"units_completed": 98})

    final_tex = make_request(f"/api/processes/execution/{tex_exec_id}/")["data"]
    tex_completed = final_tex["status"] == "COMPLETED" and final_tex["total_units_output"] == 98 and final_tex["total_units_scrap"] == 2
    log_check(16, "Full Textile parallel workflow completed with scrap accounting", tex_completed,
              f"Status: {final_tex['status']}, Output: {final_tex['total_units_output']} good, Scrap: {final_tex['total_units_scrap']}")

    # --------------------------------------------------------------------------
    # 7. Realistic Manufacturing Scenario 3: Nordic Pure BioFoods
    # --------------------------------------------------------------------------
    # START -> PAST -> BOTT -> SEAL -> INSP -> PACK -> END
    print("\n--- Running Scenario 3: Nordic Pure BioFoods (Aseptic Bottling & Cold-Chain) ---")
    wo_food = make_request("/api/processes/work-orders/", method="POST", data={
        "factory_id": food_factory["id"],
        "order_number": f"WO-FOOD-ASEPTIC-{ts}",
        "product_id": make_request(f"/api/factories/{food_factory['id']}/products/")["results"][0]["id"],
        "process_definition_id": make_request(f"/api/processes/definitions/?factory_id={food_factory['id']}")["results"][0]["id"],
        "quantity_target": 500,
        "status": "RELEASED",
        "priority": "HIGH",
    })
    food_wo_id = wo_food["data"]["id"]
    food_start = make_request(f"/api/processes/work-orders/{food_wo_id}/start/", method="POST")
    food_exec_id = food_start["execution"]["id"]

    # Step through all food stages
    food_steps = 0
    while True:
        curr = make_request(f"/api/processes/execution/{food_exec_id}/")["data"]
        if curr["status"] == "COMPLETED":
            break
        running = [s for s in curr["stage_executions"] if s["status"] == "RUNNING"]
        if not running:
            break
        for st in running:
            adv = make_request(f"/api/processes/execution/stages/{st['id']}/advance/", method="POST", data={
                "units_completed": 500,
            })
            if adv.get("success"):
                food_steps += 1

    final_food = make_request(f"/api/processes/execution/{food_exec_id}/")["data"]
    food_completed = final_food["status"] == "COMPLETED" and final_food["total_units_output"] == 500
    log_check(17, "Full Food Aseptic Packaging traversal completed", food_completed,
              f"Status: {final_food['status']}, Output: {final_food['total_units_output']}/500 units, Steps: {food_steps}")

    # --------------------------------------------------------------------------
    # 8. Factory Boundary Isolation for Executions
    # --------------------------------------------------------------------------
    execs_cnc = make_request(f"/api/processes/execution/?factory_id={cnc_factory['id']}")["results"]
    execs_tex = make_request(f"/api/processes/execution/?factory_id={tex_factory['id']}")["results"]
    execs_food = make_request(f"/api/processes/execution/?factory_id={food_factory['id']}")["results"]

    ids_cnc = {e["id"] for e in execs_cnc}
    ids_tex = {e["id"] for e in execs_tex}
    ids_food = {e["id"] for e in execs_food}

    # Verify strictly zero overlap between factory executions
    zero_overlap = (len(ids_cnc & ids_tex) == 0) and (len(ids_cnc & ids_food) == 0) and (len(ids_tex & ids_food) == 0)

    # Verify returned work orders belong to their respective factories
    cnc_wo_ids = list({e["work_order"] for e in execs_cnc})[:5]
    cnc_matches = all(
        make_request(f"/api/processes/work-orders/{wo_id}/").get("data", {}).get("factory") == cnc_factory["id"]
        for wo_id in cnc_wo_ids
    )

    tex_wo_ids = list({e["work_order"] for e in execs_tex})[:5]
    tex_matches = all(
        make_request(f"/api/processes/work-orders/{wo_id}/").get("data", {}).get("factory") == tex_factory["id"]
        for wo_id in tex_wo_ids
    )

    factory_isolation = zero_overlap and cnc_matches and tex_matches
    log_check(18, "Strict backend factory boundary isolation for executions", factory_isolation,
              f"CNC: {len(execs_cnc)} runs, Textile: {len(execs_tex)} runs, Food: {len(execs_food)} runs (Zero cross-factory leakage)")

    # --------------------------------------------------------------------------
    # 9. Audit Event Trail & Material Flows Persistence
    # --------------------------------------------------------------------------
    events = make_request(f"/api/processes/events/?execution_id={tex_exec_id}")["results"]
    flows = make_request(f"/api/processes/materials/flows/?execution_id={tex_exec_id}")["results"]
    audit_persisted = len(events) >= 5 and len(flows) >= 3
    log_check(19, "Live execution audit events and material flows persisted in database", audit_persisted,
              f"Audit Events: {len(events)}, Material Flows: {len(flows)}")

    print("\n" + "=" * 80)
    print("ALL 19 LIVE PRODUCTION EXECUTION VERIFICATION CHECKS PASSED WITH 100% SUCCESS!")
    print("=" * 80)

if __name__ == "__main__":
    run_verification()
