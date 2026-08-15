# Logistics Azure Data Engineering Project — Interview Explanation

## 1. Project Introduction

I built an end-to-end **Logistics Azure Data Engineering project** using Sales and Appointment data.

The pipeline uses Azure services to ingest, process, clean, validate, transform, and store data for analytics.

The main technologies used are:

* Azure Data Factory
* Azure Data Lake Storage Gen2
* Azure Databricks
* PySpark
* Apache Spark
* Delta Lake
* Unity Catalog
* Azure SQL Database
* Azure Key Vault
* Git
* GitHub

---

# 2. Project Objective

The objective of the project is to build a complete Azure Data Engineering pipeline for processing logistics Sales and Appointment data.

The pipeline performs:

```text
Data Ingestion
     ↓
Data Processing
     ↓
Data Cleaning
     ↓
Data Quality
     ↓
Data Modeling
     ↓
Incremental Loading
     ↓
Monitoring
```

---

# 3. Source Data

The project processes two main datasets:

```text
Sales Data
Appointment Data
```

The source data is available in CSV format.

---

# 4. Complete Project Flow

```text
Sales + Appointment CSV
          ↓
      SC1 Landing
          ↓
Azure Data Factory
          ↓
Azure Databricks
          ↓
       Bronze
          ↓
       Silver
          ↓
 Data Quality Checks
          ↓
        Gold
     /         \
    ↓           ↓
DIM_APPOINTMENT FACT_SALES
          ↓
   Unity Catalog
          ↓
SC2 Managed Storage
```

Supporting services:

```text
Azure SQL
→ Metadata + Audit

Azure Key Vault
→ Security
```

---

# 5. Why Did You Use Two Storage Accounts?

I used two Azure Data Lake Storage Gen2 accounts with different responsibilities.

## SC1

SC1 is used for file-based storage.

```text
SC1
│
├── landing
├── logs
└── archive
```

It stores:

* Incoming CSV files
* File-based logs
* Archived source files

## SC2

SC2 is used as the **Unity Catalog managed storage location**.

```text
SC2
   ↓
Unity Catalog
   ↓
Bronze
Silver
Gold
```

Easy answer:

> SC1 stores source and operational files, while SC2 stores Unity Catalog managed Delta tables.

---

# 6. What Is the Role of Azure Data Factory?

Azure Data Factory is the **orchestration layer**.

It controls:

* Pipeline execution
* Databricks notebook execution
* Activity order
* Dependencies
* Failure handling
* Monitoring

Easy answer:

> ADF controls the workflow, while Databricks performs the actual data transformations.

---

# 7. What Is the Role of Azure Databricks?

Azure Databricks is the main processing engine.

I used Databricks for:

* Reading source CSV files
* Bronze processing
* Silver transformations
* Data Quality Checks
* Gold processing
* Delta MERGE
* ETL logging
* Error handling

PySpark is used for transformations.

---

# 8. What Is Medallion Architecture?

The project follows:

```text
Bronze
   ↓
Silver
   ↓
Gold
```

## Bronze

Raw or near-raw data.

## Silver

Cleaned and standardized data.

## Gold

Business-ready analytical data.

Easy answer:

> Bronze preserves the source, Silver cleans and standardizes the data, and Gold creates business-ready Dimension and Fact tables.

---

# 9. What Did You Do in Bronze?

In Bronze, I:

* Read CSV files from SC1 Landing
* Preserved source values
* Performed schema validation
* Checked expected columns
* Checked missing columns
* Checked extra columns
* Stored data as Unity Catalog managed Delta tables

Flow:

```text
SC1 Landing
     ↓
Read CSV
     ↓
Validate Schema
     ↓
Bronze Managed Table
```

---

# 10. Why Did You Read Bronze Columns as Strings?

CSV source data may contain malformed values.

For example:

```text
215.0000, 230.0000
```

If Spark tries to directly convert this value to FLOAT during ingestion, the pipeline can fail.

Therefore:

```text
Bronze
↓
Preserve as STRING

Silver
↓
Clean + Convert
```

Easy answer:

> I kept Bronze data close to the source and performed final data-type conversion in Silver.

---

# 11. What Schema Validation Did You Perform?

I compared:

```text
Actual Columns
Expected Columns
```

I also checked:

```text
Missing Columns
Extra Columns
```

For example, during Appointment processing I found source columns:

```text
APPOINTMENT_TITLE
APPOINTMENT_STATUS
APPOINTMENT_DATE
```

