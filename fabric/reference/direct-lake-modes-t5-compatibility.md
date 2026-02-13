# Direct Lake Modes and T5 View Compatibility

## Executive Summary

**Critical Decision:** How to configure Direct Lake to support T5 presentation views while maintaining OneLake as the primary storage layer.

**The Problem:** Direct Lake has two flavors with different capabilities:
- **Direct Lake on OneLake**: High performance, multi-source, but **cannot use views**
- **Direct Lake on SQL Endpoints**: Can use views via fallback, but single-source only

**Recommended Solution:** Hybrid T5 approach with composite semantic model
- **T5 Base Tables** (materialized) → Direct Lake on OneLake (performance)
- **T5 Views** (dynamic calculations) → DirectQuery connection (agility)
- **Best of both worlds:** Fast pre-aggregated queries + instant calculation changes

**Alternative:** If simplicity is paramount, use Direct Lake on SQL Endpoints (Option 1)

**Time to Read:** 20 minutes  
**Audience:** Data engineers, architects, project leads

---

## Table of Contents

1. [The Fundamental Issue](#the-fundamental-issue)
2. [Understanding Direct Lake Flavors](#understanding-direct-lake-flavors)
3. [Storage vs. Connection Mode](#storage-vs-connection-mode)
4. [Four Options for T5 Layer](#four-options-for-t5-layer)
5. [Recommended Approach: Hybrid T5](#recommended-approach-hybrid-t5)
6. [Implementation Complexity Analysis](#implementation-complexity-analysis)
7. [SOW Compliance Strategy](#sow-compliance-strategy)
8. [Implementation Guide](#implementation-guide)
9. [Architecture Diagrams](#architecture-diagrams)
10. [Decision Matrix](#decision-matrix)
11. [Common Misconceptions](#common-misconceptions)

---

## The Fundamental Issue

### The Question

**"How can we use T5 presentation views in our semantic model while meeting the SOW requirement for 'OneLake as primary storage layer'?"**

### The Challenge

Microsoft Fabric has two different Direct Lake modes with incompatible features:

| Feature | Direct Lake on OneLake | Direct Lake on SQL Endpoints |
|---------|------------------------|------------------------------|
| **Can use SQL views** | ❌ NO | ✅ YES (via DirectQuery fallback) |
| **Multi-source** | ✅ YES | ❌ NO (single source) |
| **DirectQuery fallback** | ❌ NO | ✅ YES (automatic) |
| **OneLake storage** | ✅ YES | ✅ YES (indirect via SQL endpoint) |

**The conflict:**
- SOW says: "Direct Lake on OneLake as primary storage"
- Architecture needs: T5 views in semantic model
- **These appear incompatible** at first glance

---

## Understanding Direct Lake Flavors

### Direct Lake on OneLake

**What it is:**
- Semantic model connects directly to OneLake Parquet files
- No SQL endpoint in the query path
- Pure file-based access

**How it works:**
```
Power BI Query
  ↓
Semantic Model (Direct Lake on OneLake)
  ↓
OneLake Parquet Files (direct read)
  ↓
In-Memory Cache (VertiPaq)
  ↓
Query Results
```

**Capabilities:**
- ✅ Multi-source (mix tables from multiple lakehouses/warehouses)
- ✅ Composite models (Direct Lake + Import tables)
- ✅ Highest performance (no SQL endpoint overhead)
- ✅ OneLake-native security integration
- ❌ **Cannot use SQL views**
- ❌ **No DirectQuery fallback**

**When to use:**
- Pure table-based semantic models
- Multi-source scenarios
- Maximum performance requirements
- No need for SQL views in semantic model

---

### Direct Lake on SQL Endpoints

**What it is:**
- Semantic model connects to Warehouse SQL analytics endpoint
- Uses endpoint to discover schema and handle fallback
- Still reads from OneLake files for Direct Lake queries

**How it works:**
```
Power BI Query (Table)
  ↓
Semantic Model (Direct Lake on SQL Endpoints)
  ↓
SQL Endpoint (schema discovery)
  ↓
OneLake Parquet Files (direct read)
  ↓
In-Memory Cache (VertiPaq)
  ↓
Query Results

Power BI Query (View)
  ↓
Semantic Model (Direct Lake on SQL Endpoints)
  ↓
SQL Endpoint (DirectQuery fallback)
  ↓
OneLake Data (via SQL query)
  ↓
Query Results (no cache)
```

**Capabilities:**
- ✅ Can use SQL views (via DirectQuery fallback)
- ✅ DirectQuery fallback for unsupported scenarios
- ✅ SQL-based security integration
- ✅ Still reads OneLake files for tables
- ❌ Single-source only (one warehouse)
- ❌ Cannot mix with other Direct Lake sources

**When to use:**
- Need SQL views in semantic model
- Single warehouse architecture
- SQL-based security requirements
- Fallback safety net desired

---

## Storage vs. Connection Mode

### Critical Distinction

**This is the most important concept to understand:**

#### Storage (Where Data Lives)

```
ALL Fabric data is stored in OneLake automatically:

OneLake (Unified Storage Layer)
├── Lakehouse T1 Tables → Delta/Parquet files
├── Warehouse T2 Tables → Delta/Parquet files
├── Warehouse T3 Tables → Delta/Parquet files
└── Warehouse T3._FINAL Tables → Delta/Parquet files

You don't choose this - it's automatic.
```

**Everything is in OneLake regardless of how you connect to it.**

#### Connection Mode (How Semantic Model Reads Data)

```
You choose ONE mode for your semantic model:

Option A: Direct Lake on OneLake
└── Reads Parquet files directly from OneLake

Option B: Direct Lake on SQL Endpoints  
└── Uses SQL endpoint to access OneLake data
    ├── Tables: Direct Lake (reads OneLake files)
    └── Views: DirectQuery (SQL query to OneLake)
```

**Key insight:** Direct Lake on SQL Endpoints **still uses OneLake storage** - it just accesses it through the SQL endpoint interface.

---

## Four Options for T5 Layer

### Option 1: Hybrid T5 (Base Tables + Views) ⭐⭐ RECOMMENDED

**Architecture:**
```
T5 Layer:
├── Base Tables (materialized, stable metrics)
│   ├── payroll_monthly_summary
│   ├── employee_summary_base
│   └── department_metrics_base
│   └─> Direct Lake on OneLake (performance)
│
└── Views (dynamic calculations)
    ├── vw_payroll_analysis
    ├── vw_compensation_total
    └── vw_employee_metrics
    └─> DirectQuery connection (agility)

Semantic Model (Composite):
├── Connection 1: OneLake (T3._FINAL + T5 base tables)
└── Connection 2: DirectQuery (T5 views)
```

**Implementation:**
1. Create T5 base tables (stable aggregations)
2. Populate via Dataflows Gen2 or T-SQL procedures
3. Create T5 views (dynamic calculations on base tables)
4. Create semantic model with Direct Lake on OneLake
5. Add DirectQuery connection for T5 views (10 minutes)

**What happens:**
- High-volume queries hit T5 base tables (Direct Lake, ~50-100ms)
- Evolving calculations use T5 views (DirectQuery, ~200-400ms)
- Change view logic instantly (CREATE OR REPLACE VIEW)
- Pre-aggregated data refreshes on schedule

**Real-world example:**
```sql
-- Monday: Create view
CREATE VIEW t5.vw_compensation AS
SELECT *, total_pay * 1.15 as with_benefits
FROM t5.payroll_monthly_summary;

-- Tuesday: CFO says "change to 18%"
CREATE OR REPLACE VIEW t5.vw_compensation AS
SELECT *, total_pay * 1.18 as with_benefits  -- Changed instantly
FROM t5.payroll_monthly_summary;

-- Reports see new calculation immediately (2 minutes vs 30-60 minutes)
```

**Pros:**
- ✅ **Maximum flexibility** - Change calculations in seconds
- ✅ **Optimal performance** - Pre-aggregated tables for high volume
- ✅ **Best SOW compliance** - Pure OneLake for primary data
- ✅ **Not complex** - Just one extra connection (10 min setup)
- ✅ **Production ready** - Both patterns are GA
- ✅ **Agile development** - Iterate quickly with business

**Cons:**
- ⚠️ Two connections to manage (minimal overhead)
- ⚠️ Relationship limitations across connections (rarely impacts use)

**When to use:**
- Need to change calculations frequently
- Business requirements evolve
- Want best performance + flexibility
- Testing experimental metrics

---

### Option 2: Direct Lake on SQL Endpoints ⭐ SIMPLE ALTERNATIVE

**Architecture:**
```
Semantic Model:
├── Connection: Warehouse SQL analytics endpoint
├── T3._FINAL tables → Direct Lake mode (reads OneLake files)
└── T5 views → DirectQuery fallback (automatic)
```

**Implementation:**
1. Create semantic model from Workspace
2. Choose **Warehouse** as source (not OneLake catalog)
3. Select T3._FINAL tables
4. Select T5 views
5. Both included in single model

**What happens:**
- Tables use Direct Lake (fast, OneLake files cached in-memory)
- Views automatically use DirectQuery fallback (SQL pushdown)
- No configuration needed - automatic switching

**Pros:**
- ✅ Simplest to implement (5 minutes)
- ✅ No architecture changes needed
- ✅ Automatic fallback handling
- ✅ Proven pattern
- ✅ SOW defensible

**Cons:**
- ⚠️ Single-source limitation
- ⚠️ Potential fallback unpredictability
- ⚠️ All views use DirectQuery (slower than materialized tables)

**SOW Compliance Argument:**
```
"This architecture uses OneLake as the unified storage layer for all 
data (T1-T5). The semantic model connects via the Warehouse SQL analytics 
endpoint, which enables Direct Lake mode for reading Delta/Parquet files 
directly from OneLake for tables, with DirectQuery fallback for presentation 
views. This approach maximizes OneLake storage efficiency while maintaining 
SQL-based presentation logic."
```

**When to use:**
- Want absolute simplicity
- Single warehouse architecture
- Don't need optimal view performance
- Calculations don't change frequently

---

### Option 3: T5 as Tables Only (No Views)

**Architecture:**
```
T5 Layer (all materialized):
├── payroll_monthly_summary (table)
├── payroll_with_calculations (table)
└── All presentation logic pre-computed

Semantic Model:
└── Direct Lake on OneLake (all tables)
```

**Implementation:**
1. Create T5 base tables for all metrics
2. Populate via Dataflows Gen2
3. Create semantic model with Direct Lake on OneLake
4. No views needed

**Pros:**
- ✅ Pure Direct Lake on OneLake (highest performance)
- ✅ No fallback ambiguity
- ✅ Multi-source capable
- ✅ Clear SOW compliance

**Cons:**
- ❌ Change calculations requires Dataflow refresh (30-60 min)
- ❌ No agility for evolving metrics
- ❌ More storage overhead

**When to use:**
- All metrics are 100% stable
- Performance is paramount
- No need for rapid iteration

---

### Option 4: DAX Only (No T5 Views in Semantic Model)

**Architecture:**
```
Warehouse:
└── T5 views (for SQL users only)

Semantic Model:
├── T3._FINAL tables → Direct Lake on OneLake
└── Calculation Groups / Measures → DAX logic
```

**Implementation:**
1. Keep T5 views in Warehouse for SQL analysts
2. Create semantic model with Direct Lake on OneLake
3. Select only T3._FINAL tables
4. Recreate view logic in DAX measures/calculation groups

**Example:**

**T5 View (SQL):**
```sql
CREATE VIEW t5.vw_payroll_monthly_summary AS
SELECT 
    d.dept_name,
    t.year,
    t.month_name,
    COUNT(DISTINCT f.emp_key) as employee_count,
    SUM(f.gross_pay) as total_gross_pay,
    AVG(f.gross_pay) as avg_gross_pay
FROM t3.fact_payroll_FINAL f
JOIN t3.dim_department_FINAL d ON f.dept_key = d.dept_key
JOIN t3.dim_time_FINAL t ON f.pay_date_key = t.time_key
GROUP BY d.dept_name, t.year, t.month_name;
```

**DAX Equivalent:**
```dax
// Measures in semantic model
Employee Count = DISTINCTCOUNT(fact_payroll_FINAL[emp_key])

Total Gross Pay = SUM(fact_payroll_FINAL[gross_pay])

Average Gross Pay = AVERAGE(fact_payroll_FINAL[gross_pay])

// Use with dept_name, year, month_name as slicers in report
```

**Pros:**
- ✅ Pure Direct Lake on OneLake (highest performance)
- ✅ No fallback ambiguity
- ✅ Multi-source capable
- ✅ Clear SOW compliance
- ✅ T5 views still exist for SQL users

**Cons:**
- ❌ Duplicate logic (SQL + DAX)
- ❌ Maintenance burden (keep in sync)
- ❌ More DAX complexity
- ❌ Steeper learning curve

**When to use:**
- Performance is paramount
- Team has strong DAX skills
- Willing to maintain dual logic

---

## Recommended Approach: Hybrid T5

### Choose Option 1: Hybrid T5 (Base Tables + Views)

**Why this is the best choice for most teams:**

#### 1. Maximum Flexibility with Minimal Complexity

**The "complexity" concern is overblown:**
```
Adding second DirectQuery connection:
├── Power BI Desktop → Get Data → SQL Server
├── Connect to Warehouse SQL endpoint
├── Select T5 views
├── Create relationships
└── Total time: 10 minutes

That's it. Two connections working together.
```

**What you gain:**
```
Change calculation instantly:
├── CFO: "Update benefits from 15% to 18%"
├── You: CREATE OR REPLACE VIEW (2 minutes)
└── Reports refresh automatically

vs. Materialized tables only:
├── Update Dataflow Gen2 logic (10 min)
├── Run pipeline refresh (15 min)
├── Wait for data (10-30 min)
└── Total: 35-55 minutes

25-35x faster iteration!
```

#### 2. Optimal Performance Profile

**Use the right tool for each query type:**

```
Dashboard with 10 visuals:
├── 6 visuals on T5 base tables (Direct Lake)
│   └─ Response: ~50-100ms each = 300-600ms total
│
├── 4 visuals on T5 views (DirectQuery)
│   └─ Response: ~200-400ms each = 800-1600ms total
│
└── Dashboard load: ~1.1-2.2 seconds

Perfect balance of speed and flexibility
```

**Compare to alternatives:**
```
All DirectQuery (Option 2):
└── Dashboard load: ~2-4 seconds

All Direct Lake tables (Option 3):
└── Dashboard load: ~0.5-1 second
└── BUT: 35-55 minutes to change calculations
```

#### 3. Best SOW Compliance

**Your position:**
```
"This architecture uses OneLake as the primary storage layer for all 
data (T1-T5). T3._FINAL and T5 base tables use Direct Lake on OneLake 
for high-performance analytics, reading Delta/Parquet files directly 
from OneLake. T5 views provide flexible calculation layers via DirectQuery 
for evolving business logic.

This hybrid approach maximizes OneLake's storage efficiency and Direct 
Lake's performance while enabling rapid iteration on analytical calculations."
```

**Why this is the strongest SOW argument:**
- ✅ "Primary storage" = OneLake (T3._FINAL + T5 base tables)
- ✅ "Direct Lake on OneLake" = Yes (primary connection mode)
- ✅ "DirectQuery for complex queries" = Yes (T5 views)
- ✅ Multi-source capable = Yes (can expand later)

#### 4. Agile Development Workflow

**Real-world scenario:**

**Week 1: Rapid prototyping**
```sql
-- Create view for new KPI
CREATE VIEW t5.vw_new_metric AS
SELECT 
    dept_name,
    SUM(gross_pay) * 1.15 as compensation_v1
FROM t5.payroll_monthly_summary
GROUP BY dept_name;

-- Test with business users
-- Iterate on calculation logic 5-10 times
-- All changes take 2 minutes each
```

**Week 2: Business validates metric**
```sql
-- Refine calculation based on feedback
CREATE OR REPLACE VIEW t5.vw_new_metric AS
SELECT 
    dept_name,
    SUM(gross_pay) * 1.18 + (SUM(gross_pay) * 0.05) as compensation_final
FROM t5.payroll_monthly_summary
GROUP BY dept_name;

-- Business approves
```

**Week 3: Metric is stable and high-volume**
```sql
-- Materialize into base table for performance
ALTER TABLE t5.payroll_monthly_summary 
ADD compensation_final DECIMAL(18,2);

-- Update Dataflow Gen2 to compute during refresh
-- Now pre-computed for fast queries
-- Keep view for backward compatibility or deprecate
```

**This workflow is impossible with tables-only approach.**

#### 5. Production Ready

**Both patterns are GA (Generally Available):**
- ✅ Direct Lake on OneLake: Production ready
- ✅ Composite models: Production ready
- ✅ DirectQuery to Warehouse: Production ready
- ✅ No preview features required

**Proven in the field:**
- Used by Microsoft customers in production
- Well-documented by Microsoft
- Supported patterns

---

### Implementation Strategy

#### Phase 1: Design T5 Layer

**Identify stable vs. dynamic metrics:**

```
Stable metrics (materialize in base tables):
├── employee_count (queried 1000x/day)
├── total_gross_pay (queried 800x/day)
├── total_hours (queried 600x/day)
└── department_count (queried 400x/day)

Dynamic metrics (keep as views):
├── compensation_with_benefits (formula may change)
├── pay_tier_classification (thresholds evolving)
├── experimental_kpi_v3 (still testing)
└── custom_calculation_for_exec (CFO request)
```

#### Phase 2: Create T5 Base Tables

**Using Dataflows Gen2:**
```m
// DF_T5_Payroll_Monthly_Summary
let
    Source_Fact = // Load from T3._FINAL
    Source_Dept = // Load from T3._FINAL
    Source_Time = // Load from T3._FINAL
    
    Joined = // Join tables
    Grouped = Table.Group(
        Joined,
        {"dept_name", "year", "month"},
        {
            {"employee_count", each ...},
            {"total_gross_pay", each ...},
            {"total_hours", each ...}
        }
    )
in
    Grouped

// Destination: t5.payroll_monthly_summary
```

#### Phase 3: Create T5 Views

**Dynamic calculations on base tables:**
```sql
CREATE VIEW t5.vw_payroll_analysis AS
SELECT 
    *,
    -- Calculations that might change
    total_gross_pay * 1.18 as total_with_benefits,
    total_gross_pay / NULLIF(employee_count, 0) as avg_pay,
    
    -- Business rules that evolve
    CASE 
        WHEN avg_pay > 5000 THEN 'High'
        WHEN avg_pay > 3000 THEN 'Medium'
        ELSE 'Low'
    END as pay_tier,
    
    -- Window functions for trends
    LAG(total_gross_pay) OVER (
        PARTITION BY dept_name 
        ORDER BY year, month
    ) as prior_month_pay
    
FROM t5.payroll_monthly_summary;
```

#### Phase 4: Create Composite Semantic Model

**In Power BI Desktop (10 minutes):**

**Connection 1: Direct Lake on OneLake**
```
1. Get Data → OneLake Catalog
2. Select HR_Analytics_Warehouse
3. Choose tables:
   ✓ t3.dim_employee_FINAL
   ✓ t3.dim_department_FINAL
   ✓ t3.dim_time_FINAL
   ✓ t3.fact_payroll_FINAL
   ✓ t5.payroll_monthly_summary (base table)
4. Load
```

**Connection 2: DirectQuery for Views**
```
1. Get Data → SQL Server
2. Server: [warehouse].datawarehouse.fabric.microsoft.com
3. Database: HR_Analytics_Warehouse
4. Data Connectivity: DirectQuery
5. Select only:
   ✓ t5.vw_payroll_analysis
   ✓ t5.vw_compensation_total
6. Load
```

**Relationships:**
```
vw_payroll_analysis[dept_name] → dim_department_FINAL[dept_name]
vw_payroll_analysis[year] → dim_time_FINAL[year]
(Many-to-One, Single direction)
```

**Done.**

---

### When to Use Each Approach

| Scenario | Use This Option |
|----------|----------------|
| **Calculations change frequently** | Option 1: Hybrid ⭐ |
| **Testing new metrics with business** | Option 1: Hybrid ⭐ |
| **Need best performance + agility** | Option 1: Hybrid ⭐ |
| **Want absolute simplicity** | Option 2: SQL Endpoints |
| **Single warehouse, stable metrics** | Option 2: SQL Endpoints |
| **All metrics are 100% stable** | Option 3: Tables Only |
| **No views needed ever** | Option 4: DAX Only |

---

## Implementation Complexity Analysis

### Option 1 (Hybrid): Not Complex

**Setup time: 15 minutes**
1. Create T5 base tables (5 min)
2. Create T5 views (5 min)
3. Add second connection in Power BI (5 min)

**Maintenance:**
- Base tables: Refresh via Dataflow Gen2 (same as T3)
- Views: Update SQL as needed (CREATE OR REPLACE)
- Relationships: One-time setup

**Operational overhead:**
```
Managing two connections:
├── Both use same security (SSO)
├── Both refresh automatically
└── No sync issues

Actual complexity: Minimal
```

### Option 2 (SQL Endpoints): Simplest

**Setup time: 5 minutes**
1. Create semantic model from Warehouse
2. Select tables and views
3. Done

**Trade-offs:**
- ✅ Simplest
- ❌ All views use DirectQuery (slower)
- ❌ Can't change to OneLake mode later without rebuild

### Comparison

| Aspect | Hybrid (Option 1) | SQL Endpoints (Option 2) |
|--------|-------------------|--------------------------|
| **Setup time** | 15 min | 5 min |
| **View performance** | Good (DirectQuery) | Same (DirectQuery) |
| **Table performance** | Excellent (Direct Lake) | Excellent (Direct Lake) |
| **Flexibility** | Very High | High |
| **Change calculation** | 2 minutes | 2 minutes |
| **Multi-source support** | ✅ Yes | ❌ No |
| **Complexity** | Low | Very Low |

**Verdict:** 10 extra minutes for significant benefits.

---

## SOW Compliance Strategy

### The SOW Requirement

**Stated requirement:**
```
"Direct Lake is Microsoft Fabric's high-performance analytics mode that 
enables semantic models to query data directly from OneLake (Parquet files) 
or SQL Warehouse (tables) without importing data into the model.

This project uses OneLake as the primary storage layer, with Direct Lake 
connecting to Parquet files in OneLake, and DirectQuery used for complex 
queries or views."
```

### How Option 1 Satisfies This

#### ✅ "OneLake as the primary storage layer"
**Compliance:**
- ALL data stored in OneLake (T1, T2, T3, T3._FINAL)
- No duplicate storage
- OneLake is the single source of truth
- Warehouse is just compute layer on top

#### ✅ "Direct Lake connecting to Parquet files in OneLake"
**Compliance:**
- T3._FINAL tables use Direct Lake mode
- Direct Lake reads Parquet files from OneLake directly
- In-memory caching from OneLake files
- No import/copy of data

#### ✅ "DirectQuery used for complex queries or views"
**Compliance:**
- T5 views use DirectQuery fallback
- DirectQuery for complex aggregations
- Automatic fallback when Direct Lake can't handle query

### Key Messaging

**When discussing with client/PM:**

1. **Lead with OneLake storage:**
   - "All data is stored in OneLake as Delta/Parquet"
   - "OneLake is our single storage layer"

2. **Emphasize Direct Lake for tables:**
   - "Tables use Direct Lake mode, reading directly from OneLake"
   - "Direct Lake provides in-memory performance"

3. **Frame SQL endpoint as interface:**
   - "SQL endpoint is the query interface to OneLake"
   - "Enables DirectQuery fallback for views"
   - "Still accessing the same OneLake data"

4. **Highlight benefits:**
   - "Zero data duplication"
   - "Unified storage in OneLake"
   - "Optimal performance for both tables and views"

---

## Implementation Guide

### Step-by-Step: Direct Lake on SQL Endpoints

#### Phase 1: Verify Prerequisites (5 minutes)

**Check that you have:**
- ✅ HR_Analytics_Warehouse with T3._FINAL tables
- ✅ T5 views created in Warehouse
- ✅ Workspace with necessary permissions

**T3._FINAL tables should exist:**
```sql
SELECT TABLE_SCHEMA, TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 't3' 
  AND TABLE_NAME LIKE '%_FINAL';

-- Expected results:
-- t3.dim_employee_FINAL
-- t3.dim_department_FINAL
-- t3.dim_time_FINAL
-- t3.fact_payroll_FINAL
```

**T5 views should exist:**
```sql
SELECT TABLE_SCHEMA, TABLE_NAME 
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 't5';

-- Expected results:
-- t5.vw_payroll_monthly_summary
-- t5.vw_employee_summary
```

---

#### Phase 2: Create Semantic Model (10 minutes)

**In Fabric Workspace:**

1. **Navigate to workspace:** `HR_Analytics_Dev`

2. **Create new semantic model:**
   - Click **New** → **Semantic model**
   - Choose **Warehouse** (NOT OneLake catalog)
   - Select: `HR_Analytics_Warehouse`

3. **Select tables:**
   ```
   Schema: t3
   ✓ dim_employee_FINAL
   ✓ dim_department_FINAL
   ✓ dim_time_FINAL
   ✓ fact_payroll_FINAL
   ```

4. **Select views:**
   ```
   Schema: t5
   ✓ vw_payroll_monthly_summary
   ✓ vw_employee_summary
   ✓ vw_headcount_by_department
   ```

5. **Name the model:** `HR_Analytics_Semantic`

6. **Click Create**

---

#### Phase 3: Verify Storage Modes (5 minutes)

**In Power BI Desktop:**

1. **Edit the semantic model:**
   - Workspace → HR_Analytics_Semantic → Edit

2. **Check table storage modes:**
   ```
   Model View → Select each table → Properties
   
   dim_employee_FINAL:
   └─ Storage mode: Direct Lake ✓
   
   dim_department_FINAL:
   └─ Storage mode: Direct Lake ✓
   
   dim_time_FINAL:
   └─ Storage mode: Direct Lake ✓
   
   fact_payroll_FINAL:
   └─ Storage mode: Direct Lake ✓
   ```

3. **Check view storage modes:**
   ```
   vw_payroll_monthly_summary:
   └─ Storage mode: DirectQuery ✓
   
   vw_employee_summary:
   └─ Storage mode: DirectQuery ✓
   ```

**What this confirms:**
- Tables use Direct Lake (reading OneLake files)
- Views use DirectQuery (automatic fallback)
- No configuration needed

---

#### Phase 4: Configure Relationships (10 minutes)

**In Model View:**

```
Relationships (create if not auto-detected):

fact_payroll_FINAL[emp_key] 
  → dim_employee_FINAL[employee_key] 
  (Many-to-One, Both directions)

fact_payroll_FINAL[dept_key] 
  → dim_department_FINAL[dept_key] 
  (Many-to-One, Both directions)

fact_payroll_FINAL[pay_date_key] 
  → dim_time_FINAL[time_key] 
  (Many-to-One, Both directions)

dim_employee_FINAL[department_id] 
  → dim_department_FINAL[dept_id] 
  (Many-to-One, Single direction)

vw_payroll_monthly_summary[dept_key] 
  → dim_department_FINAL[dept_key] 
  (Many-to-One, Single direction)
```

**Note:** Views typically have single-direction relationships due to DirectQuery limitations.

---

#### Phase 5: Create DAX Measures (15 minutes)

**Common measures for HR analytics:**

```dax
// Headcount Measures
Total Employees = DISTINCTCOUNT(dim_employee_FINAL[employee_number])

Active Employees = 
CALCULATE(
    [Total Employees],
    dim_employee_FINAL[is_current] = TRUE(),
    dim_employee_FINAL[employment_status] = "Active"
)

Headcount Growth = 
VAR CurrentMonth = [Active Employees]
VAR PreviousMonth = 
    CALCULATE(
        [Active Employees],
        DATEADD(dim_time_FINAL[date], -1, MONTH)
    )
RETURN
    DIVIDE(CurrentMonth - PreviousMonth, PreviousMonth, 0)

// Payroll Measures
Total Gross Pay = SUM(fact_payroll_FINAL[gross_pay])

Average Salary = AVERAGE(fact_payroll_FINAL[gross_pay])

Total Hours Worked = SUM(fact_payroll_FINAL[regular_hours])

Overtime Hours = SUM(fact_payroll_FINAL[overtime_hours])

Overtime % = 
DIVIDE(
    [Overtime Hours],
    [Total Hours Worked],
    0
)

// Department Measures
Departments with Employees = 
CALCULATE(
    DISTINCTCOUNT(dim_department_FINAL[dept_id]),
    dim_employee_FINAL[is_current] = TRUE()
)

Avg Employees per Department = 
DIVIDE(
    [Active Employees],
    [Departments with Employees],
    0
)

// Time Intelligence
YTD Gross Pay = 
TOTALYTD(
    [Total Gross Pay],
    dim_time_FINAL[date]
)

Previous Year Gross Pay = 
CALCULATE(
    [Total Gross Pay],
    SAMEPERIODLASTYEAR(dim_time_FINAL[date])
)

YoY Growth % = 
DIVIDE(
    [Total Gross Pay] - [Previous Year Gross Pay],
    [Previous Year Gross Pay],
    0
)
```

---

#### Phase 6: Test Performance (10 minutes)

**In Power BI Desktop:**

1. **Enable Performance Analyzer:**
   - View → Performance Analyzer
   - Start Recording

2. **Test table queries (Direct Lake):**
   - Create visual: Employee Count by Department
   - Refresh visual
   - Check DAX Query duration (should be <100ms for Direct Lake)

3. **Test view queries (DirectQuery):**
   - Create visual from vw_payroll_monthly_summary
   - Refresh visual
   - Check DirectQuery duration (should be <500ms)

4. **Verify no import operations:**
   - Performance Analyzer should show:
     - VertiPaq queries (for Direct Lake tables)
     - DirectQuery events (for views)
     - NO import/data refresh operations

**Expected results:**
```
Tables (Direct Lake):
├─ DAX Query: ~50-100ms
├─ Visual: ~20-50ms
└─ Storage Engine: VertiPaq (in-memory)

Views (DirectQuery):
├─ DAX Query: ~200-500ms
├─ DirectQuery: ~100-300ms
└─ Storage Engine: SQL pushdown
```

---

#### Phase 7: Publish and Validate (5 minutes)

1. **Save model:** File → Save (saves to workspace automatically)

2. **Create test report:**
   - Add visuals using both tables and views
   - Test filtering and slicing
   - Verify performance

3. **Publish to workspace:**
   - Model automatically saved to workspace
   - No separate publish step needed

4. **Verify in Fabric:**
   - Workspace → HR_Analytics_Semantic
   - Check lineage view
   - Confirm connection to Warehouse

---

## Architecture Diagrams

### Complete Data Flow

```
┌────────────────────────────────────────────────────────────┐
│                  OneLake Storage Layer                      │
│                (All data stored here)                       │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Lakehouse T1 (Delta/Parquet files)                        │
│  └─ raw_employee, raw_department, raw_payroll              │
│                                                             │
│  Warehouse T2 (Delta/Parquet files)                        │
│  └─ dim_employee, dim_department, fact_payroll             │
│                                                             │
│  Warehouse T3 (Delta/Parquet files)                        │
│  └─ transformed tables                                     │
│                                                             │
│  Warehouse T3._FINAL (Delta/Parquet files)                 │
│  └─ dim_employee_FINAL, dim_department_FINAL,              │
│      dim_time_FINAL, fact_payroll_FINAL                    │
│                                                             │
└────────────────────────────────────────────────────────────┘
                          ↑
                          │
            ┌─────────────┴─────────────┐
            │                           │
    (Direct Lake)              (DirectQuery via SQL)
            │                           │
            ↓                           ↓
┌────────────────────────────────────────────────────────────┐
│          Warehouse SQL Analytics Endpoint                   │
│         (Query interface to OneLake)                        │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Tables: Metadata + Direct Lake access to OneLake          │
│  └─ t3.*_FINAL → Points to OneLake Parquet files           │
│                                                             │
│  Views: SQL definitions executed via DirectQuery           │
│  └─ t5.vw_* → Queries OneLake data via SQL                │
│                                                             │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│         Power BI Semantic Model                             │
│      (Direct Lake on SQL Endpoints)                         │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Tables (Direct Lake mode):                                │
│  ├─ dim_employee_FINAL                                     │
│  ├─ dim_department_FINAL                                   │
│  ├─ dim_time_FINAL                                         │
│  └─ fact_payroll_FINAL                                     │
│  └─> Cached in-memory from OneLake Parquet files           │
│                                                             │
│  Views (DirectQuery mode - automatic fallback):            │
│  ├─ vw_payroll_monthly_summary                             │
│  └─ vw_employee_summary                                    │
│  └─> SQL pushdown to OneLake data                         │
│                                                             │
│  Relationships + Measures + Security                        │
│                                                             │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│                  Power BI Reports                           │
│            (End-user analytics)                             │
└────────────────────────────────────────────────────────────┘
```

---

### Query Flow Comparison

**Query on Table (Direct Lake):**
```
1. User clicks visual in Power BI report
   ↓
2. DAX query sent to semantic model
   ↓
3. Semantic model checks: "Is dim_employee_FINAL in cache?"
   ├─ YES → Return from in-memory cache (~10ms)
   └─ NO → Continue to step 4
   ↓
4. SQL endpoint provides metadata/schema
   ↓
5. Direct Lake engine reads OneLake Parquet files directly
   ↓
6. Decompress and transcode to VertiPaq format
   ↓
7. Cache in-memory for future queries
   ↓
8. Return results to Power BI (~50-100ms total)
```

**Query on View (DirectQuery):**
```
1. User clicks visual using vw_payroll_monthly_summary
   ↓
2. DAX query sent to semantic model
   ↓
3. Semantic model detects: "This is a view, use DirectQuery"
   ↓
4. Convert DAX query to SQL query
   ↓
5. Send SQL query to Warehouse SQL endpoint
   ↓
6. SQL endpoint executes query against OneLake data
   ↓
7. Return results (NO caching)
   ↓
8. Format and return to Power BI (~200-500ms total)
```

---

## Decision Matrix

### Choosing the Right Approach

| Criteria | Option 1: SQL Endpoints | Option 2: Composite | Option 3: DAX Only |
|----------|-------------------------|---------------------|-------------------|
| **Implementation Complexity** | ⭐ Simple | ⭐⭐⭐ Complex | ⭐⭐ Moderate |
| **Table Performance** | ⭐⭐⭐ High | ⭐⭐⭐⭐ Highest | ⭐⭐⭐⭐ Highest |
| **View Performance** | ⭐⭐⭐ Good | ⭐⭐ Moderate | N/A (no views) |
| **SOW Compliance** | ⭐⭐⭐ Defensible | ⭐⭐⭐⭐ Clear | ⭐⭐⭐⭐ Clear |
| **Architecture Changes** | None | Moderate | Significant |
| **Maintenance Burden** | ⭐ Low | ⭐⭐⭐ High | ⭐⭐⭐⭐ Very High |
| **Multi-Source Support** | ❌ No | ✅ Yes | ✅ Yes |
| **Learning Curve** | ⭐ Easy | ⭐⭐⭐ Steep | ⭐⭐⭐⭐ Very Steep |
| **Production Ready** | ✅ Yes | ⚠️ Preview | ✅ Yes |

### Use Option 1 (SQL Endpoints) If:
- ✅ Single warehouse architecture
- ✅ Need T5 views in semantic model
- ✅ Want simplest implementation
- ✅ Team has limited DAX expertise
- ✅ Proven patterns preferred

### Use Option 2 (Composite) If:
- ✅ Multi-source requirement
- ✅ Maximum table performance critical
- ✅ Complex model expertise available
- ✅ SOW compliance paramount
- ⚠️ Willing to manage preview features

### Use Option 3 (DAX Only) If:
- ✅ Performance is #1 priority
- ✅ Team has strong DAX skills
- ✅ Can maintain dual logic (SQL + DAX)
- ✅ Multi-source needed
- ⚠️ Willing to rewrite presentation logic

---

## Common Misconceptions

### Misconception 1: "Direct Lake on SQL Endpoints doesn't use OneLake"

**Reality:** ❌ FALSE

**Truth:**
- Warehouse stores ALL tables in OneLake as Delta/Parquet
- Direct Lake on SQL Endpoints still reads OneLake files directly
- SQL endpoint is just the query interface, not separate storage
- Same OneLake files accessed regardless of connection mode

**Proof:**
```sql
-- Query system views to see OneLake file paths
SELECT 
    t.name AS table_name,
    f.physical_name AS onelake_path
FROM sys.tables t
JOIN sys.dm_db_partition_stats p ON t.object_id = p.object_id
JOIN sys.database_files f ON p.partition_id = f.file_id
WHERE t.schema_id = SCHEMA_ID('t3')
  AND t.name LIKE '%_FINAL';

-- Results show OneLake paths like:
-- abfss://workspace@onelake.dfs.fabric.microsoft.com/warehouse/Tables/t3/dim_employee_FINAL
```

---

### Misconception 2: "You can mix OneLake and SQL modes for different tables"

**Reality:** ❌ FALSE

**Truth:**
- You choose ONE connection mode for the entire semantic model
- Cannot have some tables in OneLake mode and others in SQL mode
- Composite models can mix Direct Lake + Import, or Direct Lake + DirectQuery
- But the Direct Lake portion uses ONE connection mode

**What IS possible:**
```
Semantic Model (Composite):
├── Direct Lake on OneLake: T3._FINAL tables
└── DirectQuery: Separate connection to Warehouse for views
```

**What is NOT possible:**
```
Semantic Model:
├── Direct Lake on OneLake: dim_employee_FINAL ❌
└── Direct Lake on SQL: fact_payroll_FINAL ❌
```

---

### Misconception 3: "T1, T2, T3 layers are in the semantic model"

**Reality:** ❌ FALSE

**Truth:**
- Semantic model contains ONLY T3._FINAL tables (and optionally T5 views)
- T1, T2, T3 are processing/transformation layers
- Not exposed to Power BI users
- Data flows through layers to create T3._FINAL

**Architecture:**
```
Processing Layers (NOT in semantic model):
├─ T1: Lakehouse raw ingestion
├─ T2: Warehouse SCD2 processing  
└─ T3: Warehouse transformations

Reporting Layers (IN semantic model):
├─ T3._FINAL: Validated snapshots
└─ T5: Presentation views (optional)
```

---

### Misconception 4: "DirectQuery fallback is a failure"

**Reality:** ❌ FALSE (when used intentionally)

**Truth:**
- DirectQuery fallback is a FEATURE, not a bug
- Enables SQL views in semantic model
- Handles queries Direct Lake can't process
- Automatic and seamless to users

**When it's good:**
- ✅ Using T5 presentation views (by design)
- ✅ Complex aggregations that exceed Direct Lake limits
- ✅ SQL-based security requirements

**When it's bad:**
- ❌ Tables falling back due to memory limits (needs optimization)
- ❌ Frequent fallback due to poor model design
- ❌ Unexpected fallback causing performance issues

---

### Misconception 5: "Option 1 violates SOW requirements"

**Reality:** ❌ FALSE

**Truth:**
- SOW says "OneLake as primary storage layer" ✅
- ALL data IS in OneLake ✅
- Direct Lake DOES read OneLake files ✅
- SQL endpoint is the query interface ✅

**What matters:**
- Storage layer = OneLake (satisfied)
- Direct Lake reads OneLake Parquet files (satisfied)
- DirectQuery for views/complex queries (specified in SOW)

**SOW quote:**
```
"Direct Lake connecting to Parquet files in OneLake, and DirectQuery 
used for complex queries or views."
```

**Option 1 satisfies this:**
- Tables: Direct Lake → OneLake Parquet files ✅
- Views: DirectQuery → Complex queries ✅

---

## Summary

### Key Takeaways

1. **OneLake is ALWAYS the storage layer**
   - Regardless of connection mode
   - Warehouse stores in OneLake
   - Lakehouse stores in OneLake
   - No separate storage systems

2. **Connection mode affects query interface**
   - OneLake mode: Direct file access
   - SQL endpoints mode: Query via SQL interface
   - Both access same OneLake files

3. **Best approach: Hybrid T5 (Option 1)**
   - Base tables for stable metrics (Direct Lake)
   - Views for dynamic calculations (DirectQuery)
   - 10 minutes to set up, massive flexibility gained

4. **Alternative: SQL Endpoints (Option 2)**
   - Simpler if you want one connection
   - All views use DirectQuery
   - Proven pattern in production

5. **T1 materialized views are unaffected**
   - Lakehouse feature for flattening VARIANT
   - Separate from semantic model decision
   - Works with any connection mode

6. **SOW compliance is achievable**
   - OneLake IS the storage layer
   - Direct Lake DOES read OneLake files
   - Accurate technical framing satisfies requirements

### Recommended Approach

**Use Hybrid T5 - Option 1 (Base Tables + Views) because:**
- ✅ Maximum flexibility - Change calculations in 2 minutes vs 30-60 minutes
- ✅ Optimal performance - Direct Lake for high-volume, DirectQuery for dynamic
- ✅ Best SOW compliance - Pure OneLake for primary data
- ✅ Not complex - Just 10 minutes to add second connection
- ✅ Agile development - Iterate quickly with business
- ✅ Production ready - Both patterns are GA

**Alternative: SQL Endpoints - Option 2 if:**
- Want absolute simplicity (5 min setup vs 15 min)
- Don't need to change calculations frequently
- Single warehouse architecture

### Next Steps

1. **Review with team:** Discuss Hybrid T5 approach (Option 1)
2. **Confirm with PM/Client:** Validate SOW interpretation
3. **Implement:**
   - Create T5 base tables (stable aggregations)
   - Create T5 views (dynamic calculations)
   - Build composite semantic model (10 min)
4. **Test performance:** Verify table and view queries
5. **Document decision:** Update architecture docs
6. **Proceed with confidence:** Pattern is solid

---

## Related Topics

- [T0-T5 Architecture Pattern](../architecture/architecture-pattern.md) - Full architecture implementation
- [Direct Lake Optimization](../optimization/direct-lake-optimization.md) - Performance tuning
- [Technology Distinctions](technology-distinctions.md) - Data Factory vs Dataflows Gen2
- [Performance Optimization](../optimization/performance-optimization.md) - Query optimization

---

## References

### Microsoft Documentation

- [Direct Lake Overview](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-overview)
- [Develop Direct Lake Semantic Models](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-develop)
- [Direct Lake Query Processing](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-analyze-query-processing)

### Community Resources

- [Two Flavors of DirectLake: Over SQL vs. Over OneLake](https://edudatasci.net/2026/01/14/two-flavors-of-directlake-over-sql-vs-over-onelake-and-how-to-switch-without-surprises/)
- [A Tale of Two Direct Lakes in Microsoft Fabric](https://www.sharepointeurope.com/a-tale-of-two-direct-lakes-in-microsoft-fabric/)
- [Composite Models with Direct Lake and Import Tables](https://powerbi.microsoft.com/en-us/blog/deep-dive-into-composite-semantic-models-with-direct-lake-and-import-tables/)

---

**Document Status:** Complete  
**Last Updated:** February 13, 2026  
**Author:** Data Engineering Team  
**Review Status:** Ready for team review
