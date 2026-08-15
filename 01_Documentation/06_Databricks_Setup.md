# Azure Databricks Implementation

## Overview

Azure Databricks is the main **data processing and transformation platform** used in the Logistics Azure Data Engineering Project.

Databricks is responsible for processing the Sales and Appointment datasets through the Medallion Architecture:

```text
Landing
   ↓
Bronze
   ↓
Silver
   ↓
Gold
```

The main technologies used inside Databricks are:

* Apache Spark
* PySpark
* Spark SQL
* Delta Lake
* Unity Catalog

---

# Role of Azure Databricks

Azure Databricks performs the main ETL processing in the project.

It is used for:

* Reading source CSV files from SC1
* Bronze layer processing
* Schema validation
* Silver layer transformations
* Metadata-driven column mapping
* Data type conversion
* NULL handling
* Duplicate removal
* Data cleaning
* Data quality checks
* Gold layer processing
* Dimension table creation
* Fact table creation
* Incremental loading
* Delta Lake MERGE / UPSERT
* ETL logging
* Error handling

---

# Project Databricks Architecture

```text
Source CSV Files
        ↓
SC1 - Landing
        ↓
Azure Databricks
        ↓
Bronze Processing
        ↓
Unity Catalog Bronze Tables
        ↓
Silver Processing
        ↓
Unity Catalog Silver Tables
        ↓
Data Quality Checks
        ↓
Gold Processing
        ↓
Unity Catalog Gold Tables
        ↓
DIM_APPOINTMENT_DATA
FACT_SALES
```

The physical storage of Unity Catalog managed tables is located in **SC2**.

---

# Storage Design

The project uses two ADLS Gen2 storage accounts.

## SC1

SC1 is used for file-based project storage.

```text
SC1
│
├── landing
├── logs
└── archive
```

Databricks reads incoming Sales and Appointment CSV files from the Landing location.

---

## SC2

SC2 is used as the **Unity Catalog managed storage location**.

```text
SC2
      ↓
Unity Catalog Managed Storage
      ↓
Bronze
Silver
Gold
```

The Bronze, Silver, and Gold datasets are created as managed Delta tables through Unity Catalog.

---

# Databricks Workspace

An Azure Databricks workspace is created for the project.

The workspace provides the environment required to:

* Create notebooks
* Run Spark workloads
* Create compute resources
* Connect to Azure services
* Use Unity Catalog
* Execute PySpark transformations

---

# Databricks Compute

A Databricks compute resource is used to execute the notebooks.

The compute provides the Spark environment required for processing.

Conceptually:

```text
Databricks Workspace
        ↓
Databricks Compute
        ↓
Apache Spark
        ↓
PySpark Notebooks
```

The compute is started when processing is required and can be stopped when it is not being used.

---

# Apache Spark

Apache Spark is the distributed processing engine used by Databricks.

Spark allows large datasets to be processed across multiple tasks.

High-level Spark execution:

```text
PySpark Code
     ↓
Spark Job
     ↓
Stages
     ↓
Tasks
     ↓
Data Processing
```

---

# PySpark

PySpark is the Python API for Apache Spark.

It is used throughout the project to perform transformations.

Examples include:

```python
df.select(...)
```

```python
df.filter(...)
```

```python
df.withColumn(...)
```

```python
df.dropDuplicates(...)
```

```python
df.join(...)
```

PySpark DataFrames are the main data structure used during ETL processing.

---

# Unity Catalog

Unity Catalog is used to manage the project's Databricks data objects.

It provides centralized management for:

* Catalogs
* Schemas
* Tables
* Storage
* Permissions
* Data governance

The processed datasets are stored as managed tables.

---

# Unity Catalog Structure

The project follows a structure similar to:

```text
Unity Catalog
      │
      ├── bronze
      │
      ├── silver
      │
      └── gold
```

Each schema represents one layer of the Medallion Architecture.

---

# Bronze Schema

The Bronze schema contains raw or near-raw processed data.

```text
Unity Catalog
└── bronze
```

Bronze tables are created after reading source CSV files from SC1.

Flow:

```text
SC1 Landing
     ↓
Databricks
     ↓
Schema Validation
     ↓
Bronze Managed Table
     ↓
SC2 Managed Storage
```

---

# Silver Schema

The Silver schema contains cleaned and standardized data.

```text
Unity Catalog
└── silver
```

Silver processing includes:

* Metadata-driven column mapping
* Column renaming
* Data type conversion
* Invalid-value handling
* NULL handling
* Duplicate removal
* Data cleaning
* Standardization

Flow:

```text
Bronze Managed Table
        ↓
PySpark Transformation
        ↓
Silver Managed Table
        ↓
SC2 Managed Storage
```

---

# Gold Schema

The Gold schema contains business-ready analytical data.

```text
Unity Catalog
└── gold
```

The project creates:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

Flow:

```text
Silver Appointment
        ↓
DIM_APPOINTMENT_DATA

Silver Sales
        ↓
Join / Business Transformation
        ↓
FACT_SALES
```

Both are stored as managed Delta tables.

---

# Managed Tables

Bronze, Silver, and Gold datasets are implemented as **Unity Catalog managed tables**.

With managed tables:

* Unity Catalog manages the table metadata
* Databricks manages the physical Delta files
* SC2 provides the managed storage location

Conceptually:

```text
CREATE TABLE
      ↓
Unity Catalog
      ↓
Managed Delta Table
      ↓
SC2
```

Therefore, Bronze/Silver/Gold are not manually stored as normal folders inside SC1.

---

# Delta Lake

Delta Lake is used as the table storage format for processed data.

Delta Lake provides:

* ACID transactions
* Schema enforcement
* Reliable writes
* UPDATE support
* DELETE support
* MERGE support
* Incremental processing

The project flow is:

```text
CSV Source
    ↓
Databricks
    ↓
Delta Managed Tables
```

---

# Databricks and SC1

Databricks reads incoming source files from SC1.

Conceptually:

```text
SC1
 ↓
Landing
 ↓
Sales / Appointment CSV
 ↓
Databricks
```

After successful processing, source files can be moved from:

```text
landing
```

to:

```text
archive
```

SC1 also contains:

```text
logs
```

for file-based processing logs where required.

---

# Databricks and SC2

SC2 has a different purpose.

It provides managed storage for Unity Catalog.

```text
Databricks
     ↓
Unity Catalog
     ↓
Managed Tables
     ↓
SC2
```

The physical Delta files for Bronze, Silver, and Gold are maintained through this managed storage.

---

# Databricks and Azure SQL

Azure Databricks connects to Azure SQL Database through JDBC.

Azure SQL stores:

```sql
metadata.OBJECTS_CONFIGURATION
```

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

and:

```sql
audit.ETL_LOG
```

---

# JDBC Connection

Conceptually:

```python
jdbc_url = (
    f"jdbc:sqlserver://{server_name}:1433;"
    f"database={database_name};"
    "encrypt=true;"
    "trustServerCertificate=false;"
)
```

Connection properties include the SQL username, password, and JDBC driver.

```python
connection_properties = {
    "user": sql_username,
    "password": sql_password,
    "driver": "com.microsoft.sqlserver.jdbc.SQLServerDriver"
}
```

Sensitive credentials are not hard-coded directly inside notebooks.

---

# Databricks and Azure Key Vault

Azure Key Vault is used to securely store credentials.

The connection flow is:

```text
Azure Key Vault
      ↓
Secure Secrets
      ↓
Databricks
      ↓
Azure SQL / Required Azure Resources
```

Secrets can be retrieved using:

```python
dbutils.secrets.get(
    scope="<secret-scope-name>",
    key="<secret-name>"
)
```

This prevents passwords from being directly stored in notebook code.

---

# Metadata-Driven Processing

Databricks reads metadata from Azure SQL.

Main metadata tables:

```sql
metadata.OBJECTS_CONFIGURATION
```

and:

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

The metadata defines how objects and columns should be processed.

High-level flow:

```text
Databricks
    ↓
Read Azure SQL Metadata
    ↓
Identify Object
    ↓
Read Column Mapping
    ↓
Apply Transformation
```

---

# Sales Object

The Sales dataset is processed using an object configuration such as:

```text
SALES_DATA_PRIOR_DAY
```

Example:

```python
sales_silver_df = apply_mapping(
    sales_bronze_df,
    "SALES_DATA_PRIOR_DAY"
)
```

The mapping function reads the related metadata and applies required transformations.

---

# Appointment Object

The Appointment dataset is processed using its own metadata configuration.

Conceptually:

```python
appointment_silver_df = apply_mapping(
    appointment_bronze_df,
    "APPOINTMENT_DATA"
)
```

This allows the same reusable mapping logic to process multiple datasets.

---

# Bronze Processing

Bronze is the first processing layer inside Databricks.

Main steps:

```text
Read CSV
   ↓
Validate Schema
   ↓
Check Expected Columns
   ↓
Check Missing / Extra Columns
   ↓
Add Required Technical Information
   ↓
Write Bronze Managed Table
```

Bronze keeps source data as close as possible to its original form.

---

# Schema Validation

Before loading data into Bronze, the project validates the incoming schema.