while the expected schema initially contained:

```text
TITLE
STATUS
DATE
```

The Bronze schema was corrected to match the real source structure, and the standardized names were handled in Silver.

---

# 12. What Did You Do in Silver?

Silver is the main cleaning and standardization layer.

I performed:

* Metadata-driven column mapping
* Column renaming
* Data type conversion
* Malformed-value handling
* NULL handling
* Duplicate removal
* Data cleaning
* Data standardization

Flow:

```text
Bronze
   ↓
Metadata Mapping
   ↓
Clean
   ↓
Convert Data Types
   ↓
Handle NULL
   ↓
Remove Duplicates
   ↓
Silver
```

---

# 13. What Is Metadata-Driven ETL?

Instead of hard-coding every object and column transformation inside the notebook, I stored configuration in Azure SQL Database.

Main metadata tables:

```sql
metadata.OBJECTS_CONFIGURATION
```

and:

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

Databricks reads this information through JDBC.

Easy answer:

> Metadata-driven ETL separates configuration from code, which makes the pipeline more reusable and maintainable.

---

# 14. What Is OBJECTS_CONFIGURATION?

`metadata.OBJECTS_CONFIGURATION` stores object-level processing configuration.

It answers:

```text
What object should be processed?
```

It can contain information such as:

* Object name
* Source information
* Target information
* Load configuration
* Processing configuration
* Active status

---

# 15. What Is OBJECTS_COLUMN_MAPPING?

`metadata.OBJECTS_COLUMN_MAPPING` stores column-level transformation information.

It answers:

```text
How should columns be transformed?
```

For example:

```text
APPOINTMENT_TITLE
       ↓
TITLE
       ↓
STRING
```

The table can contain:

* Source column
* Target column
* Target data type
* Object name

---

# 16. OBJECTS_CONFIGURATION vs OBJECTS_COLUMN_MAPPING

Easy way to remember:

```text
OBJECTS_CONFIGURATION
        ↓
What should I process?

OBJECTS_COLUMN_MAPPING
        ↓
How should I transform its columns?
```

---

# 17. How Did Databricks Connect to Azure SQL?

Databricks uses JDBC.

Conceptually:

```python
jdbc_url = (
    f"jdbc:sqlserver://{server_name}:1433;"
    f"database={database_name};"
    "encrypt=true;"
    "trustServerCertificate=false;"
)
```

Credentials are not hard-coded directly in the notebook.

---

# 18. Why Did You Use Azure Key Vault?

Azure Key Vault is used to securely store sensitive information.

Examples:

* SQL username
* SQL password
* Client ID
* Client Secret
* Tenant ID
* Storage-related secrets

Easy answer:

> Key Vault prevents credentials from being hard-coded in Databricks notebooks or committed to GitHub.

---

# 19. What Problem Did You Face in Silver?

During Sales Silver processing, a numeric column contained:

```text
215.0000, 230.0000
```

The target data type was:

```text
FLOAT
```

Spark raised:

```text
CAST_INVALID_INPUT
```

because the string contained multiple numeric values and could not be directly converted into one FLOAT.

I handled the malformed value during Silver cleaning before applying the target data type.

---

# 20. Why Is That a Good Data Engineering Example?

It demonstrates that real-world source data is not always clean.

The pipeline should not assume every source value is correct.

The proper flow is:

```text
Raw Value
    ↓
Validate
    ↓
Clean
    ↓
Convert
    ↓
Trusted Value
```

---

# 21. What Data Quality Checks Did You Implement?

The project includes checks such as:

* Row count validation
* NULL validation
* Duplicate validation
* Primary key validation
* Foreign key validation
* Schema validation
* Required-column validation
* Data type validation
* Invalid-value validation

---

# 22. Data Cleaning vs Data Quality

These are different.

## Data Cleaning

Fixes the data.

Examples:

```text
Remove Duplicate
Handle NULL
Trim Value
Convert Data Type
```

## Data Quality

Checks whether the cleaned data is correct.

Examples:

```text
Check Duplicate
Check NULL
Check PK
Check FK
```

Easy answer:

> Cleaning fixes the data; Data Quality verifies that the data is correct.

---

# 23. What Did You Do in Gold?

Gold converts cleaned Silver data into business-ready analytical tables.

Final tables:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

---

# 24. What Is DIM_APPOINTMENT_DATA?

`DIM_APPOINTMENT_DATA` is the Dimension table.

