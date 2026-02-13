# Dataflows Gen2 Patterns and Best Practices

## Overview

Dataflows Gen2 is Microsoft Fabric's cloud-based data transformation service that uses Power Query (M language) for data preparation and transformation. This guide covers patterns, best practices, and optimization strategies for using Dataflows Gen2 in the T0-T5 architecture pattern, specifically in the T3 transformation layer.

**Key Characteristics:**
- Visual, no-code/low-code transformation interface
- Power Query M language under the hood
- Runs in Fabric compute
- Supports incremental refresh
- Can write to Warehouse or Lakehouse

---

## Architecture Context

### Role in T0-T5 Pattern

**T3 Layer**: Dataflows Gen2 is the **PRIMARY and ONLY** tool for transformations in T3

**Key Distinction:**
- **Data Factory**: Used for **T1 ingestion** (copying raw data from external sources to Lakehouse)
- **Dataflows Gen2**: Used for **T3 transformations** (business logic, data quality, star schema modeling)

**T3 Transformation Responsibilities:**
- **T3.ref**: Reference data management
- **T3.table_01**: Base transformations (filtering, renaming, data type conversion)
- **T3.table_02**: Joins and enrichment (combining multiple sources)
- **T3.agg_01**: Aggregations and summaries

**Key Principle**: 
- Dataflows Gen2 should be **append-only** in T3 (no MERGE operations) since data is already versioned in T2
- **All T3 transformations** are done via Dataflows Gen2 (not Data Factory, not notebooks, not T-SQL)

---

## Pattern 1: Incremental Refresh

### When to Use

- Large datasets that don't need full refresh
- Source systems that support incremental queries
- Performance optimization for large tables

### Implementation Pattern

**Step 1: Configure Incremental Refresh**

1. In Dataflow Gen2, select the query/table
2. Go to **Settings** → **Incremental refresh**
3. Enable incremental refresh
4. Configure:
   - **Range start**: How far back to look (e.g., 30 days)
   - **Range end**: Current date/time
   - **Incremental column**: Column to use for filtering (typically date/timestamp)

**Step 2: Add Incremental Filter**

```m
let
    Source = Sql.Database("server", "database"),
    IncrementalFilter = Table.SelectRows(
        Source,
        each [LastModifiedDate] >= RangeStart and [LastModifiedDate] < RangeEnd
    )
in
    IncrementalFilter
```

**Step 3: Configure Destination**

- **Update method**: Append (for T3 layer)
- **Incremental refresh policy**: Set in dataflow settings

### Best Practices

- ✅ Use date/timestamp columns for incremental filtering
- ✅ Ensure source column is indexed for performance
- ✅ Set appropriate range (balance between performance and data freshness)
- ✅ Monitor incremental refresh performance
- ❌ Don't use incremental refresh for small tables (< 1M rows)
- ❌ Don't use incremental refresh if source doesn't support date filtering

---

## Pattern 2: Parameterization

### When to Use

- Reusable dataflows across environments
- Dynamic source connections
- Environment-specific configurations

### Implementation Pattern

**Step 1: Create Parameters**

1. In Dataflow Gen2 → **Parameters** tab
2. Create parameters:
   - `ServerName` (text)
   - `DatabaseName` (text)
   - `SchemaName` (text)
   - `TableName` (text)

**Step 2: Use Parameters in Queries**

```m
let
    Source = Sql.Database(
        #"ServerName",
        #"DatabaseName"
    ),
    Schema = Source{[Schema=#"SchemaName"]}[Data],
    Table = Schema{[Item=#"TableName"]}[Data]
in
    Table
```

**Step 3: Set Parameter Values**

- **Dev**: Set parameters to dev environment
- **Test**: Set parameters to test environment
- **Prod**: Set parameters to prod environment

### Best Practices

- ✅ Use parameters for all connection strings
- ✅ Store parameter values in configuration tables (T0)
- ✅ Use parameter groups for related parameters
- ✅ Document parameter purposes and valid values
- ❌ Don't hardcode connection strings
- ❌ Don't use parameters for frequently changing values (use T0 config tables)

---

## Pattern 3: Error Handling

### When to Use

- Unreliable data sources
- Data quality issues
- Network connectivity problems

### Implementation Pattern

