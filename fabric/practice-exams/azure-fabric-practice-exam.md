# Azure Microsoft Fabric Practice Exam (DP-600)

This practice exam is aligned with **Exam DP-600: Implementing Analytics Solutions Using Microsoft Fabric** and the skills measured on [Microsoft Learn](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/dp-600). It is intended to help you prepare for the Fabric Analytics Engineer Associate certification.

**Exam weight distribution (official):**
- Maintain a data analytics solution: 25–30%
- Prepare data: 45–50%
- Implement and manage semantic models: 25–30%

**This practice exam:** 150 questions with answers and explanations, aligned to 100% of the DP-600 skills measured (January 2026), with multiple questions per topic for thorough coverage.

### Skills coverage map

| Skill area | DP-600 bullets | Sample questions |
|------------|-----------------|------------------|
| **Maintain – Security and governance** | Workspace-, item-, row/column/object/file-level access; sensitivity labels; endorse items | 1, 2, 14, 20–24, 52–57, 76–77, 85, 100–101, 111, 122, 131, 145 |
| **Maintain – Development lifecycle** | Version control; .pbip; deployment pipelines; impact analysis; XMLA; reusable assets | 3, 16, 25–28, 51, 58–60, 78, 94, 107, 117, 127, 139 |
| **Prepare – Get data** | Data connection; OneLake catalog & Real-Time hub; ingest; lakehouse/warehouse/eventhouse; OneLake integration; shortcuts | 4, 5, 15, 18, 29–31, 61–64, 79, 86, 90, 97, 102, 108, 112, 118, 125, 132, 136, 142, 149 |
| **Prepare – Transform data** | Views, functions, stored procedures; enrich; star schema; denormalize; aggregate; merge/join; duplicates & nulls; types; filter | 6, 7, 32–38, 65–68, 80–81, 87, 91, 99, 103, 109, 113, 119, 123, 128, 133, 137, 143, 146 |
| **Prepare – Query and analyze** | Visual Query Editor; SQL; KQL; DAX | 8, 39–40, 69–70, 82, 95, 106, 116, 130, 140 |
| **Semantic models – Design and build** | Storage mode; star schema; relationships; DAX (iterators, variables, filtering, windowing, information); calculation groups; dynamic format; field parameters; large format; composite | 9–11, 19, 41–47, 71–73, 88, 92, 96, 104, 110, 114, 120, 124, 126, 134, 138, 141, 147, 150 |
| **Semantic models – Optimize** | Performance; DAX performance; Direct Lake (fallback, refresh); Direct Lake OneLake vs SQL; incremental refresh | 12, 13, 17, 48–50, 74–75, 84, 89, 93, 98, 105, 115, 121, 129, 135, 144, 148 |

---

## Questions

### 1. Maintain a data analytics solution – Security and governance

**Which role can assign workspace-level permissions (Admin, Member, Contributor, Viewer) in a Microsoft Fabric workspace?**

- A) Only a Fabric capacity administrator  
- B) Workspace Admin or a Fabric administrator  
- C) Any user with Contributor role on the workspace  
- D) Only Microsoft 365 Global Admin  

**Answer: B) Workspace Admin or a Fabric administrator**

Workspace roles (Admin, Member, Contributor, Viewer) are managed by users who are **Workspace admins** for that workspace, or by **Fabric administrators** who have tenant-level control. Capacity administrators manage capacity and capacity assignment, not individual workspace membership.  
*Ref: [Microsoft Learn – Roles in workspaces](https://learn.microsoft.com/en-us/fabric/get-started/roles-workspaces)*

---

### 2. Maintain a data analytics solution – Security and governance

**You need to restrict report users so they see only rows where `Region = 'EMEA'`. What should you implement?**

- A) Column-level security  
- B) Row-level security (RLS)  
- C) Object-level security  
- D) Sensitivity labels

**Answer: B) Row-level security (RLS)**

**Row-level security (RLS)** restricts which rows a user can see in a report or semantic model (e.g., by region, department). Column-level security hides specific columns; object-level security hides tables or measures; sensitivity labels classify and protect content.  
*Ref: [Microsoft Learn – Row-level security](https://learn.microsoft.com/en-us/power-bi/enterprise/service-admin-rls)*

---

### 3. Maintain a data analytics solution – Development lifecycle

**What is the main purpose of a Power BI Desktop project file (.pbip)?**

- A) To package a semantic model and all reports for backup  
- B) To enable source control and multi-file authoring of a semantic model with Git  
- C) To deploy a semantic model to a Fabric capacity  
- D) To create a template that can be reused with different data sources

**Answer: B) To enable source control and multi-file authoring of a semantic model with Git**

A **.pbip** (Power BI Desktop project) stores the semantic model in a folder of text-based definition files (e.g., TMDL), which works with **Git** and supports **source control** and multi-file authoring. It is not primarily for backup, deployment, or template reuse (.pbit).  
*Ref: [Microsoft Learn – Power BI Desktop project](https://learn.microsoft.com/en-us/power-bi/developer/desktop/desktop-project-files)*

---

### 4. Prepare data – Get data

**Where can you centrally discover and browse datasets, lakehouses, and other analytics assets across your organization in Microsoft Fabric?**

- A) Only from each workspace’s item list  
- B) OneLake data hub (OneLake catalog)  
- C) Power BI service app workspace only  
- D) Azure Data Catalog

**Answer: B) OneLake data hub (OneLake catalog)**

The **OneLake data hub** (OneLake catalog) provides a central place to discover and browse Fabric assets (e.g., lakehouses, warehouses, semantic models) across workspaces. Workspace item lists are per-workspace; Power BI app workspaces are a subset of the experience.  
*Ref: [Microsoft Learn – OneLake](https://learn.microsoft.com/en-us/fabric/onelake/onelake-overview)*

---

### 5. Prepare data – Get data

**When should you choose an eventhouse over a lakehouse or warehouse in Fabric?**

- A) When you need only batch loading of CSV files  
- B) When you need to ingest, store, and analyze high-volume streaming or event data with KQL  
- C) When you need a relational schema with T-SQL only  
- D) When you need a star schema with only historical snapshots

**Answer: B) When you need to ingest, store, and analyze high-volume streaming or event data with KQL**

An **eventhouse** in Fabric is for **streaming and event data** and is queried with **KQL**. Lakehouses and warehouses are for batch and relational analytics. Choosing eventhouse is appropriate when the scenario is event/streaming and KQL-based analysis.  
*Ref: [Microsoft Learn – Eventhouse](https://learn.microsoft.com/en-us/fabric/real-time-analytics/eventhouse/eventhouse-overview)*

---

### 6. Prepare data – Transform data

**In a Fabric warehouse, which object do you use to expose a saved query that returns a result set and can be used in other queries?**

- A) Materialized view only  
- B) View or table-valued function  
- C) Stored procedure only  
- D) Dataflow Gen2 only

**Answer: B) View or table-valued function**

In a Fabric **warehouse**, you expose reusable query logic as **views** (named SELECT statements) or **table-valued functions** that return a result set. Stored procedures run logic but are not used the same way as “saved queries” for reuse in other queries. Materialized views and Dataflows Gen2 serve different purposes.  
*Ref: [Microsoft Learn – Data warehousing in Fabric](https://learn.microsoft.com/en-us/fabric/data-warehouse/data-warehousing)*

---

### 7. Prepare data – Transform data

**Implementing a star schema in a lakehouse or warehouse typically involves:**

- A) Only flattening all tables into one wide table  
- B) Fact tables with measures and dimension tables with attributes, and relationships between them  
- C) Storing only raw event streams without structure  
- D) Using only KQL for all transformations

**Answer: B) Fact tables with measures and dimension tables with attributes, and relationships between them**

A **star schema** has **fact tables** (measures, keys) and **dimension tables** (attributes), with relationships between them. It is a standard design for analytics in both lakehouses and warehouses in Fabric.  
*Ref: [Microsoft Learn – Star schema](https://learn.microsoft.com/en-us/fabric/data-warehouse/star-schema)*

---

### 8. Prepare data – Query and analyze data

**Which language is used to query data in a Fabric KQL database or eventhouse?**

- A) T-SQL only  
- B) DAX only  
- C) Kusto Query Language (KQL)  
- D) Power Query M only

**Answer: C) Kusto Query Language (KQL)**

**KQL** is the query language for **KQL databases** and **eventhouses** in Fabric. T-SQL is used for warehouses; DAX for semantic models; Power Query M for transformations in dataflows.  
*Ref: [Microsoft Learn – KQL in Fabric](https://learn.microsoft.com/en-us/fabric/real-time-analytics/kql-database/)*

---

### 9. Implement and manage semantic models – Design and build

**In a Power BI semantic model, which storage mode allows the engine to get data in real time from the source and push filters to the source?**

- A) Import only  
- B) DirectQuery only  
- C) Direct Lake only  
- D) Both DirectQuery and Direct Lake (for supported sources)

**Answer: D) Both DirectQuery and Direct Lake (for supported sources)**

**DirectQuery** and **Direct Lake** (where supported) get data at query time and can push filters to the source. Import mode caches data and does not push filters to the source at query time. The question allows both modes that support real-time and pushdown.  
*Ref: [Microsoft Learn – Storage modes, DirectQuery, Direct Lake](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-storage-mode)*

---

### 10. Implement and manage semantic models – Design and build

**What is a composite model in Power BI?**

- A) A model that uses only Import mode  
- B) A model that combines two or more data connectivity modes (e.g., Import and DirectQuery, or Direct Lake and DirectQuery)  
- C) A model that uses only Direct Lake  
- D) A model that has no relationships

**Answer: B) A model that combines two or more data connectivity modes**

A **composite model** combines at least two **data connectivity modes** (e.g., Import + DirectQuery, or Direct Lake + DirectQuery). This allows mixing cached and live data in one semantic model.  
*Ref: [Microsoft Learn – Composite models](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-composite-models)*

---

### 11. Implement and manage semantic models – Design and build

**Which DAX category is used for functions that iterate over a table and evaluate an expression per row (e.g., SUMX, AVERAGEX)?**

- A) Aggregation functions  
- B) Iterator (X) functions  
- C) Information functions only  
- D) Table manipulation functions only