It stores descriptive Appointment information.

Examples include:

* Appointment details
* Title
* Status
* Date
* Other descriptive attributes

Easy answer:

> A Dimension table describes business entities.

---

# 25. What Is FACT_SALES?

`FACT_SALES` is the Fact table.

It stores measurable Sales information.

Examples include:

* Price
* Sales measurements
* Other transactional metrics

Easy answer:

> A Fact table stores measurements and connects with Dimension tables.

---

# 26. Fact vs Dimension

Easy way to remember:

```text
DIMENSION = Description

FACT = Measurement
```

For this project:

```text
DIM_APPOINTMENT_DATA
        ↓
Descriptive Appointment Data
```

```text
FACT_SALES
        ↓
Measurable Sales Data
```

---

# 27. What Is a Surrogate Key?

A surrogate key is a system-generated key used in a Dimension table.

It is different from the source business key.

```text
Business Key
↓
Comes from source

Surrogate Key
↓
Created for analytical model
```

It helps connect the Fact table with the Dimension table.

---

# 28. Why Did You Use Unity Catalog?

Unity Catalog is used to centrally manage and govern Databricks data objects.

It manages:

* Catalogs
* Schemas
* Tables
* Permissions
* Managed storage
* Governance

The project uses:

```text
bronze
silver
gold
```

schemas.

---

# 29. What Are Managed Tables?

The project uses Unity Catalog **managed Delta tables**.

For managed tables:

```text
Unity Catalog
      ↓
Manages Table Metadata
      +
Manages Storage Location
```

The physical table data is stored in SC2.

---

# 30. Where Are Bronze, Silver and Gold Stored?

They are stored as Unity Catalog managed Delta tables.

Physical storage:

```text
SC2
```

Not:

```text
SC1 / bronze
SC1 / silver
SC1 / gold
```

Easy answer:

> SC1 contains Landing, Logs, and Archive. Bronze, Silver, and Gold are managed tables stored through Unity Catalog in SC2.

---

# 31. What Is Delta Lake?

Delta Lake provides reliable table storage on top of cloud storage.

It supports:

* ACID transactions
* Schema enforcement
* UPDATE
* DELETE
* MERGE
* Incremental loading

---

# 32. What Is Incremental Loading?

Incremental loading means processing only:

```text
New Records
+
Changed Records
```

instead of processing the complete historical dataset every time.

---

# 33. Full Load vs Incremental Load

## Full Load

Processes all records.

```text
All Source Data
      ↓
Target
```

## Incremental Load

Processes only new and changed records.

```text
New / Changed
      ↓
Target
```

---

# 34. What Is MERGE?

MERGE compares incoming records with the existing target.

```text
Record Exists?
   /       \
 Yes        No
  ↓          ↓
UPDATE     INSERT
```

---

# 35. What Is UPSERT?

UPSERT means:

```text
UPDATE + INSERT
```

If the record exists:

```text
UPDATE
```

If it is new:

```text
INSERT
```

---

# 36. Why Use MERGE Instead of Overwrite?

Overwrite replaces the complete target dataset.

MERGE changes only required records.

```text
Overwrite
↓
Rewrite Complete Target

MERGE
↓
Update / Insert Required Records
```

MERGE is more suitable for incremental processing.

---

# 37. What Is ETL Logging?

ETL logging records the history of pipeline executions.

The project uses:

```sql
audit.ETL_LOG
```

The table can store:

* Process name
* Object name
* Layer
* Start time
* End time
* Record count
* Status
* Error message

---

# 38. What Status Values Did You Use?

Typical ETL statuses are:

```text
STARTED
SUCCESS
FAILED
```

Flow:

```text
Start
 ↓
STARTED
 ↓
Run ETL
 ↓
Success?
 /    \
Yes    No
 ↓      ↓
SUCCESS FAILED
```

---

# 39. What Is Error Handling?

Error handling captures pipeline failures using Python `try-except`.

Conceptually:

```python
try:
    # ETL logic

except Exception as e:
    # capture error
    # write FAILED log
    raise
```

---

# 40. Why Did You Use raise?

After logging the exception, `raise` sends the failure back to Azure Data Factory.

```text
Databricks Error
      ↓
Write FAILED Log
      ↓
raise
      ↓
ADF Activity = FAILED
```

This prevents a failed notebook from appearing successful.

---

# 41. ETL_LOG vs SC1 Logs

These are different.

## SC1 Logs

```text
SC1 / logs
```

