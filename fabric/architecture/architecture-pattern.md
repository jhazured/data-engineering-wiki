# Fabric HR Analytics POC - Implementation Guide
## Following T0-T5 Architecture Pattern

## Overview
This guide implements HR analytics using the standardized Fabric architecture with:
- **T1**: Lakehouse (raw JSON with VARIANT)
- **T2**: Warehouse (SCD2 via T-SQL stored procedures)
- **T3**: Warehouse (transformations via Dataflows Gen2)
- **T5**: Warehouse (presentation views)
- **Semantic Layer**: Direct Lake on OneLake

**Time estimate**: 6-8 hours for full implementation

---

## Architecture Overview

**CRITICAL**: This architecture uses **Direct Lake on OneLake Parquet files** as primary mode, with DirectQuery fallback for views.

```
Sample JSON/XML Files
  ↓
Data Factory Pipelines
  ↓
T1_DATA_LAKE (Lakehouse)
  - VARIANT base tables
  - Materialized views (flattened)
  ↓ (shortcuts to Warehouse)
T2 (Warehouse - T-SQL)
  - SCD2 MERGE operations
  - Full historical record
  ↓ (Dataflows Gen2)
T3.ref (Reference data)
T3.table_01 (Base transforms)
T3.table_02 (Joins)
T3 Data Modeling (Facts & Dims)
  ↓ (zero-copy clone within Warehouse)
T3._FINAL tables (Delta in OneLake)
  ↓
T5 (Views - presentation layer)
  ↓
Direct Lake on OneLake Semantic Model
  - Connection: OneLake Parquet files
  - T3._FINAL tables (Delta/Parquet in OneLake) → Direct Lake mode (cached in-memory)
  - T5 views → DirectQuery fallback (automatic when needed)
  - Dual-mode operation (seamless switching)
  ↓
Power BI Reports
```

**Why Direct Lake on OneLake (per SOW requirements):**
- ✅ High-performance in-memory caching of Parquet files
- ✅ No data import required (direct access to OneLake)
- ✅ Automatic optimization by query engine
- ✅ Seamless DirectQuery fallback for complex queries/views
- ✅ OneLake as unified storage layer
- ✅ Zero-copy architecture throughout

**Key Architectural Point:**
- **OneLake is the storage layer** - Both Lakehouse and Warehouse store data in OneLake as Delta/Parquet files
- Warehouse adds SQL query engine on top of OneLake storage
- Lakehouse adds Spark engine on top of OneLake storage
- Direct Lake accesses the underlying OneLake Parquet files directly
- T3._FINAL tables (created in Warehouse) are stored as Delta/Parquet in OneLake
- Direct Lake connects to these OneLake files, regardless of whether they're accessed via Warehouse or Lakehouse

---

## Phase 1: Environment Setup (30 mins)

### 1.0 T0 - Control Layer Setup

**Note**: For this POC, T0 control plane is simplified. In production, implement:
- Pipeline orchestration metadata tables
- Logging tables (pipeline runs, errors, data quality)
- Configuration tables (connection strings, parameters)
- Watermark management for incremental loads

**Minimal T0 for POC:**

Create in Warehouse:
```sql
CREATE SCHEMA t0;
GO

-- Control: Watermark tracking
CREATE TABLE t0.watermark (
    table_name VARCHAR(100) PRIMARY KEY,
    last_processed_timestamp DATETIME2,
    updated_at DATETIME2 DEFAULT GETDATE()
);

-- Control: Pipeline execution log
CREATE TABLE t0.pipeline_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    pipeline_name VARCHAR(200),
    start_time DATETIME2,
    end_time DATETIME2,
    status VARCHAR(20), -- Success, Failed, Running
    rows_processed INT,
    error_message VARCHAR(MAX)
);
```

### 1.1 Create Fabric Workspaces
Create workspace: `HR_Analytics_Dev`

### 1.2 Create Lakehouse (T1)
1. In workspace → **New** → **Lakehouse**
2. Name: `T1_DATA_LAKE`
3. Wait for provisioning

### 1.3 Create Warehouse (T2/T3/T5)
1. In workspace → **New** → **Warehouse**
2. Name: `HR_Analytics_Warehouse`
3. Wait for provisioning

### 1.4 Create ADLS Gen2 Storage (for sample data)
1. Azure Portal → Create Storage Account with ADLS Gen2
2. Create container: `hr-sample-data`
3. Upload the 4 sample files:
   - `dim_department.json`
   - `dim_employee.json`
   - `dim_time.json`
   - `fact_payroll.xml`

---

## Phase 2: T1 - Lakehouse Raw Layer (60 mins)

### 2.1 Create VARIANT Base Tables

Open T1 Lakehouse SQL endpoint and run:

```sql
-- Base table for department data
CREATE TABLE raw_department (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    source_file STRING,
    payload VARIANT
);

-- Base table for employee data
CREATE TABLE raw_employee (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    source_file STRING,
    payload VARIANT
);

-- Base table for time dimension
CREATE TABLE raw_time (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    source_file STRING,
    payload VARIANT
);

-- Base table for payroll data
CREATE TABLE raw_payroll (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    source_file STRING,
    payload VARIANT
);
```

### 2.2 Create Materialized Views (Flatten VARIANT)

```sql
-- Materialized view: Flatten department VARIANT
CREATE MATERIALIZED VIEW mv_department AS
SELECT
    id,
    ingested_at,
    payload:dept_id::STRING AS dept_id,
    payload:dept_name::STRING AS dept_name,
    payload:division_id::STRING AS division_id,
    payload:division_name::STRING AS division_name,
    payload:cost_center::STRING AS cost_center,
    payload:location::STRING AS location
FROM raw_department;

-- Materialized view: Flatten employee VARIANT
CREATE MATERIALIZED VIEW mv_employee AS
SELECT
    id,
    ingested_at,
    payload:employee_id::STRING AS employee_id,
    payload:first_name::STRING AS first_name,
    payload:last_name::STRING AS last_name,
    payload:email::STRING AS email,
    payload:phone::STRING AS phone,
    payload:hire_date::DATE AS hire_date,
    payload:job_title::STRING AS job_title,
    payload:department_id::STRING AS department_id,
    payload:employment_status::STRING AS employment_status,
    payload:employment_type::STRING AS employment_type,
    payload:annual_salary::DECIMAL(12,2) AS annual_salary,
    payload:date_of_birth::DATE AS date_of_birth,
    payload:gender::STRING AS gender,
    payload:manager_id::STRING AS manager_id
FROM raw_employee;

-- Materialized view: Flatten time dimension VARIANT
CREATE MATERIALIZED VIEW mv_time AS
SELECT
    id,
    ingested_at,
    payload:date_key::INT AS date_key,
    payload:full_date::DATE AS full_date,
    payload:year::INT AS year,
    payload:quarter::INT AS quarter,
    payload:month::INT AS month,
    payload:month_name::STRING AS month_name,
    payload:week::INT AS week,
    payload:day_of_month::INT AS day_of_month,
    payload:day_of_week::INT AS day_of_week,
    payload:day_name::STRING AS day_name,
    payload:is_weekend::BOOLEAN AS is_weekend,
    payload:fiscal_year::INT AS fiscal_year,
    payload:fiscal_quarter::INT AS fiscal_quarter
FROM raw_time;

-- Materialized view: Flatten payroll VARIANT (from XML)
CREATE MATERIALIZED VIEW mv_payroll AS
SELECT
    id,
    ingested_at,
    payload:PayrollID::STRING AS payroll_id,
    payload:EmployeeID::STRING AS employee_id,
    payload:PayPeriodStart::DATE AS pay_period_start,
    payload:PayPeriodEnd::DATE AS pay_period_end,
    payload:PayDate::DATE AS pay_date,
    payload:RegularHours::DECIMAL(8,2) AS regular_hours,
    payload:OvertimeHours::DECIMAL(8,2) AS overtime_hours,
    payload:HourlyRate::DECIMAL(8,2) AS hourly_rate,
    payload:GrossPay::DECIMAL(12,2) AS gross_pay,
    payload:Deductions.Tax::DECIMAL(12,2) AS tax_deducted,
    payload:Deductions.Superannuation::DECIMAL(12,2) AS superannuation,
    payload:Deductions.HealthInsurance::DECIMAL(12,2) AS health_insurance,
    payload:NetPay::DECIMAL(12,2) AS net_pay,
    payload:PaymentMethod::STRING AS payment_method
FROM raw_payroll;
```