**Answer: B) Iterator (X) functions**

**Iterator (X) functions** (e.g., SUMX, AVERAGEX, FILTER) iterate over a table and evaluate an expression per row. They are distinct from simple aggregations (SUM, AVERAGE) and other DAX categories.  
*Ref: [Microsoft Learn – DAX function reference](https://learn.microsoft.com/en-us/dax/dax-function-reference)*

---

### 12. Implement and manage semantic models – Optimize

**What is Direct Lake in Microsoft Fabric?**

- A) A way to run T-SQL on a warehouse  
- B) A semantic model connectivity mode that reads from OneLake (or SQL endpoint) without an import refresh, with in-memory caching  
- C) A type of dataflow  
- D) A lakehouse-only feature with no semantic model integration

**Answer: B) A semantic model connectivity mode that reads from OneLake (or SQL endpoint) without an import refresh, with in-memory caching**

**Direct Lake** is a **connectivity mode** for semantic models that reads from **OneLake** (or a Fabric SQL endpoint) without a separate Import refresh and uses in-memory caching for performance. It is a Fabric/Power BI feature, not a warehouse T-SQL or dataflow feature.  
*Ref: [Microsoft Learn – Direct Lake](https://learn.microsoft.com/en-us/fabric/analytics/direct-lake-overview)*

---

### 13. Implement and manage semantic models – Optimize

**When can Direct Lake fall back to DirectQuery?**

- A) Never; Direct Lake and DirectQuery are mutually exclusive  
- B) When a query or operation is not supported in Direct Lake (e.g., certain DAX or visuals), so the engine can fall back to DirectQuery  
- C) Only when the semantic model is in Premium Per User (PPU)  
- D) Only when using an on-premises data source

**Answer: B) When a query or operation is not supported in Direct Lake, the engine can fall back to DirectQuery**

**Direct Lake** can **fall back to DirectQuery** when a DAX construct or visual is not supported in Direct Lake, so the query still runs against the source. This is configurable (default fallback and refresh behavior).  
*Ref: [Microsoft Learn – Direct Lake behavior and fallback](https://learn.microsoft.com/en-us/fabric/analytics/direct-lake-overview)*

---

### 14. Maintain a data analytics solution – Security and governance

**What are sensitivity labels in the Microsoft Purview / Fabric context used for?**

- A) To set row-level security rules  
- B) To classify and protect content (e.g., Confidential, Public) and optionally apply encryption or access policies  
- C) To assign workspace roles  
- D) To define DAX measures

**Answer: B) To classify and protect content (e.g., Confidential, Public) and optionally apply encryption or access policies**

**Sensitivity labels** (Microsoft Purview) are used to **classify and protect** content (e.g., Confidential, Public) and can enforce encryption or access policies. They are not used to define RLS, workspace roles, or DAX.  
*Ref: [Microsoft Learn – Sensitivity labels in Power BI/Fabric](https://learn.microsoft.com/en-us/power-bi/enterprise/service-security-sensitivity-label-overview)*

---

### 15. Prepare data – Get data

**OneLake is best described as:**

- A) An Azure-only blob store with no Fabric integration  
- B) The unified, single data lake for Microsoft Fabric that uses a single namespace and supports Delta/Parquet and shortcuts  
- C) A replacement for SQL Server  
- D) A real-time streaming engine only

**Answer: B) The unified, single data lake for Microsoft Fabric that uses a single namespace and supports Delta/Parquet and shortcuts**

**OneLake** is Fabric’s **unified data lake**: one namespace, support for **Delta/Parquet**, and **shortcuts** to external storage. It is built into Fabric, not a generic Azure-only blob store or a streaming-only engine.  
*Ref: [Microsoft Learn – OneLake overview](https://learn.microsoft.com/en-us/fabric/onelake/onelake-overview)*

---

### 16. Maintain a data analytics solution – Development lifecycle

**Deployment pipelines in Fabric typically include:**

- A) Only development and production stages  
- B) Development, test, and production (or similar) stages to promote content between environments  
- C) Only semantic model deployment, not lakehouses or warehouses  
- D) No support for Power BI items

**Answer: B) Development, test, and production (or similar) stages to promote content between environments**

**Deployment pipelines** in Fabric typically have multiple **stages** (e.g., Development, Test, Production) to **promote** content (reports, semantic models, lakehouses, etc.) between environments. They are not limited to two stages or to semantic models only.  
*Ref: [Microsoft Learn – Deployment pipelines](https://learn.microsoft.com/en-us/fabric/cicd/deployment-pipelines/)*

---

### 17. Implement and manage semantic models – Optimize

**Incremental refresh for a semantic model is used to:**

- A) Refresh only the entire model every time  
- B) Refresh only a sliding window of data (e.g., recent periods) and keep historical data, reducing refresh time and load  
- C) Disable all refresh  
- D) Refresh only visuals, not data

**Answer: B) Refresh only a sliding window of data and keep historical data, reducing refresh time and load**

**Incremental refresh** refreshes only a **sliding window** of data (e.g., last N days/months) and keeps older partitions, reducing refresh time and load. It does not refresh only visuals or disable refresh entirely.  
*Ref: [Microsoft Learn – Incremental refresh](https://learn.microsoft.com/en-us/power-bi/connect-data/incremental-refresh-overview)*

---

### 18. Prepare data – Get data

**How can you make external data (e.g., in another cloud or ADLS Gen2) appear inside OneLake without copying?**

- A) By using OneLake shortcuts that reference the external location  
- B) Only by copying all data into the lakehouse  
- C) By using DirectQuery only  
- D) By using a KQL database only

**Answer: A) By using OneLake shortcuts that reference the external location**

**OneLake shortcuts** point to external storage (e.g., ADLS Gen2, S3) so data appears in OneLake **without copying**. Queries can run over shortcut paths. Copying, DirectQuery, or KQL database are different mechanisms.  
*Ref: [Microsoft Learn – OneLake shortcuts](https://learn.microsoft.com/en-us/fabric/onelake/onelake-shortcuts)*

---

### 19. Implement and manage semantic models – Design and build

**Calculation groups in DAX are primarily used to:**

- A) Define new tables  
- B) Reuse a common calculation pattern (e.g., time intelligence or currency conversion) across multiple measures  
- C) Replace all base measures  
- D) Define relationships

**Answer: B) Reuse a common calculation pattern across multiple measures**

**Calculation groups** let you define a **reusable calculation pattern** (e.g., time intelligence or currency conversion) that can be applied to many measures, reducing duplication and simplifying the model.  
*Ref: [Microsoft Learn – Calculation groups](https://learn.microsoft.com/en-us/analysis-services/tabular-models/calculation-groups)*

---

### 20. Maintain a data analytics solution – Security and governance

**Endorsement in Fabric (e.g., “Promoted” or “Certified”) is used to:**

- A) Set row-level security  
- B) Signal trust and discoverability of content in the OneLake data hub and for governance  
- C) Deploy to production  
- D) Configure incremental refresh

**Answer: B) Signal trust and discoverability of content in the OneLake data hub and for governance**

**Endorsement** (e.g., **Promoted**, **Certified**) marks content as trusted and affects **discoverability** in the OneLake data hub and governance. It does not set RLS, perform deployment, or configure incremental refresh.  
*Ref: [Microsoft Learn – Endorsement](https://learn.microsoft.com/en-us/fabric/governance/endorsement)*

---

### 21. Maintain a data analytics solution – Security and governance

**What are item-level access controls in a Fabric workspace?**

- A) Permissions that apply to the entire workspace only  
- B) Permissions that apply to individual items (e.g., a report, lakehouse, semantic model) such as View, Build, Write, Reshare, and Admin  
- C) The same as row-level security  
- D) Permissions that apply only to Power BI reports

**Answer: B) Permissions that apply to individual items (e.g., a report, lakehouse, semantic model) such as View, Build, Write, Reshare, and Admin**

**Item-level access controls** in Fabric apply to specific items (reports, semantic models, lakehouses, etc.) and include permissions such as **View**, **Build**, **Write**, **Reshare**, and **Admin**. These are distinct from workspace-level roles.  
*Ref: [Microsoft Learn – Item-level permissions](https://learn.microsoft.com/en-us/fabric/get-started/item-level-permissions)*

---

### 22. Maintain a data analytics solution – Security and governance

**You need to hide the "Salary" column from a specific group of users in a semantic model while still showing other columns. What should you implement?**

- A) Row-level security  
- B) Column-level security  
- C) Object-level security  
- D) Sensitivity labels

**Answer: B) Column-level security**

**Column-level security** restricts which columns a user can see in a semantic model (e.g., hide Salary from certain roles). RLS restricts rows; OLS can restrict tables/columns/measures; sensitivity labels classify content.  
*Ref: [Microsoft Learn – Column-level security](https://learn.microsoft.com/en-us/power-bi/enterprise/service-admin-column-level-security)*

---

### 23. Maintain a data analytics solution – Security and governance

**Object-level security (OLS) in a semantic model is used to:**

- A) Restrict which rows users see in a table  
- B) Restrict access to specific tables, columns, or measures so that certain users cannot see or use them  
- C) Apply sensitivity labels to the entire model  
- D) Configure workspace roles

**Answer: B) Restrict access to specific tables, columns, or measures so that certain users cannot see or use them**

**Object-level security (OLS)** in Analysis Services/Power BI restricts access to **tables**, **columns**, or **measures** so that specific users or roles cannot see or use them. It is distinct from RLS (rows) and sensitivity labels.  
*Ref: [Microsoft Learn – Object-level security](https://learn.microsoft.com/en-us/analysis-services/tabular-models/object-level-security)*

---

### 24. Maintain a data analytics solution – Security and governance

**How can you control who can read or write files and folders in a Fabric lakehouse?**

- A) Only via workspace roles; lakehouse files have no separate access control  
- B) Through file-level and folder-level permissions in OneLake (e.g., via ACLs or Fabric item permissions that apply to the lakehouse)  
- C) Only with sensitivity labels  
- D) Only with row-level security

**Answer: B) Through file-level and folder-level permissions in OneLake (e.g., via ACLs or Fabric item permissions that apply to the lakehouse)**

