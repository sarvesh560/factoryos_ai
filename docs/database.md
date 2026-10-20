# FactoryOS AI — Database Specification & Schema Architecture
## Phase 3: Universal Manufacturing Process Engine (UMPE) & Execution Ledger

### 1. Dual-Engine Architecture Overview
FactoryOS AI features an environment-controlled, multi-engine database architecture:
- **Local Development (Default)**: SQLite 3 (`backend/db.sqlite3`). Enables immediate, zero-friction local development without requiring local database daemon installations or credential recovery.
- **Production & Staging**: PostgreSQL 15+ (with `psycopg` driver, UUID primary keys, and time-series indexes).

Both engines execute identical Django ORM migrations and maintain full foreign key cascading, indexation, and atomic transactional integrity.

---

### 2. Multi-Tenant Enterprise Hierarchy (Phase 1 & Phase 2)

```
+-----------------------------------------------------------------------------------+
|                                 ORGANIZATIONS                                     |
|-----------------------------------------------------------------------------------|
| id (UUID, PK)                                                                     |
| name (VARCHAR 255)                                                                |
| slug (VARCHAR 100, UNIQUE)                                                        |
| description (TEXT)                                                                |
| is_active (BOOLEAN, DEFAULT True)                                                 |
| created_at (TIMESTAMPTZ)                                                          |
| updated_at (TIMESTAMPTZ)                                                          |
+-----------------------------------------------------------------------------------+
                                         | 1
                                         |
                                         | N
+-----------------------------------------------------------------------------------+
|                                   FACTORIES                                       |
|-----------------------------------------------------------------------------------|
| id (UUID, PK)                                                                     |
| organization_id (UUID, FK -> organizations.id, ON DELETE CASCADE)                 |
| name (VARCHAR 255)                                                                |
| code (VARCHAR 50, UNIQUE)                                                         |
| industry_type (VARCHAR 50)                                                        |
| location (VARCHAR 255)                                                            |
| timezone (VARCHAR 50)                                                             |
| capabilities (JSONB / JSON)                                                       |
| target_daily_capacity (INT, DEFAULT 5000)                                         |
| is_active (BOOLEAN, DEFAULT True)                                                 |
| created_at (TIMESTAMPTZ)                                                          |
| updated_at (TIMESTAMPTZ)                                                          |
+-----------------------------------------------------------------------------------+
         | 1                      | 1                 | 1               | 1
         |                        |                   |                 |
         | N                      | N                 | N               | N
+------------------+    +-------------------+   +---------------+  +------------------+
|     PRODUCTS     |    |   RAW_MATERIALS   |   |PRODUCTION_LINE|  |SHIFT_CONFIGS     |
|------------------|    |-------------------|   |---------------|  |------------------|
| id (UUID, PK)    |    | id (UUID, PK)     |   | id (UUID, PK) |  | id (UUID, PK)    |
| factory_id (FK)  |    | factory_id (FK)   |   |factory_id(FK) |  | factory_id (FK)  |
| name (VARCHAR)   |    | name (VARCHAR)    |   |name (VARCHAR) |  | name (VARCHAR)   |
| sku (VARCHAR)    |    | code (VARCHAR)    |   |code (VARCHAR) |  | start_time (TIME)|
| category (STR)   |    | current_stock(FLT)|   |status (STR)   |  | end_time (TIME)  |
| cycle_time(SEC)  |    | min_stock (FLOAT) |   |efficiency(FLT)|  | planned_capacity |
+------------------+    +-------------------+   +---------------+  +------------------+
```

---

### 3. Phase 3: Universal Manufacturing Process Engine (UMPE) Schema

```
+-----------------------------------------------------------------------------------+
|                              PROCESS_DEFINITIONS                                  |
|-----------------------------------------------------------------------------------|
| id (UUID, PK)                                                                     |
| factory_id (UUID, FK -> factories.id, ON DELETE CASCADE)                          |
| code (VARCHAR 50, UNIQUE)                                                         |
| name (VARCHAR 255)                                                                |
| category (VARCHAR 50)                                                             |
| active_version_id (UUID, NULLABLE)                                                |
| is_active (BOOLEAN, DEFAULT True)                                                 |
| created_at (TIMESTAMPTZ)                                                          |
+-----------------------------------------------------------------------------------+
                                         | 1
                                         |
                                         | N
+-----------------------------------------------------------------------------------+
|                                PROCESS_VERSIONS                                   |
|-----------------------------------------------------------------------------------|
| id (UUID, PK)                                                                     |
| process_definition_id (UUID, FK -> process_definitions.id, ON DELETE CASCADE)     |
| version_number (VARCHAR 20)                                                       |
| status (VARCHAR 20: 'DRAFT' | 'VALIDATED' | 'PUBLISHED' | 'ARCHIVED')              |
| is_published (BOOLEAN, DEFAULT False)                                             |
| validation_errors (JSONB / JSON)                                                  |
| visual_layout (JSONB / JSON)                                                      |
| published_at (TIMESTAMPTZ, NULLABLE)                                              |
| created_at (TIMESTAMPTZ)                                                          |
+-----------------------------------------------------------------------------------+
         | 1                                               | 1
         |                                                 |
         | N                                               | N
+------------------------------------+   +------------------------------------+
|           PROCESS_NODES            |   |           PROCESS_EDGES            |
|------------------------------------|   |------------------------------------|
| id (UUID, PK)                      |   | id (UUID, PK)                      |
| process_version_id (UUID, FK)      |   | process_version_id (UUID, FK)      |
| node_key (VARCHAR 50)              |   | edge_key (VARCHAR 50)              |
| name (VARCHAR 255)                 |   | source_node_id (UUID, FK -> nodes) |
| node_type (VARCHAR 30)             |   | target_node_id (UUID, FK -> nodes) |
| assigned_line_id (UUID, NULL FK)   |   | edge_type (VARCHAR 30)             |
| assigned_machine_id (UUID, NULL FK)|   | condition_expression (TEXT)        |
| cycle_time_seconds (FLOAT)         |   | label (VARCHAR 100)                |
| position_x (FLOAT, DEFAULT 0.0)    |   | priority (INT, DEFAULT 0)          |
| position_y (FLOAT, DEFAULT 0.0)    |   +------------------------------------+
| config_params (JSONB / JSON)       |
+------------------------------------+
```

