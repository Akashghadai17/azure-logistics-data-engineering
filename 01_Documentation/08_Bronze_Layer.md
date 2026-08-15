# Bronze Layer Implementation

## Overview

The Bronze layer is the first processing layer in the **Logistics Azure Data Engineering Project**.

Its main purpose is to read the original **Sales** and **Appointment** CSV files from the Landing area in **SC1**, validate the source structure, and store the data as **Unity Catalog managed Delta tables**.

Bronze keeps the source data as close as possible to its original form.

---

# Bronze Layer Architecture

```text
Sales CSV + Appointment CSV
             ↓
          SC1 ADLS
             ↓
           Landing
             ↓
      Azure Databricks
             ↓
       Read CSV Files
             ↓
      Schema Validation
             ↓
      Column Validation
             ↓
       Bronze Tables
             ↓
        Unity Catalog
             ↓
      SC2 Managed Storage
```

---

# Source Storage

The source CSV files are stored in **Storage Account 1 (SC1)**.

SC1 is used for:

```text
SC1
│
├── landing
├── logs
└── archive
```

The Bronze notebook reads source files from:

```text
SC1 → landing
```

---

# Source Datasets

The project processes two datasets:

1. **Sales Data**
2. **Appointment Data**

Logical object names used in the project include:

```text
SALES_DATA_PRIOR_DAY
APPOINTMENT_DATA
```

---

# Bronze Layer Purpose

The Bronze layer is responsible for:

* Reading source CSV files
* Preserving original source values
* Reading source columns safely
* Validating expected schema
* Checking expected columns
* Finding missing columns
* Finding extra columns
* Adding technical columns where required
* Writing data as Delta tables
* Registering tables in Unity Catalog
* Preparing the data for Silver processing

---

# Bronze Layer Principle

The Bronze layer performs **minimal transformation**.

Major cleaning is not done here.

```text
Bronze
   ↓
Preserve Source Data
```

The following operations are mainly performed later in Silver:

* Column renaming
* Data type conversion
* NULL handling
* Duplicate removal
* Invalid-value cleaning
* Data standardization
* Business transformations

Easy way to remember:

```text
Bronze = Raw / Near-Raw
Silver = Cleaned
Gold   = Business Ready
```

---

# Reading CSV Data

PySpark is used to read source files.

Conceptually:

```python
df = (
    spark.read
    .format("csv")
    .option("header", "true")
    .option("inferSchema", "false")
    .load(source_path)
)
```

---

# Why inferSchema Is Disabled

In the Bronze layer, source values are preserved safely.

Using:

```python
.option("inferSchema", "false")
```

causes Spark to initially read CSV columns as strings.

This is useful because source files may contain malformed values.

For example:

```text
215.0000, 230.0000
```

If Spark tries to directly read this as a FLOAT, processing may fail.

Instead:

```text
Source Value
     ↓
Read as STRING
     ↓
Bronze
     ↓
Clean in Silver
     ↓
Convert to FLOAT
```

This makes Bronze ingestion more reliable.

---

# Sales Bronze Processing

The Sales source file is read from SC1 Landing.

```text
Sales CSV
    ↓
SC1 Landing
    ↓
Azure Databricks
    ↓
Read Using PySpark
    ↓
Validate Schema
    ↓
Bronze Sales Table
```

The Sales data is preserved before Silver transformations are applied.

---

# Appointment Bronze Processing

Appointment data follows the same process.

```text
Appointment CSV
       ↓
SC1 Landing
       ↓
Azure Databricks
       ↓
Read Using PySpark
       ↓
Validate Schema
       ↓
Bronze Appointment Table
```

---

# Schema Validation

Schema validation ensures that the incoming CSV file has the expected structure.

The validation compares:

```text
Actual Columns
       ↓
Expected Columns
```

If the columns match:

```text
Continue Processing
```

If the columns do not match:

```text
Raise Error
```

---

# Column Count Validation

The pipeline first checks the number of columns.

Example:

```text
Actual Columns   : 40
Expected Columns : 40
```

However, matching column counts alone does not mean the schema is correct.

The actual column names must also match.

---

# Missing Column Validation

The pipeline checks whether any expected columns are missing.

Conceptually:

```python
missing_columns = expected_columns - actual_columns
```

Example:

```text
Missing Columns:
['TITLE', 'STATUS', 'DATE']
```

---

# Extra Column Validation

The pipeline also checks for unexpected columns.

Conceptually:

```python
extra_columns = actual_columns - expected_columns
```

Example:

```text
Extra Columns:
[
    'APPOINTMENT_TITLE',
    'APPOINTMENT_STATUS',
    'APPOINTMENT_DATE'
]
```

