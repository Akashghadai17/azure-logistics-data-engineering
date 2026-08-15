# Silver Layer Implementation

## Overview

The Silver layer is the **cleaning and transformation layer** of the Logistics Azure Data Engineering Project.

The Bronze layer preserves the source data in raw or near-raw form.

The Silver layer takes this Bronze data and converts it into:

* Clean data
* Standardized data
* Correctly typed data
* Deduplicated data
* Business-ready structured data

The Silver output is stored as **Unity Catalog managed Delta tables**.

---

# Silver Layer Architecture

```text
Bronze Managed Tables
        ↓
Azure Databricks
        ↓
Read Metadata Mapping
        ↓
Column Mapping
        ↓
Data Cleaning
        ↓
Data Type Conversion
        ↓
NULL Handling
        ↓
Duplicate Removal
        ↓
Silver Managed Tables
        ↓
Unity Catalog
        ↓
SC2 Managed Storage
```

---

# Silver Layer Purpose

The main purpose of the Silver layer is to improve data quality.

The Silver layer performs:

* Reading Bronze managed tables
* Metadata-driven column mapping
* Column renaming
* Data type conversion
* Invalid-value handling
* NULL handling
* Duplicate removal
* Data cleaning
* Data standardization
* Validation after transformation
* Writing Silver managed Delta tables

---

# Bronze to Silver

Bronze data is used as the source for Silver.

```text
Bronze
   ↓
Raw / Near-Raw Data
   ↓
Silver Transformation
   ↓
Clean Data
```

Easy way to remember:

```text
Bronze = Preserve

Silver = Clean + Standardize
```

---

# Source Tables

The Silver layer processes two Bronze datasets:

```text
Sales Bronze Data
Appointment Bronze Data
```

Logical object names used by the metadata-driven processing include:

```text
SALES_DATA_PRIOR_DAY
APPOINTMENT_DATA
```

---

# Reading Bronze Tables

Because Bronze data is stored as Unity Catalog managed tables, Databricks can read it directly.

Conceptually:

```python
sales_bronze_df = spark.table(
    "<catalog>.bronze.<sales_table>"
)
```

Appointment data:

```python
appointment_bronze_df = spark.table(
    "<catalog>.bronze.<appointment_table>"
)
```

---

# Metadata-Driven Column Mapping

A major part of the Silver implementation is **metadata-driven transformation**.

Azure SQL Database contains column-mapping configuration in:

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

Instead of manually writing all source-to-target mappings inside the notebook, Databricks reads the mapping information from Azure SQL.

---

# Why Column Mapping Is Required

Source column names may be different from the standardized target column names.

For example, the Appointment source contains:

```text
APPOINTMENT_TITLE
APPOINTMENT_STATUS
APPOINTMENT_DATE
```

The target Silver columns can be standardized as:

```text
TITLE
STATUS
DATE
```

Therefore:

```text
APPOINTMENT_TITLE
        ↓
TITLE

APPOINTMENT_STATUS
        ↓
STATUS

APPOINTMENT_DATE
        ↓
DATE
```

This transformation belongs in the Silver layer.

---

# Column Mapping Flow

```text
Bronze Data
     ↓
Read Azure SQL Metadata
     ↓
Get Mapping for Object
     ↓
Source Column
     ↓
Target Column
     ↓
Target Data Type
     ↓
Silver Data
```

---

# apply_mapping Function

A reusable PySpark function is used to apply the mapping.

Conceptually:

```python
sales_silver_df = apply_mapping(
    sales_bronze_df,
    "SALES_DATA_PRIOR_DAY"
)
```

For Appointment:

```python
appointment_silver_df = apply_mapping(
    appointment_bronze_df,
    "APPOINTMENT_DATA"
)
```

The same function can therefore process different datasets based on metadata.

---

# Why a Reusable Function Is Used

Without reusable mapping logic:

```text
Sales
↓
Separate Mapping Code

Appointment
↓
Separate Mapping Code
```

With metadata:

```text
Generic apply_mapping()
        ↓
Object Name
        ↓
Read Metadata
        ↓
Apply Required Mapping
```

This reduces duplicate code.

---

# Mapping Responsibilities

The mapping process handles:

1. Source column identification
2. Target column naming
3. Target data type selection
4. Column conversion

Conceptually:

```text
SOURCE_COLUMN
      ↓
TARGET_COLUMN
      ↓
TARGET_DATA_TYPE
```

---

# Data Type Conversion

Bronze data is read mainly as strings to safely preserve the original source values.

