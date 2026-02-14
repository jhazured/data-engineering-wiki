# Microsoft Learn DP-600 Practice Assessment (50 Questions)

This document contains the **questions, correct answers, and explanations** from the official [Practice Assessment for Exam DP-600](https://learn.microsoft.com/en-us/credentials/certifications/exams/dp-600/practice/assessment) on Microsoft Learn. It is provided for study and reference in the same format as the custom practice exam.

**Source:** Microsoft Learn – Practice Assessment for Exam DP-600: Implementing Analytics Solutions Using Microsoft Fabric  
**Questions:** **96 unique questions** (duplicates removed), plus **10 additional questions (A1–A10)** at the bottom that target DP-600 coverage gaps. Single- and multiple-answer.

### DP-600 exam coverage (skills measured January 2026)

| Skill area | Weight | Covered by questions | Gaps (no or minimal coverage) |
|------------|--------|----------------------|------------------------------|
| **Maintain – Security and governance** | 25–30% | Workspace/item/row/column/object access: 2, 4, 5, 6, 7, 51, 52, 82, 84. Sensitivity labels: 2, 4, 52. | **Endorse items** (certify/promote content) – no question. |
| **Maintain – Development lifecycle** | | Version control / Git: 53, 55. PBIP: 53. Deployment pipelines: 1, 8, 13, 57. Impact analysis: 12. XMLA endpoint: 54, 56. | **Reusable assets**: .pbit, .pbids, shared semantic models – no question. |
| **Prepare – Get data** | 45–50% | Data connection: 19. OneLake / Real-Time hub / Eventhouse: 59, 92. Ingest: 3, 14, 16, 58, 60, 61, 85, 86, 89, 90, 93. Lakehouse/warehouse/eventhouse choice: 32, 93. OneLake integration: 59, 92. Shortcuts: 3, 93. | **OneLake catalog** (discover/browse assets) – only indirectly (Eventhouse). |
| **Prepare – Transform data** | | Views: 26. Enrich (columns/tables): 64, 68. Star schema: 62. Denormalize: 20. Aggregate: 29, 30, 36, 70. Merge/join: 21, 63, 65, 35, 70, 71, 72. Duplicates/null/missing: 69, 27. Filter: 49, 87. | **Functions, stored procedures** (warehouse) – no question. **Convert column data types** – only implicit in Power Query. |
| **Prepare – Query and analyze** | | Visual Query Editor: 34, 35, 70, 71, 72. SQL: 15, 26, 29, 30, 87, 94, 95, 107-style. KQL: 33. DAX: 40, 44, 50, 79. | — |
| **Semantic models – Design and build** | 25–30% | Storage mode: 37, 73. Star schema: 62. Relationships (e.g. USERELATIONSHIP): 40. DAX (variables, iterators, RANKX): 44, 50. Calculation groups, field parameters: 38, 39, 75. Large semantic model: 74. Composite/aggregations: 73. | **Bridge tables, many-to-many** – no question. **Dynamic format strings** – no question. |
| **Semantic models – Optimize** | | Report/semantic performance: 45, 77, 78. DAX performance: 50, 79. Direct Lake / V-Order: 37, 80. Incremental refresh: 1, 88, 96. ALM Toolkit (metadata): 46. | **Direct Lake: default fallback and refresh behavior** – partial (37, 80). **Choose Direct Lake on OneLake vs Direct Lake on SQL endpoints** – no question. |

**Verdict:** This file gives **strong coverage** of most DP-600 skills. The **Additional questions (A1–A10)** at the bottom of this document target the gaps below so you can get closer to 100% coverage from this file alone.

- **Endorse items** → A1 (Promoted vs Certified vs Master Data).
- **Reusable assets** → A2 (.pbids), A3 (.pbit and shared semantic model).
- **OneLake catalog** (discover/browse) → A4.
- **Prepare data**: Warehouse stored procedures/functions → A5; convert column data types → A10.
- **Semantic models**: Bridge table / many-to-many → A6; dynamic format strings → A7; Direct Lake OneLake vs SQL and fallback → A8, A9.

For even more practice, use the custom practice exam ([azure-fabric-practice-exam.md](azure-fabric-practice-exam.md)).

*Ref: [DP-600 study guide (skills measured)](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/dp-600) – Microsoft Learn*

---

## Questions

### 1. Deployment pipeline – Maintain dependencies and efficient refresh

**You use Microsoft Fabric to manage an organization's data analytics solutions and need to set up a deployment pipeline. The deployment pipeline must maintain item dependencies and support efficient data refresh processes. Each correct answer presents part of the solution. Which three actions should you take?**

**Answer:** Configure autobinding; Enable incremental refresh; Use deployment rules for connections.

Configuring autobinding is crucial for maintaining item connections across stages, which is a key requirement for the deployment pipeline. Enabling incremental refresh ensures that the refresh policy is consistently applied, supporting efficient data management. Using deployment rules allows for proper management of data source connections, ensuring semantic models function correctly in each stage. Using a static refresh schedule and creating new workspaces manually do not contribute to the goals of maintaining connections or supporting incremental refresh, making them incorrect choices.

*Ref: [Implement deployment pipelines](https://learn.microsoft.com/en-us/training/modules/implement-deployment-pipelines/) | [The deployment pipelines process](https://learn.microsoft.com/en-us/training/modules/the-deployment-pipelines-process/) – Microsoft Learn*

---

### 2. Protect sensitive data – Sensitivity labels, OLS, Entra ID

**Your company is using Microsoft Fabric to manage its data warehousing needs. The data includes sensitive customer information that must be protected according to regulatory requirements. You need to protect sensitive data from unauthorized access while allowing authorized users to perform their tasks efficiently. Each correct answer presents part of the solution. Which three actions should you take?**

**Answer:** Apply sensitivity labels; Implement object-level security; Use Microsoft Entra ID groups for user permissions.

Applying sensitivity labels, implementing object-level security, and using Microsoft Entra ID groups are effective strategies to protect sensitive data while allowing authorized users to perform their tasks efficiently. These measures ensure compliance with regulatory requirements and streamline permission management. Revoking all user permissions temporarily would disrupt legitimate access, while granting all users the Viewer role could prevent users from performing necessary tasks due to insufficient permissions.

*Ref: [Explore end-to-end analytics with Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-end-to-end-analytics-microsoft-fabric/) | [Implement column-level security](https://learn.microsoft.com/en-us/training/modules/implement-column-level-security/) – Microsoft Learn*

---

### 3. Lakehouse shortcut to partitioned table (single partition)

**You have a Fabric tenant that contains two lakehouses named Lakehouse1 and Lakehouse2. Lakehouse1 contains a table named FactSales that is partitioned by a column named CustomerID. You need to create a shortcut to the FactSales table in Lakehouse2. The shortcut must only connect to data for CustomerID 100. What should you do?**

**Answer:** As you create the shortcut, select the CustomerKey=100 folder under the FactSales folder in Tables.

During the shortcut setup process, you can expand the FactSales folder to see each folder per CustomerID partition and select the folder for CustomerID=100. These folders are unavailable under Files, and all other options will connect to all the customer data in the shortcut.

*Ref: [Referencing data to a Lakehouse using shortcuts](https://learn.microsoft.com/en-us/fabric/onelake/onelake-shortcuts) – Microsoft Learn*

---

### 4. Security at different levels – Sensitivity labels, OLS, workspace roles

**Your company is using Microsoft Fabric to manage its data analytics solutions. The IT department needs to ensure that sensitive data is protected and only accessible to authorized personnel. You need to implement security measures to safeguard sensitive data at different levels within the data warehouse. Each correct answer presents part of the solution. Which three actions should you perform?**

**Answer:** Apply sensitivity labels; Configure object-level security; Configure workspace roles.

To safeguard sensitive data at different levels within the data warehouse, implementing object-level security, applying sensitivity labels, and configuring workspace roles are effective measures. These actions protect sensitive data and manage access efficiently. Enabling public access would compromise data security, and using role-based access control alone does not offer the necessary granularity for protecting sensitive data. Assigning all users to the Admin role provides excessive access.

*Ref: [Explore end-to-end analytics with Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-end-to-end-analytics-microsoft-fabric/) | [Secure a Microsoft Fabric data warehouse](https://learn.microsoft.com/en-us/training/modules/secure-microsoft-fabric-data-warehouse/) – Microsoft Learn*

---

### 5. Limit access to data elements without affecting application layer

**Your organization uses Microsoft Fabric to manage data analytics solutions. The team manages sensitive data within a data warehouse. You need to implement security measures to limit access to certain data elements without affecting the application layer. Each correct answer presents part of the solution. Which three actions should you take?**

**Answer:** Apply dynamic data masking; Implement column-level security; Use row-level security.

To restrict access to specific columns and rows without affecting the application layer, implementing column-level security, row-level security, and dynamic data masking are necessary. Column-level security limits access to specific columns, ensuring only authorized users can view sensitive information. Row-level security ensures users can only access rows they are authorized to see, enhancing data privacy and control. Dynamic data masking helps prevent unauthorized viewing of sensitive data by masking it in query results, without changing the actual data. Assigning workspace roles and item-level permissions only apply to access to the lakehouse, not the rows and columns within.

*Ref: [Explore end-to-end analytics with Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-end-to-end-analytics-microsoft-fabric/) | [Secure a Microsoft Fabric data warehouse](https://learn.microsoft.com/en-us/training/modules/secure-microsoft-fabric-data-warehouse/) – Microsoft Learn*

---

### 6. Access controls for specific objects in warehouse

**A company uses Microsoft Fabric for data warehousing, and there is a need to ensure that only authorized users can access specific objects within the warehouse. You need to implement access controls for these objects. Each correct answer presents part of the solution. Which two actions should you perform?**

**Answer:** Assign item-level permissions; Implement object-level security.

Assigning item-level permissions allows for precise control over who can access specific objects, aligning with the goal of securing these objects. Implementing object-level security ensures that only users with the necessary permissions can interact with particular objects, directly addressing the need for controlled access. Configuring row-level security focuses on restricting access to specific rows within a table rather than entire objects, making it insufficient for the task. Using workspace roles offers general access management but does not provide the granularity needed to secure individual objects.

*Ref: [Secure a Microsoft Fabric data warehouse](https://learn.microsoft.com/en-us/training/modules/secure-microsoft-fabric-data-warehouse/) – Microsoft Learn*

---

### 7. Control report data access by user roles

**Your company uses Microsoft Fabric for data analytics and needs to ensure that only specific users can access certain report data based on their roles. You need to configure security settings to control access to the data within the report. What should you configure?**

**Answer:** Configure row-level security.

To control dataset access based on user roles, configuring row-level security settings is crucial as it ensures that only authorized users can view specific data. Assigning workspace roles manages access at a broader level but does not provide the necessary granularity for row-level security. Configuring sensitivity labels is related to data protection and compliance, but it does not directly control dataset access based on user roles. Similarly, implementing Azure Active Directory B2C does not address the need for row-level security, as it focuses on external user identity management rather than internal access control.

*Ref: [Explore data teams and Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-data-teams-microsoft-fabric/) | [Govern data in Fabric](https://learn.microsoft.com/en-us/training/modules/govern-data-fabric/) | [Manage Fabric security](https://learn.microsoft.com/en-us/training/modules/manage-fabric-security/) – Microsoft Learn*

---

### 8. Reduce query size to Azure SQL per pipeline stage (deployment parameter)

**You have a semantic model that pulls data from an Azure SQL database and is synced via Fabric deployment pipelines to three workspaces named Development, Test, and Production. You need to reduce the size of the query requests sent to the Azure SQL database when full semantic model refreshes occur in the Development or Test workspaces. What should you do for the deployment pipeline?**

**Answer:** Add a deployment parameter rule to filter the data.

Adding query parameters to the semantic model allows you to filter the refreshed data either categorically or by date and change the amount of data being pulled in between the Development, Test, and Production workspaces. All other options will not change which data is pulled in between the pipeline workspaces.

*Ref: [Create deployment rules for Fabric's Application lifecycle management (ALM)](https://learn.microsoft.com/en-us/fabric/cicd/deployment-rules) | [Manage the analytics development lifecycle](https://learn.microsoft.com/en-us/training/modules/manage-analytics-development-lifecycle/) – Microsoft Learn*

---

### 9. Parquet file structure per customer (partition by Customer ID)

**You have a Fabric workspace that contains a data pipeline with a fact table and two dimension tables. The fact table contains customer data. One dimension table contains customer information and a column with Customer ID information, and the other dimension table contains calendar information and a column with Date ID information. You need to ensure that each customer's sales data is provisioned to their own Parquet file under the Parquet folder structure. Which data pipeline configuration should you implement?**

**Answer:** Partition by customer ID on the fact table.

Partitioning determines the Parquet file structure, depending on the column or columns selected. Partitioning the fact table by customer ID will give each customer ID its own file.

*Ref: [Load data to Lakehouse using partition](https://learn.microsoft.com/en-us/fabric/data-engineering/load-data-lakehouse-partition) – Microsoft Learn*

---

### 10. Pipeline activity – Connect Office 365 Outlook on fail only

**You have a Fabric workspace named Workspace1 that contains a data pipeline named Pipeline1. You plan to use the Office 365 Outlook activity to send an email message each time Pipeline1 experiences issues with pipeline connectors. You need to connect the Office 365 Outlook activity to each main pipeline activity. The solution must minimize the number of email messages sent by the activity. Which activity action should you connect to the Office 365 Outlook activity?**

**Answer:** On fail.

On fail is correct because it will only send a notification when there is an issue caused by an activity failing. All the other options will either notify incorrectly or notify every time.

*Ref: [Data pipeline runs](https://learn.microsoft.com/en-us/fabric/data-factory/pipeline-runs) | [Ingest data with Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/ingest-data-microsoft-fabric/) – Microsoft Learn*

---

### 11. Pipeline schedule – Set time zone to UTC-0

**You have a Fabric tenant that contains a workspace named Workspace1. Workspace1 contains a data pipeline named Pipeline1 that runs in the US-West Azure region. Workspace1 also contains a semantic model named SemanticModel1 and a warehouse named Warehouse1. You need to ensure that Pipeline1 runs at midnight (12:00 AM), and that the schedule is set to the UTC-0 time zone. How should you configure the schedule for Pipeline1?**

**Answer:** For Pipeline1, set the scheduler time zone to UTC-0.

The data pipeline artifact in the workspace has its own time zone setting that applies to only that data pipeline. This is where you need to configure the UTC time zone that will apply to only the data pipeline.

*Ref: [Data pipeline runs](https://learn.microsoft.com/en-us/fabric/data-factory/pipeline-runs) | [Use Data Factory pipelines in Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/use-data-factory-pipelines-fabric/) – Microsoft Learn*

---

### 12. Analyze downstream dependencies of semantic model

**You have a Fabric workspace that contains a semantic model and five reports that use the model. You plan to share the semantic model with another workspace and use the model in five additional reports in the new workspace. You need to analyze the downstream dependencies of the semantic model. The solution must minimize administrative effort. From the workspace, you open the semantic model. What should you do next?**

**Answer:** Select Impact analysis.

You should select Impact analysis because it automatically identifies and summarizes all downstream dependencies of the semantic model, including reports and usage across workspaces, which is essential before sharing the model and reusing it in additional reports. Impact analysis provides a clear view of affected items and dependency scope with minimal administrative effort, whereas Lineage offers a more manual, visual relationship view without consolidated impact insights, Security is focused on permissions, and View related does not provide a comprehensive dependency or impact assessment.

*Ref: [Impact analysis](https://learn.microsoft.com/en-us/fabric/cicd/deployment-pipelines/impact-analysis) – Microsoft Learn*

---

### 13. Deploy semantic model and maintain connections with reports

**An organization uses Microsoft Fabric for data analytics and needs to integrate data from multiple sources for unified business reporting. You need to deploy a semantic model while maintaining connections with dependent reports across pipeline stages. Each correct answer presents part of the solution. Which two actions should you take?**

**Answer:** Select all related items in deployment pipelines; Use deployment pipelines for both the model and reports.

Using deployment pipelines for both the semantic model and reports ensures connections are maintained by leveraging the autobinding feature. Selecting all related items in deployment pipelines ensures that all components with dependencies are deployed together, maintaining necessary connections. Deploying the semantic model and reports separately leads to broken connections, contradicting the goal of maintaining them. Disabling autobinding would prevent the automatic maintenance of connections, which is contrary to the goal of maintaining connections across pipeline stages.

*Ref: [Implement deployment pipelines](https://learn.microsoft.com/en-us/training/modules/implement-deployment-pipelines/) | [The deployment pipelines process](https://learn.microsoft.com/en-us/training/modules/the-deployment-pipelines-process/) – Microsoft Learn*

---

### 14. Code-free ingestion with custom transformations before load

**Your company plans to integrate data from multiple sources into a Microsoft Fabric warehouse for analysis. You need to select a method that allows for code-free data ingestion with the ability to perform custom transformations before loading. What should you use?**

**Answer:** Dataflows Gen2.

Dataflows are the best choice for code-free data ingestion with the ability to perform custom transformations before loading into a warehouse. Microsoft Power Automate might seem plausible due to its automation features, but it is not designed for this specific requirement. Azure Data Factory might appear suitable for data ingestion and transformation, but it requires coding for custom transformations and isn't built into Fabric. Fabric notebooks require code, such as PySpark, to load data.

*Ref: [Load data into Microsoft Fabric data warehouse](https://learn.microsoft.com/en-us/training/modules/load-data-into-microsoft-fabric-data-warehouse/) | [Use Data Factory pipelines in Fabric](https://learn.microsoft.com/en-us/training/modules/use-data-factory-pipelines-fabric/) – Microsoft Learn*

---

### 15. Combine sales and HR data across warehouses (cross-database query)

**You have a Fabric tenant that contains a workspace named Workspace1. Workspace1 contains two data warehouses named Warehouse1 and Warehouse2. Warehouse1 contains HR data. Warehouse2 contains sales data. You are analyzing the sales data in Warehouse2 by using the SQL analytics endpoint. You need to recommend a solution that utilizes a query to combine the sales data from Warehouse2 with the HR data from Warehouse1. The solution must minimize development effort and data movement. What should you recommend?**

**Answer:** Use cross-database querying between Warehouse1 and Warehouse2.

You can query data across Fabric warehouses by using cross-database querying. While you can copy the data from one warehouse to another, this involves moving data.

*Ref: [Understand data warehouses in Fabric](https://learn.microsoft.com/en-us/training/modules/understand-data-warehouses-fabric/) – Microsoft Learn*

---

### 16. Data ingestion from ADLS Gen2 and Blob (CSV, Parquet) – Pipeline, Dataflow, Copy

**Your organization plans to implement a data ingestion solution using Microsoft Fabric. The data sources include Azure Data Lake Storage Gen2 and Azure Blob Storage, with data formats in CSV and Parquet. You need to ensure efficient data ingestion and processing with adaptability for future transformations. Each correct answer presents part of the solution. Which three actions should you take?**

**Answer:** Create a data pipeline; Create a Dataflow Gen2; Use the copy data activity.

Implementing data pipelines is essential as they provide a code-free or low-code environment to orchestrate complex data workflows, automating and scheduling data ingestion tasks for consistent data flow. Using the COPY statement is crucial for high-throughput data ingestion from Microsoft Azure storage accounts, efficiently handling large volumes of data in CSV and Parquet formats. Using dataflows is beneficial for code-free data transformation before ingestion, ensuring data quality by cleaning and preparing data. Storing data in Azure SQL Database is not suitable for high-throughput data ingestion scenarios, as it is not optimized for such purposes. Azure Synapse Analytics, while powerful for analytics and data warehousing, is not specifically designed for the data ingestion processes required in this context.

*Ref: [Load data using T-SQL](https://learn.microsoft.com/en-us/training/modules/load-data-using-tsql/) | [Use the Copy Data activity](https://learn.microsoft.com/en-us/training/modules/use-copy-data-activity/) – Microsoft Learn*

---

### 17. Dataflow Gen2 – Retain current and historical records (append)

**You have an Azure SQL database that contains fact table named UnpostedSales. UnpostedSales contains unposted payments. Each day payment records from the previous day are automatically truncated from the UnpostedSales table and replaced with today's payment records. You need to use a Dataflow Gen2 query to import the data into either a lakehouse or a warehouse. The solution must ensure that all current and historical records are maintained. What should you do to retain current and historical records during a refresh?**

**Answer:** Configure the refresh to append data for the query.

Appending data for the query will add new rows each time a refresh occurs, ensuring that both historical and current records are kept and combined. All other options will not keep the historical records.

*Ref: [Lakehouse Load to Delta Lake tables](https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-load-delta-tables) – Microsoft Learn*

---

### 18. PySpark – Display top 100 rows from DataFrame

**You have a Fabric lakehouse that contains a managed Delta table named Product. You plan to analyze the data by using a Fabric notebook and PySpark. You load the data to a DataFrame by running the following code: `df = spark.sql("SELECT * FROM Product")`. You need to display the top 100 rows from the DataFrame. Which PySpark command should you run?**

**Answer:** `display(df.limit(100))`

The display PySpark method is used to display data in a DataFrame. To limit the data displayed, limit(100) can be specified.

*Ref: [Work with data in a Spark dataframe](https://learn.microsoft.com/en-us/training/modules/work-data-spark-dataframe/) – Microsoft Learn*

---

### 19. SQL connection string for lakehouse (SSMS)

**You have a Fabric tenant that contains a workspace named Workspace1. Workspace 1 contains a lakehouse named Lakehouse1. You plan to use Microsoft SQL Server Management Studio (SSMS) to write SQL queries against Lakehouse1. Where can you find the SQL connection string for Lakehouse1?**

**Answer:** In the Lakehouse settings under Copy SQL connection string.

The connection string for the SQL endpoint can be found under the Lakehouse settings under the SQL analytics endpoint.

*Ref: [Connectivity to data warehousing](https://learn.microsoft.com/en-us/fabric/data-warehouse/connectivity) – Microsoft Learn*

---

### 20. Denormalize tables to reduce model complexity (snowflaked dimensions)

**You have a Fabric workspace that contains a complex semantic model for a Microsoft Power BI report. You need to optimize the semantic model for analytical queries and use denormalization to reduce the model complexity and the number of joins between tables. Which tables should you denormalize?**

**Answer:** Snowflaked dimension tables.

A Snowflake dimension is a set of normalized tables for a single business entity. Implementing a proper star schema usually requires denormalizing the set of tables to create a single table that contains all the necessary attributes.

*Ref: [Understand star schema and the importance for Power BI](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema) – Microsoft Learn*

---

### 21. Merge queries – Left outer join (keep all FactSales)

**You have a Fabric warehouse that contains two tables named FactSales and dimGeography. The dimGeography table has a primary key column named GeographyKey. The FactSales table has a foreign key column named GeographyKey. You create a Dataflow Gen2 query and add the tables as queries. You plan to use the Diagram view to visually transform the data. You need to join the two queries so that you retain all the rows in FactSales even if there are no matching rows for them in dimGeography. What should you do after you select FactSales?**

**Answer:** Use Merge queries as new transformation with join kind set to Left outer and FactSales as the left table and dimGeography as the right table.

Using the Diagram view, you can join two existing queries by using the Merge Queries as new transformation. A left join keeps all the rows from the left table even when there is no match for them in the right table. The Append queries as new transformation adds the queries to each other like a Union operation.

*Ref: [Create your first Microsoft Fabric Dataflow Gen2](https://learn.microsoft.com/en-us/fabric/data-transform/dataflows/create-first-dataflow-gen2) – Microsoft Learn*

---

### 22. Dataflow Gen2 – Exclude records (left anti join), maintain query folding

**You have a Fabric warehouse. You have an Azure SQL database that contains a fact table named Sales and a second table named ExceptionRecords. Both tables contain a unique key column named Record ID. You plan to ingest the Sales table into the warehouse. You need to use Dataflow Gen2 to configure a merge type to ensure that the Sales table excludes any records found in the ExceptionRecords table, and that query folding is maintained. Which applied steps should you use?**

**Answer:** Merge (left anti join) applied step, and then the expand columns applied step.

A left anti join ensures that only rows not found in the ExceptionRecords table are loaded, and the expand columns step ensures that query folding is maintained for performance.

*Ref: [Merge queries overview](https://learn.microsoft.com/en-us/power-query/merge-queries-overview) – Microsoft Learn*

---

### 23. Power Query – Transformation that prevents query folding

**You have a complex Microsoft Power BI report that retrieves data from a Microsoft SQL Server database. You plan to use Power Query Editor to apply a series of transformations to shape the data. You need to make sure to use transformations that ensure that query folding is still in place. Which transformation prevents query folding?**

**Answer:** Adding index columns.

Unlike Pivot/Unpivot, as well as Keep rows transformations, adding the index column transformation in Power Query will always prevent the query from folding.

*Ref: [Query folding](https://learn.microsoft.com/en-us/power-query/power-query-query-folding) – Microsoft Learn*

---

### 24. PySpark – Save DataFrame as Delta table partitioned by Year and Quarter

**You have a Fabric tenant that contains a lakehouse. You plan to use a Fabric notebook and PySpark to read sales data and save the data as a Delta table named Sales. The table must be partitioned by Sales Year and Quarter. You load the sales data to a DataFrame named df that contains a Year column and a Quarter column. Which command should you run next?**

**Answer:** `df.write.mode("overwrite").format("delta").partitionBy("Year","Quarter").save("Tables/Sales")`

To save a DataFrame in the Delta format, you must use format("delta"). While a DataFrame can be saved to the Files section of a lakehouse, it will not be considered a table.

*Ref: [Lakehouse tutorial - Prepare and transform data in the lakehouse](https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-tutorial-transform) – Microsoft Learn*

---

### 25. Power Query – Split column (single step, remove original)

**You have a Fabric workspace. The workspace contains a Dataflow Gen2 query that displays dimensional product information. The query table contains a column named Product ID/Name that is a concatenation of Product ID and Product Name values. You need to use an applied step in Microsoft Power Query Editor to create a new column for Product ID and Product Name. The solution must use a single command to create two new columns and remove the original combined (Product ID/Name) column. Which applied step should you use?**

**Answer:** Split Column.

Split Column is the only applied step in Power Query Editor that will both remove the source column and create two new columns by using just a single command/applied step.

*Ref: [Split columns by delimiter](https://learn.microsoft.com/en-us/power-query/split-columns-delimiter) – Microsoft Learn*

---

### 26. Modify column names without changing Delta table (view)

**You have a Fabric workspace that contains a Microsoft Power BI report. You need to modify the column names in the Power BI report without changing the original names in the underlying Delta table. Which warehouse object should you create?**

**Answer:** View.

A view provides a convenient way to encapsulate additional query logic, such as renaming columns, filtering, aggregating, etc. Views contain only a query definition and do not change the underlying tables.

*Ref: [CREATE VIEW (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql) – Microsoft Learn*

---

### 27. Power Query – Percentage of valid records (column quality)

**You use Microsoft Power BI Desktop to connect to data stored in a CSV file. You need to use Power Query Editor to identify the percentage of valid records in a column before loading the data to a report. Which Power Query option should you use?**

**Answer:** Column quality.

A percentage of valid records in the column is displayed when you enable Column quality. Column distribution provides an overview of the value frequency and distribution in a column. Column profile provides statistical data about values in a column.

*Ref: [Profile data in Power BI](https://learn.microsoft.com/en-us/training/modules/profile-data-power-bi/) – Microsoft Learn*

---

### 28. PySpark – Bar chart (matplotlib) cities by sales territory

**You have Fabric tenant that contains a workspace named Workspace1. Workspace1 contains a lakehouse names Lakehouse1. Lakehouse1 contains a dimension table called dimension_city. The table contains a column named City and a column named SalesTerritory. You need to visualize the number of cities in each sales territory in a bar chart. The sales territory must be on the X axis and the number of cities on the Y axis. You begin to create PySpark code in a Fabric notebook attached to Lakehouse1. You need to complete the code to meet the analysis requirements. How should you complete the code?**

**Answer:** `plt.bar(x=data['SalesTerritory'], height=data['CityCount'])` then `plt.xlabel('SalesTerritory')`, `plt.ylabel('Cities')`, `plt.show()`.

After you create a figure, you must create a bar plot of city counts by SalesTerritory by running the given code.

*Ref: [Visualize data in a Spark notebook](https://learn.microsoft.com/en-us/training/modules/visualize-data-spark-notebook/) – Microsoft Learn*

---

### 29. SQL – GROUP BY and HAVING (yearly SalesAmount > 10000)

**You have a Fabric warehouse that contains Sales, Product, and Date tables with relationships on DateKey and ProductKey. You write a SQL query to analyze Sales by ProductName and Year, but only for products that have a yearly SalesAmount of more than $10000. You need to complete the query. How should you complete the query?**

**Answer:** `GROUP BY p.ProductName, d.Year` and `HAVING SUM(s.SalesAmount) > 10000`.

The GROUP BY columns must match the columns used in the SELECT statement. Using WHERE will eliminate individual sales records that have a daily SalesAmount larger than 10,000. The goal is to remove records for which the total SalesAmount for a year is larger than 10,000. This can be achieved by using HAVING since it works on the result of the GroupBy.

*Ref: [HAVING (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/queries/select-having-transact-sql) – Microsoft Learn*

---

### 30. SQL – Total products sold per Product_ID in January 2024

**You have a table named Sales that contains Order_ID, Customer_ID, Product_ID, Quantity, and Sales_Date. You need to write a SQL statement to find the total number of products sold for each Product_ID in January 2024. What should you run?**

**Answer:** `SELECT Product_ID, SUM(Quantity) FROM Sales WHERE MONTH(Sales_Date) = 1 AND YEAR(Sales_Date) = 2024 GROUP BY Product_ID`

The SQL statement correctly filters to sales for January 2024 for each product, with a total sum of the quantity.

*Ref: [WHERE (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/queries/where-transact-sql) – Microsoft Learn*

---

### 31. T-SQL – Ranking with no gaps after ties (DENSE_RANK)

**You have a Fabric warehouse. You are writing a T-SQL statement to retrieve data from a table named Sales to display the highest sales amount for specific customers. You need to ensure that after ties for SalesAmount, the next Sales amount increments the Ranking value by one. Which function should you use for the ranking?**

**Answer:** DENSE_RANK().

DENSE_RANK() function returns the rank of each row within the result set partition, with no gaps in the ranking values. The RANK() function includes gaps in the ranking.

*Ref: [Ranking Functions (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/ranking-functions-transact-sql) – Microsoft Learn*

---

### 32. ETL in lakehouse – Most efficient (notebooks / Spark)

**Your company has implemented a Microsoft Fabric lakehouse to store and manage very large datasets. Raw data is loaded into staging tables, then transformed before being loaded into the final tables for further analysis. You need to determine the most efficient way to perform this extract, transform, load (ETL) process in the lakehouse. What should you do?**

**Answer:** Use Fabric notebooks.

To efficiently perform data transformations and load processed data within the Microsoft Fabric lakehouse, notebooks are the most suitable method. Notebooks use Apache Spark, which is designed for big data processing, providing scalability and processing power necessary for handling large datasets. Using Data Factory pipelines for data transformation is not the most efficient method within the Microsoft Fabric lakehouse environment. Dataflows Gen2 with Power Query, while useful, may not handle large datasets as efficiently as Spark. Eventstreams are not designed for complex data transformations.

*Ref: [Work with Microsoft Fabric lakehouses](https://learn.microsoft.com/en-us/training/modules/work-microsoft-fabric-lakehouses/) | [Understand data warehouses in Fabric](https://learn.microsoft.com/en-us/training/modules/understand-data-warehouses-fabric/) – Microsoft Learn*

---

### 33. Analyze storm event data with KQL (KQL Queryset)

**Your organization uses Microsoft Fabric to manage its data analytics solutions. You have a Microsoft KQL database connected to multiple data sources, including a Microsoft Azure Data Explorer cluster and a Microsoft OneLake data hub. You need to analyze recent storm event data using Kusto Query Language (KQL). What should you do?**

**Answer:** Use a KQL Queryset.

To generate a report on recent storm events using KQL, writing and running a KQL query in the KQL Queryset is the appropriate approach. This method directly utilizes the KQL capabilities of the KQL database, allowing for efficient data retrieval. Using a KQL activity in a data pipeline is not the most direct method for this task. Using a KQL query in Power BI involves visualization rather than direct querying for report generation. Using the SQL analytics endpoint is incorrect because it involves SQL, not KQL.

*Ref: [Work with Microsoft Fabric lakehouses](https://learn.microsoft.com/en-us/training/modules/work-microsoft-fabric-lakehouses/) | [Understand data warehouses in Fabric](https://learn.microsoft.com/en-us/training/modules/understand-data-warehouses-fabric/) – Microsoft Learn*

---

### 34. Analyze warehouse data without code (Visual Query Editor)

**Your company uses Microsoft Fabric to manage a data warehouse. The team analyzes sales data by filtering and aggregating it based on specific criteria. You need to perform the analysis without writing any code. What should you do to achieve this?**

**Answer:** Use the visual query editor in Microsoft Fabric.

Using the visual query editor in Microsoft Fabric is the best approach because it enables data filtering and aggregation without the need for SQL, aligning with the requirement to avoid coding. Using Dataflow Gen2 or Power BI, while possible, is not the most efficient method for direct data manipulation within Microsoft Fabric. Pipelines are used to orchestrate data movement and processes and are not meant for data analysis.

*Ref: [Explore the visual query editor](https://learn.microsoft.com/en-us/training/modules/explore-visual-query-editor/) | [Explore Dataflows Gen2 in Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-dataflows-gen2-microsoft-fabric/) – Microsoft Learn*

---

### 35. Visual query editor – Monthly report sales by product category (add tables, merge)

**You use Microsoft Fabric for data warehousing with data in FactSales and DimProduct tables. You need to generate a monthly report summarizing sales by product category using the visual query editor. Each correct answer presents part of the solution. Which two actions should you take?**

**Answer:** Add FactSales and DimProduct tables; Merge FactSales and DimProduct on ProductKey.

To create a report showing total sales for each product category by month, you must first drag and drop the FactSales and DimProduct tables onto the canvas to set up the query environment. Then, use the Merge queries as new operator to join these tables on ProductKey, which is essential for aggregating sales data by product category. Sorting or filtering for specific sales amounts are not necessary steps for this task.

*Ref: [Explore the visual query editor](https://learn.microsoft.com/en-us/training/modules/explore-visual-query-editor/) | [Explore Dataflows Gen2 in Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-dataflows-gen2-microsoft-fabric/) – Microsoft Learn*

---

### 36. Minimize Query1 run time – Save as table (materialize)

**You have a Fabric workspace named WS1 that contains a data warehouse named DW1. DW1 contains a table named Table1. You use the visual query editor to create a query named Query1 that combines Table1 and several other tables in DW1. You plan to use Query1 as a source for analytics. You need to minimize how long it takes to run Query1. The solution must minimize development effort. What should you do?**

**Answer:** Save Query1 as a table in DW1.

You should save Query1 as a table in DW1 because this materializes the results of the combined query, allowing analytics to read precomputed data directly instead of re-executing complex joins and transformations each time the query runs. This approach significantly reduces query execution time while requiring minimal development effort. Saving the query as a view would still recompute the data on every execution, exporting it as a Power Query template only supports reuse of logic rather than performance optimization, and creating a SQL endpoint provides access but does not improve query performance.

*Ref: [Query using the SQL query editor](https://learn.microsoft.com/en-us/fabric/data-warehouse/query-using-sql-editor) – Microsoft Learn*

---

### 37. Best storage mode for NRT and report performance (Direct Lake)

**You have a Fabric tenant that contains a workspace named Workspace1. Workspace1 is assigned to an F64 capacity and contains a lakehouse. The lakehouse contains one billion historical sales records and receives up to 10,000 new or updated sales records throughout the day at 15-minute intervals. You plan to build a custom Microsoft Power BI semantic model and Power BI reports from the data. The solution must provide the best report performance while supporting near-real-time (NRT) data reporting. Which Power BI semantic model storage mode should you use?**

**Answer:** Direct Lake.

Direct Lake storage mode provides NRT access to data, while providing performance close to Import storage mode and much better performance than DirectQuery. DirectQuery provides NRT access to data, but queries can run slowly when working with large datasets. Import produces fast performance; however, it requires data to be loaded to the memory of Power BI and will not provide NRT. Direct Lake tables cannot currently be mixed with other table types, such as Import, DirectQuery, or Dual, in the same model. Composite models are not yet supported.

*Ref: [Learn about Direct Lake in Power BI and Microsoft Fabric](https://learn.microsoft.com/en-us/power-bi/connect-data/direct-lake-overview) – Microsoft Learn*

---

### 38. One column chart – Analyze by ProductCategory or Year or CustomerCity (field parameters)

**You have a Fabric workspace and a Microsoft Power BI semantic model with Sales, Product, Date, and Customer tables and appropriate relationships. You need to create a Power BI report so that end users can use a one column chart to analyze SalesAmount by ProductCategory or Year or CustomerCity. The solution must minimize development effort. What should you do?**

**Answer:** Set up a Fields parameter with ProductCategory, Year, and CustomerCity. Use the Fields parameter in the visual.

While you can use bookmarks to navigate between report pages or change the visibility of visuals, using the Fields parameter is a much easier and more efficient way of allowing an end-user to change the fields on a visual. Developing a custom visual with built-in buttons to switch the items on the axis involves extra development effort.

*Ref: [Use parameters to visualize variables](https://learn.microsoft.com/en-us/power-bi/transform-model/field-parameters) – Microsoft Learn*

---

### 39. Change y-axis category with slicer (field parameters)

**You have a Microsoft Power BI report that contains a bar chart visual. You need to ensure that users can change the y-axis category of the bar chart by using a slicer selection. Which Power BI feature should you add?**

**Answer:** Field parameters.

Field parameters allow users to change between columns that can be used on the categorical axis of visuals. All other options do not grant this ability.

*Ref: [Let report readers use field parameters to change visuals](https://learn.microsoft.com/en-us/power-bi/transform-model/field-parameters) – Microsoft Learn*

---

### 40. DAX – Sales Ordered vs Sales Shipped (USERELATIONSHIP for inactive relationship)

**You are working on a Microsoft Power BI report based on a semantic model with Sales (SalesAmount, OrderDateKey, ShipDateKey) and Date (DateKey, Date, Month, Quarter, Year). The Date table is connected to Sales on DateKey to OrderDateKey (active) and on DateKey to ShipDateKey (inactive). You need to create two measures: Sales Amount Ordered and Sales Amount Shipped, to place them side-by-side in a table visual and analyze by Year. How should you create the measures?**

**Answer:** Sales Ordered = SUM('Sales'[SalesAmount]). Sales Shipped = CALCULATE(SUM('Sales'[SalesAmount]), USERELATIONSHIP('Date'[DateKey], 'Sales'[ShipDateKey])).

In this example, the Date dimension is a role-playing dimension. Sales has an active relationship with Date based on OrderDate, so Sales Amount based on Order Date can be calculated by a simple SUM. Sales has an inactive relationship with Date based on ShippedDate. To create calculations based on inactive relationships, use the USERELATIONSHIP function and specify the two columns that are used in the existing inactive relationship. The RELATED function returns a value from the "one" side of a relationship.

*Ref: [Active vs inactive relationship guidance](https://learn.microsoft.com/en-us/power-bi/guidance/relationships-active-inactive) – Microsoft Learn*

---

### 41. Tabular Editor – Load data without rebuilding hierarchies (Process Data)

**You use Tabular Editor 2 to perform advanced data processing of the largest tables in a Microsoft Power BI semantic model. You need to load data to a table without rebuilding hierarchies and relationships and without recalculating calculated columns and measures. Which process mode should you use?**

**Answer:** Process Data.

Process Data loads data to a table without rebuilding hierarchies or relationships or recalculating calculated columns and measures. With Process Default, hierarchies, calculated columns, and relationships are built or rebuilt (recalculated). Process Defrag defragments the auxiliary table indexes, while Process Recalc recalculates hierarchies, relationships, and calculated columns on a database level.

*Ref: [Process Database, Table, or Partition (Analysis Services)](https://learn.microsoft.com/en-us/analysis-services/multidimensional-models/process-database-table-partition-analysis-services) – Microsoft Learn*

---

### 42. Dimension for zip code at time of sale (Type 2 SCD)

**You are designing a dimension table named dimCustomer that will be used to analyze historical sales data by customer zip code. The table will be joined to FactSales on CustomerKey to report historical sales data by customer zip code. The sales data must be reported based on the zip codes of customers at the time of the sale, not their most recent zip code. You need to design dimCustomer to contain a fixed number of columns. Which type of dimension should you choose for dimCustomer?**

**Answer:** Type 2 slowly changing dimension (SCD).

Type 0 SCD attributes never change and will not fit the requirement. Type 1 SCD overwrites the changes and historical analysis of data based on the zip code at the time of the sales will be impossible. Type 2 SCD will keep track of historical data by adding new records with new keys whenever an attribute changes. Type 3 SCD adds new columns to a table for attribute changes.

*Ref: [Explore data load strategies](https://learn.microsoft.com/en-us/training/modules/explore-data-load-strategies/) – Microsoft Learn*

---

### 43. Point-in-time analysis, persist status change with new row (Type 2 SCD)

**You have a Fabric warehouse named Warehouse1 that contains customer status information. You plan to implement a dimensional model in Warehouse1. The solution must meet the following requirements: Be able to perform point-in-time analysis; whenever a customer's status changes, the change must be persisted in a table named DimCustomer, and a new row is added to include the timestamp of the status change. Which type of dimension should you choose for dimCustomer?**

**Answer:** Type 2 slowly changing dimension (SCD).

Type 2 SCD keeps multiple versions of the same business entity, by adding a new row whenever change occurs. It's often implemented by including a timestamp to allow for point-in-time analysis. Type 1 SCD overwrites the previous value with the new one. Type 0 SCD doesn't track changes at all, whereas Type 3 SCD stores two versions of the dimension member as separate columns.

*Ref: [Choose between slowly changing dimension types](https://learn.microsoft.com/en-us/training/modules/choose-slowly-changing-dimension-types/) – Microsoft Learn*

---

### 44. DAX RANKX with ALL and Skip – What the measure calculates

**You have the following measure that you are reviewing as part of a model audit: `RANKX( ALL( 'Product'[Product Name] ), [Sales],, DESC, Skip )`. You need to identify what the measure is calculating. Which statement accurately describes the DAX measure?**

**Answer:** It ranks the product names by Sales, with the largest values getting the smallest (e.g. 1, 2, 3) ranks, and when product names have tied values, then the next rank value, after a tie, is the rank value of the tie plus the count of tied values.

The DAX measure ranks the product names by Sales, with the largest values getting the smallest ranks, and when product names have tied values, the next rank value after a tie is the rank value of the tie plus the count of tied values.

*Ref: [RANKX function (DAX)](https://learn.microsoft.com/en-us/dax/rankx-function-dax) – Microsoft Learn*

---

### 45. Identify which report element consumes most rendering time (Performance analyzer)

**You have a Microsoft Power BI report page that takes longer than expected to display all its visuals. You need to identify which report element consumes most of the rendering time. The solution must minimize administrative effort and how long it takes to capture the rendering information of each element on the report page. What should you use?**

**Answer:** Performance analyzer.

Performance analyzer is a built-in feature in Power BI Desktop that captures the performance information of each element on the report page. DAX Studio can be used to analyze DAX queries, whereas Tabular Editor does not capture the rendering time at all.

*Ref: [Use Performance Analyzer to examine report element performance in Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/create-reports/desktop-performance-analyzer) – Microsoft Learn*

---

### 46. Update measure definition without refreshing model in service (ALM Toolkit)

**You publish a very large Microsoft Power BI semantic model to a Power BI workspace. The model refresh will take two hours. In Power BI Desktop, you limit the data you work with by using parameters. You need to update the definition of a measure. What can you use to update the measure definition without having to refresh the model in the Power BI service?**

**Answer:** ALM Toolkit.

The ALM Toolkit is a schema diff tool for Power BI models and can be used to perform the deployment of metadata only. Deploying from Power BI Desktop will overwrite the model's data in the service and will require a refresh by the Power BI service to load the data. DAX Studio does not update metadata. You can connect to Power BI semantic models by using Excel in read-only mode.

*Ref: [Advanced incremental refresh and real-time data with the XMLA endpoint in Power BI](https://learn.microsoft.com/en-us/power-bi/connect-data/incremental-refresh-xmla-endpoint) – Microsoft Learn*

---

### 47. DAX Studio – Capture queries generated by report (All Queries trace)

**You are using DAX Studio to connect to and troubleshoot a Microsoft Power BI report that is performing poorly. You need to capture the queries generated by the report. Which feature in DAX Studio should you enable?**

**Answer:** All Queries trace.

The All Queries trace supports capturing query events from all client tools, which is useful when you must see the queries generated by Power BI Desktop. Server Timings and Query Plan capture events are sent only from DAX Studio.

*Ref: [All Queries Trace – DAX Studio](https://daxstudio.org/) – Microsoft Learn*

---

### 48. Delta table – Improve query performance and reduce storage (OPTIMIZE and VACUUM)

**You have a Fabric tenant that contains a lakehouse named Lakehouse1. A SELECT query from a managed Delta table in Lakehouse1 takes longer than expected to complete. The table receives new records daily and must keep change history for seven days. You notice that the table contains 1,000 Parquet files that are each 1 MB. You need to improve query performance and reduce storage costs. What should you do from Lakehouse explorer?**

**Answer:** Select Maintenance and run the OPTIMIZE command as well as the VACUUM command with a retention policy of seven days.

The ideal file size for Fabric engines is between 128 MB and 1 GB. This improves query performance since it reduces the need to scan numerous small files. OPTIMIZE compacts and rewrites the files into fewer larger files. VACUUM removes older Parquet files that are no longer in use. While this reduces the storage size, it by itself does not reduce the number of active files that must be scanned.

*Ref: [Use table maintenance feature to manage delta tables in Fabric](https://learn.microsoft.com/en-us/fabric/data-engineering/table-maintenance) – Microsoft Learn*

---

### 49. Dataflow performance – Filter before split (query folding)

**You have a Fabric tenant that contains a workspace named Workspace1. Workspace1 contains a warehouse and a Dataflow Gen2 query, which ingests the current year's order data from an Azure SQL database. A table named Orders in the source database has 20 years of data. The Orders table contains a column named OrderDateTime (DateTime). The Dataflow Gen2 query applies: Source (Azure SQL), Navigation (Orders), Split Column by position on OrderDateTime at position 11 (creating OrderDateTime.1 and OrderDateTime.2), Filtered rows on OrderDateTime.1 to current year. The dataflow takes longer than expected to run. You need to recommend a procedure to improve dataflow performance. What should you recommend?**

**Answer:** For step 3, first apply the filter transformation to the OrderDateTime column to current year, and then apply the split by position transformation.

Some Microsoft Power Query transformations break query folding, which causes all the data to be pulled into Power Query before it is filtered. It is more efficient to filter the data at the source when possible before moving it to Power Query. Splitting a column by position (or delimiter) breaks query folding and causes all the data to load before the current year filter is applied. To enable query folding in this example, the OrderDateTime should be filtered first, then the rest of the transformations can be applied if desired. Removing the OrderDateTime.2 column does not change the order of the operations. Using Table.Buffer prevents downstream folding.

*Ref: [Query folding](https://learn.microsoft.com/en-us/power-query/power-query-query-folding) – Microsoft Learn*

---

### 50. Optimize DAX measure (VAR to cache, SWITCH)

**You have a DAX measure that contains the following code: `Variance KPI = IF( [Variance] > 0.80, "Amazing!", IF( [Variance] > 0.60, "Good", "Bad" ) )`. You need to optimize the measure so that it will calculate faster. Which code should you use?**

**Answer:** Use a variable to cache [Variance] and SWITCH(TRUE(), ...), e.g. `VAR Calc = [Variance] RETURN SWITCH(TRUE(), Calc > 0.80, "Amazing!", Calc > 0.60, "Good", "Bad")`.

Declaring the [Variance] measure as a VAR will cache the measure and only load it once. This reduces the amount of processing and data loading that the measure must do and increases its speed. All other formulas do not leverage the VAR for best performance.

*Ref: [Use variables to improve your DAX formulas](https://learn.microsoft.com/en-us/dax/dax-variables) – Microsoft Learn*

---

## Additional questions (from another assessment attempt)

The following questions are from a second practice assessment run and are **different** from the 50 above. They are appended for extra coverage.

---

### 51. OLS – Restrict access to a specific measure (CompanyCosts) for User1 only

**You are designing a Microsoft Power BI semantic model that contains a measure named CompanyCosts. You need to restrict access to CompanyCosts and ensure that only a user named User1 can view the measure in reports. What should you implement?**

**Answer:** Object-level security (OLS).

OLS enables restricting access to semantic model objects, such as tables, columns, and calculations based on these columns. RLS (both static and dynamic) restricts access to specific attributes in the semantic model, such as location, category, etc.

*Ref: [Restrict access to Power BI model objects](https://learn.microsoft.com/en-us/training/modules/restrict-access-power-bi-model-objects/) – Microsoft Learn*

---

### 52. Protect sensitive data in a lakehouse – Sensitivity labels and RLS

**An organization uses Microsoft Fabric for data analytics solutions. You need to protect sensitive data within a Microsoft Fabric lakehouse from unauthorized access. Each correct answer presents part of the solution. Which two actions should you take?**

**Answer:** Apply sensitivity labels; Implement row-level security.

Applying sensitivity labels is crucial as it helps identify and protect sensitive information, ensuring compliance and security. Implementing row-level security is effective because it restricts data access based on user roles, providing granular control over who can view or manipulate specific data. Workspace roles and item-level permissions for access are not ideal for protecting sensitive data as they lack the necessary granularity for securing sensitive information.

*Ref: [Explore end-to-end analytics with Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-end-to-end-analytics-microsoft-fabric/) | [Secure data access in Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/secure-data-access-microsoft-fabric/) – Microsoft Learn*

---

### 53. Collaborate on semantic model – PBIP and Git

**You use Microsoft Power BI Desktop to create a Power BI semantic model. You need to recommend a solution to collaborate with another Power BI modeler. The solution must ensure that you can both work on different parts of the model simultaneously. The solution must provide the most efficient and productive way to collaborate on the same model. What should you recommend?**

**Answer:** Save your work as a Power BI Project (PBIP). Initialize a Git repository with version control.

Saving your Power BI work as a PBIP enables you to save the work as individual plain text files in a simple, intuitive folder structure, which can be checked into a source control system such as Git. This will enable multiple developers to work on different parts of the model simultaneously. Emailing a Power BI model back and forth is not efficient for collaboration. Saving a Power BI model as a PBIX file to OneDrive eases developers access, but only one developer can have the file open at a time. Publishing a PBIX file to a shared workspace does not allow multiple developers to work on the model simultaneously.

*Ref: [Power BI Desktop projects (PBIP)](https://learn.microsoft.com/en-us/power-bi/developer/desktop/desktop-project-files) | [Manage the analytics development lifecycle](https://learn.microsoft.com/en-us/training/modules/manage-analytics-development-lifecycle/) – Microsoft Learn*

---

### 54. XMLA endpoint – Main limitation (PBIX cannot be downloaded)

**You have a Fabric tenant that has XMLA Endpoint set to Read Write. You need to use the XMLA endpoint to deploy changes to only one table from the data model. What is the main limitation of using XMLA endpoints for the Microsoft Power BI deployment process?**

**Answer:** A PBIX file cannot be downloaded from the Power BI service.

Whenever the semantic model is deployed or changed by using XMLA endpoints, there is no possibility to download the PBIX file from the Power BI service. This means that no one can download the PBIX file (even the user who deployed the report). Table partitioning, as well as using parameters, is still supported, thus doesn't represent a limitation.

*Ref: [Manage a Power BI dataset using XMLA endpoint](https://learn.microsoft.com/en-us/training/modules/manage-power-bi-dataset-xmla-endpoint/) | [Semantic model connectivity and management with the XMLA endpoint in Power BI](https://learn.microsoft.com/en-us/power-bi/connect-data/service-premium-connect-tools) – Microsoft Learn*

---

### 55. Git integration – Collaborate on semantic model and report (branch and new workspace)

**You have a Fabric workspace named Workspace1 that contains a semantic model and a report. You plan to connect Workspace1 to a Git repository named Repo1 and enable version control. Repo1 will be used to manage and maintain the contents of Workspace1. You need to ensure that other users can collaborate on the semantic model and the report. The solution must minimize development effort. What should you do?**

**Answer:** From Workspace1, create a branch and a new workspace.

You should create a branch and a new workspace from Workspace1 because Fabric's Git integration supports collaborative development by allowing users to work in isolated branches that are mapped to their own workspaces. This approach enables multiple users to modify the semantic model and report independently while using Repo1 for version control, all with minimal development effort and configuration. Committing alone does not establish collaborative workflows, Power BI Desktop projects are not required for workspace-level version control in Fabric, and Fabric does not support connecting workspaces directly to local folders.

*Ref: [Implement version control and Git integration](https://learn.microsoft.com/en-us/fabric/cicd/git-integration/) – Microsoft Learn*

---

### 56. Manage semantic models with external tools (XMLA read-write)

**Your organization uses Microsoft Fabric for data analytics. You need to manage the semantic models with external tools due to the size. What should you do?**

**Answer:** Enable read-write in the XMLA Endpoint settings.

To enable write operations on semantic models from external tools, it is necessary to configure the XMLA Endpoint settings to allow read-write access. Enabling large semantic model storage format focuses on optimizing data storage and performance rather than enabling write capabilities. Enabling read-only access in the XMLA Endpoint settings allows data consumption but does not permit write operations. Enabling incremental refresh aids in data management but does not directly enable write operations on semantic models.

*Ref: [Manage a Power BI semantic model using XMLA endpoint](https://learn.microsoft.com/en-us/power-bi/enterprise/service-premium-connect-tools) – Microsoft Learn*

---

### 57. Automate deployment for consistency – Deployment pipelines with REST APIs and autobinding

**Your organization uses Microsoft Fabric for data analytics, but the team struggles to maintain consistent semantic models across deployment stages due to manual updates causing discrepancies. You need to automate the deployment process to ensure consistency in semantic models across all stages. Which two actions should you take to achieve this goal? Each correct answer contributes to the solution.**

**Answer:** Implement deployment pipelines with REST APIs; Enable autobinding for deployment pipelines.

To ensure consistency in semantic models across deployment stages, implementing autobinding is essential as it maintains the necessary connections between models and reports, preventing errors from broken links. Implementing deployment pipelines with REST APIs in Microsoft Fabric further supports this goal by reducing manual errors and ensuring consistent deployments across stages. Creating separate models for each stage increases complexity without guaranteeing consistency. Using Fabric data pipelines to deploy across different stages does not provide the necessary support for maintaining connections between semantic models and reports. Using a single model for all stages can lead to conflicts and does not support stage-specific configurations.

*Ref: [Implement deployment pipelines](https://learn.microsoft.com/en-us/training/modules/implement-deployment-pipelines/) | [The deployment pipelines process](https://learn.microsoft.com/en-us/training/modules/the-deployment-pipelines-process/) – Microsoft Learn*

---

### 58. Copy data activity – Mandatory property on General tab

**You have a Fabric workspace that contains a lakehouse named Lakehouse1. You need to create a data pipeline and ingest data into Lakehouse1 by using the Copy data activity. Which properties on the General tab are mandatory for the activity?**

**Answer:** Name only.

For the Copy Data Activity, only the name must be defined on the General tab. All the other properties are optional.

*Ref: [Lakehouse tutorial - Ingest data into the lakehouse](https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-tutorial-ingest) – Microsoft Learn*

---

### 59. Eventhouse / KQL database – Enable other Fabric items to query (Connect to OneLake)

**You have a Fabric tenant that contains an eventhouse named Eventhouse1. Eventhouse1 contains a KQL database named Database1 that stores real-time data. You plan to use the Real-Time hub in Fabric to explore and use streaming data. You need to ensure that other Fabric items can query the streaming data in Database1. What should you do?**

**Answer:** Connect Database1 to OneLake.

You should connect Database1 to OneLake because this exposes the KQL database in Eventhouse1 as a shared, queryable data source across Microsoft Fabric. By making the database available in OneLake, other Fabric items such as data warehouses, Power BI, and pipelines can query the streaming data using supported interfaces, enabling cross-item analytics with minimal configuration. Creating pipelines or eventstreams focuses on data movement and ingestion rather than data accessibility, and alerts only monitor conditions without enabling other Fabric items to query the data.

*Ref: [Eventhouse OneLake Availability](https://learn.microsoft.com/en-us/fabric/real-time-analytics/eventhouse-onelake-availability) – Microsoft Learn*

---

### 60. Ingest 500M+ records from Azure SQL (no transformations) – Copy data activity

**You have a Fabric tenant that contains a lakehouse named Lakehouse1. You need to ingest data into Lakehouse1 from a large Azure SQL Database table that contains more than 500 million records. The data must be ingested without applying any additional transformations. The solution must minimize costs and administrative effort. What should you use to ingest the data?**

**Answer:** A pipeline with the Copy data activity.

When ingesting a large data source without applying transformations, the recommended method is to use the Copy data activity in pipelines. Notebooks are recommended for complex data transformations, whereas Dataflow Gen2 is suitable for smaller data and/or specific connectors.

*Ref: [Options to get data into the Lakehouse](https://learn.microsoft.com/en-us/fabric/data-engineering/ingest-data-lakehouse) | [Ingest data with Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/ingest-data-microsoft-fabric/) – Microsoft Learn*

---

### 61. Ingest from ADLS Gen2 (no transformations) – Copy activity

**You have a Fabric tenant that contains a lakehouse named Lakehouse1. You have forecast data stored in Azure Data Lake Storage Gen2. You plan to ingest the forecast data into Lakehouse1. The data is already formatted, and you do NOT need to apply any further data transformations. The solution must minimize development effort and costs. Which method should you recommend to efficiently ingest the data?**

**Answer:** Use the Copy activity in a pipeline.

The Copy data activity should be used when you must copy data directly between a supported source and a destination without applying any transformations. Dataflow Gen2 or Spark notebooks should be used when you must apply data transformations. Downloading data to your local computer and uploading it is inefficient and will incur unnecessary egress charges.

*Ref: [Use the Copy Data activity](https://learn.microsoft.com/en-us/training/modules/use-copy-data-activity/) – Microsoft Learn*

---

### 62. Star schema – Which columns in the fact table (ProductID, SalesAmount)

**You have a Microsoft Power BI report named Sales that uses a Microsoft Excel file as a data source. Data is imported as one flat table. The table contains the following columns: ProductID, ProductColor, ProductName, ProductCategory and SalesAmount. You need to create an optimal fact table data model by using a star schema. Which two columns should remain part of the new fact tables? Each correct answer presents part of the solution.**

**Answer:** ProductID; SalesAmount.

When designing a dimensional model, all the attributes that describe the business entity (in this case, a product is a business entity) should be stored in the dimension table, whereas the fact table should store observations or events. In a well-designed star schema, a fact table consists only of numeric measure columns and foreign keys to dimension tables (in this case ProductID is the foreign key).

*Ref: [Understand star schema and the importance for Power BI](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema) – Microsoft Learn*

---

### 63. Power Query Merge – Left outer join (Employee and Contract, preserve all Employee rows)

**You are designing a semantic model for a Microsoft Power BI report. You have a table named Employee that contains EmployeeID, EmployeeName, and EmployeePosition. You have a table named Contract that contains EmployeeID and ContractType. You plan to denormalize both tables and include the ContractType attribute. You need to ensure that all the rows in the Employee table are preserved and include any matching rows from the Contract table. Which type of join should you specify in the Power Query Merge queries transformation?**

**Answer:** Left outer.

A left outer join keeps all the rows from the left table (Employee) and brings any matching rows from the right table (Contract). A Left Anti Join will keep only rows from the left table and exclude any matching rows from the right table. An inner join brings only matching rows from both the left and right tables, while a cross join returns the Cartesian product of the rows in both tables.

*Ref: [Left outer join](https://learn.microsoft.com/en-us/power-query/merge-queries-left-outer) – Microsoft Learn*

---

### 64. PySpark – Add column (InvoiceYear from InvoiceDate) – withColumn

**You have a Fabric lakehouse that contains a Fabric notebook. The notebook contains a PySpark DataFrame with order data from a source system. The DataFrame contains a column named InvoiceDate. You need to add a column named InvoiceYear that will hold only the Year value of the InvoiceDate. Which PySpark method should you use?**

**Answer:** withColumn.

The method to add new columns to a DataFrame is withColumn.

*Ref: [Lakehouse tutorial - Prepare and transform data in the lakehouse](https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-tutorial-transform) – Microsoft Learn*

---

### 65. Dataflow Gen2 – Merge Product and ProductCategory (left outer, Product to ProductCategory)

**You have a Fabric warehouse. You have an Azure SQL database that contains two tables named ProductCategory and Product. Each table contains a column named ProductCategoryKey. You plan to ingest the tables into the warehouse using Dataflow Gen2. You need to merge the tables into a single table named Product. The combined table must contain all the rows from the Product table and the matching rows from the ProductCategory table. Which join configuration should you use?**

**Answer:** A left outer join Product to ProductCategory.

Only a left outer join from Product to ProductCategory will keep all the rows from Product but only matching rows from ProductCategory. The anti joins will only keep rows not found from the left table in the right table, and the left outer join from ProductCategory to Product will start with the ProductCategory table and only keep matching rows from the Product table.

*Ref: [Ingest Data with Dataflows Gen2 in Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/ingest-data-dataflows-gen2-microsoft-fabric/) | [Merge queries overview](https://learn.microsoft.com/en-us/power-query/merge-queries-overview) – Microsoft Learn*

---

### 66. Data Wrangler – Load Parquet to pandas DataFrame (read_parquet, File API path)

**You have a Parquet file named Customers.parquet uploaded to the Files section of a Fabric lakehouse. You plan to use Data Wrangler to view basic summary statistics for the data before you load it to a Delta table. You open a notebook in the lakehouse. You need to load the data to a pandas DataFrame. Which PySpark code should you run to complete the task?**

**Answer:** `import pandas as pd` and `df = pd.read_parquet("/lakehouse/default/Files/Customers.parquet")`.

To load data to a pandas DataFrame, you must first import the pandas library by running import pandas as pd. Pandas DataFrames use the File API Path vs. the File relative path that Spark uses. The File API Path has the format of lakehouse/default/Files/Customers.parquet.

*Ref: [Accelerate data prep with Data Wrangler](https://learn.microsoft.com/en-us/fabric/data-engineering/data-wrangler) – Microsoft Learn*

---

### 67. PySpark describe() – Functions for numeric data (COUNT, MEAN, STD)

**You are profiling the data stored in a Fabric lakehouse. You run the following statement: `df.describe().show()`. Which three functions will be included in the results for the numeric data? Each correct answer presents a complete solution.**

**Answer:** COUNT; MEAN; STD (standard deviation).

describe is used to generate descriptive statistics of the DataFrame. For numeric data, results include COUNT, MEAN, STD, MIN, and MAX, while for object data it will also include TOP, UNIQUE, and FREQ.

*Ref: [Explore and transform data in a lakehouse](https://learn.microsoft.com/en-us/training/modules/explore-transform-data-lakehouse/) – Microsoft Learn*

---

### 68. Dataflow Gen2 – Add column based on condition (High vs Regular by unit price) – Conditional column

**You have a Fabric workspace that contains a Microsoft Power BI report named Sales. You plan to use Dataflow Gen2 to add an additional column to the report. The new column must be based on the unit price of a product. Any product that has a unit price that is greater than $1,000 must be labeled as High, while any product that has a unit price that is less than $1,000 must be labeled as Regular. What should you select on the Add column tab in Power Query Editor?**

**Answer:** Conditional column.

The Conditional column option enables adding new columns whose values will be based on one or more conditions applied to the existing table columns.

*Ref: [Add a conditional column](https://learn.microsoft.com/en-us/power-query/add-conditional-column) – Microsoft Learn*

---

### 69. Identify rows where any column is NULL (isnull().any(axis=1))

**You have a Fabric lakehouse named Lakehouse1. You use a notebook in Lakehouse1 to explore customer data. You need to identify the rows of a DataFrame named df_customers in which any of the columns (axis 1 of the DataFrame) are NULL. Which statement should you run?**

**Answer:** `df_customers[df_customers.isnull().any(axis=1)]`

The isnull() method identifies which individual values are NULL. To see these individual values in context, you should filter the DataFrame to include only rows in which any of the columns (axis 1 of the DataFrame) are NULL.

*Ref: [Exercise - Explore data with NumPy and Pandas](https://learn.microsoft.com/en-us/training/modules/explore-data-numpy-pandas/) – Microsoft Learn*

---

### 70. Visual query editor – Summarize passengers by year (Merge then GroupBy)

**You have a Fabric warehouse that contains Trip (TripDateID, PassengerCount) and Date (DateID, Day, Month, Quarter, Year) tables. You plan to use the visual Query Editor in Warehouse explorer to write a SQL statement that summarizes the number of passengers by year. Which transformations should you use?**

**Answer:** Choose Merge queries to join Trip and Date, and then use GroupBy.

The Merge transformation joins two tables. The Append transformation performs an equivalent of a union in SQL. Once two tables are joined, you must select the required columns from the second table by clicking the Expand icon in front of the table in the result set. The final step can be achieved by using a GroupBy transformation.

*Ref: [Data warehouse tutorial - create a query with the visual query builder](https://learn.microsoft.com/en-us/fabric/data-warehouse/visual-query-editor) – Microsoft Learn*

---

### 71. Visual query editor – Top customers by sales (Add tables, identify key, Merge)

**Your company wants to analyze sales data in a Microsoft Fabric data warehouse. You decide to use the visual query editor for this task. You need to identify top customers by sales volume by combining data from 'Sales' and 'Customer' tables. Which three actions should you take to achieve this goal? Each correct answer contributes to the solution.**

**Answer:** Add 'Sales' and 'Customer' tables to canvas; Identify common key column in both tables; Merge tables using 'Merge queries as new'.

To effectively combine data from 'Sales' and 'Customer' tables, add the 'Sales' table to canvas to initiate the query process. Identify a common key column in both tables to ensure accurate data merging, allowing for correct table joining. Use 'Merge queries as new' to join tables based on this common key, facilitating comprehensive data analysis. Using 'Append queries' instead of 'Merge queries' is ineffective for merging data based on a common key, as it only adds rows. Using 'Save as view' before merging is unnecessary, as this action is typically performed after the query is complete.

*Ref: [Explore the visual query editor](https://learn.microsoft.com/en-us/training/modules/explore-visual-query-editor/) | [Explore Dataflows Gen2 in Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-dataflows-gen2-microsoft-fabric/) – Microsoft Learn*

---

### 72. Visual query editor – Merge CustomerData and TransactionData on CustomerID

**You use Microsoft Fabric for data warehousing. The marketing team wants to analyze customer purchase patterns. You need to combine customer data with transaction data using the visual query editor. Each correct answer presents part of the solution. Which two actions should you take?**

**Answer:** Add CustomerData and TransactionData tables; Merge CustomerData and TransactionData on CustomerID.

To merge customer data with transaction data using the visual query editor, you must first drag and drop the CustomerData and TransactionData tables onto the canvas to set up the query environment. Then, use the Merge queries as new operator to join these tables on CustomerID, which is essential for linking the datasets for analysis. Sorting customers by transaction date is not required for merging the datasets. Previewing TransactionData is not directly related to merging the datasets. Filtering CustomerData by purchase frequency is not necessary before merging, as the merge should be based on a common key like CustomerID.

*Ref: [Explore the visual query editor](https://learn.microsoft.com/en-us/training/modules/explore-visual-query-editor/) | [Explore Dataflows Gen2 in Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-dataflows-gen2-microsoft-fabric/) – Microsoft Learn*

---

### 73. Composite model – Storage modes (Import, DirectQuery, Dual) for aggregations

**You are developing a large semantic model. You have a fact table that contains 500 million rows. Most analytic queries will target aggregated data, but some users must still be able to view data on a detailed level. You plan to create a composite model and implement user-defined aggregations. Which three storage modes should you use for each type of table? Each correct answer presents part of the solution.**

**Answer:** Aggregated tables should use Import mode; The detailed fact table should use DirectQuery mode; Dimension tables should use Dual mode.

When using user-defined aggregations, the detailed fact table must be in DirectQuery mode. It is recommended to set the storage mode to Import for aggregated tables because of the performance, while dimension tables should be set to Dual mode to avoid the limitations of limited relationships.

*Ref: [User-defined aggregations](https://learn.microsoft.com/en-us/power-bi/transform-model/aggregations-auto) – Microsoft Learn*

---

### 74. Semantic model ~50 GB – Enable refresh (Large semantic model storage format)

**You have a Fabric tenant that contains a workspace named Workspace1. Workspace1 is assigned to an F64 Fabric capacity and contains a warehouse. You are working on a custom Microsoft Power BI semantic model that sources data from the warehouse tables. You apply optimization best practices to reduce the model size. You estimate that once the model is published to the Power BI service and fully loaded, it will approach 50 GB. Which option should you configure for the semantic model to enable the semantic model to refresh in the Power BI service?**

**Answer:** Large semantic model storage format.

The large semantic model storage format can be enabled from the Power BI service from the semantic model settings. It will allow data to grow beyond the 10-GB limit for Power BI premium capacities or Fabric capacities of F64 or higher. The other options do not change the default limit of 10 GB after compression.

*Ref: [Design scalable semantic models](https://learn.microsoft.com/en-us/power-bi/guidance/model-scaling) – Microsoft Learn*

---

### 75. Many time intelligence calculations across 50 measures – Calculation group

**You are designing a Microsoft Power BI semantic model that will contain 50 different measures, such as Sales Amount, Order Quantity, and Refund Amount. For each measure, you need to create the same set of time intelligence calculations such as month-to-date, year-to-date, and year-over-year change. The solution must minimize administrative effort. What should you do?**

**Answer:** Create a calculation group.

Calculation groups are an efficient way to reduce the number of measures in the semantic model by grouping common measure expressions. The main benefit of using calculation groups is to reduce the overall number of measures that must be created and maintained.

*Ref: [Design scalable semantic models](https://learn.microsoft.com/en-us/power-bi/guidance/model-scaling) – Microsoft Learn*

---

### 76. Confirm queries use aggregated data – DAX Studio and SQL Server Profiler

**You are developing a large Microsoft Power BI semantic model that will contain a fact table. The table will contain 400 million rows. You plan to leverage user-defined aggregations to speed up the performance of the most frequently run queries. You need to confirm that the queries are mapped to aggregated data in the tables. Which two tools should you use? Each correct answer presents part of the solution.**

**Answer:** DAX Studio; SQL Server Profiler.

SQL Server Profiler and DAX Studio can detect whether queries were returned from the in-memory cache storage engine or pushed by DirectQuery to the data source.

*Ref: [User-defined aggregations](https://learn.microsoft.com/en-us/power-bi/transform-model/aggregations-auto) – Microsoft Learn*

---

### 77. Reduce DirectQuery requests – Apply buttons on filters

**You have an Azure SQL database. You have a Microsoft Power BI report connected to a semantic model that uses a DirectQuery connection to the database. You need to reduce the number of queries sent to the database when a user is interacting with the report by using filters and/or slicers. What should you do?**

**Answer:** Add apply buttons to all the basic filters.

Adding apply buttons will pause all requests to the Azure SQL database until you finalize your filter and/or slicer selections. Then a single request can be sent once the apply button is selected. The other options will not change the number of unique query requests sent to the database.

*Ref: [Create Apply all and Clear all slicers buttons in reports](https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-slicer-filter-introduction) | [DirectQuery optimization scenarios with the Optimize ribbon in Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-directquery-optimization) – Microsoft Learn*

---

### 78. Identify columns that contribute most to model size – DAX Studio

**You are working with a large semantic model. You need to identify which columns have contributed the most to the model size so that you can focus design efforts on either removing them from the model or reducing their cardinality. Which external tool can you use to get information about the size of each table and column in a model?**

**Answer:** DAX Studio.

DAX Studio can connect to a model in Microsoft Power BI Desktop or the Power BI service and provide statistics on the table sizes and each column. The other external tools listed have different use cases and do not provide the statistics needed.

*Ref: [External tools in Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-external-tools) – Microsoft Learn*

---

### 79. DAX performance – Filter on dimension (Calendar[Year]) vs fact table

**You have a semantic model that contains a Calendar Dimension table and a Sales fact table. The tables have a 1-to-many relationship. From DAX Studio, you discover a DAX measure that is performing slowly against the model. You plan to modify a filter in the measure to improve performance. Which measure provides the best performance for the model?**

**Answer:** `CALCULATE( [Sales], Calendar[Year] = 2023 )`

Filtering on the Calendar Dimension table will almost always perform faster than filtering directly on any fact table, as that requires more processing by both the DAX formula and the storage engine.

*Ref: [Avoid using FILTER as a filter argument in DAX](https://learn.microsoft.com/en-us/dax/avoid-filter-as-filter-argument) – Microsoft Learn*

---

### 80. Optimize lakehouse tables for Direct Lake – OPTIMIZE to apply V-Order

**You are managing a set of Dataflow Gen2 queries that are currently ingesting tables into a Fabric lakehouse. You need to ensure that the tables are optimized for Direct Lake connections that will be used by connected semantic models. What should you do?**

**Answer:** Use OPTIMIZE to apply V-Order.

Each table in a lakehouse has a setting that must be turned on to optimize and apply the V-Order, which will greatly increase the Direct Lake speeds when connecting to these tables.

*Ref: [Delta Lake table optimization and V-Order](https://learn.microsoft.com/en-us/fabric/data-engineering/delta-lake-optimization-v-order) – Microsoft Learn*

---

### 81. Dataflow timeout – Staging dataflow then transform dataflow

**You have a Fabric workspace that contains a lakehouse named Lakehouse1. Lakehouse1 contains a table named FactSales that is ingested by using a Dataflow Gen2 query. There are several applied steps and transformations applied to FactSales during the ingestion process. You notice that due to the number of Power Query transformations, there are occasional timeout issues for the dataflow. You need to recommend a solution to prevent the timeout issues. You have already confirmed that the query cannot be further optimized and that changing the refresh time does not improve the timeout issues. Which additional action should you recommend?**

**Answer:** Create a second dataflow that ingests the FactSales table with no additional transformations, and then connect the original dataflow to transform the FactSales data by using this second dataflow.

It is considered best practice to create a staging first dataflow that ingests the raw data first, and then a second dataflow to transform the data, commonly applied when there are performance or timeout issues for a query.

*Ref: [Best practices for designing and developing complex dataflows](https://learn.microsoft.com/en-us/power-query/best-practices-complex-dataflows) – Microsoft Learn*

---

### 82. Lakehouse – User1 read-only SQL only, no access to other workspace items or Spark

**You have a Fabric tenant that contains a workspace named Workspace1. Workspace1 contains a lakehouse, a data pipeline, a notebook, and several Microsoft Power BI reports. A user named User1 plans to use SQL to access the lakehouse to analyze data. User1 must have: read-only access to the lakehouse; must NOT be able to access the rest of the items in Workspace1; must NOT be able to use Spark to query the underlying files in the lakehouse. You need to configure access for User1. What should you do?**

**Answer:** Share the lakehouse with User1 directly and select Read all SQL Endpoint data.

Since the user only needs access to the lakehouse and not the other items in the workspace, you should share the lakehouse directly and select Read all SQL Endpoint data. The user should not be added as a member of the workspace. All members of the workspace, even viewers, will be able to open all Power BI reports in the workspace. The SQL analytics endpoint itself cannot be shared directly; the Share options only show for the lakehouse.

*Ref: [Lakehouse sharing and permission management](https://learn.microsoft.com/en-us/fabric/onelake/onelake-security) – Microsoft Learn*

---

### 83. Share reports with external partners – RLS, fixed identity, Power BI app

**Your company uses Microsoft Fabric to manage data analytics solutions. The marketing department needs to share reports with external partners. You need to ensure that reports can be shared with external partners without compromising sensitive data. Each correct answer presents part of the solution. Which three actions should you take?**

**Answer:** Implement row-level security; Set data source credentials to a fixed identity; Configure a Power BI app.

Implementing row-level security is crucial for controlling data visibility based on user identity. Switching to a fixed identity ensures that external partners have access to the necessary data without exposing sensitive information. Using Power BI apps enables secure sharing of reports with external partners. Assigning a viewer role allows external partners to view reports without modification access, aligning with the goal of secure sharing. Restricting workspace sharing settings does not directly address the need for secure sharing with external partners. Sharing reports via email attachments can lead to data security issues and unauthorized access.

*Ref: [Enable and use Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/enable-use-microsoft-fabric/) | [Manage Fabric security](https://learn.microsoft.com/en-us/training/modules/manage-fabric-security/) – Microsoft Learn*

---

### 84. Limit data access by user roles in warehouse – Column-level and row-level security

**Your organization uses Microsoft Fabric for data analytics. The team must protect sensitive data in a Fabric data warehouse from unauthorized access. You need to limit data access based on different user roles. Which two actions should you take to achieve this solution?**

**Answer:** Implement column-level security; Implement row-level security.

To effectively limit data visibility based on user roles, implementing both row-level and column-level security is essential. Row-level security ensures that users can only access specific rows they are authorized to view, while column-level security restricts access to sensitive columns, thereby protecting critical information. Setting up item-level permissions provides more specific access control than workspace roles but lacks the necessary granularity for row and column-level restrictions. Assigning workspace roles does not address the need for role-based access control at the row or column level. Dynamic data masking, although useful for obscuring sensitive data, does not fulfill the requirement of restricting access based on user roles.

*Ref: [Explore end-to-end analytics with Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-end-to-end-analytics-microsoft-fabric/) | [Secure a Microsoft Fabric data warehouse](https://learn.microsoft.com/en-us/training/modules/secure-microsoft-fabric-data-warehouse/) – Microsoft Learn*

---

### 85. Code-rich high-throughput ingestion from Azure storage into warehouse – COPY (T-SQL)

**Your organization is using Microsoft Fabric to manage data analytics and needs to ingest data from multiple Microsoft Azure storage accounts. You need to select a method for code-rich data ingestion with high throughput into a Fabric data warehouse. What should you use?**

**Answer:** COPY (T-SQL) statement.

The COPY (Transact-SQL) statement is specifically designed for code-rich data ingestion with high throughput, making it the most suitable choice for this scenario. Eventstreams, while capable of real-time data ingestion, are not specifically designed for high-throughput code-rich data ingestion into a warehouse. Data pipelines, while capable of handling large volumes of data, are more suited for code-free or low-code scenarios and do not meet the high-throughput requirement. Similarly, Dataflows Gen2 are intended for data preparation and transformation, lacking the necessary support for high-throughput ingestion into a warehouse.

*Ref: [Load data using T-SQL](https://learn.microsoft.com/en-us/training/modules/load-data-using-tsql/) | [Use the Copy Data activity](https://learn.microsoft.com/en-us/training/modules/use-copy-data-activity/) – Microsoft Learn*

---

### 86. Dataflow Gen2 – Language for transforming data (M)

**You have a Fabric tenant that contains a lakehouse named Lakehouse1. You plan to use Dataflow Gen2 to ingest and transform data from an Azure SQL Database into Lakehouse1. Which language should you use to transform the data in the dataflow?**

**Answer:** M.

When ingesting data by using Dataflow Gen2, you get the same surface area as in Microsoft Power Query. This assumes that you will use the M language for data manipulation, no matter which data source you are connecting to.

*Ref: [Explore Dataflows (Gen2) in Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/explore-dataflows-gen2-microsoft-fabric/) | [What is Power Query?](https://learn.microsoft.com/en-us/power-query/power-query-overview) – Microsoft Learn*

---

### 87. SQL – Customers who have not placed an order (LEFT JOIN WHERE order_id IS NULL)

**You have a Fabric warehouse that contains a table named customer_info (customer_id, name, email, join_date) and a table named order_info (order_id, customer_id, order_total, order_date). You need to write a SQL query that returns all the customers who have not yet placed an order (purchased). Which SQL query should you run?**

**Answer:** `SELECT name FROM customer_info LEFT JOIN order_info ON customer_info.customer_id = order_info.customer_id WHERE order_info.order_id IS NULL`

The SQL statement returns only customers for whom the customer_id was not found in the order_info table. The WHERE clause order_info.order_id IS NULL means that the customers have no orders found in the order_info table. An INNER JOIN or WHERE customer_id IN (SELECT customer_id FROM order_info) would return only customers who made purchases.

*Ref: [Joins (SQL Server)](https://learn.microsoft.com/en-us/sql/relational-databases/performance/joins) – Microsoft Learn*

---

### 88. Incremental refresh – Bootstrap initial full load (create partitions without processing) – Tabular Editor

**You have a Fabric tenant that contains a workspace named Workspace1. Workspace1 contains a warehouse named Warehouse1. Warehouse1 contains a table named Orders that contains 20 years of historical order data. You create a Microsoft Power BI semantic model from the Orders table. In Power BI Desktop, you enable incremental refresh for the table and load only one week's worth of data. You publish the semantic model to Workspace1. Due to the size of the semantic model, you need to bootstrap the initial full load. What can you use to create the partitions in the Power BI service without processing them?**

**Answer:** Tabular Editor.

You can use Tabular Editor to run an Apply Refresh Policy command on a table that has an incremental refresh policy defined in Power BI Desktop. This will create the partitions based on the policy but does not process them. This method is useful when working with very large datasets where the initial full load can take many hours.

*Ref: [Advanced incremental refresh and real-time data with the XMLA endpoint in Power BI](https://learn.microsoft.com/en-us/power-bi/connect-data/incremental-refresh-xmla-endpoint) – Microsoft Learn*

---

### 89. Migrate 200M rows from Snowflake to lakehouse – Fastest method (Data Pipeline Copy data)

**You have a Fabric tenant that contains a lakehouse named Lakehouse1. You have an external Snowflake database that contains a table with 200 million rows. You need to use a data pipeline to migrate the database to Lakehouse1. What is the most performant (fastest) method for ingesting data this large (200 million rows) by using a data pipeline?**

**Answer:** Data Pipeline (Copy data).

Copy data is the fastest and most direct method for migrating data from one system to another, with no transformations applied.

*Ref: [Ingest data with Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/ingest-data-microsoft-fabric/) | [How to copy data using copy activity](https://learn.microsoft.com/en-us/fabric/data-factory/copy-data-activity) – Microsoft Learn*

---

### 90. Ingest 1 TB into warehouse – Highest throughput, low-code (Copy data activity)

**You have a Fabric tenant that contains a warehouse named Warehouse1. You have a large 1 TB dataset in an external data source. You need to recommend a method to ingest the dataset into Warehouse1. The solution must provide the highest throughput and support a low-code/no-code development model. What should you recommend?**

**Answer:** Copy data activity.

The Copy data activity provides the highest throughput data ingestion and is considered low-code/no-code. Dataflow Gen2 is a great tool for transformations; however, for large data ingestions without any transformations, the Copy data activity performs best. Shortcuts do not move data. Spark notebooks are considered code-first.

*Ref: [Ingesting data into the warehouse](https://learn.microsoft.com/en-us/fabric/data-warehouse/ingest-data) | [Ingest data with Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/ingest-data-microsoft-fabric/) – Microsoft Learn*

---

### 91. Schedule notebook daily at 7:00 AM – Configure schedule on pipeline

**You have a Fabric tenant that contains a lakehouse named Lakehouse1. A notebook named Notebook1 is used to ingest and transform data from an external data source named Externaldata1 into Lakehouse1. You create a pipeline named Pipeline1 and add Notebook1. You need to configure a schedule that runs the process daily at 7:00 AM. On which object should you configure the schedule?**

**Answer:** Pipeline1.

The schedule is configured on Pipeline1. There is no option to specify retries when scheduling notebooks directly from Notebook settings.

*Ref: [Data pipeline runs](https://learn.microsoft.com/en-us/fabric/data-factory/pipeline-runs) | [Use Data Factory pipelines in Microsoft Fabric](https://learn.microsoft.com/en-us/training/modules/use-data-factory-pipelines-fabric/) – Microsoft Learn*

---

### 92. Eventhouse – Other Fabric items query streaming data – Connect KQL database to OneLake

**You have a Fabric tenant that contains a workspace named Workspace1. Workspace1 contains an eventhouse named Eventhouse1. Eventhouse1 contains a KQL database named Database1 that stores real-time data. You plan to use the Real-Time hub in Fabric to explore and use streaming data. You need to ensure that other Fabric items can query the streaming data in Database1. What should you do?**

**Answer:** Connect Database1 to OneLake.

Connect Database1 to OneLake because this exposes the KQL database in Eventhouse1 as a shared, queryable data source across Microsoft Fabric. By making the database available in OneLake, other Fabric items such as data warehouses, Power BI, and pipelines can query the streaming data using supported interfaces. Creating pipelines or eventstreams focuses on data movement and ingestion rather than data accessibility.

*Ref: [Eventhouse OneLake availability](https://learn.microsoft.com/en-us/fabric/real-analytics/eventhouse-onelake-availability) – Microsoft Learn*

---

### 93. Legacy accounting data in ADLS (1 TB, queried once a year) + sales data – Lakehouse with shortcut to legacy, ingest sales into lakehouse

**You have a Fabric tenant. Your company has 1 TB of legacy accounting data stored in an Azure Data Lake Storage Gen2 account. The data is queried only once a year for a few ad-hoc reports that submit very selective queries. You plan to create a Fabric lakehouse or warehouse to store company sales data. Developers must be able to build reports from the lakehouse or warehouse based on the sales data and do ad-hoc analysis of the legacy data at the end of each year. You need to recommend which Fabric architecture to create and the process for integrating the accounting data into Fabric. The solution must minimize administrative effort and costs. What should you recommend?**

**Answer:** Ingest the sales data into the Fabric lakehouse and set up a shortcut to the legacy accounting data in the storage account.

Since the legacy accounting data is only accessed once a year for a few ad-hoc queries that are highly selective, there is no need to move the data into a Fabric workspace. Shortcuts enable the querying of remote data without having to move the data. Shortcuts are only supported in a Fabric lakehouse. Using a shortcut minimizes cost and administrative effort compared to copying the legacy data.

*Ref: [OneLake shortcuts](https://learn.microsoft.com/en-us/fabric/onelake/onelake-shortcuts) – Microsoft Learn*

---

### 94. T-SQL Ranking – Ties then next rank increments by one – DENSE_RANK()

**You have a Fabric warehouse. You are writing a T-SQL statement to retrieve data from a table named Sales to display the highest sales amount for specific customers. You use a ranking function with OVER(ORDER BY SalesAmount DESC) and need to ensure that after ties for SalesAmount, the next Sales amount increments the Ranking value by one (e.g. 1, 1, 2). Which function should you use?**

**Answer:** DENSE_RANK().

DENSE_RANK() returns the rank of each row within the result set partition, with no gaps in the ranking values. The RANK() function includes gaps in the ranking (e.g. 1, 1, 3). ROW_NUMBER() assigns a unique number to each row and does not assign the same rank to ties.

*Ref: [Ranking Functions (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/ranking-functions-transact-sql) – Microsoft Learn*

---

### 95. SQL – Latest last_stocked_date per category where stock_quantity < 50

**You have an Azure SQL database that contains a table named inventory with columns: item_id, category, stock_quantity, last_stocked_date. You need to write a SQL statement that retrieves the latest last_stocked_date for each category, for which stock_quantity is less than 50. Which SQL statement should you run?**

**Answer:** `SELECT category, MAX(last_stocked_date) FROM inventory WHERE stock_quantity < 50 GROUP BY category`

This correctly returns the latest stock date per category for rows where quantity is less than 50. SELECT DISTINCT category, last_stocked_date with ORDER BY would return all dates per category, not the maximum per category. Filtering with HAVING MIN(stock_quantity) applies at the category level, not row level. LIMIT 1 would return only a single record overall.

*Ref: [WHERE (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/queries/where-transact-sql) | [GROUP BY (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/queries/select-group-by-transact-sql) – Microsoft Learn*

---

### 96. Incremental refresh – Required parameters (RangeStart and RangeEnd)

**You have a Fabric tenant that contains a workspace named Workspace1. Workspace1 contains a warehouse that has a table named Orders. You have a Microsoft Power BI semantic model in Power BI Desktop that sources data from the Orders table. You need to enable incremental refresh for the table. Which two parameters should you create?**

**Answer:** RangeStart and RangeEnd.

Incremental refresh looks for the following two parameters that are reserved keywords and case sensitive: RangeStart and RangeEnd.

*Ref: [Configure incremental refresh and real-time data for Power BI semantic models](https://learn.microsoft.com/en-us/power-bi/connect-data/incremental-refresh-overview) – Microsoft Learn*

---

## Additional questions (coverage gaps)

These questions target DP-600 skills that have little or no coverage in the Microsoft Learn practice assessment above. Use them to round out your study.

---

### A1. Endorse items – Promoted vs Certified vs Master Data

**Your organization uses Microsoft Fabric. You need to help users find trusted, organization-approved semantic models and lakehouses. Which endorsement type signifies that an organization-authorized reviewer has verified the item meets quality standards and is ready for organization-wide use?**

**Answer:** Certified.

**Certified** means an organization-authorized reviewer has verified the item; only administrator-designated reviewers can certify. **Promoted** indicates the creator believes the content is ready for sharing (any user with write permissions can promote). **Master Data** designates data as authoritative single-source-of-truth; only administrator-authorized users can apply it. Certification and Master Data must be enabled by Fabric administrators.

*Ref: [Endorse Fabric and Power BI items](https://learn.microsoft.com/en-us/fabric/fundamentals/endorsement-promote-certify) | [Endorsement overview](https://learn.microsoft.com/en-us/fabric/governance/endorsement-overview) – Microsoft Learn*

---

### A2. Reusable assets – Power BI data source (.pbids) file

**You want report creators to connect to a Fabric warehouse without entering server or database details. You need to provide a reusable asset that pre-configures the connection so users can open it and authenticate. What should you create?**

**Answer:** A Power BI data source (.pbids) file.

A **.pbids** (Power BI Data Source) file is a JSON file that pre-configures connection details (e.g., server, database) so users get a connection shortcut when they open it; users still authenticate individually. A .pbit file is a Power BI template that packages a report with or without data, not a connection-only asset. A shared semantic model is a published model others connect to live, not a file for pre-configuring connections.

*Ref: [Connect to data sources in Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-connect-to-data) – Microsoft Learn*

---

### A3. Reusable assets – Power BI template (.pbit) and shared semantic model

**You need to let other teams reuse a report layout and structure with their own data sources. Which two options can help achieve this? Each correct answer presents part of the solution.**

**Answer:** Create a Power BI template (.pbit) file; Publish the semantic model and have report creators use a live connection to the shared semantic model.

A **.pbit** (Power BI template) saves the report structure and optional sample data so others can open it and point to their own data. A **shared semantic model** (published to a workspace or hub) lets report creators build reports with a live connection to the same model without copying it. .pbids files only pre-configure data source connections, not full report layout.

*Ref: [Create reusable assets](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-templates) – Microsoft Learn*

---

### A4. Discover data – OneLake catalog (data hub)

**Users need to find and browse lakehouses, warehouses, and semantic models across multiple workspaces in your Fabric tenant. Where should you direct them to discover and explore these assets centrally?**

**Answer:** The OneLake data hub (OneLake catalog).

The **OneLake data hub** (OneLake catalog) is the central place in Fabric to discover, browse, and explore data items (e.g., lakehouses, warehouses, semantic models) across the organization. It provides an Explore tab with filters and details. Individual workspace item lists are per-workspace only. The Real-Time hub is for streaming and event data discovery, not all asset types.

*Ref: [Discover Fabric content in the OneLake data hub](https://learn.microsoft.com/en-us/fabric/get-started/onelake-data-hub) | [OneLake catalog overview](https://learn.microsoft.com/en-us/fabric/governance/onelake-catalog-overview) – Microsoft Learn*

---

### A5. Prepare data – Warehouse stored procedures and functions

**In a Fabric warehouse, you need to encapsulate logic that runs a set of T-SQL statements (e.g., to update a table or run multiple steps) and can be invoked by applications or other processes. Which object should you create?**

**Answer:** A stored procedure.

In a Fabric warehouse, **stored procedures** encapsulate one or more T-SQL statements and can be executed by callers; they are used for operational logic, updates, or multi-step processes. **Views** and **table-valued functions** return result sets and are used for querying, not for running imperative logic. Dataflows are for ETL in the Fabric service, not warehouse objects.

*Ref: [Data warehousing in Microsoft Fabric](https://learn.microsoft.com/en-us/fabric/data-warehouse/data-warehousing) – Microsoft Learn*

---

### A6. Semantic model – Bridge table (many-to-many)

**You have a semantic model with a Sales fact table, a Product dimension, and a Customer dimension. Products can belong to many Categories, and Categories have many Products. You need to model this many-to-many relationship between Product and Category so that Sales can be analyzed by Category. What should you implement?**

**Answer:** A bridge table (e.g., ProductCategory) that links Product and Category, and relationships from the fact table to the bridge or dimension so the model can filter correctly.

A **bridge table** (e.g., ProductKey–CategoryKey) resolves many-to-many relationships between dimensions. You create the bridge table, relate Product to it and Category to it (or use a single dimension with a bridge), and ensure relationships and filter direction allow correct filtering (e.g., Category → Bridge ← Product, with Sales related to Product). A single direct many-to-many between Product and Category without a bridge can make filtering and DAX more error-prone. Role-playing dimensions are for multiple roles of the same dimension (e.g., Order Date vs Ship Date), not many-to-many.

*Ref: [Model many-to-many relationships](https://learn.microsoft.com/en-us/power-bi/transform-model/relationships-many-to-many) | [Star schema and relationships](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema) – Microsoft Learn*

---

### A7. Semantic model – Dynamic format strings (DAX)

**You have a measure that can return currency, percentage, or count depending on a user selection. You want the visual to format the value automatically (e.g., $ for currency, % for percentage) without creating separate measures for each format. Which DAX feature should you use?**

**Answer:** Dynamic format strings (e.g., using FORMAT or a calculation group with dynamic format string expression).

**Dynamic format strings** let a measure or calculation group define the display format at query time (e.g., based on selected field or measure). You can use the **FORMAT** function in a measure or, for reuse across many measures, a **calculation group** with a format string expression that returns the appropriate format. Field parameters control which field is shown, not the numeric format. Static format strings are fixed per measure.

*Ref: [Dynamic format strings](https://learn.microsoft.com/en-us/power-bi/transform-model/calculation-groups-dynamic-format-strings) – Microsoft Learn*

---

### A8. Direct Lake – OneLake vs SQL endpoint (fallback and choice)

**You are designing a Direct Lake semantic model in Fabric. You need to support a composite model that mixes Direct Lake tables with Import tables and you do not want to depend on the lakehouse SQL analytics endpoint or DirectQuery fallback. Which Direct Lake option should you use?**

**Answer:** Direct Lake on OneLake.

**Direct Lake on OneLake** reads Delta tables directly via OneLake, does not depend on the SQL analytics endpoint, and supports multi-source and composite models (e.g., Direct Lake plus Import) without the DirectQuery fallback limitations of the SQL endpoint. **Direct Lake on SQL** uses the lakehouse SQL endpoint for discovery and permissions and can fall back to DirectQuery when needed; it is single-source and subject to DirectQuery restrictions. For new development and composite models without fallback, Direct Lake on OneLake is the recommended option.

*Ref: [Direct Lake in Power BI Desktop](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-power-bi-desktop) | [Direct Lake guidance](https://learn.microsoft.com/en-us/power-bi/connect-data/directlake-overview) – Microsoft Learn*

---

### A9. Direct Lake – Fallback and refresh behavior

**A semantic model uses Direct Lake over the lakehouse SQL endpoint. When Direct Lake cannot load a table (e.g., due to an unsupported operation or view), what typically happens?**

**Answer:** The table falls back to DirectQuery so the report can still run, subject to DirectQuery limitations.

With **Direct Lake over the SQL endpoint**, tables that cannot be served in Direct Lake mode (e.g., based on views or unsupported features) **fall back to DirectQuery**, so the report continues to work but is subject to DirectQuery performance and modeling restrictions. With Direct Lake on OneLake, there is no DirectQuery fallback (Direct Lake or error). Understanding fallback and refresh behavior is part of configuring and optimizing Direct Lake semantic models.

*Ref: [Direct Lake in Power BI Desktop](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-power-bi-desktop) | [Learn about Direct Lake](https://learn.microsoft.com/en-us/power-bi/connect-data/directlake-overview) – Microsoft Learn*

---

### A10. Prepare data – Convert column data types (Power Query)

**In a Dataflow Gen2 or Power Query report query, you have a column that was loaded as text but should be used as whole numbers for calculations. You need to change the column type so downstream steps and the semantic model treat it as integer. What should you do?**

**Answer:** Change the column type to Whole Number in Power Query (or use a transformation that converts the column to integer).

In **Power Query**, use **Change Type** (e.g., to Whole Number) or a transformation such as **Number.From** or **Value.From** so the column is treated as integer; the data type is then applied when the query runs and is reflected in the loaded model. Adding a calculated column in the semantic model does not change the source column type. Renaming or splitting the column does not convert data types.

*Ref: [Power Query – Data types](https://learn.microsoft.com/en-us/power-query/power-query-data-types) – Microsoft Learn*

---

## References

- [Practice Assessment for Exam DP-600](https://learn.microsoft.com/en-us/credentials/certifications/exams/dp-600/practice/assessment) – Microsoft Learn  
- [Exam DP-600 study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/dp-600) – Microsoft Learn  
- [Fabric Analytics Engineer Associate certification](https://learn.microsoft.com/en-us/credentials/certifications/fabric-analytics-engineer-associate/) – Microsoft Learn