Example validation:

```text
Actual Columns   : 40
Expected Columns : 40
```

The pipeline can also identify:

```text
Missing Columns
Extra Columns
```

If required columns are missing, processing can fail instead of loading incorrect data.

---

# Silver Processing

Silver transforms Bronze data into clean and standardized data.

Flow:

```text
Bronze
   ↓
Read Column Metadata
   ↓
Apply Mapping
   ↓
Data Type Conversion
   ↓
Clean Malformed Values
   ↓
NULL Handling
   ↓
Duplicate Removal
   ↓
Silver
```

---

# Column Mapping

The Silver notebook uses metadata-based mapping.

For example, source Appointment columns may be mapped from:

```text
APPOINTMENT_TITLE
APPOINTMENT_STATUS
APPOINTMENT_DATE
```

to standardized target columns such as:

```text
TITLE
STATUS
DATE
```

This mapping is stored in Azure SQL metadata.

---

# Data Type Conversion

After mapping, data is converted to the required target data types.

Examples:

```text
STRING
FLOAT
INTEGER
DATE
TIMESTAMP
```

Source data may initially be read as strings and converted during Silver processing.

---

# Handling Malformed Data

Some source values may not match the expected data type.

For example:

```text
215.0000, 230.0000
```

cannot be directly converted into one FLOAT value.

The Silver transformation therefore cleans malformed source values or safely converts them before writing the final Silver dataset.

This prevents Spark cast failures.

---

# NULL Handling

Silver processing checks NULL values where required.

Conceptually:

```text
Input Data
    ↓
Check NULL Values
    ↓
Apply Required Handling
    ↓
Clean Data
```

NULL handling depends on the column and business requirement.

---

# Duplicate Removal

Duplicate records are removed during the cleaning process.

PySpark can perform duplicate removal using:

```python
df.dropDuplicates()
```

or by using selected business-key columns where required.

The purpose is to ensure duplicate records do not incorrectly affect analytical results.

---

# Data Quality Checks

After transformation, the project performs data quality checks.

Examples include:

* Row count checks
* NULL checks
* Duplicate checks
* Schema checks
* Data type checks
* Invalid-value checks
* Business-rule checks

Flow:

```text
Silver Data
     ↓
Data Quality Checks
     ↓
Valid Data
     ↓
Gold Processing
```

---

# Gold Processing

Gold creates analytical Dimension and Fact tables.

The two main Gold tables are:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

---

# Dimension Table

The Appointment dataset is used to create:

```text
DIM_APPOINTMENT_DATA
```

It stores descriptive Appointment information.

Conceptually:

```text
Silver Appointment
        ↓
Prepare Dimension Columns
        ↓
Create Dimension Key
        ↓
DIM_APPOINTMENT_DATA
```

A surrogate key can be used as the unique key of the Dimension table.

---

# Fact Table

The Sales dataset is used to create:

```text
FACT_SALES
```

The Fact table contains measurable Sales information.

It connects to the related Appointment dimension data where required.

Conceptually:

```text
Silver Sales
      +
DIM_APPOINTMENT_DATA
      ↓
Join
      ↓
FACT_SALES
```

---

# Incremental Loading

The project supports incremental processing using Delta Lake.

Instead of overwriting all existing data, new or changed records are merged into the existing target.

Flow:

```text
Incoming Data
      ↓
Existing Delta Table
      ↓
MERGE
```

---

# Delta MERGE / UPSERT

The MERGE operation follows:

```text
Matching Record
      ↓
UPDATE

New Record
      ↓
INSERT
```

This process is known as:

```text
UPSERT = UPDATE + INSERT
```

---

# Example Delta MERGE Concept

```python
from delta.tables import DeltaTable

target.alias("target").merge(
    source.alias("source"),
    "target.id = source.id"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()
```

The actual merge key depends on the target dataset.

---

# ETL Logging

Databricks records ETL execution details in Azure SQL Database.

Main audit table:

```sql
audit.ETL_LOG
```

Typical statuses include:

```text
STARTED
SUCCESS
FAILED
```

---

# ETL Logging Flow

```text
Start Notebook
      ↓
Write STARTED
      ↓
Process Data
      ↓
Successful?
   /       \
 Yes        No
 ↓          ↓
SUCCESS    FAILED
```

The log can contain:

* Process name
* Object name
* Start time
* End time
* Record count
* Status
* Error message

---

# Error Handling

Databricks notebooks use error-handling logic to capture processing failures.

Conceptually:

```python
try:
    # ETL processing

except Exception as e:
    # capture error
    # write FAILED log
    raise
```

Flow:

```text
Try ETL Processing
        ↓
Success
        ↓
Write SUCCESS
```