---

# Appointment Schema Issue Found During Implementation

During Appointment Bronze validation, the pipeline initially reported:

```text
Actual Columns   : 40
Expected Columns : 40

Missing Columns:
['TITLE', 'STATUS', 'DATE']

Extra Columns:
[
    'APPOINTMENT_TITLE',
    'APPOINTMENT_STATUS',
    'APPOINTMENT_DATE'
]
```

This showed that the source file used:

```text
APPOINTMENT_TITLE
APPOINTMENT_STATUS
APPOINTMENT_DATE
```

instead of:

```text
TITLE
STATUS
DATE
```

The expected Bronze schema was corrected to match the actual source file.

The standardized target names are handled later during Silver transformation using metadata-based column mapping.

---

# Why This Validation Is Important

Without schema validation, incorrect source files could enter the pipeline and cause failures later.

Example:

```text
Expected Column
CUSTOMER_ID

Incoming Column
CUST_ID
```

If this difference is not identified early, Silver or Gold transformations may fail.

Therefore:

```text
Landing
   ↓
Validate
   ↓
Bronze
```

is safer than loading every source file without checks.

---

# Schema Validation Logic

Conceptually:

```python
actual_columns = set(df.columns)
expected_columns = set(expected_columns_list)

missing_columns = expected_columns - actual_columns
extra_columns = actual_columns - expected_columns

if missing_columns or extra_columns:
    raise Exception("Schema validation failed")
```

This stops invalid source structures from moving further into the ETL pipeline.

---

# Bronze Validation Flow

```text
Read CSV
   ↓
Get Actual Columns
   ↓
Get Expected Columns
   ↓
Compare
   ↓
Schema Valid?
   │
   ├── Yes → Continue
   │
   └── No  → Raise Error
```

---

# Technical Columns

Technical columns can be added in Bronze where required.

Examples include:

```text
SOURCE_FILE_NAME
LOAD_TIMESTAMP
PROCESSING_DATE
```

These columns help with:

* Traceability
* Debugging
* Auditing
* Source tracking

---

# Source File Name

Spark can capture the input file name.

Conceptually:

```python
from pyspark.sql.functions import input_file_name

df = df.withColumn(
    "SOURCE_FILE_NAME",
    input_file_name()
)
```

This helps identify which source file produced a record.

---

# Load Timestamp

A load timestamp can be added using:

```python
from pyspark.sql.functions import current_timestamp

df = df.withColumn(
    "LOAD_TIMESTAMP",
    current_timestamp()
)
```

This identifies when the record entered the Bronze layer.

---

# Bronze Delta Tables

After successful validation, the data is written as **Delta tables**.

The project uses:

```text
Azure Databricks
        +
Delta Lake
        +
Unity Catalog
```

Bronze data is therefore no longer handled only as CSV after ingestion.

---

# Unity Catalog Bronze Schema

Bronze data is registered under the Unity Catalog Bronze schema.

Conceptually:

```text
Unity Catalog
      ↓
bronze
      ↓
Sales Bronze Table
Appointment Bronze Table
```

---

# Managed Bronze Tables

The project uses **Unity Catalog managed tables**.

Conceptually:

```python
df.write \
    .format("delta") \
    .mode("overwrite") \
    .saveAsTable("<catalog>.bronze.<table_name>")
```

The exact table name depends on the object being processed.

---

# Physical Storage

Bronze tables are physically stored in **SC2**, because SC2 is configured as the managed storage location for Unity Catalog.

Correct flow:

```text
Bronze Table
     ↓
Unity Catalog Managed Table
     ↓
SC2 Managed Storage
```

Bronze data is not manually written into an SC1 Bronze folder.

---

# SC1 vs SC2 in Bronze Processing

## SC1

Used for source files.

```text
SC1
└── landing
```

## SC2

Used for managed Delta table storage.

```text
SC2
└── Unity Catalog Managed Storage
```

Therefore:

```text
SC1 Landing CSV
       ↓
Databricks
       ↓
Bronze Managed Table
       ↓
SC2
```

---

# Reading Bronze Tables

After a Bronze table is created, it can be read using Spark.

Conceptually:

```python
sales_bronze_df = spark.table(
    "<catalog>.bronze.<sales_table>"
)
```

Appointment:

```python
appointment_bronze_df = spark.table(
    "<catalog>.bronze.<appointment_table>"
)
```

These DataFrames become the input for Silver processing.

---

# Bronze to Silver Flow