---

### 4. Work Orders, Live Execution & Material Ledger Schema

```
+-----------------------------------------------------------------------------------+
|                                   WORK_ORDERS                                     |
|-----------------------------------------------------------------------------------|
| id (UUID, PK)                                                                     |
| factory_id (UUID, FK -> factories.id)                                             |
| product_id (UUID, FK -> products.id)                                              |
| process_definition_id (UUID, FK -> process_definitions.id)                       |
| process_version_id (UUID, FK -> process_versions.id)                              |
| order_number (VARCHAR 50, UNIQUE)                                                 |
| status (VARCHAR 20: 'DRAFT' | 'RELEASED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED')|
| priority (VARCHAR 20: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT')                       |
| quantity_target (INT)                                                             |
| quantity_completed (INT, DEFAULT 0)                                               |
| quantity_scrapped (INT, DEFAULT 0)                                                |
| created_at (TIMESTAMPTZ)                                                          |
+-----------------------------------------------------------------------------------+
                                         | 1
                                         |
                                         | N
+-----------------------------------------------------------------------------------+
|                                PROCESS_EXECUTIONS                                 |
|-----------------------------------------------------------------------------------|
| id (UUID, PK)                                                                     |
| work_order_id (UUID, FK -> work_orders.id, ON DELETE CASCADE)                     |
| execution_number (VARCHAR 60, UNIQUE)                                             |
| status (VARCHAR 20: 'PENDING' | 'RUNNING' | 'PAUSED' | 'COMPLETED' | 'BLOCKED')   |
| mode (VARCHAR 20: 'LIVE' | 'SIMULATION')                                          |
| bottleneck_node_id (UUID, NULL FK -> process_nodes.id)                            |
| start_time (TIMESTAMPTZ, NULLABLE)                                                |
| end_time (TIMESTAMPTZ, NULLABLE)                                                  |
| total_units_completed (INT, DEFAULT 0)                                            |
| total_units_scrapped (INT, DEFAULT 0)                                             |
+-----------------------------------------------------------------------------------+
         | 1                                               | 1
         |                                                 |
         | N                                               | N
+------------------------------------+   +------------------------------------+
|          STAGE_EXECUTIONS          |   |          MATERIAL_FLOWS            |
|------------------------------------|   |------------------------------------|
| id (UUID, PK)                      |   | id (UUID, PK)                      |
| process_execution_id (UUID, FK)    |   | process_execution_id (UUID, FK)    |
| node_id (UUID, FK -> process_nodes)|   | stage_execution_id (UUID, NULL FK) |
| status (VARCHAR 20)                |   | raw_material_id (UUID, NULL FK)    |
| actual_duration_seconds (FLOAT)    |   | flow_type (VARCHAR 30)             |
| units_completed (INT, DEFAULT 0)   |   | quantity (FLOAT)                   |
| units_scrapped (INT, DEFAULT 0)    |   | unit_of_measure (VARCHAR 20)       |
| error_message (TEXT)               |   | previous_stock_level (FLOAT)       |
| updated_at (TIMESTAMPTZ)           |   | new_stock_level (FLOAT)            |
+------------------------------------+   | timestamp (TIMESTAMPTZ)            |
                                         +------------------------------------+
```

---

### 5. Production Events & Simulation Scenarios Schema

```
+------------------------------------+   +------------------------------------+
|         PRODUCTION_EVENTS          |   |        SIMULATION_SCENARIOS        |
|------------------------------------|   |------------------------------------|
| id (UUID, PK)                      |   | id (UUID, PK)                      |
| factory_id (UUID, FK -> factories) |   | factory_id (UUID, FK -> factories) |
| work_order_id (UUID, NULL FK)      |   | name (VARCHAR 255)                 |
| process_execution_id (UUID, NULL FK|   | scenario_type (VARCHAR 50)         |
| stage_execution_id (UUID, NULL FK) |   | description (TEXT)                 |
| event_type (VARCHAR 50)            |   | parameters (JSONB / JSON)          |
| severity (VARCHAR 20)              |   | is_active (BOOLEAN, DEFAULT True)  |
| source (VARCHAR 20: 'REAL'|'SIM')  |   | created_at (TIMESTAMPTZ)           |
| message (TEXT)                     |   +------------------------------------+
| payload (JSONB / JSON)             |
| timestamp (TIMESTAMPTZ)            |
+------------------------------------+
```

---

### 6. Immutability, Graph Integrity & Transactional Guarantees

1. **Version Immutability**:
   - A `ProcessVersion` with `is_published=True` cannot have its nodes or edges modified, created, or deleted.
   - Any attempt to modify a published version triggers a validation error, guaranteeing zero operational disruptions to in-flight work orders.
2. **Deterministic Topological Integrity**:
   - Every graph must pass strict cycle detection (Tarjan & DFS), single-entry / single-exit validation, reachability analysis, and split/join balance checks before being eligible for publishing.
3. **Transactional Material Ledger**:
   - Every stage completion atomically records material consumption and scrap output into `MATERIAL_FLOWS` and decrements `RAW_MATERIALS.current_stock` inside Django's `transaction.atomic()`.