**Pattern A: Try-Other Pattern**

```m
let
    Source = try Sql.Database("server", "database") otherwise null,
    Result = if Source = null 
        then #table({"Error"}, {{"Connection failed"}})
        else Source
in
    Result
```

**Pattern B: Error Logging**

```m
let
    Source = try Sql.Database("server", "database") otherwise null,
    ErrorLog = if Source = null then
        [
            ErrorTime = DateTime.LocalNow(),
            ErrorMessage = "Failed to connect to database",
            Source = "Dataflow: Employee_Load"
        ]
    else null
in
    // Log error to T0 error table if needed
    Source
```

**Pattern C: Default Values**

```m
let
    Source = Sql.Database("server", "database"),
    Employees = Source{[Schema="hr", Item="employees"]}[Data],
    AddDefaults = Table.TransformColumns(
        Employees,
        {
            {"salary", each if _ = null then 0 else _, type number},
            {"department_id", each if _ = null then "UNKNOWN" else _, type text}
        }
    )
in
    AddDefaults
```

### Best Practices

- ✅ Use try-otherwise for external connections
- ✅ Provide meaningful error messages
- ✅ Log errors to T0 error logging tables
- ✅ Use default values for nullable columns
- ✅ Validate data types before transformations
- ❌ Don't silently fail (always log errors)
- ❌ Don't use try-otherwise for expected nulls (handle in transformation)

---

## Pattern 4: Data Quality Transformations

### When to Use

- Data cleansing requirements
- Standardization needs
- Data validation

### Implementation Pattern

**Pattern A: Standardization**

```m
let
    Source = t2_dim_employee,
    Standardize = Table.TransformColumns(
        Source,
        {
            {"email", Text.Lower, type text},
            {"first_name", Text.Proper, type text},
            {"last_name", Text.Proper, type text},
            {"phone", each Text.Remove(_, {" ", "-", "(", ")"}), type text}
        }
    )
in
    Standardize
```

**Pattern B: Data Validation**

```m
let
    Source = t2_dim_employee,
    ValidateEmail = Table.AddColumn(
        Source,
        "IsValidEmail",
        each Text.Contains([email], "@") and Text.Contains([email], ".")
    ),
    FilterInvalid = Table.SelectRows(
        ValidateEmail,
        each [IsValidEmail] = true
    ),
    RemoveValidationColumn = Table.RemoveColumns(FilterInvalid, {"IsValidEmail"})
in
    RemoveValidationColumn
```

**Pattern C: Data Enrichment**

```m
let
    Source = t2_dim_employee,
    AddDerivedColumns = Table.AddColumn(
        Source,
        "FullName",
        each Text.Combine({[first_name], [last_name]}, " "),
        type text
    ),
    AddAge = Table.AddColumn(
        AddDerivedColumns,
        "Age",
        each Duration.Days(DateTime.LocalNow() - [date_of_birth]) / 365.25,
        type number
    ),
    AddTenure = Table.AddColumn(
        AddAge,
        "TenureYears",
        each Duration.Days(DateTime.LocalNow() - [hire_date]) / 365.25,
        type number
    )
in
    AddTenure
```

### Best Practices

- ✅ Standardize early in the transformation pipeline
- ✅ Validate data before joins
- ✅ Use consistent naming conventions
- ✅ Document transformation logic
- ✅ Test transformations on sample data
- ❌ Don't perform heavy transformations in T5 (do in T3)
- ❌ Don't duplicate transformation logic (create reusable queries)

---

## Pattern 5: Joins and Enrichment (T3.table_02)

### When to Use

- Combining data from multiple sources
- Enriching fact tables with dimension data
- Adding reference data lookups

### Implementation Pattern

**Pattern A: Left Join with Reference Table**

```m
let
    EmployeeSource = t3_employee_base,
    JobLevelRef = t3_ref_job_level,
    JoinTables = Table.NestedJoin(
        EmployeeSource,
        {"job_title"},
        JobLevelRef,
        {"job_title"},
        "JobLevel",
        JoinKind.LeftOuter
    ),
    ExpandColumns = Table.ExpandTableColumn(
        JoinTables,
        "JobLevel",
        {"job_level", "job_category"},
        {"job_level", "job_category"}
    )
in
    ExpandColumns
```

