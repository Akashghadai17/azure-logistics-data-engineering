# Incremental Load, MERGE and UPSERT

## Overview

The Logistics Azure Data Engineering Project implements **incremental data loading** using **Delta Lake MERGE**.

Instead of reprocessing or replacing all existing data during every pipeline run, the incremental process handles only:

* New records
* Changed records

This improves pipeline efficiency and avoids unnecessary full reloads.

---

# What Is Incremental Loading?

Incremental loading means processing only the data that is new or changed since the previous pipeline execution.

Instead of:

```text
Load Entire Dataset
       ↓
Replace Everything
```

the project uses:

```text
Existing Data
      +
New / Changed Data
      ↓
Incremental Processing
```

---

# Full Load vs Incremental Load

## Full Load

A Full Load processes the complete dataset.

```text
Source
  ↓
Read All Records
  ↓
Write Entire Target
```

This is useful during:

* Initial table creation
* First pipeline execution
* Complete reloads

---

## Incremental Load

An Incremental Load processes only new or updated records.

```text
New / Changed Records
        ↓
Compare With Target
        ↓
Update Existing
        +
Insert New
```

This reduces unnecessary data processing.

---

# Why Incremental Loading Is Used

Suppose the target already contains:

```text
1,000,000 records
```

and today's source contains only:

```text
5,000 new or changed records
```

A Full Load may process all:

```text
1,005,000 records
```

while Incremental Loading mainly works with:

```text
5,000 records
```

This can improve:

* Performance
* Processing time
* Resource usage
* Pipeline efficiency

---

# Incremental Load Architecture

```text
Existing Delta Table
        +
Incoming Data
        ↓
Compare Records
        ↓
Delta MERGE
     /       \
    ↓         ↓
 UPDATE      INSERT
     \       /
        ↓
Updated Delta Table
```

---

# Delta Lake

The project uses **Delta Lake** for Bronze, Silver, and Gold managed tables.

Delta Lake supports operations such as:

```text
INSERT
UPDATE
DELETE
MERGE
```

This makes Delta suitable for incremental ETL processing.

---

# What Is MERGE?

`MERGE` compares incoming source records with records already present in the target Delta table.

Conceptually:

```text
Source Record
     ↓
Compare With Target
     ↓
Record Exists?
    /        \
   Yes        No
    ↓          ↓
 UPDATE      INSERT
```

---

# What Is UPSERT?

UPSERT means:

```text
UPDATE + INSERT
```

Therefore:

```text
Existing Record
      ↓
UPDATE
```

and:

```text
New Record
      ↓
INSERT
```

are handled in one MERGE process.

---

# Easy Way to Remember

```text
MERGE
  ↓
Compare

UPSERT
  ↓
Update + Insert
```

---

# Initial Load

Before incremental processing can happen, the target Delta table must exist.

During the first run:

```text
Source Data
     ↓
Create Target Table
     ↓
Initial Full Load
```

After the target exists, future pipeline runs can use MERGE.

---

# Incremental Processing Flow

```text
Start Pipeline
      ↓
Read Incoming Data
      ↓
Read Existing Target
      ↓
Compare Using Key
      ↓
MERGE
      ↓
Update Existing Records
      ↓
Insert New Records
      ↓
Complete
```

---

# Matching Key

MERGE requires a key or condition to determine whether the incoming record already exists.

Conceptually:

```text
Source Key
    =
Target Key
```

Example:

```text
target.ID = source.ID
```

The actual merge key depends on the dataset being processed.

---

# Why the Merge Key Is Important

If the key is incorrect, the pipeline may:

* Insert duplicate records
* Update the wrong record
* Miss updates
* Produce incorrect target data

Therefore, the MERGE condition should use a reliable business or target key.

---

# DeltaTable

PySpark uses the Delta Lake `DeltaTable` class for MERGE operations.

Import:

```python
from delta.tables import DeltaTable
```

The existing Delta target can then be accessed as a Delta table.

Conceptually:

```python
target_delta = DeltaTable.forName(
    spark,
    "<catalog>.<schema>.<table_name>"
)
```

---

# Basic MERGE Pattern

Conceptually:

```python
target_delta.alias("target") \
    .merge(
        source_df.alias("source"),
        "target.<key> = source.<key>"
    ) \
    .whenMatchedUpdateAll() \
    .whenNotMatchedInsertAll() \
    .execute()
```

This performs the UPSERT operation.

---

# whenMatchedUpdateAll()

This condition is used when the source record already exists in the target.

```python
.whenMatchedUpdateAll()
```

Meaning:

```text
Source Key Matches Target Key
        ↓
Update Existing Record
```

---

# whenNotMatchedInsertAll()

This condition is used when the incoming source record does not exist in the target.

```python
.whenNotMatchedInsertAll()
```

Meaning:

```text
No Matching Target Record
        ↓
Insert New Record
```

---

# MERGE Logic

```text
Incoming Record
      ↓
Search Target
      ↓
Matching Key?
   /          \
  Yes          No
   ↓            ↓
UPDATE         INSERT
```

---

# Example

Existing target:

| ID | STATUS    |
| -- | --------- |
| 1  | PENDING   |
| 2  | COMPLETED |

Incoming data:

| ID | STATUS    |
| -- | --------- |
| 1  | COMPLETED |
| 3  | PENDING   |

After MERGE:

| ID | STATUS    |
| -- | --------- |
| 1  | COMPLETED |
| 2  | COMPLETED |
| 3  | PENDING   |

Explanation:

```text
ID 1
↓
Already Exists
↓
UPDATE
```

```text
ID 3
↓
Does Not Exist
↓
INSERT
```

---

# Incremental Load in the Project

The Logistics project processes:

```text
Sales Data
Appointment Data
```

After the initial Delta tables are created, new and changed records can be merged into the existing target tables.

The general flow is:

```text
Incoming Sales / Appointment Data
              ↓
        Databricks
              ↓
      Cleaned DataFrame
              ↓
 Existing Unity Catalog Delta Table
              ↓
          MERGE / UPSERT
```

---

# Unity Catalog Integration

The project stores processed tables as **Unity Catalog managed Delta tables**.

Therefore, MERGE operations are performed against managed Delta tables.

Conceptually:

```text
Unity Catalog
      ↓
Managed Delta Table
      ↓
MERGE
      ↓
Updated Managed Table
      ↓
SC2 Managed Storage
```

---

# Physical Storage

The Bronze, Silver, and Gold managed Delta tables are physically stored in **SC2**.

Therefore:

```text
Databricks
    ↓
Unity Catalog
    ↓
MERGE Managed Table
    ↓
SC2
```

SC1 is not used to store the managed Silver or Gold tables.

---

# SC1 and Incremental Processing

SC1 continues to store:

```text
Landing
Logs
Archive
```

New source files arrive in:

```text
SC1 / landing
```

After successful processing, they can move to:

```text
SC1 / archive
```

---

# Complete Incremental Flow

```text
New Source CSV
      ↓
SC1 Landing
      ↓
Azure Databricks
      ↓
Bronze
      ↓
Silver
      ↓
Clean New / Changed Records
      ↓
Existing Delta Target
      ↓
MERGE
   /      \
UPDATE    INSERT
   \      /
      ↓
Updated Managed Table
      ↓
Unity Catalog
      ↓
SC2
```

---

# Why MERGE Is Better Than Overwrite

Using overwrite means replacing the complete target.

```text
Existing Target
      ↓
DELETE / REPLACE
      ↓
Write Everything Again
```

Using MERGE:

```text
Existing Target
      ↓
Keep Existing Records
      ↓
Change Only Required Records
```

This is more suitable for incremental pipelines.

---

# Overwrite vs MERGE

| Overwrite                | MERGE                            |
| ------------------------ | -------------------------------- |
| Replaces target data     | Updates selected records         |
| Processes more data      | Processes changes                |
| Suitable for full load   | Suitable for incremental load    |
| Can rewrite entire table | Preserves unaffected records     |
| Simpler                  | More efficient for changing data |

---

# Incremental Load and Data Quality

Before new data is merged into the target, it should pass required data quality checks.

Flow:

```text
Incoming Data
      ↓
Silver Cleaning
      ↓
Data Quality Checks
      ↓
PASS
      ↓
MERGE
```

If data quality fails:

```text
FAIL
 ↓
Do Not Merge Invalid Data
```

---

# Duplicate Handling Before MERGE

The incoming dataset should not contain unwanted duplicate keys.

For example:

```text
ID = 101
ID = 101
```

If both are present in the same source batch, MERGE may produce incorrect or ambiguous results.

Therefore:

```text
Incoming Data
      ↓
Deduplicate
      ↓
MERGE
```

---

# NULL Key Validation

The MERGE key should not normally be NULL.

Example:

```text
ID = NULL
```

cannot reliably match:

```text
target.ID
```

Therefore, key validation should happen before MERGE.

---

# MERGE Error Handling

MERGE operations are included inside ETL error-handling logic.

Conceptually:

```python
try:
    target_delta.alias("target") \
        .merge(
            source_df.alias("source"),
            "target.<key> = source.<key>"
        ) \
        .whenMatchedUpdateAll() \
        .whenNotMatchedInsertAll() \
        .execute()

except Exception as e:
    # Capture merge failure
    raise
```

---

# Successful MERGE Flow

```text
Start Incremental Job
        ↓
Read Source Data
        ↓
Validate Data
        ↓
Run MERGE
        ↓
UPDATE Existing
        +
INSERT New
        ↓
Write SUCCESS Log
```

---

# Failed MERGE Flow

```text
Start Incremental Job
        ↓
Run MERGE
        ↓
Failure
        ↓
Capture Exception
        ↓
Write FAILED Log
        ↓
Store Error Message
```

---

# ETL Audit Logging

Incremental processing is monitored using:

```sql
audit.ETL_LOG
```

The audit table can store:

* Process name
* Object name
* Start time
* End time
* Record count
* Status
* Error message

Typical statuses:

```text
STARTED
SUCCESS
FAILED
```

---

# Incremental Load Status Flow

