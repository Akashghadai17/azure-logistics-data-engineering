# Data Quality Checks

## Overview

Data Quality Checks are implemented in the **Logistics Azure Data Engineering Project** to verify that the processed data is accurate, complete, consistent, and suitable for analytical use.

The checks are mainly performed after Silver processing and before data is used in the Gold layer.

The goal is to prevent bad-quality data from moving further through the pipeline.

---

# Data Quality Flow

```text
Bronze Data
     ↓
Silver Transformation
     ↓
Data Quality Checks
     ↓
Valid Data
     ↓
Gold Layer
```

If the data passes the required checks:

```text
PASS
 ↓
Continue Processing
```

If a critical check fails:

```text
FAIL
 ↓
Capture Error
 ↓
Stop / Fail Processing
```

---

# Why Data Quality Is Important

Without Data Quality Checks, the pipeline may contain:

* Missing values
* Duplicate records
* Incorrect schema
* Invalid data types
* Invalid relationships
* Incorrect record counts
* Missing primary keys
* Broken foreign-key relationships

These problems can produce incorrect analytical results.

Therefore, validation is performed before creating the final Gold tables.

---

# Main Data Quality Checks

The project includes checks such as:

1. Row Count Validation
2. NULL Validation
3. Duplicate Validation
4. Primary Key Validation
5. Foreign Key Validation
6. Schema Validation
7. Required Column Validation
8. Data Type Validation
9. Invalid Value Validation

---

# 1. Row Count Validation

Row Count Validation checks how many records are available in a dataset.

Conceptually:

```python
row_count = df.count()

print("Row Count:", row_count)
```

Example:

```text
Row Count: 1000
```

---

# Why Row Count Is Checked

Row count helps identify problems such as:

* Empty datasets
* Unexpected data loss
* Incorrect filtering
* Duplicate removal differences
* Failed ingestion

For example:

```text
Bronze Count
   ↓
1000

Silver Count
   ↓
980
```

The difference should be understood.

It may be valid if duplicates or invalid records were removed.

---

# Row Count Flow

```text
Input Dataset
      ↓
Count Records
      ↓
Compare Expected Result
      ↓
PASS / FAIL
```

---

# Empty Dataset Check

A dataset should not continue if no records are available where data is expected.

Conceptually:

```python
if df.count() == 0:
    raise Exception("Data quality failed: Dataset is empty")
```

---

# 2. NULL Validation

NULL validation identifies missing values in important columns.

Conceptually:

```python
from pyspark.sql.functions import col

null_count = df.filter(
    col("<column_name>").isNull()
).count()
```

---

# Why NULL Checks Are Important

Important business keys should usually not contain NULL values.

For example:

```text
APPOINTMENT_ID = NULL
```

can create problems when building:

```text
DIM_APPOINTMENT_DATA
```

Similarly, a NULL key in Sales can prevent proper joins.

---

# NULL Validation Flow

```text
Dataset
   ↓
Select Important Column
   ↓
Check NULL Count
   ↓
NULL Count = 0?
   │
   ├── Yes → PASS
   └── No  → FAIL / Investigate
```

---

# Checking Multiple Columns

Conceptually:

```python
from pyspark.sql.functions import col, sum as spark_sum

df.select(
    [
        spark_sum(
            col(c).isNull().cast("int")
        ).alias(c)
        for c in df.columns
    ]
).show()
```

This helps identify NULL values across the dataset.

---

# NULL Handling vs NULL Validation

These are different activities.

## NULL Handling

Performed during Silver transformation.

```text
Find NULL
   ↓
Clean / Replace / Keep / Remove
```

## NULL Validation

Performed after transformation.

```text
Check whether required NULL rules were satisfied
```

Easy way to remember:

```text
Silver
 ↓
Fix

Data Quality
 ↓
Verify
```

---

# 3. Duplicate Validation

Duplicate validation checks whether the same business record appears more than once.

Duplicates can cause:

* Double counting
* Incorrect Sales totals
* Incorrect Dimension records
* Incorrect analytics

---

# Exact Duplicate Check

Conceptually:

```python
total_count = df.count()

distinct_count = df.distinct().count()

duplicate_count = total_count - distinct_count
```

Expected:

```text
Duplicate Count = 0
```

after required deduplication.

---

# Business-Key Duplicate Check

For important keys:

