#!/usr/bin/env python
"""
FactoryOS AI — Database Connectivity Diagnostic Utility
Supports both SQLite local development and PostgreSQL production engines.
"""
import os
import sys
import sqlite3
from pathlib import Path
from dotenv import load_dotenv

# Load backend/.env
base_dir = Path(__file__).resolve().parent.parent / "backend"
env_path = base_dir / ".env"
load_dotenv(env_path)

db_engine = os.getenv("DB_ENGINE", "sqlite").lower()

if db_engine == "postgresql":
    import psycopg2
    dbname = os.getenv("DB_NAME", "factoryos_ai")
    user = os.getenv("DB_USER", "factoryos_user")
    password = os.getenv("DB_PASSWORD", "")
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5432")

    print(f"Checking PostgreSQL at {host}:{port} for DB '{dbname}' and user '{user}'...")
    try:
        conn = psycopg2.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=port,
            connect_timeout=3,
        )
        cur = conn.cursor()
        cur.execute("SELECT version();")
        ver = cur.fetchone()[0]
        print("STATUS: CONNECTED")
        print(f"PostgreSQL Version: {ver}")
        cur.close()
        conn.close()
        sys.exit(0)
    except psycopg2.OperationalError as e:
        print("STATUS: FAILED")
        print(f"OperationalError: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"STATUS: ERROR: {e}")
        sys.exit(2)
else:
    # SQLite local development
    sqlite_path = base_dir / "db.sqlite3"
    print(f"Checking SQLite database at: {sqlite_path}...")
    try:
        conn = sqlite3.connect(sqlite_path)
        cur = conn.cursor()
        cur.execute("SELECT sqlite_version();")
        ver = cur.fetchone()[0]
        print("STATUS: CONNECTED")
        print(f"SQLite Version: {ver}")
        cur.close()
        conn.close()
        sys.exit(0)
    except Exception as e:
        print(f"STATUS: FAILED: {e}")
        sys.exit(1)