```text
Start
  ↓
STARTED
  ↓
Run Incremental Process
  ↓
Successful?
 /        \
Yes        No
 ↓          ↓
SUCCESS    FAILED
```

---

# Metadata and Incremental Loading

Azure SQL metadata can store configuration that helps control how each object should be processed.

Main configuration table:

```sql
metadata.OBJECTS_CONFIGURATION
```

Conceptually:

```text
Object Configuration
      ↓
Load Type
      ↓
Full / Incremental
      ↓
Databricks Processing
```

This supports a metadata-driven ETL approach.

---

# Incremental Load Benefits

Incremental loading provides several benefits.

## Performance

Only required records are processed.

## Efficiency

The pipeline avoids unnecessarily rewriting the entire dataset.

## Scalability

The approach works better as the amount of historical data increases.

## Reliability

Existing records remain unchanged unless an update is required.

## Cost Optimization

Less processing can reduce unnecessary compute usage.

---

# Full Load and Incremental Load Together

A common ETL lifecycle is:

```text
First Run
   ↓
Full Load
   ↓
Create Target Table
```

Then:

```text
Future Runs
    ↓
Incremental Load
    ↓
MERGE / UPSERT
```

---

# Example Project Lifecycle

```text
Day 1
 ↓
Initial Source
 ↓
Full Load
 ↓
Create Delta Table
```

```text
Day 2
 ↓
New / Changed Source
 ↓
MERGE
 ↓
Update + Insert
```

```text
Day 3
 ↓
New / Changed Source
 ↓
MERGE
 ↓
Update + Insert
```

---

# Incremental Gold Processing

The same Delta MERGE concept can be applied when maintaining Gold tables.

Conceptually:

```text
New Gold Records
      ↓
Existing Gold Delta Table
      ↓
MERGE
      ↓
Updated Gold Table
```

For example:

```text
DIM_APPOINTMENT_DATA
```

and:

```text
FACT_SALES
```

can be updated incrementally according to the implemented processing logic.

---

# Important MERGE Concepts

Remember these four concepts:

```text
Source
Target
Match Condition
Action
```

Example:

```text
Source
↓
Incoming DataFrame

Target
↓
Existing Delta Table

Match Condition
↓
target.ID = source.ID

Action
↓
UPDATE / INSERT
```

---

# MERGE Interview Question

## What happens when a record matches?

```text
UPDATE
```

## What happens when the record does not match?

```text
INSERT
```

## What is this combination called?

```text
UPSERT
```

---

# MERGE vs JOIN

MERGE and JOIN are not the same.

## JOIN

Combines records for querying or transformation.

```text
Table A
 +
Table B
 ↓
Combined Result
```

## MERGE

Changes the target table.

```text
Source
 +
Target
 ↓
UPDATE / INSERT
```

Easy way to remember:

```text
JOIN = Combine

MERGE = Modify
```

---

# MERGE vs INSERT

INSERT only adds records.

```text
New Record
   ↓
INSERT
```

MERGE can:

```text
Existing Record → UPDATE
New Record      → INSERT
```

Therefore MERGE is more useful for UPSERT processing.

---

# MERGE vs UPDATE

UPDATE modifies existing records only.

```text
Existing Record
      ↓
UPDATE
```

MERGE handles both:

```text
UPDATE + INSERT
```

---

# Incremental Processing Architecture

```text
                  New Source Data
                         │
                         ↓
                     SC1 Landing
                         │
                         ↓
                  Azure Databricks
                         │
                         ↓
                    Bronze Layer
                         │
                         ↓
                    Silver Layer
                         │
                         ↓
                Data Quality Checks
                         │
                         ↓
                 Incremental Dataset
                         │
                         ↓
                  Delta MERGE
                    /       \
                   ↓         ↓
               UPDATE      INSERT
                    \       /
                         ↓
                Unity Catalog Table
                         ↓
                  SC2 Managed Storage
```

---

# Easy Explanation

Remember Incremental Load as:

```text
Read New Data
     ↓
Clean
     ↓
Validate
     ↓
Compare With Existing
     ↓
MERGE
     ↓
Update Existing
     +
Insert New
```

And remember:

```text
UPSERT = UPDATE + INSERT
```

---

# Interview Explanation

> In my Logistics Azure Data Engineering project, I implemented incremental loading using Delta Lake MERGE. After the initial full load, future pipeline runs process only new or changed records. Databricks compares the incoming DataFrame with the existing Unity Catalog managed Delta table using a key. If the record already exists, it is updated; if it does not exist, it is inserted. This UPDATE plus INSERT pattern is called UPSERT. I also perform data-quality checks before MERGE and record execution status through the ETL audit process.

---

# Summary

The project uses Delta Lake MERGE to implement efficient incremental loading.

```text
Incoming Data
      ↓
Existing Delta Table
      ↓
MERGE
    /     \
   ↓       ↓
UPDATE   INSERT
    \     /
      ↓
UPSERT
      ↓
Updated Target Table
```

This allows the pipeline to process new and changed records without unnecessarily rebuilding the entire target dataset.

