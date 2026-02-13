# Semantic Layer Analysis: Reverse Engineering Power BI Models

## Overview

This guide demonstrates how to use **Tabular Editor** and **DAX Studio** to extract comprehensive metadata, data dictionary, and performance metrics from Power BI files (.pbix) and semantic models. This analysis is critical for:

- **Reverse engineering** existing semantic models
- **Documenting** current implementations
- **Performance analysis** to identify optimization opportunities
- **Migration planning** to Fabric Direct Lake semantic models
- **Architectural alignment** with Fabric T0-T5 data warehouse patterns

**Tools Required:**
- Tabular Editor 3 (free or paid version)
- DAX Studio (free)
- Power BI Desktop (for .pbix files)
- Excel (for viewing exported data dictionary)

---

## Part 1: Tabular Editor - Metadata & Data Dictionary Extraction

### 1.1 Installation & Setup

1. **Download Tabular Editor 3**: https://github.com/TabularEditor/TabularEditor3/releases
2. **Install** Tabular Editor 3 (free version is sufficient for metadata extraction)
3. **Connect** to your Power BI semantic model:
   - **Option A**: Connect to live Power BI service model
     - File → Open → From DB → Azure Analysis Services / Power BI
     - Enter workspace URL and model name
   - **Option B**: Open from .pbix file
     - Extract .pbix to folder (rename .pbix to .zip, extract)
     - Open `DataModelSchema` file in Tabular Editor
   - **Option C**: Connect to Power BI Desktop (if running)
     - File → Open → From DB → Analysis Services
     - Server: `localhost:xxxxx` (port shown in Power BI Desktop)

### 1.2 Data Dictionary Export Script

Use the provided C# script to export comprehensive metadata to Excel:

**Script Features:**
- Exports 5 sheets: Model Objects, Relationships, RLS Rules, Data Sources, Partitions
- Captures DAX expressions, M queries, descriptions, data types
- Includes hidden objects and calculation groups
- Generates tab-delimited text and Excel formats

**Usage:**

1. **Open Tabular Editor** and connect to your model
2. **Verify model name**: Model → Database → Name (must not be "SemanticModel")
3. **Open C# Script Editor**: Advanced Scripting → New C# Script
4. **Paste the script** (provided below)
5. **Configure file path**:
   ```csharp
   string filePath = @"C:\Users\jharker\Documents\DataDictionary";
   ```
6. **Execute**: Click Run (F5)
7. **Review output**: Excel file will be created with 5 sheets

**Complete Script:**