```text
Bronze Managed Table
        ↓
Read Using Spark
        ↓
Read Metadata Mapping
        ↓
Apply Column Mapping
        ↓
Clean Data
        ↓
Convert Data Types
        ↓
Remove Duplicates
        ↓
Silver Managed Table
```

---

# Bronze vs Silver Responsibilities

| Bronze Layer                         | Silver Layer            |
| ------------------------------------ | ----------------------- |
| Read source CSV                      | Read Bronze table       |
| Preserve original values             | Clean values            |
| Validate schema                      | Apply metadata mapping  |
| Check missing columns                | Rename columns          |
| Check extra columns                  | Convert data types      |
| Minimal transformation               | Handle malformed values |
| Add technical columns where required | Handle NULLs            |
| Create managed Delta tables          | Remove duplicates       |

---

# Error Handling

Bronze processing is wrapped with error-handling logic.

Conceptually:

```python
try:
    # Read CSV
    # Validate schema
    # Write Bronze table

except Exception as e:
    # Capture error
    # Record failure
    raise
```

If schema validation fails:

```text
Source File
    ↓
Validation Failure
    ↓
Capture Error
    ↓
ETL Status = FAILED
```

---

# ETL Audit Logging

Bronze processing is tracked using the Azure SQL audit table:

```sql
audit.ETL_LOG
```

The log can store information such as:

* Object name
* Processing layer
* Start time
* End time
* Record count
* Status
* Error message

Example statuses:

```text
STARTED
SUCCESS
FAILED
```

---

# Successful Bronze Execution

```text
Start Bronze Job
       ↓
Write STARTED Log
       ↓
Read Landing File
       ↓
Validate Schema
       ↓
Write Bronze Table
       ↓
Write SUCCESS Log
```

---

# Failed Bronze Execution

```text
Start Bronze Job
       ↓
Read Landing File
       ↓
Validation Failed
       ↓
Capture Exception
       ↓
Write FAILED Log
```

---

# Archive Process

SC1 contains an Archive area.

After a source file has been successfully processed, it can be moved from:

```text
SC1 / landing
```

to:

```text
SC1 / archive
```

Flow:

```text
Landing File
     ↓
Successful Processing
     ↓
Archive
```

This helps prevent successfully processed source files from being treated as new files.

---

# Landing vs Bronze vs Archive

## Landing

Stores incoming CSV files.

```text
SC1 / landing
```

## Bronze

Stores raw or near-raw managed Delta tables.

```text
Unity Catalog / bronze
        ↓
SC2
```

## Archive

Stores source files after successful processing.

```text
SC1 / archive
```

Easy way to remember:

```text
Landing = New Source File

Bronze = Loaded Raw Data

Archive = Processed Source File
```

---

# Complete Bronze Data Flow

```text
               Sales CSV
                   │
                   ↓
             SC1 Landing
                   │
                   ↓
           Azure Databricks
                   │
                   ↓
             Read as STRING
                   │
                   ↓
          Validate Column Count
                   │
                   ↓
        Validate Column Names
                   │
                   ↓
         Missing / Extra Check
                   │
                   ↓
             Schema Valid
                   │
                   ↓
          Add Technical Columns
                   │
                   ↓
          Write Delta Managed Table
                   │
                   ↓
             Unity Catalog
                   │
                   ↓
             Bronze Schema
                   │
                   ↓
         SC2 Managed Storage
```

Appointment data follows the same process.

---

# Bronze Layer Benefits

The Bronze layer provides:

* Preservation of source data
* Early schema validation
* Detection of incorrect files
* Safe handling of source values
* Source traceability
* Reliable Delta storage
* Unity Catalog management
* Separation between source files and managed data
* Stable input for Silver processing

---

# Easy Explanation

Bronze can be remembered as:

```text
Receive
   ↓
Validate
   ↓
Preserve
   ↓
Store
```

The Bronze layer does **not try to fully clean the data**.

Its responsibility is to safely ingest and preserve it.

---

# Interview Explanation

> In my Logistics Azure Data Engineering project, the Bronze layer reads Sales and Appointment CSV files from the Landing area in the first ADLS account. I read the source values safely as strings, validate the schema by checking expected, missing, and extra columns, and preserve the raw source information with minimal transformation. After validation, the data is stored as Unity Catalog managed Delta tables. The physical managed storage for these Bronze tables is configured in the second ADLS account.

---

# Summary

The Bronze layer provides the first reliable stage of the ETL pipeline.

```text
SC1 Landing
     ↓
Databricks
     ↓
Read CSV
     ↓
Schema Validation
     ↓
Bronze Managed Delta Table
     ↓
Unity Catalog
     ↓
SC2 Managed Storage
```

The Bronze data then becomes the source for the Silver transformation layer.