Lakehouse data lives in **OneLake**; access can be controlled via **file-level and folder-level** permissions (e.g., ACLs) and via Fabric **item permissions** on the lakehouse. Workspace roles apply at workspace level; RLS and sensitivity labels are for semantic models/reports.  
*Ref: [Microsoft Learn – OneLake security](https://learn.microsoft.com/en-us/fabric/onelake/onelake-security)*

---

### 25. Maintain a data analytics solution – Development lifecycle

**To use Git-based version control for a Fabric workspace, what do you need to configure?**

- A) Only a Power BI Desktop project (.pbip); no workspace setting  
- B) A Git repository connection and branch for the workspace so that workspace content can be committed and synced  
- C) Only deployment pipelines  
- D) Only the XMLA endpoint

**Answer: B) A Git repository connection and branch for the workspace so that workspace content can be committed and synced**

To use **version control** for a Fabric workspace, you **connect the workspace to a Git repository** and configure the branch. Content can then be committed and synced. .pbip is for Power BI projects; deployment pipelines and XMLA are separate.  
*Ref: [Microsoft Learn – Version control for workspaces](https://learn.microsoft.com/en-us/fabric/cicd/git-integration/)*

---

### 26. Maintain a data analytics solution – Development lifecycle

**Before changing or deleting a lakehouse table that is referenced by a dataflow and a semantic model, what should you do?**

- A) Only backup the lakehouse  
- B) Perform impact analysis to identify downstream dependencies (e.g., dataflows, semantic models, reports) that use the table  
- C) Only update the semantic model  
- D) Disable the dataflow

**Answer: B) Perform impact analysis to identify downstream dependencies (e.g., dataflows, semantic models, reports) that use the table**

**Impact analysis** identifies **downstream dependencies** (dataflows, semantic models, reports, etc.) that reference an asset before you change or delete it. This avoids breaking dependent content.  
*Ref: [Microsoft Learn – Impact analysis](https://learn.microsoft.com/en-us/fabric/cicd/deployment-pipelines/impact-analysis)*

---

### 27. Maintain a data analytics solution – Development lifecycle

**How can you deploy and manage a Fabric semantic model programmatically (e.g., from a script or CI/CD)?**

- A) Only by manually publishing from Power BI Desktop  
- B) By using the XMLA endpoint, which allows read/write operations so that tools (e.g., Tabular Editor, DAX Studio, scripts) can deploy and modify the model  
- C) Only via deployment pipelines; no programmatic access  
- D) Only by using the Fabric REST API for reports

**Answer: B) By using the XMLA endpoint, which allows read/write operations so that tools (e.g., Tabular Editor, DAX Studio, scripts) can deploy and modify the model**

The **XMLA endpoint** exposes Fabric semantic models for **read/write** access, enabling tools like **Tabular Editor**, **DAX Studio**, and scripts to deploy, update, and manage the model programmatically.  
*Ref: [Microsoft Learn – XMLA endpoint](https://learn.microsoft.com/en-us/fabric/analytics/direct-lake-overview#xmla)*

---

### 28. Maintain a data analytics solution – Development lifecycle

**A Power BI data source (.pbids) file is used to:**

- A) Package a full semantic model for backup  
- B) Provide a predefined connection to a data source so that users can quickly connect and start building with a consistent connection  
- C) Define row-level security rules  
- D) Store DAX measures

**Answer: B) Provide a predefined connection to a data source so that users can quickly connect and start building with a consistent connection**

A **.pbids** (Power BI data source) file defines a **predefined connection** to a data source so users can open it and connect quickly with consistent settings. It is a reusable asset for data connections.  
*Ref: [Microsoft Learn – PBIDS](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-data-sources#pbids-file)*

---

### 29. Prepare data – Get data

**When you create a data connection in Fabric to an on-premises SQL Server, what is typically required for scheduled refresh or pipeline access?**

- A) No gateway; Fabric always connects directly  
- B) An on-premises data gateway (or VNet gateway) so that Fabric can reach the private data source  
- C) Only a Power BI Desktop file  
- D) Only sensitivity labels

**Answer: B) An on-premises data gateway (or VNet gateway) so that Fabric can reach the private data source**

For **on-premises** or private network data sources, Fabric typically needs an **on-premises data gateway** (or **VNet gateway**) so the cloud service can reach the source for refresh and pipelines.  
*Ref: [Microsoft Learn – Gateways](https://learn.microsoft.com/en-us/data-integration/gateway/)*

---

### 30. Prepare data – Get data

**Where in Fabric can you discover and access real-time or streaming data sources and event streams?**

- A) Only in the OneLake data hub  
- B) In the Real-Time hub, which provides a central place for real-time and streaming data discovery and management  
- C) Only in deployment pipelines  
- D) Only in Power BI Desktop

**Answer: B) In the Real-Time hub, which provides a central place for real-time and streaming data discovery and management**

The **Real-Time hub** in Fabric is the central place to **discover and manage** real-time and streaming data sources and event streams. The OneLake data hub is for general asset discovery.  
*Ref: [Microsoft Learn – Real-Time hub](https://learn.microsoft.com/en-us/fabric/real-time-analytics/real-time-hub)*

---

### 31. Prepare data – Get data

**How can a Fabric semantic model use Direct Lake with data in an eventhouse?**

- A) Eventhouse data is only queried with KQL; semantic models cannot use it with Direct Lake  
- B) By using OneLake integration: eventhouse data can be exposed in OneLake, and semantic models can use Direct Lake on that data where supported  
- C) Only by importing the eventhouse data into the semantic model  
- D) Only by using DirectQuery to the eventhouse

**Answer: B) By using OneLake integration: eventhouse data can be exposed in OneLake, and semantic models can use Direct Lake on that data where supported**

**OneLake integration** allows eventhouse (and other) data to be exposed in **OneLake**. Semantic models can then use **Direct Lake** on that data where supported, in addition to KQL for direct querying.  
*Ref: [Microsoft Learn – OneLake integration](https://learn.microsoft.com/en-us/fabric/onelake/onelake-overview)*

---

### 32. Prepare data – Transform data

**Enriching data in a lakehouse or warehouse typically means:**

- A) Deleting columns to reduce size  
- B) Adding new columns or tables (e.g., calculated columns, lookups, reference tables) to add context or derived values  
- C) Only filtering rows  
- D) Only changing the table name

**Answer: B) Adding new columns or tables (e.g., calculated columns, lookups, reference tables) to add context or derived values**

**Enriching data** means **adding** new columns or tables (e.g., calculated columns, lookups, reference data) to add context or derived values. It does not mean only deleting, filtering, or renaming.  
*Ref: [Microsoft Learn – Prepare data](https://learn.microsoft.com/en-us/fabric/data-warehouse/transform-data)*

---

### 33. Prepare data – Transform data

**Denormalizing data in a warehouse or dataflow usually means:**

- A) Splitting one table into many normalized tables  
- B) Combining related data from multiple tables into fewer, flatter tables (e.g., bringing dimension attributes into a fact table) to simplify reporting  
- C) Removing all duplicates  
- D) Converting all columns to the same data type

**Answer: B) Combining related data from multiple tables into fewer, flatter tables to simplify reporting**

**Denormalizing** combines related data from multiple tables into **fewer, flatter** tables (e.g., bringing dimension attributes into a fact table) to simplify reporting and reduce joins. Normalizing does the opposite.  
*Ref: [Microsoft Learn – Star schema, denormalization](https://learn.microsoft.com/en-us/fabric/data-warehouse/star-schema)*

---

### 34. Prepare data – Transform data

**When transforming data for analytics, aggregating data means:**

- A) Only sorting rows  
- B) Summarizing data (e.g., SUM, COUNT, AVG) at a chosen grain, often by group  
- C) Only merging two tables without grouping  
- D) Only filtering null values

**Answer: B) Summarizing data (e.g., SUM, COUNT, AVG) at a chosen grain, often by group**

**Aggregating** data means **summarizing** it (SUM, COUNT, AVG, etc.) at a chosen grain, often **by group**. It is a core transformation for analytics.  
*Ref: [Microsoft Learn – Transform data](https://learn.microsoft.com/en-us/fabric/data-warehouse/transform-data)*

---

### 35. Prepare data – Transform data

**Merging or joining data in Power Query or a warehouse is used to:**

- A) Only delete duplicate rows  
- B) Combine two tables based on key columns (e.g., left join, inner join) to create a single result or table  
- C) Only change column data types  
- D) Only apply sensitivity labels

**Answer: B) Combine two tables based on key columns (e.g., left join, inner join) to create a single result or table**

**Merging or joining** combines two tables based on **key columns** (e.g., left join, inner join) to produce a single result or table. It is standard in Power Query and warehouse T-SQL.  
*Ref: [Microsoft Learn – Merge and join](https://learn.microsoft.com/en-us/power-query/merge-queries-overview)*

---

### 36. Prepare data – Transform data

**To improve data quality before loading into a warehouse or semantic model, you should:**

- A) Ignore duplicates and nulls  
- B) Identify and resolve duplicate data, missing data, and null values (e.g., remove duplicates, fill or remove nulls, validate keys)  
- C) Only aggregate the data  
- D) Only denormalize the data

**Answer: B) Identify and resolve duplicate data, missing data, and null values**

**Data quality** practices include **identifying and resolving** duplicate data, missing data, and null values (e.g., remove duplicates, fill or remove nulls, validate keys) before loading.  
*Ref: [Microsoft Learn – Data quality](https://learn.microsoft.com/en-us/power-query/power-query-ui)*

---

### 37. Prepare data – Transform data

**Converting column data types during transformation (e.g., text to number, or to date) is important because:**

- A) It has no effect on downstream queries  
- B) It ensures correct sorting, filtering, and calculations in the warehouse or semantic model  
- C) It removes the need for relationships  
- D) It is only required for Direct Lake

**Answer: B) It ensures correct sorting, filtering, and calculations in the warehouse or semantic model**