```csharp
#r "System.IO"
#r "Microsoft.Office.Interop.Excel"

using System.IO;
using Excel = Microsoft.Office.Interop.Excel;

// ============================================================================
// CONFIGURATION
// ============================================================================
string filePath = @"C:\Users\jharker\Documents\DataDictionary";
bool dataSourceM = false; // Set this to true if you want the data source to use M
string excelFilePath = filePath + ".xlsx"; 
string textFilePath = filePath + ".txt";
string modelName = Model.Database.Name;

// ============================================================================
// VALIDATION
// ============================================================================
if (modelName == "SemanticModel")
{
    Error("Please name your model in the properties window: Model -> Database -> Name");
    return;
}

// ============================================================================
// SHEET 1: TABLES, COLUMNS, MEASURES, HIERARCHIES
// ============================================================================
var sbMain = new System.Text.StringBuilder();
string[] colNameMain = { "Model","Table","Object Type","Object","Hidden Flag","Description","Display Folder","Formula/Expression","Format String","Data Type" };
int colNameMainCount = colNameMain.Length;
string newline = Environment.NewLine;

// Add headers
for (int i=0; i < colNameMainCount; i++)
{
    if (i<colNameMainCount-1)
    {
        sbMain.Append(colNameMain[i] + '\t');
    }
    else
    {
        sbMain.Append(colNameMain[i] + newline);
    }
}

// Extract model metadata
foreach (var t in Model.Tables.Where(a => a.ObjectType.ToString() != "CalculationGroupTable").OrderBy(a => a.Name).ToList())
{
    string tableName = t.Name;
    string tableDesc = (t.Description ?? "").Replace("'","''");
    string objectType = "Table";
    string hiddenFlag;                 
    string expr;
    string formatStr = "";
    string dataType = "";

    if (t.IsHidden)
    {
        hiddenFlag = "Yes";
    }
    else
    {
        hiddenFlag = "No";
    }
    
    if (t.SourceType.ToString() == "Calculated")
    {
        expr = (Model.Tables[tableName] as CalculatedTable).Expression;
        expr = expr.Replace("\n"," ").Replace("\r"," ").Replace("\t"," ");
        sbMain.Append(modelName + '\t' + tableName + '\t' + objectType + '\t' + tableName + '\t' + hiddenFlag + '\t' + tableDesc + '\t' + " " + '\t' + expr + '\t' + formatStr + '\t' + dataType + newline);
    }
    else
    {
        sbMain.Append(modelName + '\t' + tableName + '\t' + objectType + '\t' + tableName + '\t' + hiddenFlag + '\t' + tableDesc + '\t' + " " + '\t' + "***N/A***" + '\t' + formatStr + '\t' + dataType + newline);
    }
    
    // Columns
    foreach (var o in t.Columns.OrderBy(a => a.Name).ToList())
    {
        string objectName = o.Name;
        string objectDesc = (o.Description ?? "").Replace("'","''");
        string objectDF = o.DisplayFolder ?? "";
        objectType = "Attribute";
        dataType = o.DataType.ToString();
        
        if (o.IsHidden)
        {
            hiddenFlag = "Yes";
        }
        else
        {
            hiddenFlag = "No";
        }
        
        if (o.Type.ToString() == "Calculated")
        {
            expr = (Model.Tables[tableName].Columns[objectName] as CalculatedColumn).Expression;
            expr = expr.Replace("\n"," ").Replace("\r"," ").Replace("\t"," ");
            sbMain.Append(modelName + '\t' + tableName + '\t' + objectType + '\t' + objectName + '\t' + hiddenFlag + '\t' + objectDesc + '\t' + objectDF + '\t' + expr + '\t' + formatStr + '\t' + dataType + newline);        
        }
        else
        {
            sbMain.Append(modelName + '\t' + tableName + '\t' + objectType + '\t' + objectName + '\t' + hiddenFlag + '\t' + objectDesc + '\t' + objectDF + '\t' + "***N/A***" + '\t' + formatStr + '\t' + dataType + newline); 
        }
    }
    
    // Measures
    foreach (var o in t.Measures.OrderBy(a => a.Name).ToList())
    {
        string objectName = o.Name;
        string objectDesc = (o.Description ?? "").Replace("'","''");
        string objectDF = o.DisplayFolder ?? "";
        objectType = "Measure";
        expr = o.Expression;
        formatStr = (o.FormatString ?? "").Replace("\t"," ");
        
        expr = expr.Replace("\n"," ").Replace("\r"," ").Replace("\t"," ");
        
        if (o.IsHidden)
        {
            hiddenFlag = "Yes";
        }
        else
        {
            hiddenFlag = "No";
        }
        
        sbMain.Append(modelName + '\t' + tableName + '\t' + objectType + '\t' + objectName + '\t' + hiddenFlag + '\t' + objectDesc + '\t' + objectDF + '\t' + expr + '\t' + formatStr + '\t' + dataType + newline);
    }
    
    // Hierarchies
    foreach (var o in t.Hierarchies.OrderBy(a => a.Name).ToList())
    {
        string objectName = o.Name;
        string objectDesc = (o.Description ?? "").Replace("'","''");
        string objectDF = o.DisplayFolder ?? "";
        objectType = "Hierarchy";
        
        // Build hierarchy levels
        var levels = string.Join(" > ", o.Levels.Select(l => l.Name));
        expr = "Levels: " + levels;
        
        if (o.IsHidden)
        {
            hiddenFlag = "Yes";
        }
        else
        {
            hiddenFlag = "No";
        }
        
        sbMain.Append(modelName + '\t' + tableName + '\t' + objectType + '\t' + objectName + '\t' + hiddenFlag + '\t' + objectDesc + '\t' + objectDF + '\t' + expr + '\t' + formatStr + '\t' + dataType + newline);
    }
}

// Calculation Groups
foreach (var o in Model.CalculationGroups.ToList())
{
    string tableName = o.Name;
    string tableDesc = (o.Description ?? "").Replace("'","''");
    string hiddenFlag;
    string objectType = "Calculation Group";
    string formatStr = "";
    string dataType = "";
    
    if (o.IsHidden)
    {
        hiddenFlag = "Yes";
    }
    else
    {
        hiddenFlag = "No";
    }
    
    sbMain.Append(modelName + '\t' + tableName + '\t' + objectType + '\t' + tableName + '\t' + hiddenFlag + '\t' + tableDesc + '\t' + "" + '\t' + "***N/A***" + '\t' + formatStr + '\t' + dataType + newline);    
    
    foreach (var i in o.CalculationItems.ToList())
    {        
        string objectName = i.Name;
        string objectDesc = (i.Description ?? "").Replace("'","''");
        string expr = i.Expression;
        objectType = "Calculation Item";
        formatStr = (i.FormatStringExpression ?? "").Replace("\t"," ");
        
        expr = expr.Replace("\n"," ").Replace("\r"," ").Replace("\t"," ");
        
        sbMain.Append(modelName + '\t' + tableName + '\t' + objectType + '\t' + objectName + '\t' + hiddenFlag + '\t' + objectDesc + '\t' + "" + '\t' + expr + '\t' + formatStr + '\t' + dataType + newline);    
    }
} 

// ============================================================================
// SHEET 2: RELATIONSHIPS
// ============================================================================
var sbRel = new System.Text.StringBuilder();
string[] colNameRel = { "From Table","From Column","To Table","To Column","Cardinality","Cross Filter","Active","Security Filtering" };
int colNameRelCount = colNameRel.Length;

// Add headers
for (int i=0; i < colNameRelCount; i++)
{
    if (i<colNameRelCount-1)
    {
        sbRel.Append(colNameRel[i] + '\t');
    }
    else
    {
        sbRel.Append(colNameRel[i] + newline);
    }
}

// Extract relationships
foreach(var r in Model.Relationships.OrderBy(a => a.FromTable.Name))
{
    string fromTable = r.FromTable.Name;
    string fromCol = r.FromColumn.Name;
    string toTable = r.ToTable.Name;
    string toCol = r.ToColumn.Name;
    string card = r.FromCardinality.ToString() + ":" + r.ToCardinality.ToString();
    string cross = r.CrossFilteringBehavior.ToString();
    string active = r.IsActive.ToString();
    string security = r.SecurityFilteringBehavior.ToString();
    
    sbRel.Append(fromTable + '\t' + fromCol + '\t' + toTable + '\t' + toCol + '\t' + card + '\t' + cross + '\t' + active + '\t' + security + newline);
}

// ============================================================================
// SHEET 3: RLS RULES
// ============================================================================
var sbRls = new System.Text.StringBuilder();
string[] colNameRls = { "Role","Table","Filter Expression","Description" };
int colNameRlsCount = colNameRls.Length;

// Add headers
for (int i=0; i < colNameRlsCount; i++)
{
    if (i<colNameRlsCount-1)
    {
        sbRls.Append(colNameRls[i] + '\t');
    }
    else
    {
        sbRls.Append(colNameRls[i] + newline);
    }
}

// Extract RLS rules
foreach(var role in Model.Roles.OrderBy(a => a.Name))
{
    string roleName = role.Name;
    string roleDesc = (role.Description ?? "").Replace("'","''");
    
    if (role.TablePermissions.Count == 0)
    {
        sbRls.Append(roleName + '\t' + "***No table permissions***" + '\t' + "" + '\t' + roleDesc + newline);
    }
    else
    {
        foreach(var perm in role.TablePermissions.OrderBy(a => a.Table.Name))
        {
            string table = perm.Table.Name;
            string filter = (perm.FilterExpression ?? "").Replace("\n"," ").Replace("\r"," ").Replace("\t"," ");
            
            sbRls.Append(roleName + '\t' + table + '\t' + filter + '\t' + roleDesc + newline);
        }
    }
}

// ============================================================================
// SHEET 4: DATA SOURCES
// ============================================================================
var sbDs = new System.Text.StringBuilder();
string[] colNameDs = { "Data Source","Type","Connection String","Description" };
int colNameDsCount = colNameDs.Length;

// Add headers
for (int i=0; i < colNameDsCount; i++)
{
    if (i<colNameDsCount-1)
    {
        sbDs.Append(colNameDs[i] + '\t');
    }
    else
    {
        sbDs.Append(colNameDs[i] + newline);
    }
}

// Extract data sources
foreach(var ds in Model.DataSources.OrderBy(a => a.Name))
{
    string dsName = ds.Name;
    string dsType = ds.Type.ToString();
    string connStr = "";
    string dsDesc = (ds.Description ?? "").Replace("'","''");
    
    if (ds.Type.ToString() == "Structured")
    {
        var sds = ds as StructuredDataSource;
        connStr = "Protocol: " + (sds.Protocol ?? "") + " | Path: " + (sds.Path ?? "");
    }
    else
    {
        var lds = ds as ProviderDataSource;
        connStr = (lds.ConnectionString ?? "").Replace("\t"," ");
    }
    
    sbDs.Append(dsName + '\t' + dsType + '\t' + connStr + '\t' + dsDesc + newline);
}

// ============================================================================
// SHEET 5: TABLE PARTITIONS & STORAGE MODES
// ============================================================================
var sbPart = new System.Text.StringBuilder();
string[] colNamePart = { "Table","Partition Name","Mode","Source Type","Query/Expression" };
int colNamePartCount = colNamePart.Length;

// Add headers
for (int i=0; i < colNamePartCount; i++)
{
    if (i<colNamePartCount-1)
    {
        sbPart.Append(colNamePart[i] + '\t');
    }
    else
    {
        sbPart.Append(colNamePart[i] + newline);
    }
}

// Extract partition info
foreach(var t in Model.Tables.Where(a => a.ObjectType.ToString() != "CalculationGroupTable").OrderBy(a => a.Name))
{
    foreach(var p in t.Partitions)
    {
        string tableName = t.Name;
        string partName = p.Name;
        string mode = p.Mode.ToString();
        string sourceType = p.SourceType.ToString();
        string query = "";
        
        if (p is Partition)
        {
            query = ((Partition)p).Query ?? "";
        }
        else if (p is MPartition)
        {
            query = ((MPartition)p).Expression ?? "";
        }
        
        query = query.Replace("\n"," ").Replace("\r"," ").Replace("\t"," ");
        
        // Truncate very long queries
        if (query.Length > 500)
        {
            query = query.Substring(0, 497) + "...";
        }
        
        sbPart.Append(tableName + '\t' + partName + '\t' + mode + '\t' + sourceType + '\t' + query + newline);
    }
}

// ============================================================================
// CREATE EXCEL FILE
// ============================================================================

// Delete existing files
try
{
    File.Delete(textFilePath);
    File.Delete(excelFilePath);
}
catch
{
}

// Create combined text file (will be parsed into sheets)
var sbCombined = new System.Text.StringBuilder();
sbCombined.Append("SHEET:Model Objects" + newline);
sbCombined.Append(sbMain.ToString());
sbCombined.Append(newline + "SHEET:Relationships" + newline);
sbCombined.Append(sbRel.ToString());
sbCombined.Append(newline + "SHEET:RLS Rules" + newline);
sbCombined.Append(sbRls.ToString());
sbCombined.Append(newline + "SHEET:Data Sources" + newline);
sbCombined.Append(sbDs.ToString());
sbCombined.Append(newline + "SHEET:Partitions" + newline);
sbCombined.Append(sbPart.ToString());

SaveFile(textFilePath, sbCombined.ToString());

// Create Excel workbook with multiple sheets
var excelApp = new Excel.Application();
excelApp.Visible = false;
excelApp.DisplayAlerts = false;

var wb = excelApp.Workbooks.Add();

// Create 5 sheets
string[] sheetNames = { "Model Objects", "Relationships", "RLS Rules", "Data Sources", "Partitions" };
string[] sheetData = { sbMain.ToString(), sbRel.ToString(), sbRls.ToString(), sbDs.ToString(), sbPart.ToString() };

for (int s = 0; s < 5; s++)
{
    Excel.Worksheet ws;
    
    // Use existing sheets or add new ones
    if (s < wb.Worksheets.Count)
    {
        ws = wb.Worksheets[s + 1] as Excel.Worksheet;
    }
    else
    {
        ws = wb.Worksheets.Add() as Excel.Worksheet;
    }
    
    ws.Name = sheetNames[s];
    
    // Parse tab-delimited data
    var lines = sheetData[s].Split(new[] { newline }, StringSplitOptions.RemoveEmptyEntries);
    
    for (int row = 0; row < lines.Length; row++)
    {
        var cols = lines[row].Split('\t');
        
        for (int col = 0; col < cols.Length; col++)
        {
            ws.Cells[row + 1, col + 1] = cols[col];
        }
        
        // Format header row
        if (row == 0)
        {
            var headerRange = ws.Range[ws.Cells[1, 1], ws.Cells[1, cols.Length]];
            headerRange.Font.Bold = true;
            headerRange.Interior.Color = Excel.XlRgbColor.rgbLightGray;
        }
    }
    
    // Auto-fit columns
    ws.Columns.AutoFit();
    
    // Freeze header row
    ws.Range["A2"].Select();
    excelApp.ActiveWindow.FreezePanes = true;
}

// Delete extra default sheets if any
while (wb.Worksheets.Count > 5)
{
    ((Excel.Worksheet)wb.Worksheets[wb.Worksheets.Count]).Delete();
}

// Save workbook
wb.SaveAs(excelFilePath, Excel.XlFileFormat.xlWorkbookDefault);

// Close and cleanup
wb.Close();
excelApp.Quit();
System.Runtime.InteropServices.Marshal.ReleaseComObject(excelApp);

// Delete temp text file
try
{
    File.Delete(textFilePath);
}
catch
{
}

// Show success message
var summary = "Complete Data Dictionary exported to: " + excelFilePath + newline + newline;
summary += "Sheet 1 - Model Objects: " + Model.Tables.Sum(t => t.Columns.Count + t.Measures.Count + t.Hierarchies.Count + 1) + " objects" + newline;
summary += "Sheet 2 - Relationships: " + Model.Relationships.Count + " relationships" + newline;
summary += "Sheet 3 - RLS Rules: " + Model.Roles.Count + " roles" + newline;
summary += "Sheet 4 - Data Sources: " + Model.DataSources.Count + " data sources" + newline;
summary += "Sheet 5 - Partitions: " + Model.Tables.Sum(t => t.Partitions.Count) + " partitions";

Info(summary);
```