---

## Phase 3: Data Factory - Load T1 (60 mins)

### 3.1 Create Linked Services

**ADLS Gen2 Linked Service:**
- Name: `LS_ADLS_SampleData`
- Connection: Your ADLS Gen2 account
- Authentication: Account key or Managed Identity

**Lakehouse Linked Service:**
- Name: `LS_Lakehouse_T1`
- Connection: T1_DATA_LAKE lakehouse
- Authentication: Organizational account

### 3.2 Pipeline: Load Department to T1

Create pipeline: `PL_T1_Load_Department`

**Copy Data Activity:**
- Source:
  - Dataset: JSON file from ADLS (`dim_department.json`)
  - Settings: Document form (parse entire file as single VARIANT)
  
- Sink:
  - Dataset: Lakehouse table `raw_department`
  - Write behavior: Append
  - Mapping:
    - Map entire JSON document to `payload` column
    - Set `source_file` = `dim_department.json`

**Note**: T1 truncation happens AFTER successful T2 processing (see Phase 4.7)

### 3.3 Pipeline: Load Employee to T1

Create pipeline: `PL_T1_Load_Employee`

Similar structure:
- Source: `dim_employee.json`
- Parse each array element as separate VARIANT row
- Sink: `raw_employee` table

**For JSON arrays**, use ForEach activity:
```json
{
  "items": "@activity('LookupEmployees').output.value",
  "activities": [
    {
      "type": "Copy",
      "inputs": "VARIANT payload from array element",
      "outputs": "raw_employee table"
    }
  ]
}
```

### 3.4 Pipeline: Load Time to T1

Create pipeline: `PL_T1_Load_Time`

- Source: `dim_time.json`
- Array notation: `$.time_dimension[*]`
- Sink: `raw_time`

### 3.5 Pipeline: Load Payroll to T1

Create pipeline: `PL_T1_Load_Payroll`

**Special handling for XML:**

**Data Flow Activity** (required for XML parsing):
1. Source: XML from ADLS
2. Parse transformation:
   - Convert XML to JSON structure
   - Preserve nested elements (Deductions)
3. Derived Column: Cast entire parsed structure to VARIANT
4. Sink: `raw_payroll.payload`

### 3.6 Master Pipeline: T1 Orchestration

Create: `PL_T1_Master_Ingest`

**Execute Pipeline activities:**
1. `PL_T1_Load_Department`
2. `PL_T1_Load_Time`
3. `PL_T1_Load_Employee` (depends on department)
4. `PL_T1_Load_Payroll` (depends on employee)

**Success path**: Refresh materialized views
```sql
REFRESH MATERIALIZED VIEW mv_department;
REFRESH MATERIALIZED VIEW mv_employee;
REFRESH MATERIALIZED VIEW mv_time;
REFRESH MATERIALIZED VIEW mv_payroll;
```

---

## Phase 4: T2 - Warehouse SCD2 Layer (90 mins)

### 4.1 Create Shortcuts from Warehouse to Lakehouse

In Warehouse SQL editor:

```sql
-- Create shortcuts to T1 materialized views
CREATE SHORTCUT t1_department
IN SCHEMA dbo
FROM LAKEHOUSE 'T1_DATA_LAKE'
TABLE 'mv_department';

CREATE SHORTCUT t1_employee
IN SCHEMA dbo
FROM LAKEHOUSE 'T1_DATA_LAKE'
TABLE 'mv_employee';

CREATE SHORTCUT t1_time
IN SCHEMA dbo
FROM LAKEHOUSE 'T1_DATA_LAKE'
TABLE 'mv_time';

CREATE SHORTCUT t1_payroll
IN SCHEMA dbo
FROM LAKEHOUSE 'T1_DATA_LAKE'
TABLE 'mv_payroll';
```

### 4.2 Create T2 Historical Tables

First, create the schema:
```sql
CREATE SCHEMA t2;
GO

CREATE SCHEMA t5; -- Will be used for views later
GO
```

Now create the dimension and fact tables:

```sql
-- T2: Department dimension (SCD2)
CREATE TABLE t2.dim_department (
    dept_key INT IDENTITY(1,1) PRIMARY KEY,
    dept_id VARCHAR(10) NOT NULL,
    dept_name VARCHAR(100),
    division_id VARCHAR(10),
    division_name VARCHAR(100),
    cost_center VARCHAR(20),
    location VARCHAR(100),
    effective_date DATETIME2 NOT NULL DEFAULT GETDATE(),
    expiry_date DATETIME2,
    is_current BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_t2_dept_id ON t2.dim_department(dept_id);
CREATE INDEX idx_t2_dept_current ON t2.dim_department(is_current);

-- T2: Employee dimension (SCD2)
CREATE TABLE t2.dim_employee (
    emp_key INT IDENTITY(1,1) PRIMARY KEY,
    employee_id VARCHAR(10) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    hire_date DATE,
    job_title VARCHAR(100),
    department_id VARCHAR(10),
    employment_status VARCHAR(20),
    employment_type VARCHAR(20),
    annual_salary DECIMAL(12,2),
    date_of_birth DATE,
    gender VARCHAR(20),
    manager_id VARCHAR(10),
    effective_date DATETIME2 NOT NULL DEFAULT GETDATE(),
    expiry_date DATETIME2,
    is_current BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_t2_emp_id ON t2.dim_employee(employee_id);
CREATE INDEX idx_t2_emp_current ON t2.dim_employee(is_current);
CREATE INDEX idx_t2_emp_dept ON t2.dim_employee(department_id);

-- T2: Time dimension (Type 1, no history)
CREATE TABLE t2.dim_time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    week INT,
    day_of_month INT,
    day_of_week INT,
    day_name VARCHAR(20),
    is_weekend BIT,
    fiscal_year INT,
    fiscal_quarter INT,
    created_at DATETIME2 DEFAULT GETDATE()
);

-- T2: Payroll fact (insert-only, no SCD)
CREATE TABLE t2.fact_payroll (
    payroll_key INT IDENTITY(1,1) PRIMARY KEY,
    payroll_id VARCHAR(10) NOT NULL UNIQUE,
    employee_id VARCHAR(10) NOT NULL,
    emp_key INT, -- Will be populated after dimension load
    dept_key INT,
    pay_date_key INT,
    pay_period_start DATE,
    pay_period_end DATE,
    pay_date DATE,
    regular_hours DECIMAL(8,2),
    overtime_hours DECIMAL(8,2),
    hourly_rate DECIMAL(8,2),
    gross_pay DECIMAL(12,2),
    tax_deducted DECIMAL(12,2),
    superannuation DECIMAL(12,2),
    health_insurance DECIMAL(12,2),
    net_pay DECIMAL(12,2),
    payment_method VARCHAR(50),
    created_at DATETIME2 DEFAULT GETDATE(),
    source_ingested_at DATETIME2 -- Watermark from T1
);

CREATE INDEX idx_t2_payroll_emp ON t2.fact_payroll(employee_id);
CREATE INDEX idx_t2_payroll_date ON t2.fact_payroll(pay_date);
```

### 4.3 T-SQL Stored Procedure: SCD2 MERGE for Department

```sql
CREATE PROCEDURE t2.usp_merge_dim_department
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Expire old records that have changed
    UPDATE t2.dim_department
    SET 
        expiry_date = GETDATE(),
        is_current = 0,
        updated_at = GETDATE()
    WHERE is_current = 1
    AND dept_id IN (
        SELECT s.dept_id
        FROM t1_department s
        INNER JOIN t2.dim_department t ON s.dept_id = t.dept_id AND t.is_current = 1
        WHERE s.dept_name <> t.dept_name
           OR s.division_id <> t.division_id
           OR s.cost_center <> t.cost_center
           OR s.location <> t.location
    );
    
    -- Insert new versions for changed records
    INSERT INTO t2.dim_department (
        dept_id, dept_name, division_id, division_name, 
        cost_center, location, effective_date, is_current
    )
    SELECT 
        s.dept_id,
        s.dept_name,
        s.division_id,
        s.division_name,
        s.cost_center,
        s.location,
        GETDATE(),
        1
    FROM t1_department s
    WHERE EXISTS (
        SELECT 1 
        FROM t2.dim_department t 
        WHERE t.dept_id = s.dept_id 
        AND t.is_current = 0
        AND t.expiry_date = CAST(GETDATE() AS DATE)
    );
    
    -- Insert completely new records
    INSERT INTO t2.dim_department (
        dept_id, dept_name, division_id, division_name,
        cost_center, location, effective_date, is_current
    )
    SELECT 
        s.dept_id,
        s.dept_name,
        s.division_id,
        s.division_name,
        s.cost_center,
        s.location,
        GETDATE(),
        1
    FROM t1_department s
    WHERE NOT EXISTS (
        SELECT 1 FROM t2.dim_department t WHERE t.dept_id = s.dept_id
    );
END;
GO
```

### 4.4 T-SQL Stored Procedure: SCD2 MERGE for Employee

```sql
CREATE PROCEDURE t2.usp_merge_dim_employee
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Expire changed records
    UPDATE t2.dim_employee
    SET 
        expiry_date = GETDATE(),
        is_current = 0,
        updated_at = GETDATE()
    WHERE is_current = 1
    AND employee_id IN (
        SELECT s.employee_id
        FROM t1_employee s
        INNER JOIN t2.dim_employee t ON s.employee_id = t.employee_id AND t.is_current = 1
        WHERE s.job_title <> t.job_title
           OR s.department_id <> t.department_id
           OR s.employment_status <> t.employment_status
           OR s.annual_salary <> t.annual_salary
           OR ISNULL(s.manager_id, '') <> ISNULL(t.manager_id, '')
    );
    
    -- Insert new versions
    INSERT INTO t2.dim_employee (
        employee_id, first_name, last_name, email, phone, hire_date,
        job_title, department_id, employment_status, employment_type,
        annual_salary, date_of_birth, gender, manager_id,
        effective_date, is_current
    )
    SELECT 
        s.employee_id, s.first_name, s.last_name, s.email, s.phone, s.hire_date,
        s.job_title, s.department_id, s.employment_status, s.employment_type,
        s.annual_salary, s.date_of_birth, s.gender, s.manager_id,
        GETDATE(), 1
    FROM t1_employee s
    WHERE EXISTS (
        SELECT 1 FROM t2.dim_employee t 
        WHERE t.employee_id = s.employee_id 
        AND t.is_current = 0
        AND t.expiry_date = CAST(GETDATE() AS DATE)
    );
    
    -- Insert new employees
    INSERT INTO t2.dim_employee (
        employee_id, first_name, last_name, email, phone, hire_date,
        job_title, department_id, employment_status, employment_type,
        annual_salary, date_of_birth, gender, manager_id,
        effective_date, is_current
    )
    SELECT 
        s.employee_id, s.first_name, s.last_name, s.email, s.phone, s.hire_date,
        s.job_title, s.department_id, s.employment_status, s.employment_type,
        s.annual_salary, s.date_of_birth, s.gender, s.manager_id,
        GETDATE(), 1
    FROM t1_employee s
    WHERE NOT EXISTS (
        SELECT 1 FROM t2.dim_employee t WHERE t.employee_id = s.employee_id
    );
END;
GO
```

### 4.5 T-SQL Stored Procedure: Load Time Dimension

```sql
CREATE PROCEDURE t2.usp_load_dim_time
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE t2.dim_time AS target
    USING t1_time AS source
    ON target.time_key = source.date_key
    WHEN NOT MATCHED THEN
        INSERT (time_key, full_date, year, quarter, month, month_name,
                week, day_of_month, day_of_week, day_name, is_weekend,
                fiscal_year, fiscal_quarter)
        VALUES (source.date_key, source.full_date, source.year, source.quarter,
                source.month, source.month_name, source.week, source.day_of_month,
                source.day_of_week, source.day_name, source.is_weekend,
                source.fiscal_year, source.fiscal_quarter);
END;
GO
```

### 4.6 T-SQL Stored Procedure: Load Payroll Fact (Incremental)