Silver converts those values into the required target data types.

Common target types include:

```text
STRING
INTEGER
FLOAT
DATE
TIMESTAMP
```

Example:

```text
Bronze

PRICE = "215.0000"

        ↓

Silver

PRICE = 215.0
```

---

# Why Type Conversion Is Done in Silver

CSV source data can contain unexpected values.

If data is converted immediately in Bronze, malformed values can cause ingestion failure.

Therefore:

```text
Bronze
   ↓
Keep Values Safely

Silver
   ↓
Clean Values
   ↓
Convert Types
```

This separates ingestion from cleaning.

---

# Malformed Numeric Value Issue

During Sales Silver processing, a numeric column contained a value similar to:

```text
215.0000, 230.0000
```

The target data type was:

```text
FLOAT
```

A direct Spark cast failed because the value contained more than one number in a single string.

The Spark error was similar to:

```text
CAST_INVALID_INPUT
```

The value could not be directly cast from STRING to FLOAT.

---

# Why the Cast Failed

A valid FLOAT value looks like:

```text
215.0000
```

But the source contained:

```text
215.0000, 230.0000
```

This is not one valid floating-point value.

Therefore:

```text
STRING
"215.0000, 230.0000"

       ↓

FLOAT

       ✕
Cannot Directly Cast
```

---

# Fix for Malformed Numeric Data

Before applying the final FLOAT conversion, the source value must be cleaned or safely converted.

Conceptually:

```text
Raw Value
215.0000, 230.0000
        ↓
Clean / Extract Valid Value
        ↓
215.0000
        ↓
Cast to FLOAT
        ↓
215.0
```

The Silver layer is the correct location for handling this kind of source-data problem.

---

# Safe Casting

Where malformed input is possible, Spark safe-casting logic can be used.

Conceptually:

```sql
try_cast(column_name AS FLOAT)
```

With safe casting:

```text
Valid Value
"215.0000"
     ↓
215.0

Invalid Value
"ABC"
     ↓
NULL
```

The resulting NULL can then be handled according to project rules.

---

# Data Cleaning

Silver performs cleaning before data is used for analytics.

Cleaning activities can include:

* Removing unwanted characters
* Trimming spaces
* Standardizing text
* Correcting malformed values
* Converting numeric columns
* Converting date columns
* Handling blank values

---

# Trimming String Values

Leading and trailing spaces can create inconsistent records.

Example:

```text
" COMPLETED "
```

becomes:

```text
"COMPLETED"
```

PySpark concept:

```python
from pyspark.sql.functions import trim

df = df.withColumn(
    "STATUS",
    trim("STATUS")
)
```

---

# Standardizing Text

Text values may appear in different formats.

Example:

```text
completed
COMPLETED
Completed
```

These can be standardized.

For example:

```text
COMPLETED
```

Conceptually:

```python
from pyspark.sql.functions import upper

df = df.withColumn(
    "STATUS",
    upper("STATUS")
)
```

Standardization helps prevent the same business value from appearing in multiple formats.

---

# NULL Handling

The Silver layer checks NULL values in important columns.

NULL values can come from:

* Missing source values
* Empty strings
* Failed data type conversions
* Invalid source records

Flow:

```text
Silver Transformation
       ↓
Check NULL Values
       ↓
Handle According to Column Rule
```

---

# NULL Handling Strategy

NULL handling depends on the meaning of the column.

Possible actions include:

```text
Keep NULL
Fill Default Value
Remove Invalid Record
Flag Record for Validation
```

Not every NULL should automatically be replaced.

Business meaning must be considered.

---

# Empty String vs NULL

An empty string:

```text
""
```

is not always the same as:

```text
NULL
```

Silver processing can standardize blank values where required.

Conceptually:

```text
Empty String
     ↓
Convert to NULL
     ↓
Apply NULL Rule
```

---

# Duplicate Removal

Duplicate records are removed during Silver processing.

Duplicates can cause:

* Incorrect counts
* Double counting
* Incorrect totals
* Incorrect analytics

PySpark can remove exact duplicate rows using:

```python
df = df.dropDuplicates()
```

---

# Business-Key Deduplication

In some datasets, duplicate detection should use selected columns instead of every column.

Conceptually:

```python
df = df.dropDuplicates(
    ["<business_key_column>"]
)
```

The selected columns depend on the dataset.

---

# Why Deduplication Is Important

Suppose the same Sales record appears twice:

```text
Sale 101
Sale 101
```

Without duplicate removal:

```text
Sales Count = 2
```

After deduplication:

```text
Sales Count = 1
```

This improves analytical accuracy.

---

# Data Standardization

Silver creates consistent data.

Examples include:

```text
Column Names
Data Types
Text Values
Dates
Numeric Values
NULL Representation
```

This means downstream Gold logic receives predictable data.

---

# Appointment Silver Processing

Appointment Bronze data goes through:

```text
Appointment Bronze
        ↓
Read Mapping
        ↓
Rename Columns
        ↓
Convert Data Types
        ↓
Clean Values
        ↓
Handle NULLs
        ↓
Remove Duplicates
        ↓
Appointment Silver
```

Example source-to-target mapping:

```text
APPOINTMENT_TITLE
        ↓
TITLE

APPOINTMENT_STATUS
        ↓
STATUS

APPOINTMENT_DATE
        ↓
DATE
```

---

# Sales Silver Processing

Sales Bronze data follows the same overall framework.

```text
Sales Bronze
     ↓
Read Mapping
     ↓
Rename Columns
     ↓
Clean Numeric Values
     ↓
Convert Data Types
     ↓
Handle NULLs
     ↓
Remove Duplicates
     ↓
Sales Silver
```

The Sales data required additional care because malformed numeric source values were identified during transformation.

---

# Silver Validation

After cleaning and transformation, Silver data is checked before it is saved.

Checks may include:

* Column count
* Required columns
* Data types
* NULL values
* Duplicate records
* Invalid values
* Row counts

---

# Schema Check

The final Silver schema should match the expected standardized schema.

Conceptually:

```text
Transformed Columns
        ↓
Expected Silver Columns
        ↓
Compare
        ↓
Valid Schema
```

---

# Data Type Validation

After conversion, the target types should match the metadata definition.

For example:

```text
PRICE
↓
FLOAT

DATE
↓
DATE

TITLE
↓
STRING
```

This ensures Gold receives consistent data.

---

# Row Count Validation

Row counts can also be compared during transformation.

Conceptually:

```text
Bronze Count
     ↓
Cleaning
     ↓
Silver Count
```

Differences can occur because of:

* Duplicate removal
* Invalid-record removal
* Filtering
* Cleaning rules

The count should therefore be monitored.

---

# Silver Managed Tables

After successful transformation, Silver DataFrames are written as Unity Catalog managed Delta tables.

Conceptually:

```python
sales_silver_df.write \
    .format("delta") \
    .mode("overwrite") \
    .saveAsTable(
        "<catalog>.silver.<sales_table>"
    )
```

Appointment:

```python
appointment_silver_df.write \
    .format("delta") \
    .mode("overwrite") \
    .saveAsTable(
        "<catalog>.silver.<appointment_table>"
    )
```

The exact write mode depends on the processing step.

---

# Physical Storage

Silver tables are managed through Unity Catalog.

Their Delta files are physically stored in **SC2 managed storage**.

```text
Silver Table
     ↓
Unity Catalog
     ↓
Managed Delta Table
     ↓
SC2
```

They are not manually written to an SC1 Silver folder.

---

# SC1 vs SC2

## SC1

Used for:

```text
Landing
Logs
Archive
```

## SC2

Used for:

```text
Unity Catalog Managed Storage
```

which contains managed:

```text
Bronze Tables
Silver Tables
Gold Tables
```

---

# Silver and Azure SQL Metadata

Azure SQL provides the transformation configuration.

```text
Azure SQL Database
        ↓
metadata.OBJECTS_COLUMN_MAPPING
        ↓
Databricks
        ↓
Silver Transformation
```

This separates configuration from transformation logic.

---

# Metadata-Driven Silver Architecture

```text
               Azure SQL Database
                       │
                       ↓
         OBJECTS_COLUMN_MAPPING
                       │
                       ↓
Bronze Table → Azure Databricks
                       │
                       ↓
                apply_mapping()
                       │
             ┌─────────┼─────────┐
             ↓         ↓         ↓
           Rename     Cast      Clean
             │         │         │
             └─────────┼─────────┘
                       ↓
                   Silver
```

---

# Silver and Data Quality

Silver transformation and data-quality checking are related but have different goals.

Silver transformation:

```text
Clean the data
```

Data-quality checks:

```text
Verify the cleaned data
```

Flow:

```text
Bronze
   ↓
Silver Transformation
   ↓
Data Quality Checks
   ↓
Gold
```

---

# Error Handling

Silver processing uses error handling to capture transformation failures.