### 1.3 Understanding the Export Output

**Sheet 1: Model Objects**
- **Tables**: Source type (Import, DirectQuery, Calculated), descriptions
- **Columns**: Data types, calculated column expressions, display folders
- **Measures**: DAX expressions, format strings, display folders
- **Hierarchies**: Level structure
- **Calculation Groups**: Calculation items and expressions

**Sheet 2: Relationships**
- **Cardinality**: One-to-Many, Many-to-One, etc.
- **Cross-filter direction**: Single, Both, None
- **Active/Inactive**: Relationship status
- **Security filtering**: None, OneWay, BothDirections

**Sheet 3: RLS Rules**
- **Role-based security**: Table-level filter expressions
- **DAX filter expressions**: Used for row-level security

**Sheet 4: Data Sources**
- **Connection strings**: Original data source connections
- **Source types**: Import, DirectQuery, Composite
- **Protocols**: SQL Server, Azure SQL, SharePoint, etc.

**Sheet 5: Partitions**
- **Storage mode**: Import, DirectQuery, Dual
- **M queries**: Power Query expressions for Import mode
- **SQL queries**: DirectQuery source queries
- **Partition strategy**: Full load vs incremental

### 1.4 Additional Tabular Editor Scripts

**Export All DAX Expressions:**

```csharp
// Export all measures to text file
var sb = new System.Text.StringBuilder();
sb.AppendLine("Table\tMeasure\tDAX Expression\tFormat String");

foreach(var t in Model.Tables)
{
    foreach(var m in t.Measures)
    {
        sb.AppendLine($"{t.Name}\t{m.Name}\t{m.Expression}\t{m.FormatString}");
    }
}

SaveFile(@"C:\Users\jharker\Documents\AllMeasures.txt", sb.ToString());
Info("Measures exported!");
```