```python
from pyspark.sql.functions import count

duplicate_df = (
    df.groupBy("<business_key>")
      .count()
      .filter("count > 1")
)
```

Example:

```text
APPOINTMENT_ID
       ↓
Should identify one required business record
```

---

# Duplicate Validation Flow

```text
Dataset
   ↓
Group by Business Key
   ↓
Count Records
   ↓
Count > 1?
   │
   ├── Yes → Duplicate
   └── No  → Valid
```

---

# 4. Primary Key Validation

A Primary Key should uniquely identify a record.

The project validates important key columns before using them in analytical tables.

A valid key should generally be:

```text
NOT NULL
+
UNIQUE
```

---

# Primary Key NULL Check

Conceptually:

```python
pk_null_count = df.filter(
    col("<primary_key>").isNull()
).count()
```

Expected:

```text
0
```

---

# Primary Key Duplicate Check

Conceptually:

```python
pk_duplicate_count = (
    df.groupBy("<primary_key>")
      .count()
      .filter("count > 1")
      .count()
)
```

Expected:

```text
0
```

---

# Primary Key Validation Logic

```text
Primary Key
    ↓
NULL?
  /     \
Yes      No
 ↓        ↓
FAIL    Duplicate?
          /   \
        Yes    No
         ↓      ↓
       FAIL    PASS
```

---

# Gold Dimension Key Validation

For:

```text
DIM_APPOINTMENT_DATA
```

the Dimension key should uniquely identify each Dimension row.

If a surrogate key is used:

```text
APPOINTMENT_KEY
```

it should satisfy:

```text
No NULLs
No Duplicates
```

---

# 5. Foreign Key Validation

Foreign Key Validation checks whether records in one table correctly reference records in another table.

In the Gold model:

```text
DIM_APPOINTMENT_DATA
        ↓
APPOINTMENT_KEY
        ↓
FACT_SALES
```

The Fact table should reference valid Dimension keys where required.

---

# Foreign Key Validation Flow

```text
FACT_SALES
    ↓
Read Foreign Key
    ↓
Search DIM_APPOINTMENT_DATA
    ↓
Matching Dimension Key?
    │
    ├── Yes → Valid
    └── No  → Invalid
```

---

# Foreign Key Check Using Left Anti Join

PySpark can identify unmatched records.

Conceptually:

```python
invalid_fk_df = (
    fact_df.alias("f")
    .join(
        dim_df.alias("d"),
        col("f.<foreign_key>") == col("d.<dimension_key>"),
        "left_anti"
    )
)
```

Then:

```python
invalid_fk_count = invalid_fk_df.count()
```

Expected:

```text
0
```

if all required relationships are valid.

---

# Why Foreign Key Validation Is Important

Suppose:

```text
FACT_SALES
APPOINTMENT_KEY = 105
```

but:

```text
DIM_APPOINTMENT_DATA
```

does not contain:

```text
APPOINTMENT_KEY = 105
```

Then the Fact record has an invalid Dimension reference.

This is called an **orphan record**.

---

# 6. Schema Validation

Schema validation checks whether the dataset contains the expected structure.

This begins in Bronze and can also be checked after transformation.

It verifies:

* Column names
* Number of columns
* Required columns
* Data types

---

# Expected vs Actual Schema

```text
Expected Schema
       ↓
Compare
       ↓
Actual Schema
       ↓
PASS / FAIL
```

Example:

```text
Actual Columns   : 40
Expected Columns : 40
```

However, matching counts are not enough.

The column names must also match.

---

# Missing Columns

Conceptually:

```python
missing_columns = (
    expected_columns - actual_columns
)
```

Example:

```text
Missing Columns:
['TITLE', 'STATUS', 'DATE']
```

---

# Extra Columns

Conceptually:

```python
extra_columns = (
    actual_columns - expected_columns
)
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

# 7. Required Column Validation

Certain columns must exist for downstream processing.

For example:

```text
Sales Key
Appointment Key
Required Date Columns
Required Measures
```

If a required column is missing, processing should fail.

Conceptually:

```python
required_columns = [
    "<column1>",
    "<column2>"
]

missing = [
    c for c in required_columns
    if c not in df.columns
]

if missing:
    raise Exception(
        f"Missing required columns: {missing}"
    )
```

---

# Why Required Column Validation Matters

Gold processing may depend on certain columns.

For example:

```text
Silver Appointment
        ↓