**Pattern B: Multiple Joins**

```m
let
    EmployeeSource = t3_employee_base,
    DepartmentSource = t2_dim_department,
    TimeSource = t2_dim_time,
    
    // First join: Employee with Department
    JoinDept = Table.NestedJoin(
        EmployeeSource,
        {"department_id"},
        DepartmentSource,
        {"dept_id"},
        "Department",
        JoinKind.Inner
    ),
    ExpandDept = Table.ExpandTableColumn(
        JoinDept,
        "Department",
        {"dept_name", "division_name", "location"},
        {"dept_name", "division_name", "location"}
    ),
    
    // Second join: Add time dimension
    JoinTime = Table.NestedJoin(
        ExpandDept,
        {"hire_date"},
        TimeSource,
        {"full_date"},
        "Time",
        JoinKind.LeftOuter
    ),
    ExpandTime = Table.ExpandTableColumn(
        JoinTime,
        "Time",
        {"year", "quarter", "month_name"},
        {"hire_year", "hire_quarter", "hire_month"}
    )
in
    ExpandTime
```

**Pattern C: Conditional Enrichment**

```m
let
    Source = t2_fact_payroll,
    SalaryBandRef = t3_ref_salary_band,
    AddSalaryBand = Table.AddColumn(
        Source,
        "salary_band",
        each 
            if [annual_salary] < 70000 then "Band 1"
            else if [annual_salary] < 100000 then "Band 2"
            else if [annual_salary] < 140000 then "Band 3"
            else if [annual_salary] < 200000 then "Band 4"
            else "Band 5",
        type text
    )
in
    AddSalaryBand
```

### Best Practices

- ✅ Use Inner joins for required relationships
- ✅ Use Left joins for optional enrichments
- ✅ Expand nested tables immediately after joins
- ✅ Rename columns to avoid conflicts
- ✅ Join on indexed columns for performance
- ❌ Don't perform joins in T5 (do in T3)
- ❌ Don't join large fact tables multiple times (enrich once in T3)

---

## Pattern 6: Aggregations (T3.agg_01)

### When to Use

- Pre-computed summaries
- Common reporting patterns
- Performance optimization

### Implementation Pattern

**Pattern A: Simple Aggregation**

```m
let
    Source = t2_fact_payroll,
    GroupBy = Table.Group(
        Source,
        {"year", "month", "department_id"},
        {
            {"TotalGrossPay", each List.Sum([gross_pay]), type number},
            {"TotalHours", each List.Sum([regular_hours]) + List.Sum([overtime_hours]), type number},
            {"EmployeeCount", each List.Count(List.Distinct([employee_id])), Int64.Type}
        }
    )
in
    GroupBy
```

**Pattern B: Multiple Aggregations**

```m
let
    Source = t2_fact_payroll,
    GroupBy = Table.Group(
        Source,
        {"year", "month", "department_id"},
        {
            {"TotalGrossPay", each List.Sum([gross_pay]), type number},
            {"TotalNetPay", each List.Sum([net_pay]), type number},
            {"TotalTax", each List.Sum([tax_deducted]), type number},
            {"TotalHours", each List.Sum([regular_hours]) + List.Sum([overtime_hours]), type number},
            {"TotalOvertimeHours", each List.Sum([overtime_hours]), type number},
            {"AvgHourlyRate", each List.Average([hourly_rate]), type number},
            {"PayrollCount", each Table.RowCount(_), Int64.Type},
            {"UniqueEmployees", each List.Count(List.Distinct([employee_id])), Int64.Type}
        }
    )
in
    GroupBy
```

**Pattern C: Aggregation with Filters**

```m
let
    Source = t2_fact_payroll,
    FilterCurrent = Table.SelectRows(
        Source,
        each [is_current] = true
    ),
    GroupBy = Table.Group(
        FilterCurrent,
        {"year", "month"},
        {
            {"TotalGrossPay", each List.Sum([gross_pay]), type number},
            {"ActiveEmployeeCount", each List.Count(List.Distinct([employee_id])), Int64.Type}
        }
    )
in
    GroupBy
```

### Best Practices