**Export Table Dependencies:**

```csharp
// Find table dependencies
var sb = new System.Text.StringBuilder();
sb.AppendLine("Table\tDepends On\tDependency Type");

foreach(var t in Model.Tables)
{
    foreach(var col in t.Columns.Where(c => c.Type.ToString() == "Calculated"))
    {
        var calcCol = col as CalculatedColumn;
        // Parse expression to find table references
        // (simplified - would need regex parsing for full dependency graph)
    }
}

SaveFile(@"C:\Users\jharker\Documents\Dependencies.txt", sb.ToString());
```

---

## Part 2: DAX Studio - Performance Analysis

### 2.1 Installation & Connection

1. **Download DAX Studio**: https://daxstudio.org/
2. **Install** DAX Studio
3. **Connect** to Power BI model:
   - **Option A**: Connect to Power BI Desktop
     - File → Connect → Power BI Desktop
     - Select running instance
   - **Option B**: Connect to Power BI Service
     - File → Connect → Power BI Service
     - Authenticate with Azure AD
     - Select workspace and dataset

### 2.2 Query Performance Analysis

**Step 1: Enable Query Tracing**

1. Open **All Queries** tab
2. Click **Start Trace** (or press F5)
3. Execute queries in Power BI report (interact with visuals)
4. Stop trace to capture query log