**Converting column data types** (e.g., text to number, to date) ensures **correct** sorting, filtering, and calculations downstream. Incorrect types can cause wrong results or errors.  
*Ref: [Microsoft Learn – Data types in Power Query](https://learn.microsoft.com/en-us/power-query/data-types)*

---

### 38. Prepare data – Transform data

**Filtering data in a dataflow or warehouse transformation:**

- A) Only affects the semantic model, not the stored data  
- B) Removes rows that do not meet the filter criteria, reducing volume and focusing on relevant data  
- C) Only applies to real-time data  
- D) Replaces the need for row-level security

**Answer: B) Removes rows that do not meet the filter criteria, reducing volume and focusing on relevant data**

**Filtering** in a dataflow or warehouse transformation **removes rows** that do not meet the criteria, reducing volume and focusing on relevant data. It affects the stored data, not only the semantic model.  
*Ref: [Microsoft Learn – Filter data](https://learn.microsoft.com/en-us/power-query/filter-rows)*

---

### 39. Prepare data – Query and analyze data

**The Visual Query Editor in Microsoft Fabric is used to:**

- A) Write T-SQL only  
- B) Select, filter, and aggregate data using a visual interface (e.g., for a warehouse or lakehouse) without writing full SQL or KQL  
- C) Deploy semantic models only  
- D) Configure sensitivity labels only

**Answer: B) Select, filter, and aggregate data using a visual interface without writing full SQL or KQL**

The **Visual Query Editor** in Fabric lets you **select, filter, and aggregate** data with a **visual interface** for warehouse or lakehouse without writing full SQL or KQL.  
*Ref: [Microsoft Learn – Visual Query Editor](https://learn.microsoft.com/en-us/fabric/data-warehouse/visual-query-editor)*

---

### 40. Prepare data – Query and analyze data

**To select, filter, and aggregate data in a Power BI semantic model for use in a report or another measure, you would use:**

- A) Only Power Query M  
- B) DAX (e.g., CALCULATE, FILTER, SUMX) to write measures or calculated tables that select, filter, and aggregate model data  
- C) Only T-SQL  
- D) Only KQL

**Answer: B) DAX (e.g., CALCULATE, FILTER, SUMX) to write measures or calculated tables**

In a **semantic model**, **DAX** (e.g., CALCULATE, FILTER, SUMX) is used to **select, filter, and aggregate** data in measures or calculated tables. Power Query M is for data loading; T-SQL and KQL are for warehouse and eventhouse.  
*Ref: [Microsoft Learn – DAX](https://learn.microsoft.com/en-us/dax/dax-overview)*

---

### 41. Implement and manage semantic models – Design and build

**Implementing a star schema in a semantic model (Power BI) means:**

- A) Using only one large table  
- B) Structuring the model with fact tables (metrics) and dimension tables (attributes) and defining relationships between them for efficient filtering and aggregation  
- C) Using only DirectQuery  
- D) Avoiding any relationships

**Answer: B) Structuring the model with fact tables (metrics) and dimension tables (attributes) and defining relationships**

Implementing a **star schema** in a Power BI semantic model means **fact tables** (metrics), **dimension tables** (attributes), and **relationships** between them for efficient filtering and aggregation.  
*Ref: [Microsoft Learn – Star schema in Power BI](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema)*

---

### 42. Implement and manage semantic models – Design and build

**When you have a many-to-many relationship between two dimension tables (e.g., Products and Customers) in a semantic model, a common approach is to:**

- A) Use only one dimension table  
- B) Use a bridge table (junction table) that links the two dimensions and connect the model so that filtering works correctly across both  
- C) Avoid relationships entirely  
- D) Use only calculated columns

**Answer: B) Use a bridge table (junction table) that links the two dimensions**

For **many-to-many** relationships between dimensions, a **bridge table** (junction table) links the two dimensions so that filtering and relationships work correctly across both.  
*Ref: [Microsoft Learn – Many-to-many, bridge tables](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-many-to-many-relationships)*

---

### 43. Implement and manage semantic models – Design and build

**Using DAX variables (VAR) in a measure is recommended because:**

- A) Variables are not supported in DAX  
- B) Variables improve readability and performance by storing intermediate results and avoiding repeated evaluation of the same expression  
- C) Variables replace the need for relationships  
- D) Variables are only for calculated tables

**Answer: B) Variables improve readability and performance by storing intermediate results and avoiding repeated evaluation**

**DAX variables (VAR)** store intermediate results so expressions are not re-evaluated multiple times, improving **readability** and **performance**.  
*Ref: [Microsoft Learn – DAX variables](https://learn.microsoft.com/en-us/dax/var-dax)*

---

### 44. Implement and manage semantic models – Design and build

**DAX information functions (e.g., ISBLANK, ISERROR, USERNAME) are used to:**

- A) Define new tables only  
- B) Return information about the context or the data (e.g., whether a value is blank, or the current user) to use in conditional logic or security  
- C) Create relationships only  
- D) Replace calculation groups

**Answer: B) Return information about the context or the data to use in conditional logic or security**

**DAX information functions** (e.g., ISBLANK, ISERROR, USERNAME) return **information** about the context or data and are used in conditional logic or security (e.g., RLS).  
*Ref: [Microsoft Learn – DAX information functions](https://learn.microsoft.com/en-us/dax/information-functions-dax)*

---

### 45. Implement and manage semantic models – Design and build

**Dynamic format strings in DAX (e.g., in calculation items) allow you to:**

- A) Only use a fixed format for all measures  
- B) Apply different display formats (e.g., currency, percentage) based on the selected calculation item or context  
- C) Define relationships  
- D) Replace the need for measures

**Answer: B) Apply different display formats based on the selected calculation item or context**

**Dynamic format strings** (e.g., in calculation groups) let you apply **different display formats** (currency, percentage, etc.) based on the selected calculation item or context.  
*Ref: [Microsoft Learn – Dynamic format strings](https://learn.microsoft.com/en-us/analysis-services/tabular-models/calculation-groups)*

---

### 46. Implement and manage semantic models – Design and build

**Field parameters in Power BI allow you to:**

- A) Set row-level security only  
- B) Let report users dynamically choose which fields (e.g., measures or columns) to use in a visual from a predefined list, without creating multiple copies of the report  
- C) Only connect to data sources  
- D) Only configure incremental refresh

**Answer: B) Let report users dynamically choose which fields to use in a visual from a predefined list**

**Field parameters** let report users **dynamically choose** which fields (e.g., measures or columns) to use in a visual from a predefined list, without duplicating reports.  
*Ref: [Microsoft Learn – Field parameters](https://learn.microsoft.com/en-us/power-bi/transform-model/field-parameters)*

---

### 47. Implement and manage semantic models – Design and build

**The large semantic model storage format in Fabric is used when:**

- A) The model has fewer than 1 million rows  
- B) The model is very large (e.g., hundreds of millions of rows or large cardinality) and you need the scalability and performance benefits of the large format  
- C) You use only DirectQuery  
- D) You do not use Direct Lake

**Answer: B) The model is very large and you need the scalability and performance benefits of the large format**

The **large semantic model storage format** is for **very large** models (e.g., hundreds of millions of rows or high cardinality) and provides **scalability and performance** benefits in Fabric.  
*Ref: [Microsoft Learn – Large semantic model format](https://learn.microsoft.com/en-us/fabric/analytics/large-semantic-model)*

---

### 48. Implement and manage semantic models – Optimize

**To improve performance of report visuals and queries, you should:**

- A) Always use the most complex DAX possible  
- B) Reduce visual complexity, use filters and aggregations appropriately, avoid unnecessary cross-filtering, and consider aggregations or incremental refresh where applicable  
- C) Disable Direct Lake  
- D) Only increase the number of measures

**Answer: B) Reduce visual complexity, use filters and aggregations appropriately, avoid unnecessary cross-filtering, and consider aggregations or incremental refresh**

**Performance** improvements include reducing **visual complexity**, using **filters and aggregations** appropriately, avoiding unnecessary cross-filtering, and using **aggregations** or **incremental refresh** where applicable.  
*Ref: [Microsoft Learn – Optimize reports](https://learn.microsoft.com/en-us/power-bi/guidance/power-bi-optimization)*

---

### 49. Implement and manage semantic models – Optimize

**Improving DAX performance in a semantic model can involve:**

- A) Avoiding variables and re-evaluating the same expression many times  
- B) Using variables, avoiding unnecessary iterators over large tables, reducing filter context complexity, and using efficient functions (e.g., avoid row-by-row logic where aggregations suffice)  
- C) Using only DirectQuery for all tables  
- D) Removing all measures

**Answer: B) Using variables, avoiding unnecessary iterators over large tables, reducing filter context complexity, and using efficient functions**

**DAX performance** is improved by using **variables**, avoiding unnecessary **iterators** over large tables, reducing **filter context** complexity, and using efficient functions (e.g., aggregations instead of row-by-row where possible).  
*Ref: [Microsoft Learn – DAX performance](https://learn.microsoft.com/en-us/dax/dax-best-practices)*

---

### 50. Implement and manage semantic models – Optimize

**When should you choose Direct Lake on a Fabric SQL endpoint (e.g., warehouse) instead of Direct Lake on OneLake?**

- A) Direct Lake is only available on OneLake  
- B) When your data lives in a Fabric warehouse and you want Direct Lake to read from the warehouse's SQL endpoint (e.g., for T-SQL-managed tables and views) rather than from raw OneLake files  
- C) Only when you do not use a lakehouse  
- D) Only for semantic models smaller than 1 GB

**Answer: B) When your data lives in a Fabric warehouse and you want Direct Lake to read from the warehouse's SQL endpoint**

**Direct Lake on a SQL endpoint** (e.g., Fabric warehouse) is used when data is in a **warehouse** and you want Direct Lake to read from the **warehouse’s SQL endpoint** (T-SQL tables/views). **Direct Lake on OneLake** reads from OneLake files (e.g., lakehouse).  
*Ref: [Microsoft Learn – Direct Lake modes](https://learn.microsoft.com/en-us/fabric/analytics/direct-lake-overview)*

---

### 51. Maintain a data analytics solution – Development lifecycle

**A Power BI template (.pbit) file is used to:**

- A) Store only the connection string to a data source  
- B) Distribute a semantic model with report layout and structure so that recipients can connect to their own data source and reuse the design  
- C) Define row-level security rules only  
- D) Deploy to production via the XMLA endpoint