- ✅ Aggregate at appropriate grain (not too detailed)
- ✅ Use additive aggregations (SUM, COUNT) for incremental refresh
- ✅ Document aggregation logic
- ✅ Validate aggregation results
- ✅ Consider using T5 views for complex aggregations instead
- ❌ Don't aggregate in T5 (aggregate in T3 or use views)
- ❌ Don't create too many aggregation tables (balance with query performance)

---

## Pattern 7: Reference Data Management (T3.ref)

### When to Use

- Lookup tables
- Mapping tables
- Configuration data

### Implementation Pattern

**Pattern A: Static Reference Table**

```m
let
    Source = #table(
        type table [
            job_title = text,
            job_level = text,
            job_category = text
        ],
        {
            {"Chief Executive Officer", "Executive", "Leadership"},
            {"Chief Financial Officer", "Executive", "Leadership"},
            {"VP Sales", "Senior Management", "Leadership"},
            {"Data Engineer", "Mid IC", "Technology"}
        }
    )
in
    Source
```

**Pattern B: Reference Table from Source**

```m
let
    Source = Sql.Database("server", "database"),
    ReferenceTable = Source{[Schema="ref", Item="job_levels"]}[Data],
    Standardize = Table.TransformColumns(
        ReferenceTable,
        {
            {"job_title", Text.Proper, type text},
            {"job_level", Text.Proper, type text}
        }
    )
in
    Standardize
```

**Pattern C: Reference Table with Defaults**

```m
let
    Source = Sql.Database("server", "database"),
    ReferenceTable = Source{[Schema="ref", Item="departments"]}[Data],
    AddDefaults = Table.TransformRows(
        ReferenceTable,
        each [
            dept_id = [dept_id] ?? "UNKNOWN",
            dept_name = [dept_name] ?? "Unknown Department",
            is_active = [is_active] ?? true
        ]
    )
in
    AddDefaults
```

### Best Practices

- ✅ Store reference data in T3.ref schema
- ✅ Use consistent naming conventions
- ✅ Include effective dates for time-variant reference data
- ✅ Validate reference data completeness
- ✅ Document reference data sources and update frequency
- ❌ Don't join reference data in T5 (do in T3)
- ❌ Don't hardcode reference data in transformations

---

## Pattern 8: Star Schema Modeling

### When to Use

- Creating dimension tables from T2
- Creating fact tables from T2
- Preparing data for semantic layer

### Implementation Pattern

**Pattern A: Dimension Table Creation**

```m
let
    Source = t2_dim_employee,
    FilterCurrent = Table.SelectRows(
        Source,
        each [is_current] = true
    ),
    SelectColumns = Table.SelectColumns(
        FilterCurrent,
        {
            "emp_key",
            "employee_id",
            "first_name",
            "last_name",
            "email",
            "hire_date",
            "job_title",
            "department_id",
            "employment_status",
            "annual_salary"
        }
    ),
    RenameColumns = Table.RenameColumns(
        SelectColumns,
        {
            {"emp_key", "employee_key"},
            {"employee_id", "employee_number"}
        }
    )
in
    RenameColumns
```

**Pattern B: Fact Table Creation**

```m
let
    Source = t2_fact_payroll,
    SelectColumns = Table.SelectColumns(
        Source,
        {
            "payroll_key",
            "payroll_id",
            "emp_key",
            "dept_key",
            "pay_date_key",
            "pay_date",
            "gross_pay",
            "net_pay",
            "regular_hours",
            "overtime_hours"
        }
    ),
    AddCalculatedColumns = Table.AddColumn(
        SelectColumns,
        "total_hours",
        each [regular_hours] + [overtime_hours],
        type number
    )
in
    AddCalculatedColumns
```

### Best Practices

- ✅ Create star schema in T3 (not T5)
- ✅ Use surrogate keys from T2
- ✅ Filter to current records for dimensions
- ✅ Select only needed columns
- ✅ Rename columns for business-friendly names
- ❌ Don't create star schema in T5 (do in T3)
- ❌ Don't join facts and dims in T3 (semantic layer handles relationships)

---

## Pattern 9: Performance Optimization

