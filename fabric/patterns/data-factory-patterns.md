# Data Factory Pipeline Patterns and Best Practices

## Overview

Azure Data Factory (ADF) in Microsoft Fabric provides orchestration capabilities for data pipelines. This guide covers patterns, best practices, and strategies for using Data Factory pipelines to orchestrate the T0-T5 architecture pattern.

**Key Characteristics:**
- Visual pipeline design
- Supports complex orchestration
- Integration with Fabric services
- Error handling and retry logic
- Monitoring and alerting

---

## Architecture Context

### Role in T0-T5 Pattern

**Data Factory has two primary roles:**

1. **T1 Ingestion (Primary Role)**: Load raw data from external sources to Lakehouse
   - Copy data from external sources (ADLS, SQL, APIs, etc.)
   - Load into T1 Lakehouse VARIANT tables
   - Handle various data formats (JSON, XML, CSV, Parquet)
   - Manage ingestion orchestration

2. **Pipeline Orchestration**: Orchestrate the overall data flow
   - **T1 Ingestion**: Execute Data Factory copy activities
   - **T2 Processing**: Execute T-SQL stored procedures for SCD2 MERGE
   - **T3 Transformation**: Trigger Dataflows Gen2 for transformations
   - **T5 Refresh**: Execute clone refresh procedures
   - **T0 Logging**: Log pipeline execution and errors

**Key Distinction:**
- **Data Factory**: Used for **T1 ingestion** (copying data from external sources)
- **Dataflows Gen2**: Used for **T3 transformations** (business logic, joins, aggregations)
- **Data Factory**: Also orchestrates the overall pipeline flow (T1 → T2 → T3 → T5)

---

## Pattern 1: Pipeline Orchestration Structure

### Master Pipeline Pattern

**Structure:**
```
PL_MASTER_[Domain]
├── PL_T1_Master_Ingest
├── PL_T2_Process_SCD2
├── PL_T3_Transform
└── PL_T5_Clone_Refresh
```

**Implementation:**

```json
{
  "name": "PL_MASTER_HR_Analytics",
  "activities": [
    {
      "name": "Execute_T1_Ingest",
      "type": "ExecutePipeline",
      "dependsOn": [],
      "pipeline": {
        "referenceName": "PL_T1_Master_Ingest",
        "type": "PipelineReference"
      }
    },
    {
      "name": "Execute_T2_SCD2",
      "type": "ExecutePipeline",
      "dependsOn": [
        {
          "activity": "Execute_T1_Ingest",
          "dependencyConditions": ["Succeeded"]
        }
      ],
      "pipeline": {
        "referenceName": "PL_T2_Process_SCD2",
        "type": "PipelineReference"
      }
    },
    {
      "name": "Execute_T3_Transform",
      "type": "ExecutePipeline",
      "dependsOn": [
        {
          "activity": "Execute_T2_SCD2",
          "dependencyConditions": ["Succeeded"]
        }
      ],
      "pipeline": {
        "referenceName": "PL_T3_Transform",
        "type": "PipelineReference"
      }
    },
    {
      "name": "Execute_T5_Refresh",
      "type": "ExecutePipeline",
      "dependsOn": [
        {
          "activity": "Execute_T3_Transform",
          "dependencyConditions": ["Succeeded"]
        }
      ],
      "pipeline": {
        "referenceName": "PL_T5_Clone_Refresh",
        "type": "PipelineReference"
      }
    }
  ]
}
```

### Best Practices

- ✅ Use master pipeline for end-to-end orchestration
- ✅ Break pipelines into logical components
- ✅ Use pipeline references for reusability
- ✅ Document pipeline dependencies
- ✅ Name pipelines consistently (PL_[Layer]_[Purpose])
- ❌ Don't create monolithic pipelines
- ❌ Don't skip dependency management

---

## Pattern 2: Error Handling and Retry Logic