**Step 2: Analyze Query Performance**

Key metrics to review:

- **Duration**: Total query execution time
- **CPU Time**: CPU processing time
- **Storage Engine**: Time spent in storage engine
- **Formula Engine**: Time spent in formula engine
- **Rows Returned**: Result set size
- **SE Queries**: Number of storage engine queries

**Step 3: Export Query Log**

1. **All Queries** tab → Right-click → **Export to CSV**
2. Columns exported:
   - Query text (DAX)
   - Duration
   - CPU time
   - Storage engine queries
   - Rows returned
   - Timestamp

**Sample Analysis Query:**

```dax
// Test measure performance
EVALUATE
SUMMARIZECOLUMNS(
    'DimDate'[Year],
    'DimDate'[MonthName],
    "Total Sales", [Total Sales],
    "Total Quantity", [Total Quantity]
)
```

### 2.3 Storage Engine Query Analysis

**View Storage Engine Queries:**

1. Run a DAX query
2. Click on query in **All Queries** tab
3. View **Storage Engine Queries** sub-tab
4. See actual SQL/MDX queries sent to data source

**Key Insights:**
- **Query folding**: Are M queries folding to SQL?
- **DirectQuery efficiency**: Are queries optimized?
- **Aggregation usage**: Are aggregations being used?
- **Filter pushdown**: Are filters pushed to source?