Used for file-based technical or processing logs where required.

## Azure SQL Audit

```sql
audit.ETL_LOG
```

Used for structured ETL execution history.

Easy answer:

> SC1 logs are file-based logs, while `audit.ETL_LOG` stores structured pipeline execution information in Azure SQL.

---

# 42. Metadata vs Audit

Easy difference:

```text
Metadata
↓
What should the pipeline do?

Audit
↓
What happened when the pipeline ran?
```

---

# 43. What Happens When a Data Quality Check Fails?

A critical failure should prevent the pipeline from moving bad data to Gold.

```text
DQ Check
   ↓
FAIL
   ↓
Raise Exception
   ↓
Write FAILED Log
   ↓
ADF Activity Fails
```

---

# 44. How Does ADF Know a Notebook Failed?

The Databricks notebook raises the exception.

```text
Notebook Error
     ↓
raise
     ↓
ADF Databricks Activity
     ↓
FAILED
```

ADF can then stop downstream processing.

---

# 45. How Do You Monitor the Pipeline?

I use:

```text
ADF Monitor
+
Azure SQL audit.ETL_LOG
+
Databricks execution output
```

ADF provides orchestration-level monitoring.

Azure SQL provides detailed ETL execution information.

---

# 46. Why Did You Use Archive?

After successful processing, source files can be moved from:

```text
SC1 / landing
```

to:

```text
SC1 / archive
```

This helps:

* Prevent accidental reprocessing
* Keep Landing clean
* Maintain source history
* Support debugging
* Support reprocessing

---

# 47. Landing vs Archive

```text
Landing
↓
Files waiting to be processed

Archive
↓
Files already processed
```

---

# 48. What Is the Role of SC1?

SC1 stores:

```text
Landing
Logs
Archive
```

Easy answer:

> SC1 is the file-storage account.

---

# 49. What Is the Role of SC2?

SC2 stores:

```text
Unity Catalog Managed Storage
```

for:

```text
Bronze
Silver
Gold
```

Easy answer:

> SC2 is the managed-table storage account.

---

# 50. What Is the Most Important Feature of Your Project?

The project combines multiple real Data Engineering concepts:

* Medallion Architecture
* Metadata-driven ETL
* PySpark transformations
* Schema validation
* Data Quality Checks
* Delta Lake
* Unity Catalog
* Incremental MERGE
* Dimension and Fact modeling
* ETL audit logging
* Error handling
* Key Vault security
* ADF orchestration

---

# 51. What Was the Most Important Challenge?

One important challenge was handling malformed source data.

A Sales numeric field contained:

```text
215.0000, 230.0000
```

and Spark could not directly cast it to FLOAT.

I identified the issue during Silver processing and corrected the cleaning/type-conversion logic before allowing the record to move further.

---

# 52. Why Is Your Pipeline Metadata-Driven?

Because processing configuration is stored outside the transformation code.

```text
Azure SQL Metadata
        ↓
Databricks Reads Configuration
        ↓
Reusable PySpark Logic
```

This reduces hard-coding.

---

# 53. Why Is Your Project Scalable?

The design separates:

```text
Storage
Processing
Configuration
Security
Orchestration
Monitoring
```

It also uses:

* Reusable metadata
* Managed Delta tables
* Incremental processing
* Cloud storage
* Spark processing

This makes it easier to extend the project to additional datasets.

---

# 54. How Would You Add a New Dataset?

Conceptually:

```text
New Source Dataset
       ↓
Add Metadata Configuration
       ↓
Add Column Mapping
       ↓
Place Source File in Landing
       ↓
Run Reusable ETL Logic
```

Some dataset-specific business logic may still be required, especially for Gold modeling.

---

# 55. What Would You Improve in Production?

For a production system, I would consider:

* Stronger automated testing
* More advanced monitoring
* Alert notifications
* Retry mechanisms
* More detailed data-quality rules
* Environment separation for DEV / TEST / PROD
* CI/CD deployment
* Better performance tuning
* More detailed governance and access control

---

# 56. 30-Second Project Explanation

> I built an end-to-end Logistics Data Engineering pipeline on Azure using Sales and Appointment CSV data. Source files land in the first ADLS Gen2 account, and Azure Data Factory orchestrates Databricks processing. I implemented Bronze ingestion and schema validation, Silver metadata-driven transformations and data cleaning, Data Quality Checks, and Gold Dimension and Fact modeling. Bronze, Silver, and Gold are Unity Catalog managed Delta tables stored through the second ADLS account. I also implemented Delta MERGE for incremental loading, Azure SQL metadata and ETL audit logging, Azure Key Vault for secret management, and error handling.