**Note**: This covers Data Factory pipeline-level error handling. For stored procedure error handling, see [T-SQL Patterns - Error Handling](t-sql-patterns.md#pattern-2-error-handling).

### Retry Configuration

**Activity-Level Retry:**

```json
{
  "name": "Execute_Stored_Procedure",
  "type": "SqlServerStoredProcedure",
  "retry": {
    "count": 3,
    "intervalInSeconds": 30,
    "backoffCoefficient": 2.0
  }
}
```

**Pipeline-Level Error Handling:**

```json
{
  "name": "PL_T2_Process_SCD2",
  "activities": [
    {
      "name": "Merge_Department",
      "type": "SqlServerStoredProcedure",
      "onSuccess": [
        {
          "name": "Log_Success",
          "type": "Script"
        }
      ],
      "onFailure": [
        {
          "name": "Log_Error",
          "type": "Script"
        },
        {
          "name": "Send_Alert",
          "type": "WebActivity"
        }
      ]
    }
  ]
}
```

### Error Logging Pattern

**Script Activity for Error Logging:**

```sql
-- Log pipeline error to T0.pipeline_log
INSERT INTO t0.pipeline_log (
    pipeline_name,
    start_time,
    end_time,
    status,
    error_message,
    rows_processed
)
VALUES (
    '@{pipeline().Pipeline}',
    '@{pipeline().TriggerTime}',
    GETDATE(),
    'Failed',
    '@{activity('ErrorActivity').error.message}',
    0
);
```

### Best Practices

- ✅ Configure retry logic for transient failures
- ✅ Log all errors to T0.pipeline_log
- ✅ Send alerts for critical failures
- ✅ Use exponential backoff for retries
- ✅ Distinguish between transient and permanent failures
- ✅ Stored procedures should handle their own errors (see [T-SQL Patterns](t-sql-patterns.md))
- ❌ Don't retry indefinitely
- ❌ Don't ignore errors silently

---

## Pattern 3: T1 Ingestion Pipelines (Primary Use Case)

### Pattern: Load Raw Data to Lakehouse

**This is the PRIMARY use case for Data Factory in this architecture.**

**Pipeline Structure:**

```
PL_T1_Load_[Table]
├── Copy_Data_Activity (Data Factory)
│   ├── Source: External (ADLS, SQL, APIs, etc.)
│   └── Sink: Lakehouse VARIANT table
└── Refresh_Materialized_View
```

**Key Point**: Data Factory is specifically used for **ingestion** - copying data from external sources into T1 Lakehouse. Transformations are handled by Dataflows Gen2 in T3.

### Initial Load Strategy: Snapshot Loading

**Initial Approach**: 
- **Daily Full Snapshots**: Initially, daily full snapshots may be loaded to T1 raw layer
- **Full Refresh**: Complete replacement of T1 data each day
- **No Incremental Logic**: Simple full load pattern

**Example: Daily Snapshot Load**

```json
{
  "name": "Copy_Department_Snapshot",
  "type": "Copy",
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "SELECT * FROM source.department"
    },
    "sink": {
      "type": "LakehouseSink",
      "writeBehavior": "replace"  // Full snapshot replacement
    }
  }
}
```

**Transition to Incremental**:
- After initial load, transition to incremental/watermark-based loading
- Use watermark tables in T0 for tracking
- Implement incremental copy activities

**Copy Data Activity Configuration:**

```json
{
  "name": "Copy_Department_Data",
  "type": "Copy",
  "inputs": [
    {
      "referenceName": "DS_ADLS_Department",
      "type": "DatasetReference"
    }
  ],
  "outputs": [
    {
      "referenceName": "DS_Lakehouse_RawDepartment",
      "type": "DatasetReference"
    }
  ],
  "typeProperties": {
    "source": {
      "type": "JsonSource",
      "storeSettings": {
        "type": "AzureBlobFSReadSettings",
        "recursive": false
      }
    },
    "sink": {
      "type": "LakehouseSink",
      "writeBehavior": "append"
    }
  }
}
```

### Pattern: Master T1 Orchestration

**Pipeline Structure:**

```
PL_T1_Master_Ingest
├── Execute_Load_Department (parallel)
├── Execute_Load_Time (parallel)
├── Execute_Load_Employee (depends on Department)
├── Execute_Load_Payroll (depends on Employee)
└── Refresh_All_Materialized_Views
```

**Implementation:**

```json
{
  "name": "PL_T1_Master_Ingest",
  "activities": [
    {
      "name": "Load_Department",
      "type": "ExecutePipeline",
      "pipeline": {
        "referenceName": "PL_T1_Load_Department",
        "type": "PipelineReference"
      }
    },
    {
      "name": "Load_Time",
      "type": "ExecutePipeline",
      "dependsOn": [],
      "pipeline": {
        "referenceName": "PL_T1_Load_Time",
        "type": "PipelineReference"
      }
    },
    {
      "name": "Load_Employee",
      "type": "ExecutePipeline",
      "dependsOn": [
        {
          "activity": "Load_Department",
          "dependencyConditions": ["Succeeded"]
        }
      ],
      "pipeline": {
        "referenceName": "PL_T1_Load_Employee",
        "type": "PipelineReference"
      }
    },
    {
      "name": "Refresh_Materialized_Views",
      "type": "Script",
      "dependsOn": [
        {
          "activity": "Load_Department",
          "dependencyConditions": ["Succeeded"]
        },
        {
          "activity": "Load_Time",
          "dependencyConditions": ["Succeeded"]
        },
        {
          "activity": "Load_Employee",
          "dependencyConditions": ["Succeeded"]
        }
      ],
      "script": {
        "type": "SqlQuery",
        "query": "REFRESH MATERIALIZED VIEW mv_department; REFRESH MATERIALIZED VIEW mv_employee; REFRESH MATERIALIZED VIEW mv_time;"
      }
    }
  ]
}
```

### Best Practices

- ✅ Load independent tables in parallel
- ✅ Respect dependencies (e.g., Employee depends on Department)
- ✅ Refresh materialized views after all loads complete
- ✅ Use append mode for T1 (no deduplication)
- ✅ Log ingestion metrics (rows loaded, file size)
- ❌ Don't load dependent tables before dependencies
- ❌ Don't refresh materialized views after each table

---

## Pattern 4: T2 SCD2 Processing Pipelines

### Pattern: Execute Stored Procedures in Sequence

**Pipeline Structure:**

```
PL_T2_Process_SCD2
├── Execute_Merge_Department
├── Execute_Load_Time
├── Execute_Merge_Employee (depends on Department)
├── Execute_Load_Payroll (depends on Employee)
└── Truncate_T1_Tables (on success)
```

**Stored Procedure Activity:**

```json
{
  "name": "Execute_Merge_Department",
  "type": "SqlServerStoredProcedure",
  "linkedService": {
    "referenceName": "LS_Warehouse",
    "type": "LinkedServiceReference"
  },
  "typeProperties": {
    "storedProcedureName": "t2.usp_merge_dim_department"
  }
}
```

### Pattern: T1 Truncation After T2 Success

**Script Activity:**

```sql
-- Only truncate T1 after successful T2 processing
-- This ensures T1 is transient and doesn't accumulate data

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
INSERT INTO t0.pipeline_log (pipeline_name, start_time, end_time, status, rows_processed)
VALUES ('PL_T2_Process_SCD2', '@{pipeline().TriggerTime}', GETDATE(), 'Success', 
    (SELECT COUNT(*) FROM t2.dim_department WHERE updated_at >= '@{pipeline().TriggerTime}')
);
```

### Best Practices

- ✅ Execute dimension MERGE before fact loads
- ✅ Execute dependent procedures in sequence
- ✅ Truncate T1 only after T2 success
- ✅ Update watermarks after successful processing
- ✅ Log processing metrics
- ❌ Don't truncate T1 before T2 completion
- ❌ Don't skip watermark updates

---

## Pattern 5: T3 Transformation Pipelines

### Pattern: Execute Dataflows Gen2

**Pipeline Structure:**

```
PL_T3_Transform
├── Execute_DF_Employee_Base
├── Execute_DF_Employee_Enriched (depends on Base)
├── Execute_DF_Payroll_Summary
├── Execute_DF_Dim_Employee
├── Execute_DF_Dim_Department
├── Execute_DF_Dim_Time
└── Execute_DF_Fact_Payroll
```

**Dataflow Gen2 Activity:**

```json
{
  "name": "Execute_DF_Employee_Base",
  "type": "ExecuteDataFlow",
  "dataflow": {
    "referenceName": "DF_T3_Employee_Base",
    "type": "DataFlowReference"
  },
  "compute": {
    "computeType": "General",
    "coreCount": 8
  }
}
```

### Pattern: Parallel Execution

**For Independent Dataflows:**

```json
{
  "name": "PL_T3_Transform",
  "activities": [
    {
      "name": "Execute_DF_Dim_Employee",
      "type": "ExecuteDataFlow",
      "dependsOn": []
    },
    {
      "name": "Execute_DF_Dim_Department",
      "type": "ExecuteDataFlow",
      "dependsOn": []
    },
    {
      "name": "Execute_DF_Dim_Time",
      "type": "ExecuteDataFlow",
      "dependsOn": []
    },
    {
      "name": "Execute_DF_Fact_Payroll",
      "type": "ExecuteDataFlow",
      "dependsOn": [
        {
          "activity": "Execute_DF_Dim_Employee",
          "dependencyConditions": ["Succeeded"]
        },
        {
          "activity": "Execute_DF_Dim_Department",
          "dependencyConditions": ["Succeeded"]
        }
      ]
    }
  ]
}
```

### Best Practices

- ✅ Execute independent dataflows in parallel
- ✅ Respect dependencies between dataflows
- ✅ Monitor dataflow execution times
- ✅ Configure appropriate compute resources
- ✅ Log dataflow execution metrics
- ❌ Don't execute dependent dataflows before dependencies
- ❌ Don't overallocate compute resources

---

## Pattern 6: T5 Clone Refresh Pipeline

### Pattern: Refresh Clones and Views

**Pipeline Structure:**

```
PL_T5_Clone_Refresh
├── Execute_Clone_Refresh_Procedure
└── Deploy_T5_Views (from Git)
```

**Script Activity for Clone Refresh:**

```sql
-- Execute stored procedure to refresh clones
EXEC t3.usp_refresh_final_clones;
```

**Script Activity for View Deployment:**

```sql
-- Deploy T5 views from version-controlled script
-- This would typically be done via CI/CD, but can be manual for POC

CREATE VIEW t5.vw_employee AS
SELECT
    employee_key AS [Employee Key],
    employee_number AS [Employee ID],
    first_name + ' ' + last_name AS [Employee Name],
    ...
FROM t3.dim_employee_FINAL;
```

### Best Practices

- ✅ Refresh clones only after successful T3 completion
- ✅ Deploy views from version-controlled scripts
- ✅ Drop views before dropping clones (avoid dependencies)
- ✅ Recreate clones in correct order
- ✅ Log clone refresh metrics
- ❌ Don't refresh clones during T3 execution
- ❌ Don't skip view deployment

---

## Pattern 7: Watermark Management

### Pattern: Track Last Processed Timestamps

**Watermark Table Structure:**

```sql
CREATE TABLE t0.watermark (
    table_name VARCHAR(100) PRIMARY KEY,
    last_processed_timestamp DATETIME2,
    updated_at DATETIME2 DEFAULT GETDATE()
);
```

**Lookup Activity:**

```json
{
  "name": "Lookup_Watermark",
  "type": "Lookup",
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "SELECT last_processed_timestamp FROM t0.watermark WHERE table_name = 'fact_payroll'"
    },
    "dataset": {
      "referenceName": "DS_Warehouse",
      "type": "DatasetReference"
    }
  }
}
```

**Use Watermark in Copy Activity:**

```json
{
  "name": "Copy_Incremental_Data",
  "type": "Copy",
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "@concat('SELECT * FROM source_table WHERE modified_date > ''', activity('Lookup_Watermark').output.firstRow.last_processed_timestamp, '''')"
    }
  }
}
```

**Update Watermark:**

```sql
MERGE INTO t0.watermark AS target
USING (SELECT 'fact_payroll' AS table_name, GETDATE() AS last_processed_timestamp) AS source
ON target.table_name = source.table_name
WHEN MATCHED THEN UPDATE SET last_processed_timestamp = source.last_processed_timestamp, updated_at = GETDATE()
WHEN NOT MATCHED THEN INSERT (table_name, last_processed_timestamp) VALUES (source.table_name, source.last_processed_timestamp);
```

### Best Practices

- ✅ Use watermarks for incremental loads
- ✅ Update watermarks after successful processing
- ✅ Store watermarks in T0 control layer
- ✅ Include timestamp precision appropriate for source
- ✅ Handle watermark initialization (first run)
- ❌ Don't update watermarks before processing completes
- ❌ Don't use watermarks for full refresh scenarios

---

## Pattern 8: Parameterization

### Pattern: Environment-Specific Parameters

**Pipeline Parameters:**

```json
{
  "parameters": {
    "WarehouseServer": {
      "type": "string",
      "defaultValue": "dev-warehouse.database.windows.net"
    },
    "LakehouseName": {
      "type": "string",
      "defaultValue": "T1_DATA_LAKE_DEV"
    },
    "SchemaName": {
      "type": "string",
      "defaultValue": "t2"
    }
  }
}
```

**Use Parameters in Activities:**

```json
{
  "name": "Execute_Stored_Procedure",
  "type": "SqlServerStoredProcedure",
  "typeProperties": {
    "storedProcedureName": {
      "value": "@concat(pipeline().parameters.SchemaName, '.usp_merge_dim_department')",
      "type": "Expression"
    }
  }
}
```

### Pattern: Dynamic Configuration

**Lookup Configuration Table:**

```sql
-- T0 configuration table
CREATE TABLE t0.pipeline_config (
    config_key VARCHAR(100) PRIMARY KEY,
    config_value VARCHAR(MAX),
    environment VARCHAR(20)
);
```

**Lookup Activity:**

```json
{
  "name": "Lookup_Config",
  "type": "Lookup",
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "@concat('SELECT config_value FROM t0.pipeline_config WHERE config_key = ''batch_size'' AND environment = ''', pipeline().parameters.Environment, '''')"
    }
  }
}
```

### Best Practices

- ✅ Use parameters for environment-specific values
- ✅ Store configuration in T0 tables
- ✅ Document parameter purposes
- ✅ Use parameter defaults for development
- ✅ Validate parameter values
- ❌ Don't hardcode environment-specific values
- ❌ Don't use parameters for frequently changing values

---

## Pattern 9: Monitoring and Alerting

### Pattern: Pipeline Execution Logging

**Log Pipeline Start:**

```sql
INSERT INTO t0.pipeline_log (
    pipeline_name,
    start_time,
    status,
    rows_processed
)
VALUES (
    '@{pipeline().Pipeline}',
    '@{pipeline().TriggerTime}',
    'Running',
    0
);
```

**Log Pipeline Completion:**

```sql
UPDATE t0.pipeline_log
SET 
    end_time = GETDATE(),
    status = 'Success',
    rows_processed = @{activity('CopyActivity').output.rowsCopied}
WHERE pipeline_name = '@{pipeline().Pipeline}'
AND start_time = '@{pipeline().TriggerTime}'
AND status = 'Running';
```

### Pattern: Alert on Failure

**Web Activity for Alert:**

```json
{
  "name": "Send_Alert",
  "type": "WebActivity",
  "typeProperties": {
    "url": "https://hooks.office.com/webhook/...",
    "method": "POST",
    "body": {
      "text": "@concat('Pipeline ', pipeline().Pipeline, ' failed at ', utcnow(), '. Error: ', activity('ErrorActivity').error.message)"
    }
  }
}
```

### Pattern: Performance Monitoring

**Log Execution Metrics:**

```sql
INSERT INTO t0.pipeline_metrics (
    pipeline_name,
    execution_id,
    start_time,
    end_time,
    duration_seconds,
    rows_processed,
    data_size_mb
)
VALUES (
    '@{pipeline().Pipeline}',
    '@{pipeline().RunId}',
    '@{pipeline().TriggerTime}',
    GETDATE(),
    DATEDIFF(SECOND, '@{pipeline().TriggerTime}', GETDATE()),
    @{activity('CopyActivity').output.rowsCopied},
    @{activity('CopyActivity').output.dataRead}
);
```

### Best Practices

- ✅ Log all pipeline executions to T0
- ✅ Track execution times and metrics
- ✅ Set up alerts for failures
- ✅ Monitor pipeline performance trends
- ✅ Create dashboards for pipeline monitoring
- ❌ Don't skip logging
- ❌ Don't alert on every failure (use thresholds)

---

## Pattern 10: Scheduling and Triggers

### Pattern: Scheduled Execution

**Schedule Trigger:**

```json
{
  "name": "Daily_2AM_Trigger",
  "type": "ScheduleTrigger",
  "typeProperties": {
    "recurrence": {
      "frequency": "Day",
      "interval": 1,
      "startTime": "2024-01-01T02:00:00Z",
      "timeZone": "UTC"
    }
  },
  "pipelines": [
    {
      "pipelineReference": {
        "referenceName": "PL_MASTER_HR_Analytics",
        "type": "PipelineReference"
      }
    }
  ]
}
```

### Pattern: Event-Driven Triggers

**Event Trigger (T0-based):**

```json
{
  "name": "On_T1_Complete_Trigger",
  "type": "CustomEventTrigger",
  "typeProperties": {
    "events": [
      {
        "eventType": "PipelineCompleted",
        "pipelineName": "PL_T1_Master_Ingest",
        "status": "Succeeded"
      }
    ]
  },
  "pipelines": [
    {
      "pipelineReference": {
        "referenceName": "PL_T2_Process_SCD2",
        "type": "PipelineReference"
      }
    }
  ]
}
```

### Best Practices

- ✅ Use scheduled triggers for regular execution
- ✅ Use event triggers for dependent pipelines
- ✅ Set appropriate time zones
- ✅ Consider business hours for scheduling
- ✅ Document trigger dependencies
- ❌ Don't create circular trigger dependencies
- ❌ Don't schedule too frequently (consider cost)

---

## Summary

Data Factory pipelines serve two critical roles in the T0-T5 architecture pattern:

**Primary Role: T1 Ingestion**
- Copy data from external sources (ADLS, SQL, APIs, etc.)
- Load into T1 Lakehouse VARIANT tables
- Handle various data formats (JSON, XML, CSV, Parquet)
- Manage ingestion orchestration

**Secondary Role: Pipeline Orchestration**
- Orchestrate end-to-end data flow (T1 → T2 → T3 → T5)
- Execute T-SQL stored procedures for T2 SCD2
- Trigger Dataflows Gen2 for T3 transformations
- Execute clone refresh procedures for T5

**Key Takeaways:**

1. **T1 Ingestion**: Data Factory is the primary tool for loading raw data from external sources
2. **T3 Transformations**: Dataflows Gen2 handles all transformations (not Data Factory)
3. **Master Pipeline**: Use for end-to-end orchestration
4. **Error Handling**: Implement retry logic and error logging
5. **Dependencies**: Manage pipeline dependencies correctly
6. **Watermarks**: Use for incremental load tracking
7. **Parameterization**: Use parameters for environment-specific values
8. **Monitoring**: Log all executions and set up alerts
9. **Scheduling**: Use appropriate triggers for execution

**Architecture Clarification:**
- **Data Factory**: T1 ingestion + pipeline orchestration
- **Dataflows Gen2**: T3 transformations only
- Clear separation of concerns between ingestion and transformation

## Related Topics

- [T-SQL Patterns](t-sql-patterns.md) - Error handling in stored procedures
- [Technology Distinctions](../reference/technology-distinctions.md) - Data Factory vs Dataflows Gen2
- [Lakehouse Patterns](lakehouse-patterns.md) - T1 Lakehouse patterns
- [Warehouse Patterns](warehouse-patterns.md) - T2/T3/T5 Warehouse patterns
- [Monitoring & Observability](../operations/monitoring-observability.md) - Pipeline monitoring
- [Troubleshooting Guide](../operations/troubleshooting-guide.md) - Common pipeline issues

---

Follow these patterns to build reliable, maintainable pipeline orchestration in Fabric.