**Answer: B) Distribute a semantic model with report layout and structure so that recipients can connect to their own data source and reuse the design**

A **.pbit** (Power BI template) file packages a **semantic model and report layout** without the data. Recipients open it, connect to **their own data source**, and reuse the design. It is a reusable asset alongside .pbids and shared semantic models.  
*Ref: [Microsoft Learn – Power BI templates](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-templates)*

---

### 52. Maintain – Security and governance

**Which Fabric workspace role can create and delete items but cannot share the workspace or change access to items?**

- A) Viewer  
- B) Admin  
- C) Contributor  
- D) Member

**Answer: C) Contributor**

Contributor can create and delete items but cannot share the workspace or manage access; that is an Admin capability.

---

### 53. Maintain – Security and governance

**A user with "Build" permission on a semantic model can:**

- A) Only view reports that use the model  
- B) Create new reports and content that use the semantic model; they may not have permission to edit the model itself  
- C) Delete the semantic model  
- D) Change workspace settings

**Answer: B)**

Build permission allows creating reports and content that use the model; Edit/Admin may be needed to change the model.

---

### 54. Maintain – Security and governance

**Row-level security (RLS) in Power BI is configured:**

- A) In the Fabric admin portal only  
- B) In the semantic model (e.g., in Power BI Desktop or Tabular Editor) by defining roles and DAX filter expressions  
- C) Only in the gateway  
- D) Only via sensitivity labels

**Answer: B)**

RLS is defined in the semantic model via roles and DAX filter expressions.

---

### 55. Maintain – Security and governance

**To hide a specific measure from certain users in a semantic model while keeping the table visible, you would use:**

- A) Row-level security  
- B) Column-level security  
- C) Object-level security on the measure  
- D) Endorsement

**Answer: C)**

Object-level security can restrict access to specific tables, columns, or measures.

---

### 56. Maintain – Security and governance

**Sensitivity labels can be applied to:**

- A) Only workspaces  
- B) Workspaces and items such as reports, semantic models, and dataflows (when supported)  
- C) Only reports  
- D) Only semantic models

**Answer: B)**

Sensitivity labels apply to workspaces and supported items (reports, semantic models, dataflows, etc.).

---

### 57. Maintain – Security and governance

**What is the difference between "Promoted" and "Certified" endorsement in Fabric?**

- A) They are identical  
- B) Certified typically requires a formal review process and indicates higher trust; Promoted is a lighter endorsement  
- C) Only Certified can be used for semantic models  
- D) Promoted is set by Microsoft only

**Answer: B)**

Certified usually requires formal review and indicates higher trust; Promoted is a lighter endorsement.

---

### 58. Maintain – Development lifecycle

**When a Fabric workspace is connected to Git, what can be versioned?**

- A) Only .pbip files  
- B) Workspace item definitions (e.g., semantic models, reports, dataflows) that are saved in source-control-friendly formats  
- C) Only deployment pipeline configs  
- D) Only Power BI Desktop files

**Answer: B)**

Git-connected workspaces version item definitions in source-control-friendly formats.

---

### 59. Maintain – Development lifecycle

**In a deployment pipeline, moving content from the development stage to the test stage is called:**

- A) Cloning  
- B) Deploying or promoting  
- C) Refreshing  
- D) Endorsing

**Answer: B)**

Moving content between stages is deploying or promoting.

---

### 60. Maintain – Development lifecycle

**Shared semantic models in Fabric allow:**

- A) Only one user to use the model  
- B) Multiple reports and users to connect to a single published semantic model, enabling reuse and consistency  
- C) Only DirectQuery models  
- D) Only models smaller than 1 GB

**Answer: B)**

Shared semantic models let multiple reports and users connect to one published model.

---

### 61. Prepare – Get data

**Which of the following can be used as a data source for a Fabric dataflow or pipeline?**

- A) Only other Fabric lakehouses  
- B) Many sources including Azure SQL, SharePoint, REST APIs, and other Fabric items  
- C) Only Excel files  
- D) Only OneLake

**Answer: B)**

Dataflows and pipelines can connect to many sources (Azure SQL, SharePoint, REST, Fabric items, etc.).

---

### 62. Prepare – Get data

**The OneLake data hub allows you to:**

- A) Only create new lakehouses  
- B) Discover, browse, and access endorsed and shared analytics assets across workspaces  
- C) Only run KQL queries  
- D) Only deploy reports

**Answer: B)**

OneLake data hub is for discovering and browsing endorsed/shared assets.

---

### 63. Prepare – Get data

**When would you choose a Fabric warehouse over a lakehouse?**

- A) When you need only unstructured files with no schema  
- B) When you need a relational SQL (T-SQL) experience with tables, views, and stored procedures in a single engine  
- C) When you need only KQL for streaming  
- D) When you need only Power Query for all transformations

**Answer: B)**

Warehouse provides a relational T-SQL experience (tables, views, stored procedures).

---

### 64. Prepare – Get data

**A lakehouse in Fabric is best suited for:**

- A) Only real-time event streaming with KQL  
- B) Combining structured and semi-structured data with Delta/Parquet in OneLake and support for both SQL and Spark  
- C) Only T-SQL stored procedures  
- D) Only Power BI reports

**Answer: B)**

Lakehouse combines structured/semi-structured data with Delta/Parquet and SQL/Spark.

---

### 65. Prepare – Transform data

**In a Fabric warehouse, a stored procedure is typically used to:**

- A) Only define a view  
- B) Run a sequence of T-SQL statements (e.g., for ETL, SCD2, or batch logic) that can be called by pipelines or other processes  
- C) Only create a shortcut  
- D) Only set RLS

**Answer: B)**

Stored procedures run T-SQL batches for ETL, SCD2, or other logic.

---

### 66. Prepare – Transform data

**Adding a calculated column in Power Query that combines FirstName and LastName is an example of:**

- A) Filtering data  
- B) Enriching data  
- C) Only aggregating data  
- D) Only merging tables

**Answer: B)**

Adding columns (e.g., combined name) is enriching data.

---

### 67. Prepare – Transform data

**In a star schema, dimension tables typically contain:**

- A) Only numeric measures and foreign keys  
- B) Descriptive attributes and keys used for filtering and grouping (e.g., ProductName, Category)  
- C) Only fact data  
- D) Only raw event streams

**Answer: B)**

Dimension tables hold descriptive attributes and keys.

---

### 68. Prepare – Transform data

**To resolve duplicate rows in Power Query, you can use:**

- A) Only the Merge operation  
- B) "Remove duplicates" based on selected columns, or group by and aggregate  
- C) Only Change Type  
- D) Only Append

**Answer: B)**

Remove duplicates or group-by to resolve duplicates.

---

### 69. Prepare – Query and analyze data

**Which Fabric item allows you to run ad-hoc SQL queries against relational tables?**

- A) Only the eventhouse  
- B) A warehouse or lakehouse (via SQL endpoint)  
- C) Only Dataflows Gen2  
- D) Only the Real-Time hub

**Answer: B)**

Warehouse and lakehouse (via SQL endpoint) support ad-hoc SQL.

---

### 70. Prepare – Query and analyze data

**KQL (Kusto Query Language) is best used for:**

- A) Only defining DAX measures  
- B) Querying and analyzing event, log, and time-series data in eventhouses and KQL databases  
- C) Only T-SQL views  
- D) Only Power Query steps

**Answer: B)**

KQL is for event/log/time-series data in eventhouses and KQL databases.

---

### 71. Implement – Semantic models – Design and build

**In a semantic model, Import mode means:**

- A) Data is always queried live from the source  
- B) Data is copied into the model and cached; refresh is needed to update it  
- C) Only Direct Lake is used  
- D) No data is stored

**Answer: B)**

Import mode copies data into the model; refresh updates it.

---

### 72. Implement – Semantic models – Design and build

**A many-to-many relationship in Power BI can be modeled using:**

- A) Only a single direct relationship between two fact tables  
- B) A bridge (junction) table or the built-in many-to-many feature with a single relationship  
- C) Only calculated columns  
- D) Only calculation groups

**Answer: B)**

Many-to-many can use a bridge table or built-in M2M.

---

### 73. Implement – Semantic models – Design and build

**DAX table filtering functions include:**

- A) Only SUM and AVERAGE  
- B) FILTER, ALL, ALLEXCEPT, and related functions that return or modify tables for use in calculations  
- C) Only USERNAME  
- D) Only FORMAT

**Answer: B)**

FILTER, ALL, ALLEXCEPT, etc. are table filtering functions.

---

### 74. Implement – Semantic models – Optimize

**Configuring "default fallback" for Direct Lake affects:**

- A) Only Import mode  
- B) Whether and when the engine falls back to DirectQuery when a Direct Lake query cannot be satisfied  
- C) Only incremental refresh  
- D) Only RLS

**Answer: B)**

Default fallback controls when the engine falls back to DirectQuery.

---

### 75. Implement – Semantic models – Optimize

**Incremental refresh requires:**

- A) Only a single partition  
- B) A date/time column (or similar) to partition data and parameters (e.g., RangeStart, RangeEnd) to define which partitions to refresh  
- C) Only DirectQuery  
- D) Only calculation groups

**Answer: B)**

Incremental refresh uses a date/time column and RangeStart/RangeEnd (or similar) parameters.

---

### 76. Maintain – Security and governance

**The "Viewer" role on a Fabric workspace allows a user to:**

- A) Create and delete items  
- B) View and use content in the workspace but not create or edit items  
- C) Share the workspace with others  
- D) Change item permissions

**Answer: B)**

Viewer can view and use content but not create or edit.

---

### 77. Maintain – Security and governance

**Applying a sensitivity label to a Fabric item may:**

- A) Only change the item name  
- B) Classify the item and optionally enforce protection (e.g., encryption, access restrictions) based on organizational policy  
- C) Only enable Direct Lake  
- D) Only set RLS

**Answer: B)**

Sensitivity labels classify and can enforce protection (encryption, access).

---

### 78. Maintain – Development lifecycle

**Impact analysis in a deployment pipeline helps you:**