---

# 57. 1-Minute Project Explanation

> My project is an end-to-end Logistics Azure Data Engineering pipeline that processes Sales and Appointment CSV data. I use two ADLS Gen2 storage accounts: SC1 for Landing, Logs, and Archive, and SC2 as the Unity Catalog managed storage location. Azure Data Factory orchestrates the workflow, while Azure Databricks and PySpark perform the processing. In Bronze, I ingest and validate the source schema while preserving raw values. In Silver, I use Azure SQL metadata for dynamic column mapping, clean malformed values, convert data types, handle NULLs, and remove duplicates. I then perform Data Quality Checks before creating the Gold `DIM_APPOINTMENT_DATA` and `FACT_SALES` tables. The Gold tables are Unity Catalog managed Delta tables. I also implemented incremental loading with Delta MERGE, Azure SQL-based ETL logging, error handling, and Azure Key Vault for secure credential management.

---

# 58. 2-Minute Project Explanation

> I developed a Logistics Azure Data Engineering project using Sales and Appointment datasets. The source data comes as CSV files and lands in the first ADLS Gen2 storage account. I separated storage responsibilities by using SC1 for Landing, Logs, and Archive and SC2 for Unity Catalog managed storage.
>
> Azure Data Factory is used as the orchestration layer, and Azure Databricks is the main processing engine. In the Bronze layer, Databricks reads the source files, validates the expected schema, checks missing and extra columns, and stores the raw or near-raw data as managed Delta tables.
>
> In the Silver layer, I implemented metadata-driven transformations. Azure SQL stores object configuration and source-to-target column mappings. Databricks reads this metadata using JDBC and applies reusable PySpark transformations. I handled column renaming, data-type conversion, NULLs, duplicates, malformed numeric values, and standardization.
>
> After Silver, I implemented Data Quality Checks such as row count, NULL, duplicate, schema, primary-key, foreign-key, and data-type validation. The validated data is then used to create the Gold `DIM_APPOINTMENT_DATA` Dimension table and `FACT_SALES` Fact table.
>
> I use Unity Catalog to manage Bronze, Silver, and Gold Delta tables, with the physical managed storage in SC2. I also implemented incremental loading using Delta MERGE, where existing records are updated and new records are inserted. For monitoring, I use `audit.ETL_LOG` in Azure SQL with STARTED, SUCCESS, and FAILED statuses, and I use try-except with exception propagation so ADF correctly identifies failures. Azure Key Vault is used to securely manage sensitive credentials.

---

# 59. Architecture Explanation in Easy Words

```text
CSV
 ↓
SC1
 ↓
ADF
 ↓
Databricks
 ↓
Bronze
 ↓
Silver
 ↓
DQ
 ↓
Gold
 ↓
DIM + FACT
 ↓
Unity Catalog
 ↓
SC2
```

Supporting:

```text
Azure SQL
↓
Metadata + Audit
```

```text
Key Vault
↓
Security
```

---

# 60. One-Line Explanation of Every Service

### Azure Data Factory

Controls the pipeline.

### ADLS Gen2 SC1

Stores source files, logs, and archive files.

### Azure Databricks

Processes and transforms the data.

### PySpark

Used to write transformation logic.

### Apache Spark

Distributed data-processing engine.

### Delta Lake

Provides reliable tables and MERGE capability.

### Unity Catalog

Manages and governs Bronze, Silver, and Gold tables.

### ADLS Gen2 SC2

Stores Unity Catalog managed table data.

### Azure SQL Database

Stores metadata and ETL audit logs.

### Azure Key Vault

Stores credentials and secrets securely.

### GitHub

Stores project code and documentation.

---

# 61. Final Interview Memory Formula

Remember:

```text
Source
 ↓
SC1
 ↓
ADF
 ↓
Databricks
 ↓
Bronze = Preserve
 ↓
Silver = Clean
 ↓
DQ = Verify
 ↓
Gold = Business
 ↓
DIM + FACT
 ↓
MERGE = Incremental
 ↓
SC2 = Managed Tables
```

And:

```text
Azure SQL
↓
Metadata = Instructions
Audit = History
```

```text
Key Vault
↓
Secrets
```

This is the complete interview explanation for the Logistics Azure Data Engineering Project.