or:

```text
Processing Error
      ↓
Capture Exception
      ↓
Write FAILED
      ↓
Store Error Message
```

---

# Notebook Processing Flow

The Databricks implementation follows a logical sequence such as:

```text
Setup / Configuration
        ↓
Read Metadata
        ↓
Read Landing Data
        ↓
Bronze Processing
        ↓
Silver Processing
        ↓
Data Quality Checks
        ↓
Gold Processing
        ↓
Incremental MERGE
        ↓
ETL Logging
```

---

# Azure Data Factory Integration

Azure Data Factory acts as the orchestration layer.

ADF can execute Databricks notebooks in the required order.

```text
Azure Data Factory
        ↓
Databricks Notebook
        ↓
Bronze
        ↓
Silver
        ↓
Data Quality
        ↓
Gold
        ↓
MERGE
```

ADF controls **when the processing runs**, while Databricks performs the main transformations.

---

# Databricks vs ADF

These services have different responsibilities.

## Azure Databricks

Used for:

```text
Data Processing
PySpark
Transformations
Data Cleaning
Delta Lake
MERGE
Data Quality
```

## Azure Data Factory

Used for:

```text
Orchestration
Scheduling
Activity Sequencing
Notebook Execution
Pipeline Monitoring
```

Easy way to remember:

```text
ADF
 ↓
Controls the workflow

Databricks
 ↓
Processes the data
```

---

# Databricks vs ADLS

Databricks performs processing.

ADLS provides storage.

```text
ADLS
 ↓
Stores Data

Databricks
 ↓
Processes Data
```

For this project:

```text
SC1
 ↓
Source Files

Databricks
 ↓
Processing

SC2
 ↓
Managed Delta Table Storage
```

---

# Databricks vs Unity Catalog

Databricks provides the data-processing platform.

Unity Catalog provides governance and management of data objects.

```text
Databricks
    ↓
Runs Spark / PySpark

Unity Catalog
    ↓
Manages Catalogs / Schemas / Tables
```

---

# Complete Databricks Architecture

```text
                    Source CSV Files
                 Sales + Appointment
                         │
                         ↓
                    SC1 ADLS
                         │
                       Landing
                         │
                         ↓
                 Azure Databricks
                         │
                  Spark / PySpark
                         │
                         ↓
                      Bronze
                         │
                         ↓
                      Silver
                         │
                         ↓
                Data Quality Checks
                         │
                         ↓
                       Gold
                    /        \
                   ↓          ↓
      DIM_APPOINTMENT_DATA   FACT_SALES
                   \          /
                    \        /
                         ↓
                   Unity Catalog
                         ↓
                  Managed Tables
                         ↓
                      SC2 ADLS
```

Supporting components:

```text
Azure SQL Database
        │
        ├── metadata.OBJECTS_CONFIGURATION
        ├── metadata.OBJECTS_COLUMN_MAPPING
        └── audit.ETL_LOG
```

```text
Azure Key Vault
        │
        └── Secure Credentials / Secrets
```

```text
Azure Data Factory
        │
        └── Pipeline Orchestration
```

---

# Easy Project Explanation

The easiest way to remember the Databricks role is:

```text
SC1 Landing
     ↓
Databricks reads CSV
     ↓
Bronze
     ↓
Clean + Transform
     ↓
Silver
     ↓
Data Quality
     ↓
Gold
     ↓
DIM + FACT
     ↓
Unity Catalog Managed Tables
     ↓
SC2
```

---

# Interview Explanation

> In my Logistics Azure Data Engineering project, I used Azure Databricks as the main processing engine. Databricks reads Sales and Appointment CSV files from the Landing area in the first ADLS account. I used PySpark for Bronze ingestion, Silver cleaning and metadata-driven transformations, data-quality checks, and Gold Dimension and Fact table creation. Bronze, Silver, and Gold are Unity Catalog managed Delta tables whose managed storage is configured in the second ADLS account. I also implemented Delta MERGE for incremental loading, Azure SQL-based metadata and audit logging, and Azure Key Vault for secure credential management.

---

# Summary

Azure Databricks is the main transformation engine of the Logistics Azure Data Engineering Project.

It connects:

```text
SC1 Landing
      ↓
Databricks
      ↓
Bronze
      ↓
Silver
      ↓
Gold
      ↓
Unity Catalog
      ↓
SC2 Managed Storage
```

Along with:

```text
Azure SQL → Metadata + Audit
Azure Key Vault → Security
Azure Data Factory → Orchestration
```

This provides a complete, secure, metadata-driven, and scalable Azure Data Engineering processing architecture.
