# T0-T5 Architecture Overview

## High-Level Architecture Flow

```mermaid
graph TB
    subgraph "External Sources"
        S1[JSON Files]
        S2[XML Files]
        S3[SQL Databases]
        S4[APIs]
    end
    
    subgraph "T0 - Control Layer"
        T0[Warehouse<br/>T-SQL Tables]
        T0 --> T0_LOG[Pipeline Logs]
        T0 --> T0_WM[Watermarks]
    end
    
    subgraph "T1 - Raw Landing"
        T1[Lakehouse<br/>VARIANT Tables]
        T1 --> T1_MV[Materialized Views]
    end
    
    subgraph "T2 - Historical Record"
        T2[Warehouse<br/>SCD2 Dimensions]
        T2 --> T2_FACT[Fact Tables]
    end
    
    subgraph "T3 - Transformations"
        T3[Warehouse<br/>Dataflows Gen2]
        T3 --> T3_REF[Reference Data]
        T3 --> T3_STAR[Star Schema]
    end
    
    subgraph "T3._FINAL - Snapshots"
        T3F[Zero-Copy Clones]
    end
    
    subgraph "T5 - Presentation"
        T5[Warehouse<br/>SQL Views]
    end
    
    subgraph "Semantic Layer"
        SEM[Direct Lake on SQL<br/>Semantic Model]
        SEM --> SEM_DL[Direct Lake<br/>_FINAL Tables]
        SEM --> SEM_DQ[DirectQuery<br/>T5 Views]
    end
    
    subgraph "Consumption"
        PBI[Power BI Reports]
    end
    
    S1 --> T1
    S2 --> T1
    S3 --> T1
    S4 --> T1
    
    T0 -.->|Orchestrates| T1
    T1 -->|Shortcuts| T2
    T2 -->|Dataflows Gen2| T3
    T3 -->|Zero-Copy Clone| T3F
    T3F --> T5
    T5 --> SEM
    T3F --> SEM
    SEM --> PBI
    
    style T0 fill:#e1f5ff
    style T1 fill:#fff4e1
    style T2 fill:#ffe1f5
    style T3 fill:#e1ffe1
    style T3F fill:#f5e1ff
    style T5 fill:#ffe1e1
    style SEM fill:#e1f5e1
    style PBI fill:#f5f5e1
```

## Key Components

### T0 - Control Layer
- Pipeline orchestration metadata
- Execution logs
- Watermark tracking
- Configuration tables

### T1 - Raw Landing
- VARIANT columns for schema flexibility
- Materialized views for performance
- Transient layer (truncated after T2)

### T2 - Historical Record
- SCD2 dimensions with full history
- Fact tables with incremental loading
- T-SQL stored procedures

### T3 - Transformations
- Dataflows Gen2 for all transformations
- Reference data tables
- Star schema creation

### T3._FINAL - Snapshots
- Zero-copy clones
- Isolated from T3 failures
- Stable for semantic layer

### T5 - Presentation
- SQL views only
- Business-friendly naming
- RLS-ready

### Semantic Layer
- Direct Lake on SQL endpoints
- Automatic DirectQuery fallback
- Single Warehouse source

## Related Documentation

- [Architecture Pattern](../architecture/architecture-pattern.md) - Detailed implementation guide
- [Pattern Summary](../architecture/pattern-summary.md) - High-level overview