```sql
CREATE PROCEDURE t2.usp_load_fact_payroll
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get watermark (last loaded timestamp)
    DECLARE @last_load DATETIME2;
    SELECT @last_load = ISNULL(MAX(source_ingested_at), '1900-01-01')
    FROM t2.fact_payroll;
    
    -- Insert only new payroll records
    INSERT INTO t2.fact_payroll (
        payroll_id, employee_id, pay_period_start, pay_period_end, pay_date,
        regular_hours, overtime_hours, hourly_rate, gross_pay,
        tax_deducted, superannuation, health_insurance, net_pay,
        payment_method, source_ingested_at
    )
    SELECT 
        s.payroll_id,
        s.employee_id,
        s.pay_period_start,
        s.pay_period_end,
        s.pay_date,
        s.regular_hours,
        s.overtime_hours,
        s.hourly_rate,
        s.gross_pay,
        s.tax_deducted,
        s.superannuation,
        s.health_insurance,
        s.net_pay,
        s.payment_method,
        s.ingested_at
    FROM t1_payroll s
    WHERE s.ingested_at > @last_load
    AND NOT EXISTS (
        SELECT 1 FROM t2.fact_payroll f WHERE f.payroll_id = s.payroll_id
    );
    
    -- Update surrogate keys
    UPDATE f
    SET 
        f.emp_key = e.emp_key,
        f.dept_key = d.dept_key,
        f.pay_date_key = CAST(CONVERT(VARCHAR(8), f.pay_date, 112) AS INT)
    FROM t2.fact_payroll f
    LEFT JOIN t2.dim_employee e ON f.employee_id = e.employee_id AND e.is_current = 1
    LEFT JOIN t2.dim_department d ON e.department_id = d.dept_id AND d.is_current = 1
    WHERE f.emp_key IS NULL;
END;
GO
```

### 4.7 Data Factory Pipeline: T2 Orchestration

Create pipeline: `PL_T2_Process_SCD2`

