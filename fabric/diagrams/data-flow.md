# Data Flow Diagram

## Detailed Data Flow Through T0-T5 Layers

```mermaid
sequenceDiagram
    participant Ext as External Sources
    participant DF as Data Factory
    participant T1 as T1 Lakehouse
    participant T2 as T2 Warehouse
    participant DFG2 as Dataflows Gen2
    participant T3 as T3 Warehouse
    participant T5 as T5 Views
    participant SEM as Semantic Model
    participant PBI as Power BI
    
    Note over Ext,T1: T1 Ingestion Phase
    Ext->>DF: JSON/XML/CSV Files
    DF->>T1: Copy to VARIANT tables
    T1->>T1: Create Materialized Views
    
    Note over T1,T2: T2 Historical Phase
    T2->>T1: Create Shortcuts
    T2->>T2: Execute SCD2 MERGE (T-SQL)
    T2->>T2: Load Facts (Incremental)
    T2->>T1: Truncate T1 (on success)
    
    Note over T2,T3: T3 Transformation Phase
    DFG2->>T2: Read T2 Dimensions/Facts
    DFG2->>T3: Transform & Load (Append)
    DFG2->>T3: Create Star Schema
    
    Note over T3,T5: T5 Presentation Phase
    T3->>T3: Create Zero-Copy Clones (_FINAL)
    T3->>T5: Create Views (Git-managed)
    
    Note over T5,SEM: Semantic Layer
    SEM->>T3: Direct Lake (_FINAL tables)
    SEM->>T5: DirectQuery (Views)
    
    Note over SEM,PBI: Consumption
    PBI->>SEM: Query Semantic Model
    SEM->>PBI: Return Results
```

## Technology Flow

```mermaid
graph LR
    subgraph "Ingestion"
        A[Data Factory] -->|Copy| B[Lakehouse VARIANT]
    end
    
    subgraph "Historical"
        B -->|Shortcuts| C[Warehouse]
        C -->|T-SQL SP| D[SCD2 Tables]
    end
    
    subgraph "Transformations"
        D -->|Dataflows Gen2| E[T3 Tables]
        E -->|Zero-Copy| F[T3._FINAL]
    end
    
    subgraph "Presentation"
        F -->|Views| G[T5 Views]
    end
    
    subgraph "Analytics"
        F -->|Direct Lake| H[Semantic Model]
        G -->|DirectQuery| H
        H --> I[Power BI]
    end
    
    style A fill:#0078D4
    style B fill:#F2C811
    style C fill:#CC2927
    style E fill:#00A4EF
    style F fill:#7FBA00
    style G fill:#FFB900
    style H fill:#E81123
    style I fill:#F2C811
```

## Related Documentation

- [Architecture Pattern](../architecture/architecture-pattern.md) - Detailed implementation guide
- [Data Factory Patterns](../patterns/data-factory-patterns.md) - T1 ingestion patterns
- [Dataflows Gen2 Patterns](../patterns/dataflows-gen2-patterns.md) - T3 transformation patterns