Required Appointment Identifier
        ↓
Create Dimension
```

If the identifier is missing, the Dimension cannot be built correctly.

---

# 8. Data Type Validation

Silver converts source strings into standardized data types.

Data Quality Checks verify that the final schema contains the expected types.

Examples:

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

---

# Data Type Validation Flow

```text
Metadata Target Type
        ↓
Compare With
        ↓
Silver Data Type
        ↓
PASS / FAIL
```

---

# Why Data Type Validation Is Important

Incorrect data types can cause:

* Failed calculations
* Failed joins
* Invalid comparisons
* Gold processing failures
* Incorrect analytical output

For example:

```text
PRICE = STRING
```

is less useful for calculations than:

```text
PRICE = FLOAT
```

---

# Malformed Value Validation

During Silver transformation, malformed numeric data was identified.

Example:

```text
215.0000, 230.0000
```

This could not be directly converted into:

```text
FLOAT
```

After cleaning, Data Quality Checks help verify that the transformed values now follow the expected numeric structure.

---

# 9. Invalid Value Validation

Some data may technically have the correct type but still contain invalid business values.

Examples:

```text
Negative values where not allowed
Invalid status values
Invalid dates
Blank identifiers
```

Business-rule checks can identify these records.

---

# Status Validation Example

Suppose valid Appointment statuses are:

```text
COMPLETED
PENDING
CANCELLED
```

A value such as:

```text
UNKNOWN_STATUS
```

can be identified as invalid if it is not allowed by the business rules.

---

# Date Validation

Dates should be checked for valid conversion.

Conceptually:

```text
Source Date String
      ↓
Convert to DATE
      ↓
Conversion Successful?
      │
      ├── Yes → Valid
      └── No  → NULL / Invalid
```

These invalid dates can then be identified through NULL validation.

---

# Data Quality for Sales

Sales data can be checked for:

* Record count
* Required columns
* NULL business keys
* Duplicate records
* Numeric data types
* Malformed numeric values
* Invalid values

Flow:

```text
Sales Silver
     ↓
Run DQ Checks
     ↓
Valid Sales Data
     ↓
FACT_SALES
```

---

# Data Quality for Appointment

Appointment data can be checked for:

* Required Appointment columns
* NULL Appointment identifiers
* Duplicate Appointment records
* Valid dates
* Standardized status
* Schema correctness
* Dimension-key uniqueness

Flow:

```text
Appointment Silver
        ↓
Run DQ Checks
        ↓
Valid Appointment Data
        ↓
DIM_APPOINTMENT_DATA
```

---

# Data Quality Before Gold

Only clean and validated Silver data should be used to create Gold tables.

```text
Silver Sales
      │
      ├── DQ PASS
      │
      ↓
FACT_SALES
```

```text
Silver Appointment
        │
        ├── DQ PASS
        │
        ↓
DIM_APPOINTMENT_DATA
```

---

# Data Quality Check Status

Each validation can conceptually produce:

```text
PASS
FAIL
```

For example:

```text
Row Count Check       → PASS
NULL Check            → PASS
Duplicate Check       → PASS
Primary Key Check     → PASS
Foreign Key Check     → PASS
```

---

# Combined Data Quality Result

Conceptually:

```text
Run All Checks
      ↓
Any Critical Failure?
      │
      ├── No
      │    ↓
      │  DQ PASS
      │    ↓
      │  Continue
      │
      └── Yes
           ↓
         DQ FAIL
           ↓
      Stop Processing
```

---

# Reusable Data Quality Functions

Data Quality logic can be implemented using reusable PySpark functions.

Example:

```python
def check_nulls(df, column_name):
    return (
        df.filter(
            col(column_name).isNull()
        ).count()
    )
```

Duplicate check:

```python
def check_duplicates(df, key_columns):
    return (
        df.groupBy(*key_columns)
          .count()
          .filter("count > 1")
          .count()
    )
```

These functions make the validation logic easier to reuse.

---

# Example Data Quality Summary

Conceptually:

```text
=================================
DATA QUALITY CHECK
=================================

Object      : SALES_DATA_PRIOR_DAY
Layer       : SILVER

Row Count   : PASS
NULL Check  : PASS
Duplicates  : PASS
Schema      : PASS
Data Types  : PASS