**Execute Stored Procedure activities (in order):**
1. `t2.usp_merge_dim_department`
2. `t2.usp_load_dim_time`
3. `t2.usp_merge_dim_employee` (depends on #1)
4. `t2.usp_load_fact_payroll` (depends on #3)

**On Success - Truncate T1 Tables (Transient Layer):**

Script Activity: Execute after all T2 procedures succeed
```sql
-- T1 is transient - truncate after successful T2 processing
TRUNCATE TABLE T1_DATA_LAKE.raw_department;
TRUNCATE TABLE T1_DATA_LAKE.raw_employee;
TRUNCATE TABLE T1_DATA_LAKE.raw_time;
TRUNCATE TABLE T1_DATA_LAKE.raw_payroll;

-- Update watermark
MERGE INTO t0.watermark AS target
USING (SELECT 'T2_SCD2_Complete' AS table_name, GETDATE() AS last_processed_timestamp) AS source
ON target.table_name = source.table_name
WHEN MATCHED THEN UPDATE SET last_processed_timestamp = source.last_processed_timestamp, updated_at = GETDATE()
WHEN NOT MATCHED THEN INSERT (table_name, last_processed_timestamp) VALUES (source.table_name, source.last_processed_timestamp);

-- Log pipeline success
INSERT INTO t0.pipeline_log (pipeline_name, start_time, end_time, status)
VALUES ('PL_T2_Process_SCD2', @pipeline().TriggerTime, GETDATE(), 'Success');
```

**On Failure:**
```sql
-- Log pipeline failure
INSERT INTO t0.pipeline_log (pipeline_name, start_time, end_time, status, error_message)
VALUES ('PL_T2_Process_SCD2', @pipeline().TriggerTime, GETDATE(), 'Failed', '@{activity('Error').error.message}');
```

---

## Phase 5: T3 - Transformation Layer via Dataflows Gen2 (90 mins)

### 5.1 Create T3 Schema in Warehouse

```sql
CREATE SCHEMA t3;
GO
```

### 5.2 Create T3.ref - Reference Tables

```sql
-- Reference: Job level mapping
CREATE TABLE t3.ref_job_level (
    job_title VARCHAR(100) PRIMARY KEY,
    job_level VARCHAR(20),
    job_category VARCHAR(50)
);

INSERT INTO t3.ref_job_level VALUES
('Chief Executive Officer', 'Executive', 'Leadership'),
('Chief Financial Officer', 'Executive', 'Leadership'),
('VP Sales', 'Senior Management', 'Leadership'),
('VP Engineering', 'Senior Management', 'Leadership'),
('Senior Data Engineer', 'Senior IC', 'Technology'),
('Data Engineer', 'Mid IC', 'Technology'),
('Software Engineer', 'Mid IC', 'Technology');

-- Reference: Salary bands
CREATE TABLE t3.ref_salary_band (
    band_name VARCHAR(20) PRIMARY KEY,
    min_salary DECIMAL(12,2),
    max_salary DECIMAL(12,2)
);

INSERT INTO t3.ref_salary_band VALUES
('Band 1', 50000, 70000),
('Band 2', 70000, 100000),
('Band 3', 100000, 140000),
('Band 4', 140000, 200000),
('Band 5', 200000, 300000);
```

### 5.3 Dataflow Gen2: T3.table_01 - Base Transforms

Create Dataflow Gen2: `DF_T3_Employee_Base`

**Source**: `t2.dim_employee` (current records only)

**Transformations**:
```m
// Filter current records
= Table.SelectRows(Source, each [is_current] = true)

// Standardize field names (technical naming)
= Table.RenameColumns(PreviousStep, {
    {"employee_id", "emp_id"},
    {"first_name", "emp_first_name"},
    {"last_name", "emp_last_name"}
})

// Add derived columns
= Table.AddColumn(PreviousStep, "emp_full_name", 
    each Text.Combine({[emp_first_name], [emp_last_name]}, " "))

= Table.AddColumn(PreviousStep, "emp_age", 
    each Duration.Days(DateTime.LocalNow() - [date_of_birth]) / 365.25)

= Table.AddColumn(PreviousStep, "emp_tenure_years",
    each Duration.Days(DateTime.LocalNow() - [hire_date]) / 365.25)

// Data quality fixes
= Table.TransformColumns(PreviousStep, {
    {"email", Text.Lower},
    {"emp_first_name", Text.Proper},
    {"emp_last_name", Text.Proper}
})
```

**Destination**: 
- Table: `t3.employee_base`
- Update method: **Append** (incremental load)

### 5.4 Dataflow Gen2: T3.table_02 - Joins & Enrichment

Create Dataflow Gen2: `DF_T3_Employee_Enriched`

**Sources**:
- `t3.employee_base`
- `t3.ref_job_level`
- `t3.ref_salary_band`
- `t2.dim_department` (current)

**Transformations**:
```m
// Join employee with job level reference
= Table.NestedJoin(
    t3_employee_base, {"job_title"},
    t3_ref_job_level, {"job_title"},
    "JobLevel", JoinKind.LeftOuter
)

// Expand job level columns
= Table.ExpandTableColumn(PreviousStep, "JobLevel", 
    {"job_level", "job_category"})

// Join with department
= Table.NestedJoin(
    PreviousStep, {"department_id"},
    t2_dim_department_current, {"dept_id"},
    "Department", JoinKind.Inner
)

// Expand department columns
= Table.ExpandTableColumn(PreviousStep, "Department",
    {"dept_name", "division_name", "location"})

// Calculate salary band
= Table.AddColumn(PreviousStep, "salary_band",
    each if [annual_salary] < 70000 then "Band 1"
    else if [annual_salary] < 100000 then "Band 2"
    else if [annual_salary] < 140000 then "Band 3"
    else if [annual_salary] < 200000 then "Band 4"
    else "Band 5")
```

**Destination**:
- Table: `t3.employee_enriched`
- Update method: **Append**

### 5.5 Dataflow Gen2: T3.agg_01 - Aggregations

Create Dataflow Gen2: `DF_T3_Payroll_Summary`

**Source**: `t2.fact_payroll`

**Transformations**:
```m
// Join with dimensions
= Table.NestedJoin(fact_payroll, {"emp_key"}, 
    dim_employee, {"emp_key"}, "Employee", JoinKind.Inner)

= Table.NestedJoin(PreviousStep, {"pay_date_key"},
    dim_time, {"time_key"}, "Time", JoinKind.Inner)

// Expand necessary columns
= Table.ExpandTableColumn(..., "Employee", {"employee_id", "department_id"})
= Table.ExpandTableColumn(..., "Time", {"year", "month", "full_date"})

// Group and aggregate
= Table.Group(PreviousStep, 
    {"year", "month", "department_id"},
    {
        {"total_gross_pay", each List.Sum([gross_pay]), type number},
        {"total_hours", each List.Sum([regular_hours]) + List.Sum([overtime_hours]), type number},
        {"total_overtime", each List.Sum([overtime_hours]), type number},
        {"avg_hourly_rate", each List.Average([hourly_rate]), type number},
        {"payroll_count", each Table.RowCount(_), Int64.Type},
        {"unique_employees", each List.Count(List.Distinct([employee_id])), Int64.Type}
    }
)
```

**Destination**:
- Table: `t3.payroll_monthly_summary`
- Update method: **Append** (for new months only - additive aggregations)
- **Note**: If aggregations require full recalculation (e.g., rolling averages, YTD with historical changes), use **Replace** mode instead

### 5.6 T3 Data Modeling - Star Schema

Create Dataflow Gen2: `DF_T3_Dim_Employee`

**Source**: `t2.dim_employee`

**Transformations**:
```m
// Select and rename for star schema
= Table.SelectColumns(Source, {
    "emp_key", "employee_id", "first_name", "last_name",
    "email", "hire_date", "job_title", "department_id",
    "employment_status", "annual_salary", "date_of_birth",
    "effective_date", "expiry_date", "is_current"
})

// Add business-friendly names as aliases (for T5)
= Table.RenameColumns(PreviousStep, {
    {"emp_key", "employee_key"},
    {"employee_id", "employee_number"}
})
```

**Destination**:
- Table: `t3.dim_employee`
- Update method: **Append** (SCD2 versions from T2)

Similarly create dataflows for:
- `DF_T3_Dim_Department` → `t3.dim_department`
- `DF_T3_Dim_Time` → `t3.dim_time`
- `DF_T3_Fact_Payroll` → `t3.fact_payroll`

### 5.7 Data Factory Pipeline: T3 Orchestration

Create pipeline: `PL_T3_Transform`

**Dataflow Gen2 activities (in order):**
1. `DF_T3_Employee_Base`
2. `DF_T3_Employee_Enriched` (depends on #1)
3. `DF_T3_Payroll_Summary`
4. `DF_T3_Dim_Employee` (star schema)
5. `DF_T3_Dim_Department`
6. `DF_T3_Dim_Time`
7. `DF_T3_Fact_Payroll`

---

## Phase 6: T3 → T5 Clone Refresh (45 mins)

### 6.1 Create Clone Refresh Stored Procedure

```sql
CREATE PROCEDURE t3.usp_refresh_final_clones
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Drop T5 views first (to avoid dependencies)
    IF OBJECT_ID('t5.vw_employee', 'V') IS NOT NULL
        DROP VIEW t5.vw_employee;
    
    IF OBJECT_ID('t5.vw_department', 'V') IS NOT NULL
        DROP VIEW t5.vw_department;
    
    IF OBJECT_ID('t5.vw_payroll_detail', 'V') IS NOT NULL
        DROP VIEW t5.vw_payroll_detail;
    
    -- Drop existing _FINAL clones
    IF OBJECT_ID('t3.dim_employee_FINAL', 'U') IS NOT NULL
        DROP TABLE t3.dim_employee_FINAL;
    
    IF OBJECT_ID('t3.dim_department_FINAL', 'U') IS NOT NULL
        DROP TABLE t3.dim_department_FINAL;
    
    IF OBJECT_ID('t3.dim_time_FINAL', 'U') IS NOT NULL
        DROP TABLE t3.dim_time_FINAL;
    
    IF OBJECT_ID('t3.fact_payroll_FINAL', 'U') IS NOT NULL
        DROP TABLE t3.fact_payroll_FINAL;
    
    -- Create new clones (zero-copy)
    CREATE TABLE t3.dim_employee_FINAL AS CLONE OF t3.dim_employee;
    CREATE TABLE t3.dim_department_FINAL AS CLONE OF t3.dim_department;
    CREATE TABLE t3.dim_time_FINAL AS CLONE OF t3.dim_time;
    CREATE TABLE t3.fact_payroll_FINAL AS CLONE OF t3.fact_payroll;
    
    -- Recreate T5 views will be done via CI/CD deployment
END;
GO
```

### 6.2 Store T5 View Scripts in Git

Create file: `t5_views.sql` (version controlled)

```sql
-- T5 View: Employee (business-friendly names, RLS ready)
CREATE VIEW t5.vw_employee AS
SELECT
    employee_key AS [Employee Key],
    employee_number AS [Employee ID],
    first_name + ' ' + last_name AS [Employee Name],
    email AS [Email],
    hire_date AS [Hire Date],
    DATEDIFF(YEAR, hire_date, GETDATE()) AS [Tenure (Years)],
    job_title AS [Job Title],
    employment_status AS [Status],
    annual_salary AS [Annual Salary],
    DATEDIFF(YEAR, date_of_birth, GETDATE()) AS [Age],
    is_current AS [Is Current]
FROM t3.dim_employee_FINAL;
GO

-- T5 View: Department
CREATE VIEW t5.vw_department AS
SELECT
    dept_key AS [Department Key],
    dept_id AS [Department ID],
    dept_name AS [Department Name],
    division_name AS [Division],
    location AS [Location],
    cost_center AS [Cost Center]
FROM t3.dim_department_FINAL
WHERE is_current = 1;
GO

-- T5 View: Payroll Detail (denormalized for reporting)
CREATE VIEW t5.vw_payroll_detail AS
SELECT
    f.payroll_key AS [Payroll Key],
    f.payroll_id AS [Payroll ID],
    e.[Employee Name],
    d.[Department Name],
    d.[Division],
    t.full_date AS [Pay Date],
    t.year AS [Year],
    t.month_name AS [Month],
    f.regular_hours AS [Regular Hours],
    f.overtime_hours AS [Overtime Hours],
    f.regular_hours + f.overtime_hours AS [Total Hours],
    f.gross_pay AS [Gross Pay],
    f.tax_deducted AS [Tax],
    f.superannuation AS [Superannuation],
    f.net_pay AS [Net Pay]
FROM t3.fact_payroll_FINAL f
INNER JOIN t5.vw_employee e ON f.emp_key = e.[Employee Key]
INNER JOIN t5.vw_department d ON f.dept_key = d.[Department Key]
INNER JOIN t3.dim_time_FINAL t ON f.pay_date_key = t.time_key;
GO

-- T5 Aggregation View: Monthly Summary
CREATE VIEW t5.vw_payroll_monthly_summary AS
SELECT
    t.year AS [Year],
    t.month_name AS [Month],
    d.[Division],
    d.[Department Name],
    COUNT(DISTINCT f.employee_id) AS [Headcount],
    SUM(f.gross_pay) AS [Total Gross Pay],
    SUM(f.tax_deducted) AS [Total Tax],
    SUM(f.net_pay) AS [Total Net Pay],
    SUM(f.overtime_hours) AS [Total Overtime Hours]
FROM t3.fact_payroll_FINAL f
INNER JOIN t3.dim_time_FINAL t ON f.pay_date_key = t.time_key
INNER JOIN t3.dim_employee_FINAL e ON f.emp_key = e.employee_key AND e.is_current = 1
INNER JOIN t3.dim_department_FINAL d ON e.department_id = d.dept_id AND d.is_current = 1
GROUP BY t.year, t.month_name, d.[Division], d.[Department Name];
GO
```

### 6.3 Data Factory Pipeline: Clone + View Refresh

Create pipeline: `PL_T5_Clone_Refresh`

**Script Activity 1: Execute Clone Procedure**
```sql
EXEC t3.usp_refresh_final_clones;
```

**Script Activity 2: Deploy T5 Views**
- Read `t5_views.sql` from git repo
- Execute SQL script to recreate views
- Alternatively: Use CI/CD to deploy views automatically

---

## Phase 7: Direct Lake Semantic Model (60 mins)

### 7.1 Create Semantic Model (Direct Lake on OneLake)

**CRITICAL**: Use **Direct Lake on OneLake Parquet files** mode.

**Why Direct Lake on OneLake:**
- High-performance in-memory caching of Parquet files
- Direct access to OneLake unified storage layer
- Automatic optimization by query engine
- Seamless DirectQuery fallback for views and complex queries
- Zero-copy architecture throughout

**Key Understanding:**
- **OneLake is the storage layer** - Warehouse tables are stored as Delta/Parquet files in OneLake
- When you create tables in Warehouse, they're automatically stored in OneLake
- Direct Lake accesses these OneLake Parquet files directly
- Whether you connect via Warehouse endpoint or OneLake catalog, you're accessing the same OneLake storage

**How to create Direct Lake semantic model:**

**⚠️ IMPORTANT: See [Direct Lake Modes & T5 View Compatibility](../reference/direct-lake-modes-t5-compatibility.md) for comprehensive guidance on choosing the right approach.**

**Two Main Approaches:**

**Approach 1: Direct Lake on SQL Endpoints (Simplest - Recommended for most cases)**
1. In Fabric workspace → **New** → **Semantic Model**
2. Name: `HR_Analytics_Semantic`
3. **Connection method**: Select Warehouse `HR_Analytics_Warehouse`
   - This connects to Warehouse tables which are stored in OneLake as Delta/Parquet
   - Direct Lake will access the underlying OneLake Parquet files
4. Select tables:
   - `t3.dim_employee_FINAL` (stored as Delta/Parquet in OneLake)
   - `t3.dim_department_FINAL` (stored as Delta/Parquet in OneLake)
   - `t3.dim_time_FINAL` (stored as Delta/Parquet in OneLake)
   - `t3.fact_payroll_FINAL` (stored as Delta/Parquet in OneLake)
5. Select views:
   - `t5.vw_payroll_monthly_summary` (will use DirectQuery fallback automatically)

**Approach 2: Hybrid T5 (Base Tables + Views) - Best flexibility**
- See [Direct Lake Modes & T5 View Compatibility](../reference/direct-lake-modes-t5-compatibility.md#option-1-hybrid-t5-base-tables--views--recommended) for detailed implementation
- Create T5 base tables for stable metrics (materialized aggregations)
- Keep T5 views for dynamic calculations
- Use composite semantic model: Direct Lake on OneLake for tables + DirectQuery connection for views

**Verification:**
- Open semantic model in Power BI Desktop
- Check Storage Mode for tables: Should show **Direct Lake** ✓
- Check Storage Mode for views: Should show **DirectQuery** ✓ (automatic fallback)
- Tables are cached in-memory from OneLake Parquet files
- Views automatically use DirectQuery when needed

**Key Points:**
- Both approaches access the same OneLake Parquet files
- Warehouse connection provides SQL query capabilities and DirectQuery fallback
- Direct Lake on SQL Endpoints is simplest (single connection)
- Hybrid T5 provides maximum flexibility (change calculations in 2 minutes vs 30-60 minutes)
- See the [comprehensive guide](../reference/direct-lake-modes-t5-compatibility.md) for decision matrix and detailed comparison

### 7.2 Configure Relationships

In Model view:

```
fact_payroll_FINAL[emp_key] → dim_employee_FINAL[employee_key] (Many-to-One)
fact_payroll_FINAL[dept_key] → dim_department_FINAL[dept_key] (Many-to-One)
fact_payroll_FINAL[pay_date_key] → dim_time_FINAL[time_key] (Many-to-One)
dim_employee_FINAL[department_id] → dim_department_FINAL[dept_id] (Many-to-One)
```

### 7.3 Verify Direct Lake on OneLake Mode

**Check Storage Mode in semantic model settings:**

**Tables (_FINAL):**
- Storage mode: **Direct Lake** ✓
- Data is cached in-memory on first query
- Reads directly from Delta/Parquet files in OneLake
- Fast, columnar compression
- No refresh required - direct access to OneLake

**Views (T5):**
- Storage mode: **DirectQuery** (automatic fallback) ✓
- Cannot use Direct Lake (views aren't Delta/Parquet files)
- Queries execute via Warehouse SQL endpoint
- Acceptable performance for aggregated data
- Automatic fallback when Direct Lake cannot handle query

**How DirectQuery fallback works:**

**With Direct Lake on SQL Endpoints (Approach 1):**
1. Query requests data from T5 view
2. Direct Lake detects source is a SQL view (not Parquet file)
3. Automatically falls back to DirectQuery mode
4. Query sent to Warehouse SQL endpoint (which queries OneLake data)
5. Results returned to semantic model
6. No configuration needed - this is automatic

**With Hybrid T5 (Approach 2):**
- T5 base tables use Direct Lake on OneLake (high performance)
- T5 views use separate DirectQuery connection (flexibility)
- See [Direct Lake Modes & T5 View Compatibility](../reference/direct-lake-modes-t5-compatibility.md#recommended-approach-hybrid-t5) for details

**Key Point:**
- Direct Lake accesses OneLake Parquet files directly (high performance)
- DirectQuery accesses same OneLake data via Warehouse SQL endpoint (for views/complex queries)
- Both modes access the same OneLake storage layer
- Seamless switching between modes based on query requirements
- **See [Direct Lake Modes & T5 View Compatibility](../reference/direct-lake-modes-t5-compatibility.md) for comprehensive guidance**

### 7.4 Create DAX Measures

```dax
// Headcount measures
Total Employees = DISTINCTCOUNT(dim_employee_FINAL[employee_number])

Active Employees = 
CALCULATE(
    [Total Employees],
    dim_employee_FINAL[is_current] = TRUE(),
    dim_employee_FINAL[employment_status] = "Active"
)

// Payroll measures
Total Gross Pay = SUM(fact_payroll_FINAL[gross_pay])
Total Net Pay = SUM(fact_payroll_FINAL[net_pay])
Total Tax = SUM(fact_payroll_FINAL[tax_deducted])

Labor Cost per Employee = DIVIDE([Total Gross Pay], [Active Employees], 0)

Overtime % = 
DIVIDE(
    SUM(fact_payroll_FINAL[overtime_hours]),
    SUM(fact_payroll_FINAL[regular_hours]) + SUM(fact_payroll_FINAL[overtime_hours]),
    0
)

// Time intelligence
Gross Pay MTD = 
CALCULATE(
    [Total Gross Pay],
    DATESMTD(dim_time_FINAL[full_date])
)

Gross Pay YTD = 
CALCULATE(
    [Total Gross Pay],
    DATESYTD(dim_time_FINAL[full_date])
)

Previous Month Pay = 
CALCULATE(
    [Total Gross Pay],
    DATEADD(dim_time_FINAL[full_date], -1, MONTH)
)

Pay % Change = 
DIVIDE(
    [Total Gross Pay] - [Previous Month Pay],
    [Previous Month Pay],
    0
)
```

---

## Phase 8: Power BI Dashboard (60 mins)

### 8.1 Create Report

1. From semantic model → **Create report**
2. Or Power BI Desktop → Connect to semantic model

### 8.2 Page 1: Executive Overview

**KPI Cards:**
- Active Employees
- Total Gross Pay (MTD)
- Labor Cost per Employee
- Overtime %

**Visuals:**
1. Line Chart: Payroll trend (uses Direct Lake on _FINAL tables)
2. Bar Chart: Cost by Division (uses T5 view → DirectQuery fallback)
3. Matrix: Department summary (uses T5 aggregation view)

### 8.3 Confirm Dual-Mode Operation

**Query Diagnostics**:
- Queries hitting `_FINAL` tables → **Direct Lake** (fast, in-memory)
- Queries hitting `vw_*` views → **DirectQuery** (SQL pushdown)
- No configuration needed - automatic based on source type

---

## Phase 9: Master Orchestration Pipeline (30 mins)

### 9.1 Create End-to-End Pipeline

Create: `PL_MASTER_HR_Analytics`

**Execute Pipeline activities in sequence:**

```
1. PL_T1_Master_Ingest
   ↓
2. PL_T2_Process_SCD2
   ↓
3. PL_T3_Transform
   ↓
4. PL_T5_Clone_Refresh
   ↓
5. Success notification
```

**Schedule**: Daily at 2:00 AM

---

## Phase 10: Testing & Validation (45 mins)

### 10.1 Data Quality Checks

```sql
-- Verify T1 → T2 flow
SELECT 
    'T1 Department' as source, COUNT(*) as count FROM t1_department
UNION ALL
SELECT 'T2 Department (current)', COUNT(*) FROM t2.dim_department WHERE is_current = 1;

-- Check SCD2 history
SELECT 
    employee_id,
    job_title,
    effective_date,
    expiry_date,
    is_current
FROM t2.dim_employee
WHERE employee_id = 'E1001'
ORDER BY effective_date;

-- Validate _FINAL clones
SELECT 
    'T3 Employee' as source, COUNT(*) FROM t3.dim_employee
UNION ALL
SELECT 'T3 Employee FINAL', COUNT(*) FROM t3.dim_employee_FINAL;

-- Check T5 views
SELECT TOP 10 * FROM t5.vw_payroll_detail;
```

### 10.2 Performance Testing

1. Execute master pipeline end-to-end
2. Check execution times:
   - T1 ingest: <5 mins
   - T2 SCD2: <10 mins
   - T3 transforms: <15 mins
   - T5 clone refresh: <2 mins
3. Verify Direct Lake performance in semantic model

### 10.3 Verify Architecture Compliance

- ✅ T1 uses VARIANT landing
- ✅ T2 SCD2 via T-SQL stored procedures
- ✅ T3 transformations via Dataflows Gen2
- ✅ Zero-copy clones with _FINAL suffix
- ✅ T5 views in git (version controlled)
- ✅ Direct Lake on _FINAL tables
- ✅ DirectQuery fallback on T5 views
- ✅ No notebooks used

---

## Phase 11: Deployment Pipeline Setup (Optional - 30 mins)

### 11.1 Create Deployment Stages

**Dev workspace**: `HR_Analytics_Dev`
**Test workspace**: `HR_Analytics_Test`
**Prod workspace**: `HR_Analytics_Prod`

### 11.2 Configure Datasource Deployment Rules

**Direct Lake on OneLake supports datasource deployment rules** - this is critical for Dev/Test/Prod promotion.

In deployment pipeline settings → Target stage (Test/Prod):

**Semantic Model datasource rules:**

For `HR_Analytics_Semantic`:
- **Source**: Warehouse connection (which accesses OneLake Parquet files)
- **Dev workspace**: 
  - Connection: `HR_Analytics_Warehouse` (Dev) → OneLake Parquet files (Dev workspace)
- **Test workspace**: 
  - Connection: `HR_Analytics_Warehouse` (Test) → OneLake Parquet files (Test workspace)
  - Rule: Automatically rebind to Test warehouse
- **Prod workspace**: 
  - Connection: `HR_Analytics_Warehouse` (Prod) → OneLake Parquet files (Prod workspace)
  - Rule: Automatically rebind to Prod warehouse

**How datasource rules work:**
1. Deploy semantic model from Dev → Test
2. Deployment pipeline automatically updates connection
3. Semantic model now points to Test warehouse
4. Direct Lake accesses Test workspace OneLake Parquet files
5. No manual rebinding required

**Key Point:**
- Each workspace has its own OneLake storage
- Warehouse connection points to workspace-specific OneLake files
- Deployment rules update the connection to point to target workspace
- Direct Lake accesses the correct OneLake Parquet files for each environment

**Verification:**
After deployment, open semantic model in each environment:
- Dev: Should connect to Dev warehouse → Dev OneLake files
- Test: Should connect to Test warehouse → Test OneLake files
- Prod: Should connect to Prod warehouse → Prod OneLake files

### 11.3 Deployment Order

1. Deploy Lakehouse (T1)
2. Deploy Warehouse (T2, T3, T5)
3. Deploy Dataflows Gen2 + rebind to target warehouse
4. Deploy Semantic Model + apply datasource rules
5. Deploy Reports (auto-binds to semantic model)

---

## Success Criteria

**✅ You've successfully implemented the architecture when:**

### T0 - Control Layer
- ✅ Watermark tables exist for incremental load tracking
- ✅ Pipeline logging captures success/failure
- ✅ Metadata tables store configuration

### T1 - Lakehouse (Raw)
- ✅ VARIANT base tables accept JSON/XML without schema changes
- ✅ Materialized views flatten VARIANT → typed columns
- ✅ Tables are truncated AFTER successful T2 processing (transient)
- ✅ Data Factory pipelines land raw data with ingested_at timestamps

### T2 - Warehouse (SCD2 Historical)
- ✅ Shortcuts from Warehouse to T1 materialized views work
- ✅ T-SQL stored procedures handle all SCD2 MERGE operations
- ✅ Dimensions have: surrogate keys, effective_date, expiry_date, is_current
- ✅ Fact table uses watermark-based incremental loading
- ✅ Full history maintained (not just current state)

### T3 - Warehouse (Transformations)
- ✅ Dataflows Gen2 ONLY (no notebooks, no T-SQL in T3)
- ✅ All T3 Dataflows use append refresh mode (no MERGE)
- ✅ T3.ref reference data exists
- ✅ T3.table_01 (base transforms), T3.table_02 (joins) pattern followed
- ✅ T3 data modeling creates star schema (facts & dims)
- ✅ Data is read-and-transform only (already versioned from T2)

### T3._FINAL Clone Layer
- ✅ Zero-copy clones exist with _FINAL suffix in t3 schema (not separate schema)
- ✅ Clone refresh follows sequence: DROP VIEW → DROP CLONE → CREATE CLONE → RECREATE VIEW
- ✅ Copy-on-write means only changed data consumes storage
- ✅ _FINAL tables isolate T5 from T3 pipeline failures

### T5 - Presentation Layer
- ✅ Views ONLY (no base tables in T5)
- ✅ Views reference T3._FINAL cloned tables
- ✅ View scripts stored in git, deployed via CI/CD (not runtime stored procedures)
- ✅ Business-friendly naming, light transformations only
- ✅ No joins, aggregations, or heavy transformations in T5

### Semantic Layer
- ✅ **Direct Lake on OneLake mode** (primary)
- ✅ Connection to OneLake Parquet files (via Warehouse or OneLake catalog)
- ✅ _FINAL tables → Direct Lake (in-memory cache from OneLake Parquet files)
- ✅ T5 views → DirectQuery fallback (automatic when needed)
- ✅ No special configuration needed for dual-mode operation
- ✅ Datasource deployment rules configured and working for Dev/Test/Prod
- ✅ OneLake as unified storage layer (Warehouse tables stored in OneLake)

### Orchestration
- ✅ End-to-end pipeline completes in <30 mins
- ✅ Pipeline sequence: T1 → T2 → T3 → T5 Clone → Semantic refresh
- ✅ T1 truncation happens AFTER T2 success
- ✅ Error handling and logging to t0.pipeline_log
- ✅ All layers follow naming convention (t0, t2, t3, t5)

### Deployment
- ✅ Lakehouse and Warehouse deploy to target stages
- ✅ Dataflows Gen2 rebind to target warehouse manually
- ✅ Semantic model datasource rules apply automatically
- ✅ Reports auto-bind to semantic model

### Architecture Compliance
- ✅ No notebooks used anywhere
- ✅ T-SQL only in T2 (SCD2 MERGE)
- ✅ Dataflows Gen2 for all T3 transformations
- ✅ VARIANT landing absorbs schema drift
- ✅ Shortcuts (no data duplication between Lakehouse and Warehouse)

---

## Architecture Decision Summary

| Layer | Technology | Purpose | Key Pattern |
|-------|-----------|---------|-------------|
| T1 | Lakehouse (Delta) | Raw JSON/XML landing | VARIANT columns, materialized views |
| T2 | Warehouse (T-SQL) | SCD2 historical record | MERGE via stored procedures |
| T3 | Warehouse (Dataflows Gen2) | Transformations & modeling | Append-only, no MERGE |
| T3._FINAL | Warehouse (Zero-copy clone) | Validated snapshots | Isolates T5 from T3 failures |
| T5 | Warehouse (Views) | Presentation layer | Git-managed view scripts |
| Semantic | **Direct Lake on OneLake** | Analytics consumption | OneLake Parquet files |
| | | | DirectQuery fallback for views |
| | | | Datasource deployment rules |

**Why Direct Lake on OneLake (per SOW requirements):**

| Requirement | Direct Lake on OneLake | Notes |
|-------------|----------------------|-------|
| High-performance caching | ✅ Yes | In-memory caching of Parquet files |
| DirectQuery fallback for views | ✅ Yes | Automatic fallback when needed |
| Datasource deployment rules | ✅ Yes | Works with Warehouse connection |
| OneLake unified storage | ✅ Yes | Primary storage layer |
| Zero-copy architecture | ✅ Yes | No data duplication |
| Connection method | OneLake Parquet files | Via Warehouse or OneLake catalog |

---

## Next Steps

1. **Document**: Architecture diagram, data flows, deployment process
2. **Package**: Export pipelines, SQL scripts, dataflows as templates
3. **Adapt**: Customize for actual client HR project requirements
4. **Scale**: Apply pattern to other domains (Finance, Sales, Operations)
5. **Governance**: Add RLS, column masking, data quality rules
6. **Monitoring**: Set up alerts, logging, performance tracking

**You now have a production-ready reference architecture following Fabric best practices!**

## Related Topics

- [Pattern Summary](../architecture/pattern-summary.md) - High-level architecture overview
- [Data Factory Patterns](../patterns/data-factory-patterns.md) - T1 ingestion patterns
- [Dataflows Gen2 Patterns](../patterns/dataflows-gen2-patterns.md) - T3 transformation patterns
- [Warehouse Patterns](../patterns/warehouse-patterns.md) - T2/T3/T5 Warehouse patterns
- [T-SQL Patterns](../patterns/t-sql-patterns.md) - T-SQL stored procedures and error handling
- [Direct Lake Optimization](../optimization/direct-lake-optimization.md) - Semantic layer optimization
- [Deployment & CI/CD](../operations/deployment-cicd.md) - Deployment patterns
- [Monitoring & Observability](../operations/monitoring-observability.md) - Monitoring patterns
- [Troubleshooting Guide](../operations/troubleshooting-guide.md) - Common issues and solutions