- A) Only schedule refreshes  
- B) See which items (e.g., reports, dataflows) depend on the content you are deploying, so you can assess impact before deployment  
- C) Only set endorsement  
- D) Only configure gateways

**Answer: B)**

Impact analysis shows dependent items before deployment.

---

### 79. Prepare – Get data

**Shortcuts in OneLake can reference:**

- A) Only other Fabric workspaces  
- B) External storage such as Azure Data Lake Storage Gen2, Amazon S3, or another OneLake location  
- C) Only eventhouses  
- D) Only semantic models

**Answer: B)**

Shortcuts can reference ADLS Gen2, S3, or other OneLake locations.

---

### 80. Prepare – Transform data

**In Power Query, the "Group By" operation is used to:**

- A) Only merge two tables  
- B) Aggregate rows by one or more key columns (e.g., SUM, COUNT, AVG per group)  
- C) Only remove duplicates  
- D) Only change data types

**Answer: B)**

Group By aggregates by key columns (SUM, COUNT, AVG, etc.).

---

### 81. Prepare – Transform data

**Fact tables in a star schema typically contain:**

- A) Only descriptive attributes  
- B) Foreign keys to dimensions and numeric measures (e.g., sales amount, quantity)  
- C) Only primary keys with no measures  
- D) Only text columns

**Answer: B)**

Fact tables have foreign keys and numeric measures.

---

### 82. Prepare – Query and analyze data

**In the Fabric warehouse Visual Query Editor, you can:**

- A) Only write KQL  
- B) Build queries by selecting tables, adding filters, and choosing columns and aggregations in a visual interface  
- C) Only deploy semantic models  
- D) Only set RLS

**Answer: B)**

Visual Query Editor lets you build queries with a visual interface.

---

### 83. Implement – Semantic models – Design and build

**DAX windowing functions (e.g., OFFSET, INDEX, WINDOW) are used for:**

- A) Only defining relationships  
- B) Calculations that consider relative rows (e.g., running totals, previous/next row) in a sorted context  
- C) Only creating tables  
- D) Only formatting

**Answer: B)**

Windowing functions (OFFSET, INDEX, WINDOW) work over relative rows.

---

### 84. Implement – Semantic models – Optimize

**To reduce semantic model size and refresh time for very large tables, you should consider:**

- A) Importing all historical data every time with no partitioning  
- B) Incremental refresh so that only recent or changed data is refreshed  
- C) Only using DirectQuery for all tables  
- D) Only removing relationships

**Answer: B)**

Incremental refresh reduces size and refresh time.

---

### 85. Maintain – Security and governance

**Who can endorse an item (e.g., set it as Promoted or Certified) in Fabric?**

- A) Any user who can view the item  
- B) Users with appropriate permissions (e.g., item Admin or workspace role that allows endorsement), as configured by the organization  
- C) Only Microsoft  
- D) Only the capacity administrator

**Answer: B)**

Endorsement is done by users with appropriate permissions.

---

### 86. Prepare – Get data

**Dataflows Gen2 in Fabric can write data to:**

- A) Only Excel  
- B) Destinations such as a lakehouse, warehouse, or semantic model (and other supported targets)  
- C) Only OneLake shortcuts  
- D) Only eventhouses

**Answer: B)**

Dataflows Gen2 can write to lakehouse, warehouse, semantic model, etc.

---

### 87. Prepare – Transform data

**Merging two tables with a "Left Outer" join keeps:**

- A) Only matching rows from both tables  
- B) All rows from the left table and matching rows from the right table; non-matching right rows are dropped  
- C) Only the right table  
- D) Only duplicate rows

**Answer: B)**

Left outer join keeps all left rows and matching right rows.

---

### 88. Implement – Semantic models – Design and build

**Composite models allow:**

- A) Only one storage mode per table  
- B) Mixing Import, DirectQuery, and/or Direct Lake in the same model so different tables can use different modes  
- C) Only Direct Lake  
- D) Only one relationship per table

**Answer: B)**

Composite models mix Import, DirectQuery, and/or Direct Lake.

---

### 89. Implement – Semantic models – Optimize

**Direct Lake refresh behavior refers to:**

- A) Only Import schedule  
- B) How and when the semantic model syncs or refreshes metadata and data from the Direct Lake source (e.g., OneLake or SQL endpoint)  
- C) Only RLS  
- D) Only calculation groups

**Answer: B)**

Direct Lake refresh behavior is how/when the model syncs from the source.

---

### 90. Prepare – Get data

**The Real-Time hub in Fabric can show:**

- A) Only historical batch data  
- B) Event streams, KQL databases, and real-time data sources that you can use for streaming scenarios  
- C) Only Power BI reports  
- D) Only deployment pipelines

**Answer: B)**

Real-Time hub shows event streams, KQL databases, real-time sources.

---

### 91. Prepare – Transform data

**Converting a text column to a whole number in Power Query ensures:**

- A) The column cannot be used in visuals  
- B) Correct numeric sorting, filtering, and aggregation in downstream steps and in the destination  
- C) Only that the column is hidden  
- D) Only that RLS applies

**Answer: B)**

Correct types ensure correct sorting, filtering, aggregation.

---

### 92. Implement – Semantic models – Design and build

**In DAX, the CALCULATE function is used to:**

- A) Only create new tables  
- B) Evaluate an expression under modified filter context (e.g., add or remove filters)  
- C) Only define relationships  
- D) Only format numbers

**Answer: B)**

CALCULATE evaluates an expression under modified filter context.

---

### 93. Implement – Semantic models – Optimize

**Report-level performance can be improved by:**

- A) Adding as many visuals as possible to one page  
- B) Reducing the number of visuals per page, using filters, and avoiding overly complex DAX in visuals  
- C) Only using DirectQuery for all tables  
- D) Only disabling Direct Lake

**Answer: B)**

Fewer visuals, filters, and simpler DAX improve performance.

---

### 94. Maintain – Development lifecycle

**The XMLA endpoint for a Fabric semantic model enables:**

- A) Only viewing the model in the Fabric portal  
- B) Programmatic read/write access so that external tools (e.g., Tabular Editor, DAX Studio) and scripts can connect and modify the model  
- C) Only Power BI Desktop to open the model  
- D) Only deployment pipelines

**Answer: B)**

XMLA enables programmatic read/write for Tabular Editor, DAX Studio, scripts.

---

### 95. Prepare – Query and analyze data

**Writing a DAX measure that uses SUMX(Table, Expression) is an example of:**

- A) Only defining a relationship  
- B) Selecting, filtering, and aggregating data using DAX (iterator) in the semantic model  
- C) Only Power Query  
- D) Only KQL

**Answer: B)**

SUMX is an example of selecting/filtering/aggregating with DAX.

---

### 96. Implement – Semantic models – Design and build

**Field parameters are created in:**

- A) Only the gateway  
- B) The semantic model (e.g., Power BI Desktop) as a special parameter table that lists fields; report authors can then use it in slicers or visuals  
- C) Only deployment pipelines  
- D) Only OneLake

**Answer: B)**

Field parameters are created in the semantic model as a parameter table.

---

### 97. Prepare – Get data

**Choosing between lakehouse, warehouse, and eventhouse depends mainly on:**

- A) Only the license type  
- B) Data type (batch vs streaming), query language (SQL vs KQL), and use case (e.g., relational analytics vs event analytics)  
- C) Only the workspace name  
- D) Only the number of users

**Answer: B)**

Choice depends on data type, query language, and use case.

---

### 98. Implement – Semantic models – Optimize

**Large semantic model format in Fabric supports:**

- A) Only models under 1 GB  
- B) Very large models with improved scalability (e.g., more rows, larger cardinality) and performance characteristics  
- C) Only DirectQuery  
- D) Only Import mode with no refresh

**Answer: B)**

Large format supports very large models with better scalability.

---

### 99. Prepare – Transform data

**Filtering rows in Power Query to keep only "Status = Active" is an example of:**

- A) Enriching data  
- B) Filtering data to reduce volume and focus on relevant rows  
- C) Only merging  
- D) Only changing types

**Answer: B)**

Keeping only "Status = Active" is filtering data.

---

### 100. Maintain – Security and governance

**Column-level security in a semantic model is implemented by:**

- A) Setting workspace roles only  
- B) Defining a role and configuring which columns are visible to that role (e.g., hide Salary from a role)  
- C) Only using sensitivity labels  
- D) Only endorsing the item

**Answer: B)**

Column-level security is implemented via roles and column visibility.

---

### 101. Maintain – Security and governance

**A Fabric workspace "Member" can:**

- A) Only view content; cannot create or edit  
- B) Create and edit content; typically cannot share the workspace or manage access (unlike Admin)  
- C) Only delete the workspace  
- D) Only configure the capacity

**Answer: B)**

Member can create and edit; Admin can share and manage access.

---

### 102. Prepare – Get data

**Creating a "data connection" in Fabric often involves:**

- A) Only selecting a workspace  
- B) Specifying the source type (e.g., SQL, REST), connection details, and authentication (e.g., OAuth, key) so that data can be ingested or queried  
- C) Only setting endorsement  
- D) Only creating a report

**Answer: B)**

Data connection = source type, connection details, authentication.

---

### 103. Prepare – Transform data

**In a Fabric warehouse, you can create a view that:**

- A) Only runs KQL  
- B) Stores a SELECT query as a named object so users and other queries can reference it  
- C) Only stores data physically  
- D) Only defines RLS

**Answer: B)**

A view stores a SELECT as a named object.

---

### 104. Implement – Semantic models – Design and build

**Calculation groups reduce redundancy when you have:**

- A) Only one measure  
- B) Multiple measures that share a common calculation pattern (e.g., same time intelligence applied to many measures)  
- C) Only relationships  
- D) Only Import mode

**Answer: B)**

Calculation groups share a common pattern across measures.

---

### 105. Implement – Semantic models – Optimize

**Choosing Direct Lake on OneLake (vs on a SQL endpoint) is appropriate when:**

- A) Your data is only in an on-premises server  
- B) Your data is in a lakehouse or other OneLake-backed item and you want the semantic model to read directly from OneLake files  
- C) You use only KQL databases  
- D) You do not use Fabric

