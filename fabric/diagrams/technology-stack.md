# Technology Stack Diagram

## Technology Mapping to T0-T5 Layers

```mermaid
graph TB
    subgraph "T0 - Control"
        T0_TECH[T-SQL<br/>Warehouse Tables]
    end
    
    subgraph "T1 - Raw Landing"
        T1_TECH1[Data Factory<br/>Copy Activities]
        T1_TECH2[Lakehouse<br/>VARIANT Tables]
        T1_TECH3[Materialized Views<br/>Delta Lake]
        T1_TECH1 --> T1_TECH2
        T1_TECH2 --> T1_TECH3
    end
    
    subgraph "T2 - Historical"
        T2_TECH1[Warehouse<br/>SQL Analytics]
        T2_TECH2[T-SQL<br/>Stored Procedures]
        T2_TECH3[SCD2 MERGE<br/>Delta Tables]
        T2_TECH1 --> T2_TECH2
        T2_TECH2 --> T2_TECH3
    end
    
    subgraph "T3 - Transformations"
        T3_TECH1[Dataflows Gen2<br/>Power Query M]
        T3_TECH2[Warehouse<br/>Delta Tables]
        T3_TECH1 --> T3_TECH2
    end
    
    subgraph "T3._FINAL - Snapshots"
        T3F_TECH[Zero-Copy Clones<br/>Delta in OneLake]
    end
    
    subgraph "T5 - Presentation"
        T5_TECH[T-SQL Views<br/>Warehouse]
    end
    
    subgraph "Semantic Layer"
        SEM_TECH1[Direct Lake on OneLake<br/>Parquet Files]
        SEM_TECH2[DirectQuery<br/>SQL Pushdown]
        SEM_TECH1 --> SEM_TECH2
    end
    
    subgraph "Consumption"
        PBI_TECH[Power BI<br/>Reports & Dashboards]
    end
    
    T0_TECH -.->|Orchestrates| T1_TECH1
    T1_TECH3 -->|Shortcuts| T2_TECH1
    T2_TECH3 -->|Dataflows Gen2| T3_TECH1
    T3_TECH2 -->|Clone| T3F_TECH
    T3F_TECH --> T5_TECH
    T3F_TECH --> SEM_TECH1
    T5_TECH --> SEM_TECH2
    SEM_TECH1 --> PBI_TECH
    SEM_TECH2 --> PBI_TECH
    
    style T0_TECH fill:#e1f5ff
    style T1_TECH1 fill:#fff4e1
    style T1_TECH2 fill:#fff4e1
    style T1_TECH3 fill:#fff4e1
    style T2_TECH1 fill:#ffe1f5
    style T2_TECH2 fill:#ffe1f5
    style T2_TECH3 fill:#ffe1f5
    style T3_TECH1 fill:#e1ffe1
    style T3_TECH2 fill:#e1ffe1
    style T3F_TECH fill:#f5e1ff
    style T5_TECH fill:#ffe1e1
    style SEM_TECH1 fill:#e1f5e1
    style SEM_TECH2 fill:#e1f5e1
    style PBI_TECH fill:#f5f5e1
```

## Technology by Layer

| Layer | Primary Technology | Secondary Technology | Purpose |
|-------|-------------------|---------------------|---------|
| T0 | T-SQL | Warehouse | Control & orchestration |
| T1 | Data Factory | Lakehouse (Delta) | Raw data ingestion |
| T2 | T-SQL | Warehouse (Delta) | Historical record (SCD2) |
| T3 | Dataflows Gen2 | Warehouse (Delta) | Transformations |
| T3._FINAL | Zero-Copy Clone | Delta in OneLake | Validated snapshots |
| T5 | T-SQL Views | Warehouse | Presentation layer |
| Semantic | Direct Lake on OneLake | OneLake Parquet files | Analytics consumption |

## Related Documentation

- [Technology Distinctions](../reference/technology-distinctions.md) - Data Factory vs Dataflows Gen2
- [Architecture Pattern](../architecture/architecture-pattern.md) - Detailed implementation guide