Conceptually:

```python
try:
    # Read Bronze
    # Apply mapping
    # Clean values
    # Convert data types
    # Write Silver

except Exception as e:
    # Capture error
    # Write FAILED status
    raise
```

---

# Transformation Failure Example

The malformed Sales numeric value caused a cast error.

Flow:

```text
Sales Bronze
     ↓
apply_mapping()
     ↓
FLOAT Cast
     ↓
Malformed Value Found
     ↓
CAST_INVALID_INPUT
     ↓
Transformation Failed
```

The transformation logic was then improved to safely handle malformed numeric data.

---

# ETL Logging

Silver processing can record execution information in:

```sql
audit.ETL_LOG
```

Typical information includes:

* Object name
* Layer name
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

# Successful Silver Flow

```text
Start Silver Processing
        ↓
Write STARTED Log
        ↓
Read Bronze
        ↓
Read Mapping
        ↓
Transform
        ↓
Clean
        ↓
Validate
        ↓
Write Silver
        ↓
Write SUCCESS Log
```

---

# Failed Silver Flow

```text
Start Silver Processing
        ↓
Read Bronze
        ↓
Transformation Error
        ↓
Capture Exception
        ↓
Write FAILED Log
```

---

# Silver to Gold

After Sales and Appointment data are cleaned, they become inputs for the Gold layer.

```text
Appointment Silver
        ↓
DIM_APPOINTMENT_DATA
```

and:

```text
Sales Silver
      +
DIM_APPOINTMENT_DATA
      ↓
FACT_SALES
```

Therefore, the Silver layer acts as the clean foundation for Gold modeling.

---

# Bronze vs Silver vs Gold

| Layer  | Main Purpose                                   |
| ------ | ---------------------------------------------- |
| Bronze | Preserve raw or near-raw source data           |
| Silver | Clean, standardize, and validate data          |
| Gold   | Build business-ready Dimension and Fact tables |

Easy way to remember:

```text
Bronze
Raw

Silver
Clean

Gold
Business
```

---

# Complete Silver Processing Flow

```text
                   Bronze Managed Tables
                    /                \
                   ↓                  ↓
                Sales             Appointment
                   \                  /
                    \                /
                         ↓
                  Azure Databricks
                         │
                         ↓
                Read SQL Metadata
                         │
                         ↓
                  apply_mapping()
                         │
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
   Rename Columns   Convert Types     Clean Data
        │                │                │
        └────────────────┼────────────────┘
                         ↓
                    Handle NULLs
                         ↓
                  Remove Duplicates
                         ↓
                  Validate Results
                         ↓
                 Silver Managed Tables
                         ↓
                    Unity Catalog
                         ↓
                 SC2 Managed Storage
```

---

# Key Problem Solved in Silver

One important issue identified during the implementation was malformed numeric source data.

Example:

```text
215.0000, 230.0000
```

The value could not be directly converted to:

```text
FLOAT
```

The Silver layer handled this problem by cleaning or safely converting the source value before applying the required target data type.

This demonstrates why data-quality and transformation logic should be applied before data reaches the Gold layer.

---

# Easy Silver Layer Explanation

The Silver layer can be remembered as:

```text
Read Bronze
    ↓
Map Columns
    ↓
Clean Data
    ↓
Fix Data Types
    ↓
Handle NULLs
    ↓
Remove Duplicates
    ↓
Validate
    ↓
Save Silver
```

---

# Interview Explanation

> In my Logistics Azure Data Engineering project, the Silver layer cleans and standardizes the Bronze data using PySpark. I implemented metadata-driven column mapping using Azure SQL, so source columns and target data types are configured outside the notebook. The Silver processing handles column renaming, malformed values, data-type conversion, NULL values, duplicate removal, and standardization. During implementation, I also handled a malformed numeric value that caused a Spark cast error. After cleaning, the Sales and Appointment datasets are stored as Unity Catalog managed Delta tables in the Silver schema, with their physical storage managed in the second ADLS account.

---

# Summary

The Silver layer converts raw Bronze data into trusted and standardized datasets.

```text
Bronze
   ↓
Metadata Mapping
   ↓
Column Renaming
   ↓
Data Cleaning
   ↓
Data Type Conversion
   ↓
NULL Handling
   ↓
Duplicate Removal
   ↓
Validation
   ↓
Silver Managed Tables
   ↓
Unity Catalog
   ↓
SC2
```

The cleaned Silver datasets are then used to build the Gold **Dimension and Fact tables**.