**Answer: B)**

Direct Lake on OneLake when data is in lakehouse/OneLake-backed item.

---

### 106. Prepare – Query and analyze data

**Selecting and aggregating data using SQL in a Fabric warehouse means:**

- A) Only using DAX  
- B) Writing T-SQL queries (e.g., SELECT, WHERE, GROUP BY) to filter and aggregate data in the warehouse  
- C) Only using the Visual Query Editor  
- D) Only using KQL

**Answer: B)**

T-SQL (SELECT, WHERE, GROUP BY) filters and aggregates in the warehouse.

---

### 107. Maintain – Development lifecycle

**A .pbip project can contain:**

- A) Only connection strings  
- B) The semantic model definition (e.g., in TMDL format) in a folder structure that works with Git  
- C) Only reports  
- D) Only dataflows

**Answer: B)**

.pbip contains the model definition (e.g., TMDL) for Git.

---

### 108. Prepare – Get data

**OneLake integration for semantic models means:**

- A) Only using Import mode  
- B) Semantic models can connect to OneLake-backed data (e.g., lakehouse, warehouse) and use features like Direct Lake where supported  
- C) Only using DirectQuery to on-premises  
- D) Only using KQL

**Answer: B)**

OneLake integration lets semantic models connect to OneLake-backed data and use Direct Lake.

---

### 109. Prepare – Transform data

**Resolving "missing data" in a dataset might involve:**

- A) Ignoring nulls  
- B) Using Power Query to fill down, replace nulls with a default, or remove rows with critical missing values, depending on business rules  
- C) Only merging more tables  
- D) Only adding columns

**Answer: B)**

Fill down, replace nulls, or remove rows to handle missing data.

---

### 110. Implement – Semantic models – Design and build

**DAX variables (VAR) help performance because:**

- A) They are required for all measures  
- B) The expression assigned to the variable is evaluated once and reused, avoiding repeated evaluation  
- C) They replace the need for CALCULATE  
- D) They only work in calculated tables

**Answer: B)**

VAR is evaluated once and reused.

---

### 111. Maintain – Security and governance

**File-level access in a lakehouse may be managed through:**

- A) Only RLS in Power BI  
- B) OneLake security (e.g., ACLs) and Fabric item permissions so that only authorized users can read or write files/folders  
- C) Only sensitivity labels  
- D) Only endorsement

**Answer: B)**

File-level access via OneLake security and item permissions.

---

### 112. Prepare – Get data

**Ingesting data in Fabric can be done with:**

- A) Only manual upload  
- B) Data pipelines (e.g., Data Factory copy activity), dataflows, or eventstream/eventhouse for streaming  
- C) Only Power BI Desktop  
- D) Only the Visual Query Editor

**Answer: B)**

Ingest via pipelines, dataflows, eventstream/eventhouse.

---

### 113. Prepare – Transform data

**Denormalizing for a report might mean:**

- A) Splitting one table into many  
- B) Adding dimension attributes (e.g., ProductName, Category) into a fact table or wide table so the report needs fewer joins  
- C) Only removing columns  
- D) Only filtering

**Answer: B)**

Denormalizing = adding dimension attributes into a fact/wide table.

---

### 114. Implement – Semantic models – Design and build

**Dynamic format strings in calculation groups allow:**

- A) Only one format for all measures  
- B) The format of a measure to change based on the selected calculation item (e.g., show as currency for one item, percentage for another)  
- C) Only defining relationships  
- D) Only RLS

**Answer: B)**

Dynamic format strings change format by calculation item.

---

### 115. Implement – Semantic models – Optimize

**Improving DAX performance often includes:**

- A) Using as many iterators (e.g., SUMX) as possible on large tables  
- B) Preferring simple aggregations (e.g., SUM) over iterators when the logic allows, and using variables to avoid duplicate evaluation  
- C) Only using DirectQuery  
- D) Only removing all measures

**Answer: B)**

Prefer simple aggregations and variables; avoid unnecessary iterators.

---

### 116. Prepare – Query and analyze data

**Using the Visual Query Editor to add a filter and then sum a column is an example of:**

- A) Only writing T-SQL by hand  
- B) Selecting, filtering, and aggregating data with the visual interface  
- C) Only deploying a semantic model  
- D) Only configuring Direct Lake

**Answer: B)**

Visual Query Editor = select, filter, aggregate visually.

---

### 117. Maintain – Development lifecycle

**Deployment pipeline "rules" can:**

- A) Only clone items  
- B) Allow you to configure which items are deployed and how (e.g., parameterize connection strings per stage)  
- C) Only set endorsement  
- D) Only run KQL

**Answer: B)**

Pipeline rules configure what is deployed and how (e.g., parameters).

---

### 118. Prepare – Get data

**Discovering data via the OneLake catalog means:**

- A) Only creating new data  
- B) Browsing and finding existing datasets, lakehouses, and other assets shared or endorsed in your tenant  
- C) Only running pipelines  
- D) Only setting RLS

**Answer: B)**

OneLake catalog = browse and find shared/endorsed assets.

---

### 119. Prepare – Transform data

**A table-valued function in a Fabric warehouse:**

- A) Only runs once per day  
- B) Returns a result set (table) and can be used in FROM or JOIN like a view, often with parameters  
- C) Only defines a measure  
- D) Only creates a shortcut

**Answer: B)**

Table-valued function returns a table, often with parameters.

---

### 120. Implement – Semantic models – Design and build

**Implementing a star schema in a semantic model improves:**

- A) Only the number of tables  
- B) Query performance and clarity by having clear facts and dimensions with relationships and appropriate cardinality  
- C) Only DirectQuery  
- D) Only Import mode

**Answer: B)**

Star schema improves performance and clarity.

---

### 121. Implement – Semantic models – Optimize

**When Direct Lake cannot satisfy a query (e.g., unsupported DAX), the engine may:**

- A) Fail the query  
- B) Fall back to DirectQuery (when configured) so the query still runs against the source  
- C) Only use Import  
- D) Only use cached data

**Answer: B)**

Engine can fall back to DirectQuery when Direct Lake cannot satisfy the query.

---

### 122. Maintain – Security and governance

**Item-level "Write" permission generally allows:**

- A) Only viewing the item  
- B) Editing the item (e.g., edit a report or semantic model)  
- C) Only sharing the workspace  
- D) Only deleting the workspace

**Answer: B)**

Write permission allows editing the item.

---

### 123. Prepare – Transform data

**Merging two tables with an "Inner" join keeps:**

- A) All rows from both tables  
- B) Only rows that have matching keys in both tables  
- C) Only the left table  
- D) Only duplicate keys

**Answer: B)**

Inner join keeps only matching rows.

---

### 124. Implement – Semantic models – Design and build

**Information functions in DAX (e.g., ISBLANK, USERNAME) are useful for:**

- A) Only creating tables  
- B) Conditional logic and security (e.g., RLS) that depend on context or value checks  
- C) Only defining relationships  
- D) Only formatting

**Answer: B)**

Information functions support conditional logic and security.

---

### 125. Prepare – Get data

**An eventhouse is optimized for:**

- A) Only batch CSV loads  
- B) High-throughput ingestion and querying of event/streaming data with KQL  
- C) Only T-SQL  
- D) Only Power Query

**Answer: B)**

Eventhouse is for high-throughput event/streaming data with KQL.

---

### 126. Implement – Semantic models – Design and build

**Storage mode (Import, DirectQuery, Direct Lake) in Power BI determines:**

- A) Only the theme of reports  
- B) Where and how data is stored and queried (cached vs live, and which engine is used)  
- C) Only RLS  
- D) Only the number of visuals

**Answer: B)**

Storage mode determines where and how data is stored and queried.

---

### 127. Maintain – Development lifecycle

**Reusable assets in Fabric include:**

- A) Only workspaces  
- B) .pbit (templates), .pbids (data source files), and shared semantic models that can be reused across reports and users  
- C) Only pipelines  
- D) Only gateways

**Answer: B)**

Reusable assets = .pbit, .pbids, shared semantic models.

---

### 128. Prepare – Transform data

**Identifying duplicate rows before loading is important for:**

- A) Increasing data volume  
- B) Data quality and accurate analytics (e.g., avoid double-counting or incorrect aggregations)  
- C) Only making tables larger  
- D) Only Direct Lake

**Answer: B)**

Identifying duplicates supports data quality and accurate analytics.

---

### 129. Implement – Semantic models – Optimize

**Incremental refresh partitions are typically based on:**

- A) Only the table name  
- B) A date/time column (e.g., OrderDate) so that ranges (e.g., last 2 years) can be refreshed independently  
- C) Only text columns  
- D) Only measures

**Answer: B)**

Partitions are based on a date/time column and ranges.

---

### 130. Prepare – Query and analyze data

**KQL can be used to:**

- A) Only define DAX measures  
- B) Select, filter, and aggregate data in eventhouses and KQL databases (e.g., project, where, summarize)  
- C) Only create semantic models  
- D) Only configure deployment pipelines

**Answer: B)**

KQL selects, filters, aggregates in eventhouses and KQL databases.

---

### 131. Maintain – Security and governance

**Workspace "Admin" role can:**

- A) Only view content  
- B) Manage the workspace (e.g., add/remove users, assign roles, delete workspace, manage items)  
- C) Only create reports  
- D) Only refresh semantic models

**Answer: B)**

Admin manages workspace (users, roles, delete, items).

---

### 132. Prepare – Get data

**Shortcuts in OneLake provide:**

- A) Only a copy of the data in another location  
- B) A pointer to data in another location so it appears in OneLake without copying; queries can run over the shortcut  
- C) Only a backup  
- D) Only a connection to Power BI Desktop

**Answer: B)**

Shortcuts are pointers; data appears without copying.

---

### 133. Prepare – Transform data

**Aggregating data at a coarser grain (e.g., by month instead of day) can:**

- A) Only increase row count  
- B) Reduce row count and improve query performance when detailed grain is not needed  
- C) Only remove columns  
- D) Only change data types

**Answer: B)**

Coarser grain reduces rows and can improve performance.

---

### 134. Implement – Semantic models – Design and build