Final Status: PASS
=================================
```

Appointment can be validated in the same way.

---

# Data Quality and ETL Logging

Data Quality failures can also be captured in the ETL audit process.

Main audit table:

```sql
audit.ETL_LOG
```

If all checks pass:

```text
STATUS = SUCCESS
```

If a critical Data Quality Check fails:

```text
STATUS = FAILED
```

and the error message can explain the reason.

---

# Example Failure

```text
Data Quality Check
      ↓
Duplicate Primary Key Found
      ↓
Raise Exception
      ↓
Capture Error
      ↓
audit.ETL_LOG
      ↓
FAILED
```

---

# Data Quality Error Handling

Conceptually:

```python
try:
    # Run DQ checks

    if dq_failed:
        raise Exception(
            "Data quality validation failed"
        )

except Exception as e:
    # capture error
    # write FAILED log
    raise
```

This prevents invalid data from silently continuing through the pipeline.

---

# Data Quality vs Data Cleaning

These two concepts should not be confused.

## Data Cleaning

Changes incorrect data.

Examples:

```text
Trim Spaces
Convert Data Types
Remove Duplicates
Handle NULLs
```

Mainly performed in:

```text
Silver
```

## Data Quality Checks

Verify whether the resulting data is correct.

Examples:

```text
Check Duplicates
Check NULLs
Check Row Count
Check PK/FK
```

Performed before final analytical processing.

Easy way to remember:

```text
Cleaning = Fix

Quality Check = Verify
```

---

# Data Quality vs ETL Audit

Data Quality Checks validate the **data**.

ETL Audit tracks the **pipeline execution**.

```text
Data Quality
     ↓
Is the data correct?
```

```text
ETL Audit
     ↓
Did the pipeline run successfully?
```

Both are important but serve different purposes.

---

# Complete Data Quality Architecture

```text
                   Bronze
                      ↓
                   Silver
                      ↓
                Cleaned Data
                      ↓
              Data Quality Checks
                      │
        ┌─────────────┼─────────────┐
        ↓             ↓             ↓
     Row Count       NULL        Duplicate
        │             │             │
        └─────────────┼─────────────┘
                      ↓
                  PK Check
                      ↓
                  FK Check
                      ↓
                Schema Check
                      ↓
               Data Type Check
                      ↓
                 Final Result
                    /      \
                   ↓        ↓
                 PASS      FAIL
                   ↓        ↓
                 Gold    Error Log
```

---

# Key Data Quality Rules

The project focuses on these important rules:

```text
Dataset must not be unexpectedly empty

Required columns must exist

Important keys must not be NULL

Primary keys must be unique

Unwanted duplicates must not exist

Foreign keys must reference valid Dimension records

Final columns must have correct data types

Malformed values must not enter Gold
```

---

# Benefits

Data Quality Checks provide:

* More reliable data
* Better analytical results
* Early detection of errors
* Reduced downstream failures
* Improved pipeline reliability
* Better debugging
* Better monitoring
* Protection of Gold-layer data

---

# Easy Explanation

Remember Data Quality as:

```text
Count
  ↓
Check NULL
  ↓
Check Duplicate
  ↓
Check Primary Key
  ↓
Check Foreign Key
  ↓
Check Schema
  ↓
Check Data Type
  ↓
PASS
  ↓
Gold
```

---

# Interview Explanation

> In my Logistics Azure Data Engineering project, I implemented Data Quality Checks after Silver transformation and before Gold processing. I validated row counts, NULL values, duplicate records, required columns, schema, data types, primary-key uniqueness, and foreign-key relationships. For the Gold model, I also validated the relationship between `FACT_SALES` and `DIM_APPOINTMENT_DATA`. If a critical validation fails, the ETL process raises an exception and the failure can be recorded in `audit.ETL_LOG`, which prevents bad-quality data from reaching the Gold layer.

---

# Summary

Data Quality Checks protect the Gold layer from incorrect or inconsistent data.

The overall process is:

```text
Silver
   ↓
Row Count Check
   ↓
NULL Check
   ↓
Duplicate Check
   ↓
Primary Key Check
   ↓
Foreign Key Check
   ↓
Schema Check
   ↓
Data Type Check
   ↓
PASS
   ↓
Gold
```

This ensures that `DIM_APPOINTMENT_DATA` and `FACT_SALES` are built using trusted and validated data.