**Example Storage Engine Query:**

```sql
-- Generated from DirectQuery table
SELECT 
    SUM([SalesAmount]) AS [a0],
    [DimDate].[Year] AS [a1],
    [DimDate].[MonthName] AS [a2]
FROM [FactSales]
INNER JOIN [DimDate] ON [FactSales].[DateKey] = [DimDate].[DateKey]
WHERE [DimDate].[Year] = 2024
GROUP BY [DimDate].[Year], [DimDate].[MonthName]
```

### 2.4 Server Timings Analysis

**View Server Timings:**

1. Execute DAX query
2. Click **Server Timings** tab
3. Analyze:
   - **SE CPU**: Storage engine CPU time
   - **FE CPU**: Formula engine CPU time
   - **SE Queries**: Number of storage engine queries
   - **SE Cache**: Cache hit rate

**Performance Bottlenecks:**

- **High FE CPU**: Complex DAX expressions, many calculated columns
- **High SE CPU**: Large scans, missing indexes, inefficient queries
- **Many SE Queries**: Missing relationships, complex filters
- **Low Cache Hit Rate**: Queries not reusing cached results

### 2.5 Export Performance Report

**Create Performance Summary:**

1. **All Queries** tab → Select multiple queries
2. Right-click → **Export Selected**
3. Export format: CSV or Excel
4. Analyze in Excel:
   - Average duration by measure
   - Slowest queries
   - Most frequently executed queries
   - Storage engine vs formula engine time

**Power Query for Analysis:**

```m
// Load DAX Studio export into Power BI for analysis
let
    Source = Csv.Document(File.Contents("C:\Users\jharker\Documents\DAXStudio_Export.csv")),
    #"Promoted Headers" = Table.PromoteHeaders(Source),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{
        {"Duration", type duration},
        {"CPU Time", type duration},
        {"Rows Returned", Int64.Type}
    }),
    #"Added Custom" = Table.AddColumn(#"Changed Type", "Duration Seconds", 
        each Duration.TotalSeconds([Duration]))
in
    #"Added Custom"
```

---

## Part 3: Reverse Engineering Workflow

### 3.1 Complete Analysis Process

**Step 1: Extract Metadata (Tabular Editor)**
1. Connect to Power BI model
2. Run data dictionary export script
3. Review Excel output:
   - Identify all tables and their sources
   - Document calculated columns and measures
   - Map relationships
   - Extract RLS rules

**Step 2: Analyze Performance (DAX Studio)**
1. Connect to model
2. Start trace
3. Execute typical report interactions
4. Export query log
5. Identify slow queries and bottlenecks