**See [Performance Optimization](../optimization/performance-optimization.md#pattern-5-dataflow-gen2-optimization) for comprehensive performance optimization guide.**

**Dataflows Gen2-Specific Quick Tips:**
- Enable query folding when possible
- Select columns early in the query
- Filter data before joins
- Use incremental refresh for large tables
- Monitor dataflow execution times

**Key Strategies:**
1. **Query Folding**: Push operations to source (see Pattern 1 for examples)
2. **Column Selection**: Select only needed columns early
3. **Filter Early**: Filter before joins and transformations
4. **Incremental Refresh**: Use for large tables (see Pattern 1)

---

## Pattern 10: Destination Configuration

### Update Methods

**Append (Recommended for T3)**
- Use for incremental loads
- Data already versioned in T2
- No MERGE needed

**Replace**
- Use for reference data (T3.ref)
- Use for full refresh scenarios
- Use when data needs complete replacement

**Upsert**
- Use when source doesn't support incremental
- Requires key column definition
- More complex but handles updates

### Configuration Pattern

**For T3 Tables (Append)**

```
Destination: Warehouse
Schema: t3
Table: employee_enriched
Update method: Append
Incremental refresh: Enabled
```

**For T3.ref Tables (Replace)**

```
Destination: Warehouse
Schema: t3.ref
Table: job_level
Update method: Replace
Incremental refresh: Disabled
```

### Best Practices

- ✅ Use Append for T3 transformation tables
- ✅ Use Replace for T3.ref reference tables
- ✅ Configure incremental refresh appropriately
- ✅ Set proper schema and table names
- ✅ Document update method choices
- ❌ Don't use MERGE in T3 (data already versioned in T2)
- ❌ Don't use Replace for large fact tables

---

## Monitoring and Troubleshooting

### Monitoring Dataflow Execution

1. **Fabric Portal** → **Dataflows Gen2** → Select dataflow
2. View execution history
3. Check execution times
4. Review error messages
5. Monitor refresh status

### Common Issues

**Issue 1: Slow Performance**
- **Cause**: Loading too much data, no query folding
- **Solution**: Add filters, enable query folding, use incremental refresh

**Issue 2: Memory Errors**
- **Cause**: Large datasets, complex transformations
- **Solution**: Break into smaller dataflows, optimize transformations

**Issue 3: Refresh Failures**
- **Cause**: Connection issues, data quality problems
- **Solution**: Add error handling, validate source data

**Issue 4: Incremental Refresh Not Working**
- **Cause**: Incorrect date column, range configuration
- **Solution**: Verify date column, check range settings

### Best Practices

- ✅ Monitor dataflow execution regularly
- ✅ Set up alerts for failures
- ✅ Log errors to T0 error tables
- ✅ Document troubleshooting steps
- ✅ Test dataflows on sample data first

---

## Related Topics

- [Performance Optimization](../optimization/performance-optimization.md) - Comprehensive performance optimization guide
- [Technology Distinctions](../reference/technology-distinctions.md) - Data Factory vs Dataflows Gen2
- [Warehouse Patterns](warehouse-patterns.md) - Warehouse patterns for T2/T3/T5
- [T0-T5 Architecture Pattern](../architecture/architecture-pattern.md) - Detailed implementation guide
- [Troubleshooting Guide](../operations/troubleshooting-guide.md) - Common Dataflows Gen2 issues

---

## Summary

Dataflows Gen2 is the **primary and only** tool for T3 transformations in the T0-T5 architecture pattern. Key takeaways:

1. **T3 Transformations Only**: Dataflows Gen2 is used for ALL T3 transformations (not Data Factory, not notebooks)
2. **Use Append Mode**: T3 dataflows should append (data already versioned in T2)
3. **Enable Query Folding**: Optimize performance by pushing operations to source
4. **Incremental Refresh**: Use for large tables to improve performance
5. **Error Handling**: Implement robust error handling and logging
6. **Star Schema**: Create star schema structures in T3
7. **Performance**: Optimize queries by filtering early and selecting columns early (see [Performance Optimization](../optimization/performance-optimization.md))
8. **Monitoring**: Monitor execution and troubleshoot issues proactively

**Architecture Clarification:**
- **Data Factory**: T1 ingestion (copying data from external sources)
- **Dataflows Gen2**: T3 transformations (business logic, joins, aggregations)
- **Data Factory**: Also orchestrates overall pipeline flow (T1 → T2 → T3 → T5)

Follow these patterns to build efficient, maintainable data transformation pipelines in Fabric.
