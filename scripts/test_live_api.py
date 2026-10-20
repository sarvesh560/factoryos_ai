#!/usr/bin/env python
import json
import urllib.request

def test_api():
    print("=" * 60)
    print("TESTING DJANGO LIVE API WITH SQLITE BACKEND")
    print("=" * 60)

    # 1. Health Endpoint
    health_url = "http://127.0.0.1:8000/api/health/"
    print(f"\n1. GET {health_url}")
    with urllib.request.urlopen(health_url) as res:
        assert res.status == 200, f"Health check failed with status {res.status}"
        health_data = json.loads(res.read().decode())
        print(f"Status: {health_data.get('status')}")
        print(f"Database Engine: {health_data['services']['database']['engine']}")
        print(f"Database Connected: {health_data['services']['database']['connected']}")
        print(f"Database Latency: {health_data['services']['database']['latency_ms']} ms")

    # 2. Factories Endpoint
    factories_url = "http://127.0.0.1:8000/api/factories/"
    print(f"\n2. GET {factories_url}")
    with urllib.request.urlopen(factories_url) as res:
        assert res.status == 200, f"Factories failed with status {res.status}"
        factories_data = json.loads(res.read().decode())
        results = factories_data.get("results", [])
        print(f"Success: {factories_data.get('success')}")
        print(f"Total Factories Returned: {len(results)}")
        assert len(results) == 3, f"Expected 3 factories, got {len(results)}"
        for f in results:
            print(f" - [{f['code']}] {f['name']} ({f['industry_type_display']}) | Lines: {f['total_production_lines']} (Active: {f['active_lines']}) | Location: {f['location']}")

    # 3. Factory Overview Endpoints (for each factory)
    print("\n3. GET Overview for each factory")
    for f in results:
        fid = f["id"]
        overview_url = f"http://127.0.0.1:8000/api/factories/{fid}/overview/"
        print(f"\nFetching {overview_url} ({f['name']}):")
        with urllib.request.urlopen(overview_url) as res:
            assert res.status == 200, f"Overview failed with status {res.status}"
            overview_data = json.loads(res.read().decode())
            data = overview_data["data"]
            m = data["metrics"]
            ls = data["lines_summary"]
            lines = data["production_lines"]
            print(f"  Name: {data['factory']['name']}")
            print(f"  OEE: {m['overall_oee']}% | Avail: {m['availability']}% | Perf: {m['performance']}% | Qual: {m['quality_rate']}% | Energy: {m['energy_consumption_kwh']} kWh")
            print(f"  Lines Summary: Total={ls['total']}, Running={ls['running']}, Idle={ls['idle']}, Maint={ls['maintenance']}, Offline={ls['offline']}")
            print(f"  Production Lines Count: {len(lines)}")
            for l in lines[:2]:
                print(f"    Line [{l['code']}] {l['name']}: {l['status_display']} (Eff: {l['efficiency_rate']}%)")

    print("\n" + "=" * 60)
    print("ALL API ENDPOINT TESTS PASSED WITH REAL SQLITE DATA!")
    print("=" * 60)

if __name__ == "__main__":
    test_api()