**Step 3: Document Findings**
1. Create analysis document with:
   - **Data Sources**: Original connections, query types
   - **Table Mapping**: Source tables → Semantic model tables
   - **Measure Inventory**: All measures with DAX expressions
   - **Performance Issues**: Slow queries, optimization opportunities
   - **RLS Requirements**: Security rules to preserve

**Step 4: Plan Migration**
1. Map to Fabric architecture:
   - **T1**: Identify raw data sources
   - **T2**: Map to SCD2 dimensions
   - **T3**: Identify transformation logic
   - **T5**: Map to presentation views
   - **Semantic Layer**: Recreate measures in Direct Lake model

### 3.2 Mapping to Fabric T0-T5 Architecture

**Original Power BI Model → Fabric Architecture:**

| Power BI Component | Fabric Layer | Notes |
|-------------------|--------------|-------|
| Import tables | T1 → T2 → T3 | Migrate M queries to Dataflows Gen2 |
| DirectQuery tables | T5 Views → DirectQuery | Keep DirectQuery, point to T5 views |
| Calculated tables | T3 Dataflows | Convert M to Dataflows Gen2 |
| Calculated columns | T3 Transformations | Move to T3 layer |
| Measures | Semantic Model | Recreate in Direct Lake semantic model |
| Relationships | T3 Star Schema | Ensure proper foreign keys in T3 |
| RLS Rules | Semantic Model | Recreate RLS in Fabric semantic model |

**Example Mapping:**

**Original Power BI:**
- Table: `Sales` (Import from SQL Server)
- Calculated Column: `SalesAmount = [Quantity] * [UnitPrice]`
- Measure: `Total Sales = SUM([SalesAmount])`

**Fabric Architecture:**
- **T1**: Raw `Sales` table (VARIANT or typed)
- **T2**: `t2.fact_sales` (SCD2 if needed)
- **T3**: `t3.fact_sales` with `SalesAmount` calculated column
- **T3._FINAL**: `t3.fact_sales_FINAL` (zero-copy clone)
- **T5**: `t5.vw_sales` (view if needed)
- **Semantic Model**: `Total Sales` measure referencing `t3.fact_sales_FINAL[SalesAmount]`

### 3.3 Performance Optimization Opportunities

**From DAX Studio Analysis:**

1. **Replace Import with Direct Lake**
   - If model is Import mode → Migrate to Direct Lake
   - Benefits: No refresh, automatic query optimization
   - Action: Point semantic model to T3._FINAL tables

2. **Optimize Storage Engine Queries**
   - If many SE queries → Add aggregations or materialized views
   - Action: Create T5 aggregation views, use in semantic model

3. **Reduce Formula Engine Load**
   - If high FE CPU → Move calculations to T3 layer
   - Action: Convert calculated columns to T3 transformations

4. **Improve Relationship Performance**
   - If slow cross-filtering → Optimize T3 star schema
   - Action: Ensure proper indexes, foreign keys in T3

---

## Part 4: Alignment with Fabric Data Warehouse Pattern

### 4.1 Semantic Model Design Principles

**Following T0-T5 Architecture:**

1. **T3._FINAL Tables → Direct Lake**
   - Semantic model should reference `t3.*_FINAL` tables
   - Enables Direct Lake mode (in-memory cache)
   - Zero-copy clones isolate from T3 pipeline failures

2. **T5 Views → DirectQuery Fallback**
   - Complex aggregations in T5 views
   - Semantic model automatically uses DirectQuery
   - No manual configuration needed

3. **Measures Stay in Semantic Layer**
   - Business logic (DAX measures) remains in semantic model
   - Data transformations in T3, analytics in semantic layer
   - Clear separation of concerns

### 4.2 Migration Checklist

**Pre-Migration Analysis:**
- [ ] Extract complete data dictionary (Tabular Editor)
- [ ] Document all measures and their DAX expressions
- [ ] Map all data sources and connection strings
- [ ] Document RLS rules and security requirements
- [ ] Analyze performance baseline (DAX Studio)

**Migration Execution:**
- [ ] Create T1-T5 layers following architecture pattern
- [ ] Migrate data sources to T1 (VARIANT landing)
- [ ] Implement T2 SCD2 via T-SQL stored procedures
- [ ] Create T3 transformations via Dataflows Gen2
- [ ] Create T3._FINAL zero-copy clones
- [ ] Create T5 presentation views
- [ ] Build Direct Lake semantic model
- [ ] Recreate measures in semantic model
- [ ] Implement RLS rules
- [ ] Test performance vs baseline

