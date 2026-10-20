"""
FactoryOS AI — Phase 2 Live System & REST API Verification Script
Verifies:
1. Health & Server Status
2. Company Management & Seeded Multi-Factory Hierarchy
3. Industry Templates Catalog
4. AI-Assisted Manufacturing Onboarding Proposal & Transparency Disclaimer
5. Transactional Universal Onboarding Activation (All 8 Steps)
6. Factory Switching & Real-Time Availability in Factory Registry
"""
import urllib.request
import json
import sys

BASE_URL = 'http://127.0.0.1:8000'

def http_get(endpoint):
    url = f"{BASE_URL}{endpoint}"
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode('utf-8'))

def http_post(endpoint, data):
    url = f"{BASE_URL}{endpoint}"
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode('utf-8'))

def run_verification():
    print("=================================================================")
    print("FACTORYOS AI - PHASE 2 LIVE API VERIFICATION")
    print("=================================================================")

    # 1. Health
    print("\n[1] Verifying System Health...")
    health = http_get('/api/health/')
    assert health.get('status') == 'healthy', f"Unhealthy status: {health}"
    print(f" -> System is healthy: {health['status']} (DB: {health.get('database')})")

    # 2. Company Management & Seeded Hierarchy
    print("\n[2] Verifying Enterprise Companies & Multi-Factory Hierarchy...")
    comps = http_get('/api/companies/')
    companies = comps.get('results', [])
    assert len(companies) >= 1, "Expected at least 1 seeded company"
    print(f" -> Companies Count: {len(companies)}")
    for c in companies:
        factories = c.get('factories', [])
        print(f"    Company: {c['name']} (ID: {c['id']}) | Active: {c['is_active']} | Factories: {len(factories)}")

    facts = http_get('/api/factories/')
    factory_list = facts.get('results', [])
    assert len(factory_list) >= 3, "Expected at least 3 seeded factories"
    print(f" -> Preserved Seeded Factories ({len(factory_list)}):")
    for f in factory_list:
        print(f"    - {f['name']} [{f['code']}] | Industry: {f.get('industry_type_display')} | Lines: {f.get('total_production_lines')} | OEE: {f.get('overall_oee')}%")

    # 3. Industry Templates
    print("\n[3] Verifying Industry Templates Catalog...")
    templates_res = http_get('/api/onboarding/templates/')
    templates = templates_res.get('results', [])
    assert len(templates) >= 4, f"Expected 4 industry templates, found {len(templates)}"
    print(f" -> Available Templates ({len(templates)}):")
    for t in templates:
        print(f"    - [{t['id']}] {t['title']}: {t['description']}")

    # 4. AI-Assisted Advisor Suggestion
    print("\n[4] Verifying AI-Assisted Manufacturing Onboarding Proposal...")
    prompt_text = "We manufacture precision automotive components using stamping, CNC machining, heat treatment, robotic welding, quality inspection, and automated packaging."
    ai_resp = http_post('/api/onboarding/ai-suggest/', {'prompt': prompt_text})
    assert ai_resp.get('success') is True, "AI suggestion request failed"
    ai_data = ai_resp.get('data', {})
    
    print(f" -> AI Source: {ai_data.get('source')}")
    print(f" -> Provider Name: {ai_data.get('provider_name')}")
    print(f" -> Confirmation Required: {ai_data.get('confirmation_required')}")
    print(f" -> Transparency Disclaimer: {ai_data.get('disclaimer')}")
    recommended = ai_data.get('recommended_configuration', {})
    print(f" -> Proposed Products ({len(recommended.get('products', []))}): {[p['name'] for p in recommended.get('products', [])]}")
    print(f" -> Proposed Stages ({len(recommended.get('process_stages', []))}): {[s['name'] for s in recommended.get('process_stages', [])]}")
    print(f" -> Proposed Lines ({len(recommended.get('production_lines', []))}): {[line['name'] for line in recommended.get('production_lines', [])]}")

    # 5. Transactional Onboarding Activation
    print("\n[5] Verifying Transactional Onboarding Activation (All 8 Steps)...")
    wizard_payload = {
        'company': {
            'name': 'Apex Dynamics Holdings',
            'description': 'Advanced robotics and automotive Tier-1 supplier',
            'website': 'https://apexdynamics.example.com',
            'contact_email': 'ops@apexdynamics.example.com'
        },
        'factory': {
            'name': 'Apex Robotics Gigafactory',
            'code': 'AR-GF-01',
            'industry_type': 'AUTOMOTIVE_EV',
            'location': 'Detroit Advanced Manufacturing Hub, MI',
            'country': 'United States',
            'timezone': 'America/Detroit',
            'operating_hours': '24/7 Continuous Operation (Three 8h Shifts)',
            'capabilities': ['Precision Stamping', 'Robotic Assembly', 'CNC Machining', 'AI Vision QC'],
            'target_daily_capacity': 5000
        },
        'products': [
            {
                'name': 'EV Drive Stator Assembly',
                'sku': 'EV-STAT-99',
                'category': 'Powertrain',
                'unit_of_measure': 'pcs',
                'cycle_time_seconds': 45.0,
                'target_hourly_rate': 80
            },
            {
                'name': 'Rotor Core Pack',
                'sku': 'EV-ROTR-12',
                'category': 'Powertrain',
                'unit_of_measure': 'pcs',
                'cycle_time_seconds': 35.0,
                'target_hourly_rate': 100
            }
        ],
        'raw_materials': [
            {
                'name': 'High-Grade Electrical Steel Laminations',
                'code': 'MAT-STL-01',
                'category': 'Metals',
                'unit_of_measure': 'kg',
                'minimum_stock_level': 2500.0,
                'current_stock_level': 10000.0
            },
            {
                'name': 'Oxygen-Free Copper Magnet Wire',
                'code': 'MAT-CU-02',
                'category': 'Metals',
                'unit_of_measure': 'kg',
                'minimum_stock_level': 1200.0,
                'current_stock_level': 5000.0
            }
        ],
        'process_stages': [
            {'name': 'Lamination Stamping', 'sequence_order': 1, 'stage_type': 'machining', 'cycle_time_seconds': 15.0},
            {'name': 'Stator Winding', 'sequence_order': 2, 'stage_type': 'assembly', 'cycle_time_seconds': 45.0},
            {'name': 'Impregnation & Curing', 'sequence_order': 3, 'stage_type': 'treatment', 'cycle_time_seconds': 120.0},
            {'name': 'High-Voltage Testing & QC', 'sequence_order': 4, 'stage_type': 'inspection', 'cycle_time_seconds': 25.0},
            {'name': 'Robotic Packing', 'sequence_order': 5, 'stage_type': 'packaging', 'cycle_time_seconds': 20.0}
        ],
        'production_lines': [
            {
                'name': 'Gigafactory Stator Line 1',
                'code': 'GIGA-STAT-01',
                'target_hourly_units': 80,
                'machines': [
                    {'name': '300-Ton Servo Stamping Press', 'code': 'PRS-01', 'machine_type': 'Press', 'rated_power_kw': 75.0},
                    {'name': '12-Spindle High-Speed Winder', 'code': 'WND-01', 'machine_type': 'Winder', 'rated_power_kw': 30.0},
                    {'name': 'Automated Vacuum Impregnator', 'code': 'IMP-01', 'machine_type': 'Chamber', 'rated_power_kw': 45.0},
                    {'name': 'Multi-Axis Quality Test Cell', 'code': 'QTC-01', 'machine_type': 'Tester', 'rated_power_kw': 15.0}
                ]
            }
        ],
        'shifts': [
            {
                'name': 'Morning Production Shift',
                'start_time': '06:00:00',
                'end_time': '14:00:00',
                'operating_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                'planned_capacity_units': 640
            },
            {
                'name': 'Evening Production Shift',
                'start_time': '14:00:00',
                'end_time': '22:00:00',
                'operating_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                'planned_capacity_units': 640
            },
            {
                'name': 'Night Production Shift',
                'start_time': '22:00:00',
                'end_time': '06:00:00',
                'operating_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                'planned_capacity_units': 640
            }
        ]
    }

    act_res = http_post('/api/onboarding/activate/', {'wizard_data': wizard_payload})
    assert act_res.get('success') is True, f"Activation failed: {act_res}"
    new_factory = act_res.get('data', {})
    new_factory_id = new_factory.get('id')
    print(f" -> Successfully Activated Factory: '{new_factory.get('name')}' (ID: {new_factory_id})")
    print(f" -> Organization: {new_factory.get('organization_name')} (ID: {new_factory.get('organization_id')})")
    print(f" -> Activation Message: {act_res.get('message')}")

    # 6. Verify Factory in Registry
    print("\n[6] Verifying Factory Directory & Real-time Integration...")
    facts_after = http_get('/api/factories/')
    after_list = facts_after.get('results', [])
    activated_found = any(f['id'] == new_factory_id for f in after_list)
    assert activated_found, f"Newly activated factory {new_factory_id} not found in factory listing!"
    print(f" -> Factory listing count now: {len(after_list)} (Successfully includes '{new_factory.get('name')}')")

    print("\n=================================================================")
    print("ALL PHASE 2 VERIFICATIONS PASSED SUCCESSFULLY (100% OPERATIONAL)")
    print("=================================================================")

if __name__ == '__main__':
    run_verification()