**A bridge table for a many-to-many relationship typically contains:**

- A) Only measures  
- B) Keys from both dimensions (or entities) that it links, so the model can filter correctly across both  
- C) Only one key  
- D) Only calculated columns

**Answer: B)**

Bridge table contains keys from both dimensions.

---

### 135. Implement – Semantic models – Optimize

**Report visual performance can be improved by:**

- A) Using as many visuals as possible on one page  
- B) Limiting visuals per page, using filters and bookmarks, and optimizing DAX and data granularity  
- C) Only using DirectQuery for every table  
- D) Only disabling filters

**Answer: B)**

Limit visuals, use filters/bookmarks, optimize DAX and granularity.

---

### 136. Prepare – Get data

**The Real-Time hub is used to:**

- A) Only view historical data  
- B) Discover and manage real-time and streaming assets (e.g., event streams, KQL databases) in one place  
- C) Only create warehouses  
- D) Only set endorsement

**Answer: B)**

Real-Time hub = discover and manage real-time/streaming assets.

---

### 137. Prepare – Transform data

**Converting a column to Date type in Power Query:**

- A) Has no effect on downstream use  
- B) Enables correct date filtering, sorting, and time intelligence in the destination  
- C) Only hides the column  
- D) Only applies to Direct Lake

**Answer: B)**

Date type enables correct date filtering and time intelligence.

---

### 138. Implement – Semantic models – Design and build

**Composite models are useful when:**

- A) All data must be in one storage mode  
- B) You need to combine data from different sources or modes (e.g., some cached, some live) in a single report  
- C) Only Direct Lake is allowed  
- D) Only one table exists

**Answer: B)**

Composite = combine different sources or modes in one report.

---

### 139. Maintain – Development lifecycle

**Impact analysis before deploying helps:**

- A) Only schedule refreshes  
- B) Identify reports, dataflows, and other items that depend on the content you are changing, reducing risk of breakage  
- C) Only set sensitivity labels  
- D) Only configure gateways

**Answer: B)**

Impact analysis identifies dependents to reduce breakage risk.

---

### 140. Prepare – Query and analyze data

**DAX measures that use FILTER and SUM are an example of:**

- A) Only Power Query  
- B) Selecting, filtering, and aggregating data in the semantic model using DAX  
- C) Only KQL  
- D) Only T-SQL

**Answer: B)**

FILTER and SUM in DAX = select, filter, aggregate in the model.

---

### 141. Implement – Semantic models – Design and build

**Large semantic model format is configured:**

- A) Only in the gateway  
- B) In the semantic model settings (e.g., when creating or managing the model in Fabric) for models that need the large format  
- C) Only in deployment pipelines  
- D) Only for DirectQuery

**Answer: B)**

Large format is configured in semantic model settings.

---

### 142. Prepare – Get data

**When connecting to an on-premises data source from Fabric, you typically need:**

- A) No gateway  
- B) A gateway (on-premises data gateway or VNet gateway) installed and configured so Fabric can reach the source  
- C) Only a .pbids file  
- D) Only a .pbit file

**Answer: B)**

On-premises typically requires a gateway.

---

### 143. Prepare – Transform data

**Enriching data by adding a "Region" column from a lookup table is an example of:**

- A) Only filtering  
- B) Adding context or derived attributes (enrichment) to improve analytics  
- C) Only removing columns  
- D) Only aggregating

**Answer: B)**

Adding Region from lookup = enrichment.

---

### 144. Implement – Semantic models – Optimize

**Direct Lake on a Fabric SQL endpoint (e.g., warehouse) is useful when:**

- A) Data is only in a lakehouse and you do not use a warehouse  
- B) Your semantic model source is a warehouse and you want Direct Lake to query the warehouse’s tables/views via its SQL endpoint  
- C) Only KQL is used  
- D) Only Import mode is used

**Answer: B)**

Direct Lake on SQL endpoint when source is a warehouse.

---

### 145. Maintain – Security and governance

**Object-level security can restrict access to:**

- A) Only the entire workspace  
- B) Specific tables, columns, or measures in the semantic model for selected roles  
- C) Only reports  
- D) Only dataflows

**Answer: B)**

OLS restricts specific tables, columns, or measures.

---

### 146. Prepare – Transform data

**In Power Query, "Fill Down" can help with:**

- A) Only merging tables  
- B) Replacing nulls in a column with the value from the row above (e.g., for sparse repeated values)  
- C) Only removing duplicates  
- D) Only changing types

**Answer: B)**

Fill Down replaces nulls with the value from above.

---

### 147. Implement – Semantic models – Design and build

**Calculation groups are defined in:**

- A) Only the gateway  
- B) The semantic model (e.g., in Tabular Editor or Power BI Desktop with supported features) as a special table with calculation items  
- C) Only OneLake  
- D) Only deployment pipelines

**Answer: B)**

Calculation groups are defined in the semantic model (Tabular Editor, etc.).

---

### 148. Implement – Semantic models – Optimize

**Incremental refresh "RangeStart" and "RangeEnd" parameters:**

- A) Only define the model name  
- B) Define the date range for each partition so the refresh process knows which data to load or update  
- C) Only set RLS  
- D) Only configure Direct Lake

**Answer: B)**

RangeStart/RangeEnd define the date range per partition.

---

### 149. Prepare – Get data

**OneLake catalog (data hub) endorsement affects:**

- A) Only the workspace name  
- B) How items are presented and discoverable (e.g., Certified/Promoted) for governance and trust  
- C) Only refresh schedule  
- D) Only capacity

**Answer: B)**

Endorsement affects discoverability and trust in the catalog.

---

### 150. Implement – Semantic models – Design and build

**DAX iterators (e.g., SUMX, FILTER) are used when:**

- A) You only need a simple SUM over a column  
- B) You need row-by-row evaluation or a filtered table (e.g., conditional sum, or FILTER for a subset) before aggregation  
- C) Only defining relationships  
- D) Only formatting  

**Answer: B)**

Iterators are for row-by-row or filtered-table evaluation.

---


## Exam readiness: Is studying this enough to pass?

**Short answer:** This practice exam is a **strong foundation** and covers all DP-600 skills, but **studying it alone is usually not enough** to guarantee a pass. Use it together with hands-on practice, the official practice assessment, and Microsoft Learn.

### What this practice exam does well

| Strength | Detail |
|----------|--------|
| **Coverage** | All DP-600 skill bullets (Jan 2026) are covered with multiple questions per topic. |
| **Alignment** | Questions and explanations are aligned with Microsoft Learn concepts and terminology. |
| **Volume** | 150 questions give broad exposure to the scope of the exam. |
| **Explanations** | Answers include brief rationale and Learn references so you can deepen understanding. |
| **Weight balance** | Question mix reflects exam weights: Prepare data (45–50%), Maintain (25–30%), Semantic models (25–30%). |

### Gaps vs. the real DP-600 exam

| Gap | Why it matters |
|-----|----------------|
| **Question format** | The real exam uses **multiple question types**: single- and **multiple-answer** multiple choice, **case studies** (scenario + exhibits + several questions), and **practical scenario** questions. This doc is single-answer multiple choice only. |
| **No hands-on** | Microsoft explicitly recommends **hands-on experience**. The exam tests “implement” and “configure”; you need to have used Fabric (lakehouse, warehouse, dataflows, semantic models, deployment pipelines, security). |
| **No case-study practice** | Case studies test applying knowledge in a scenario (e.g., Contoso-style). You need to practice reading requirements and choosing the right approach, not just recalling facts. |
| **Official practice** | The **free [DP-600 Practice Assessment](https://learn.microsoft.com/en-us/credentials/certifications/exams/dp-600/practice/assessment?assessment-type=practice&assessmentId=90)** gives you the real question style and wording; this doc does not replace it. |
| **Preview / GA** | The exam may include commonly used **Preview** features; this doc emphasizes GA and may not cover every Preview item. |

### Recommended study plan

1. **Use this practice exam** – Work through all 150 questions; read every explanation and follow the Learn links for weak areas. Aim for high consistency (e.g., 85%+ without peeking) before the exam.
2. **Get hands-on in Fabric** – Create a workspace; build a lakehouse, warehouse, and semantic model; run dataflows and pipelines; set RLS/CLS, sensitivity labels, endorsement; use deployment pipelines and Git. [Microsoft Learn – Get trained](https://learn.microsoft.com/en-us/credentials/certifications/exams/DP-600#two-ways-to-prepare) and [Fabric documentation](https://learn.microsoft.com/en-us/fabric/) are the source.
3. **Take the official Practice Assessment** – [DP-600 practice assessment](https://learn.microsoft.com/en-us/credentials/certifications/exams/dp-600/practice/assessment?assessment-type=practice&assessmentId=90). Do it after this doc to see official wording and format.
4. **Try the exam sandbox** – [Exam sandbox](https://aka.ms/examdemo) to get used to the interface and question types (including case studies if shown).
5. **Fill gaps with Learn** – Use the [DP-600 study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/dp-600) and linked learning paths for any skill area where you’re unsure.

### Bottom line

- **If you already have Fabric experience:** This practice exam + the official practice assessment + a pass through the study guide may be **enough** to pass, assuming you’re comfortable with the skills measured.
- **If you are new or light on Fabric:** Treat this doc as **one part** of preparation. Add **hands-on labs and Learn modules**, then the **official practice assessment**. Don’t rely on this document alone.

Passing requires **knowledge + application**. This document mainly builds **knowledge**; **application** comes from hands-on work and practicing scenario/case-study style questions.

---

## References

- [Exam DP-600 study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/dp-600) – Skills measured and study resources  
- [DP-600 Practice Assessment](https://learn.microsoft.com/en-us/credentials/certifications/exams/dp-600/practice/assessment?assessment-type=practice&assessmentId=90) – Official free practice questions  
- [Exam sandbox](https://aka.ms/examdemo) – Try the exam interface and question types  
- [Microsoft Fabric documentation](https://learn.microsoft.com/en-us/fabric/)  
- [Fabric Analytics Engineer Associate certification](https://learn.microsoft.com/en-us/credentials/certifications/fabric-analytics-engineer-associate/)