**Post-Migration Validation:**
- [ ] Compare measure results (original vs migrated)
- [ ] Validate RLS security rules
- [ ] Performance testing (DAX Studio)
- [ ] User acceptance testing
- [ ] Document architecture decisions

### 4.3 Best Practices

**Semantic Model Design:**
1. **Use Direct Lake for Facts**: Point to `t3.fact_*_FINAL` tables
2. **Use Direct Lake for Dimensions**: Point to `t3.dim_*_FINAL` tables
3. **Use DirectQuery for Aggregations**: Point to `t5.vw_*` views when needed
4. **Avoid Calculated Tables**: Use T3 calculated tables instead
5. **Minimize Calculated Columns**: Move to T3 transformations

**Performance Optimization:**
1. **Monitor Query Performance**: Regular DAX Studio analysis
2. **Optimize Storage Engine**: Ensure T3 tables have proper indexes
3. **Use Aggregations**: Create T5 aggregation views for common queries
4. **Cache Strategy**: Leverage Direct Lake cache for frequently accessed data

**Documentation:**
1. **Maintain Data Dictionary**: Regular exports from Tabular Editor
2. **Track Performance Metrics**: Baseline and ongoing monitoring
3. **Document Architecture Decisions**: Why measures vs calculated columns
4. **Version Control**: Export semantic model to .bim file, store in git

---

## Part 5: Advanced Analysis Techniques

### 5.1 Dependency Analysis

**Find Measure Dependencies:**

```csharp
// Tabular Editor script to find measure dependencies
var sb = new System.Text.StringBuilder();
sb.AppendLine("Measure\tDepends On Measures\tDepends On Columns");

foreach(var t in Model.Tables)
{
    foreach(var m in t.Measures)
    {
        var expr = m.Expression;
        var measureDeps = Model.AllMeasures.Where(me => expr.Contains("[" + me.Name + "]")).Select(me => me.Name);
        var colDeps = Model.AllColumns.Where(c => expr.Contains("[" + c.Name + "]")).Select(c => c.Name);
        
        sb.AppendLine($"{m.Name}\t{string.Join(", ", measureDeps)}\t{string.Join(", ", colDeps)}");
    }
}

SaveFile(@"C:\Users\jharker\Documents\MeasureDependencies.txt", sb.ToString());
```

### 5.2 Query Pattern Analysis

**Identify Common Query Patterns:**

1. Export DAX Studio query log
2. Analyze query text patterns:
   - Most common measures
   - Most common filters
   - Most common table combinations
3. Use findings to:
   - Create T5 aggregation views
   - Optimize T3 table structure
   - Pre-aggregate common queries

### 5.3 Storage Mode Analysis

**Identify Storage Mode Issues:**

From Tabular Editor partition export:
- **Import tables**: Can migrate to Direct Lake
- **DirectQuery tables**: Keep DirectQuery, optimize source queries
- **Dual mode**: Evaluate if Direct Lake is better option

**Migration Strategy:**
- Import → Direct Lake: Point to T3._FINAL tables
- DirectQuery → DirectQuery: Point to T5 views
- Dual → Direct Lake: Prefer Direct Lake for better performance

---

## Summary

This guide provides a complete workflow for:

1. **Extracting metadata** from Power BI models using Tabular Editor
2. **Analyzing performance** using DAX Studio
3. **Reverse engineering** semantic models for migration
4. **Aligning** with Fabric T0-T5 data warehouse architecture

**Key Deliverables:**
- Comprehensive data dictionary (Excel)
- Performance baseline (DAX Studio export)
- Migration mapping document
- Architecture alignment plan

**Next Steps:**
- Use extracted metadata to plan Fabric migration
- Reference performance analysis for optimization
- Follow T0-T5 architecture pattern for new semantic models
- Maintain documentation through regular exports

## Related Topics

- [Direct Lake Optimization](../optimization/direct-lake-optimization.md) - Optimizing Direct Lake semantic models
- [T0-T5 Architecture Pattern](../architecture/architecture-pattern.md) - Semantic layer implementation
- [Performance Optimization](../optimization/performance-optimization.md) - DAX query optimization
- [Troubleshooting Guide](../operations/troubleshooting-guide.md) - Semantic model issues
