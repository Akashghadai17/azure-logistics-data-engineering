# ETL Logging and Error Handling

## Overview

ETL Logging and Error Handling are implemented in the **Logistics Azure Data Engineering Project** to monitor pipeline execution and capture failures.

The project uses Azure SQL Database to store structured ETL execution information in:

```sql
audit.ETL_LOG
```

The ETL logging process records whether a job:

* Started
* Completed successfully
* Failed

It also stores useful execution details such as timestamps, record counts, object names, and error messages.

---

# Why ETL Logging Is Important

Without ETL logging, it is difficult to know:

* Which job ran
* When it started
* When it ended
* Whether it succeeded
* Whether it failed
* How many records were processed
* What error occurred

ETL logging provides a central execution history.

---

# ETL Logging Architecture

```text
Azure Databricks
      ↓
ETL Process
      ↓
Generate Execution Information
      ↓
Azure SQL Database
      ↓
audit.ETL_LOG
```

---

# Audit Schema

Azure SQL Database contains an `audit` schema.

```sql
audit
```

The main audit table used in the project is:

```sql
audit.ETL_LOG
```

The audit schema is kept separate from the metadata schema.

---

# Metadata vs Audit

The project uses two different SQL schemas.

```text
Azure SQL Database
        │
        ├── metadata
        │     ├── OBJECTS_CONFIGURATION
        │     └── OBJECTS_COLUMN_MAPPING
        │
        └── audit
              └── ETL_LOG
```

## Metadata

Metadata tells the pipeline:

```text
What should I process?
How should I process it?
```

## Audit

Audit tells us:

```text
What happened during processing?
```

Easy way to remember:

```text
Metadata = Instructions

Audit = History
```

---

# audit.ETL_LOG Purpose

`audit.ETL_LOG` stores ETL execution information.

Typical information includes:

* ETL process name
* Object name
* Layer name
* Source object
* Target object
* Start time
* End time
* Record count
* Status
* Error message

The exact columns depend on the SQL table created in the project.

---

# ETL Status Values

The ETL process uses status values such as:

```text
STARTED
SUCCESS
FAILED
```

---

# STARTED Status

When processing begins:

```text
Start Job
   ↓
Write STARTED
```

This records that the ETL process has started.

---

# SUCCESS Status

If processing completes successfully:

```text
ETL Processing
      ↓
Completed Successfully
      ↓
Write SUCCESS
```

---

# FAILED Status

If an exception occurs:

```text
ETL Processing
      ↓
Exception
      ↓
Capture Error
      ↓
Write FAILED
```

The error message can also be stored in the audit table.

---

# Complete ETL Logging Flow

```text
Start ETL
   ↓
Write STARTED Log
   ↓
Run Processing
   ↓
Successful?
  /       \
Yes        No
 ↓          ↓
SUCCESS    Capture Error
 ↓          ↓
End        FAILED
```

---

# Typical ETL Log Record

Conceptually:

| Field         | Example              |
| ------------- | -------------------- |
| Process       | SILVER_SALES         |
| Object        | SALES_DATA_PRIOR_DAY |
| Layer         | SILVER               |
| Start Time    | 2026-08-15 10:00     |
| End Time      | 2026-08-15 10:02     |
| Record Count  | 5000                 |
| Status        | SUCCESS              |
| Error Message | NULL                 |

A failed record may look like:

| Field         | Example              |
| ------------- | -------------------- |
| Process       | SILVER_SALES         |
| Object        | SALES_DATA_PRIOR_DAY |
| Layer         | SILVER               |
| Start Time    | 2026-08-15 10:00     |
| End Time      | 2026-08-15 10:01     |
| Record Count  | 0                    |
| Status        | FAILED               |
| Error Message | CAST_INVALID_INPUT   |

---

# ETL Logging in Databricks

Databricks writes audit information to Azure SQL Database using JDBC.

Flow:

```text
Databricks
    ↓
Create Log Record
    ↓
JDBC
    ↓
Azure SQL
    ↓
audit.ETL_LOG
```

---

# Azure SQL JDBC Connection

The project uses a JDBC URL similar to:

```python
jdbc_url = (
    f"jdbc:sqlserver://{server_name}:1433;"
    f"database={database_name};"
    "encrypt=true;"
    "trustServerCertificate=false;"
)
```

Connection properties contain the SQL credentials.

Conceptually:

```python
connection_properties = {
    "user": sql_username,
    "password": sql_password,
    "driver": "com.microsoft.sqlserver.jdbc.SQLServerDriver"
}
```

The actual username and password should be retrieved securely rather than hard-coded.

---

# Azure Key Vault Integration

Sensitive SQL credentials are stored in Azure Key Vault.

Flow:

```text
Azure Key Vault
      ↓
SQL Credentials
      ↓
Databricks
      ↓
JDBC Connection
      ↓
audit.ETL_LOG
```

This keeps credentials out of notebook code and GitHub.

---

# Logging Function

A reusable function can be used to write ETL logs.

Conceptually:

```python
def write_etl_log(
    process_name,
    object_name,
    layer_name,
    status,
    record_count=None,
    error_message=None
):
    # Create log dataframe
    # Write to audit.ETL_LOG
    pass
```

Using a reusable function avoids writing the same logging code in every notebook.

---

# STARTED Log

At the beginning of a process:

```python
write_etl_log(
    process_name="SILVER_SALES",
    object_name="SALES_DATA_PRIOR_DAY",
    layer_name="SILVER",
    status="STARTED"
)
```

This records that the process has begun.

---

# SUCCESS Log

After successful completion:

```python
write_etl_log(
    process_name="SILVER_SALES",
    object_name="SALES_DATA_PRIOR_DAY",
    layer_name="SILVER",
    status="SUCCESS",
    record_count=sales_silver_df.count()
)
```

---

# FAILED Log

If processing fails:

```python
write_etl_log(
    process_name="SILVER_SALES",
    object_name="SALES_DATA_PRIOR_DAY",
    layer_name="SILVER",
    status="FAILED",
    error_message=str(e)
)
```

---

# Error Handling

Error Handling is implemented using Python `try` and `except`.

Conceptually:

```python
try:
    # ETL processing

except Exception as e:
    # capture error
    # write FAILED log
    raise
```

This allows the pipeline to capture failures instead of silently continuing.

---

# Why raise Is Important

After logging the error, the exception is raised again.

Example:

```python
raise
```

This ensures that the notebook or pipeline is marked as failed.

Without raising the exception again, the pipeline may appear successful even though processing failed.

---

# Error Handling Flow

```text
try
 ↓
Run ETL
 ↓
Error?
 /   \
No    Yes
↓      ↓
Continue Capture Exception
↓      ↓
SUCCESS Write FAILED Log
         ↓
        raise
```

---

# Example Error

During Silver processing, a malformed Sales value caused a Spark cast error.

Example value:

```text
215.0000, 230.0000
```

Expected type:

```text
FLOAT
```

Spark raised an error similar to:

```text
CAST_INVALID_INPUT
```

The error-handling process can capture this failure and store the error message in the audit log.

---

# Error Capture Example

Conceptually:

```python
try:
    sales_silver_df = apply_mapping(
        sales_bronze_df,
        "SALES_DATA_PRIOR_DAY"
    )

    sales_silver_df.count()

except Exception as e:
    error_message = str(e)

    write_etl_log(
        process_name="SILVER_SALES",
        object_name="SALES_DATA_PRIOR_DAY",
        layer_name="SILVER",
        status="FAILED",
        error_message=error_message
    )

    raise
```

---

# Successful Processing Example

Conceptually:

```python
try:
    write_etl_log(
        process_name="SILVER_SALES",
        object_name="SALES_DATA_PRIOR_DAY",
        layer_name="SILVER",
        status="STARTED"
    )

    # ETL logic

    row_count = sales_silver_df.count()

    write_etl_log(
        process_name="SILVER_SALES",
        object_name="SALES_DATA_PRIOR_DAY",
        layer_name="SILVER",
        status="SUCCESS",
        record_count=row_count
    )

except Exception as e:

    write_etl_log(
        process_name="SILVER_SALES",
        object_name="SALES_DATA_PRIOR_DAY",
        layer_name="SILVER",
        status="FAILED",
        error_message=str(e)
    )

    raise
```

---

# Logging Across Pipeline Layers

ETL logging can be applied to each major layer.

```text
Bronze
 ↓
Log Execution

Silver
 ↓
Log Execution

Gold
 ↓
Log Execution

Data Quality
 ↓
Log Execution

Incremental Load
 ↓
Log Execution
```

This provides visibility into each stage of the ETL workflow.

---

# Bronze Logging

Bronze logs can track:

* Source object
* Start time
* End time
* Source record count
* Bronze record count
* Schema validation failure
* Status

Example:

```text
Object: APPOINTMENT_DATA
Layer: BRONZE
Status: SUCCESS
```

---

# Silver Logging

Silver logs can track:

* Metadata mapping execution
* Transformation status
* Record count
* Data type conversion errors
* Cleaning failures

Example:

```text
Object: SALES_DATA_PRIOR_DAY
Layer: SILVER
Status: FAILED
Error: CAST_INVALID_INPUT
```

---

# Gold Logging

Gold logs can track:

* Dimension creation
* Fact creation
* Join execution
* Gold row counts
* Gold process status

Example:

```text
Process: FACT_SALES_LOAD
Layer: GOLD
Status: SUCCESS
```

---

# Data Quality Logging

Data Quality checks can also contribute to pipeline status.

For example:

```text
NULL CHECK
     ↓
FAIL
     ↓
Raise Exception
     ↓
Write FAILED Log
```

This prevents invalid data from reaching Gold.

---

# Incremental Load Logging

MERGE execution can be tracked.

```text
Start MERGE
    ↓
Run UPSERT
    ↓
Successful?
   /       \
 Yes        No
 ↓           ↓
SUCCESS     FAILED
```

Errors during Delta MERGE are captured through the same error-handling process.

---

# ETL Log vs SC1 Logs

The project also uses an SC1 `logs` area.

These should not be confused with `audit.ETL_LOG`.

## SC1 Logs

```text
SC1
└── logs
```

Used for file-based technical or process log information where required.

## Azure SQL Audit Log

```sql
audit.ETL_LOG
```

Used for structured ETL execution history.

---

# Easy Difference

```text
SC1 logs
    ↓
File-Based Technical Logs
```

```text
audit.ETL_LOG
    ↓
Structured Pipeline Execution Logs
```

---

# Why Azure SQL Is Useful for Audit Logging

Storing ETL logs in Azure SQL makes it easy to query pipeline history.

For example:

```sql
SELECT *
FROM audit.ETL_LOG;
```

The audit information can be filtered by:

* Status
* Object
* Layer
* Date
* Process name

---

# Query Failed Runs

Conceptually:

```sql
SELECT *
FROM audit.ETL_LOG
WHERE STATUS = 'FAILED';
```

This helps quickly identify failed ETL executions.

---

# Query Successful Runs

Conceptually:

```sql
SELECT *
FROM audit.ETL_LOG
WHERE STATUS = 'SUCCESS';
```

---

# Query by Object

Conceptually:

```sql
SELECT *
FROM audit.ETL_LOG
WHERE OBJECT_NAME = 'SALES_DATA_PRIOR_DAY';
```

This makes troubleshooting easier.

---

# Error Message Storage

The error message field should capture enough information to understand the failure.

Example:

```text
CAST_INVALID_INPUT:
The value '215.0000, 230.0000'
cannot be cast to FLOAT
```

This helps developers identify the root cause.

---

# Avoid Storing Secrets in Error Logs

Error messages should not expose sensitive information.

Do not store:

* Passwords
* Client Secrets
* Storage Keys
* Tokens

in the audit log.

Only technical error information should be stored.

---

# Record Count Logging

Record counts help identify how much data was processed.

Example:

```text
Input Count  : 5000
Output Count : 4990
```

The difference may be caused by:

* Duplicate removal
* Invalid record filtering
* Data quality rules

Record counts are therefore useful during monitoring.

---

# Start and End Time

The audit log can track:

```text
START_TIME
END_TIME
```

This helps calculate processing duration.

Conceptually:

```text
Duration = End Time - Start Time
```

This can help identify slow pipeline stages.

---

# Pipeline Monitoring

ETL logging supports monitoring at different levels.

```text
Pipeline
   ↓
Notebook
   ↓
Layer
   ↓
Object
```

This helps answer questions such as:

* Which object failed?
* Which layer failed?
* When did it fail?
* How many records were processed?
* What was the error?

---

# ETL Logging and ADF

Azure Data Factory orchestrates the pipeline.

ADF can show whether an activity succeeds or fails.

Azure SQL audit logging provides additional application-level execution details.

```text
ADF
 ↓
Pipeline Activity Status

Azure SQL
 ↓
Detailed ETL Execution History
```

These two monitoring methods complement each other.

---

# ADF Failure Flow

```text
ADF Pipeline
     ↓
Databricks Notebook
     ↓
Exception Raised
     ↓
Notebook Fails
     ↓
ADF Activity = FAILED
```

At the same time:

```text
Databricks
     ↓
Capture Error
     ↓
audit.ETL_LOG
     ↓
FAILED
```

---

# Why Both ADF and SQL Logging Are Useful

ADF shows orchestration-level information.

Azure SQL shows ETL-specific information.

Easy way to remember:

```text
ADF
 ↓
Did the activity run?

ETL_LOG
 ↓
What happened inside the ETL?
```

---

# Complete Logging Architecture

```text
                     Azure Data Factory
                            │
                            ↓
                    Azure Databricks
                            │
                         ETL Job
                            │
            ┌───────────────┼───────────────┐
            │                               │
            ↓                               ↓
        Processing                     Exception
            │                               │
            ↓                               ↓
        SUCCESS                         Capture Error
            │                               │
            └───────────────┬───────────────┘
                            ↓
                   Azure SQL Database
                            ↓
                       audit.ETL_LOG
```

---

# Complete Error Handling Architecture

```text
Start Process
     ↓
Write STARTED
     ↓
try:
     ↓
Run ETL
     ↓
Success?
  /       \
Yes        No
 ↓          ↓
Count      Exception
Records       ↓
 ↓        Capture Error
SUCCESS       ↓
 ↓        Write FAILED
End           ↓
             raise
```

---

# Recommended Logging Sequence

For each ETL process:

```text
1. Write STARTED
2. Run ETL Logic
3. Calculate Record Count
4. Write SUCCESS
```

If an exception occurs:

```text
1. Capture Exception
2. Write FAILED
3. Store Error Message
4. Raise Exception
```

---

# ETL Logging Benefits

The implementation provides:

* Better monitoring
* Faster debugging
* Pipeline traceability
* Execution history
* Record-count tracking
* Failure tracking
* Error visibility
* Easier troubleshooting
* Better operational control

---

# Error Handling Benefits

Error Handling provides:

* Controlled failure behavior
* Clear error messages
* Prevention of silent failures
* Better monitoring
* Accurate ADF status
* Better debugging
* Protection from incomplete processing

---

# Easy Explanation

Remember ETL logging as:

```text
Start
 ↓
STARTED
 ↓
Process
 ↓
Success?
 /     \
Yes     No
 ↓       ↓
SUCCESS FAILED
         ↓
      Error Message
```

Remember error handling as:

```text
try
 ↓
Run Code

except
 ↓
Capture Error
 ↓
Log Failure
 ↓
raise
```

---

# Interview Explanation

> In my Logistics Azure Data Engineering project, I implemented ETL logging and error handling using Azure Databricks and Azure SQL Database. I created the `audit.ETL_LOG` table to capture process name, object, layer, start time, end time, record count, status, and error details. Each ETL step writes a STARTED status before processing, SUCCESS after successful completion, and FAILED when an exception occurs. I use try-except logic in Databricks, capture the error message, write it to the audit table, and raise the exception again so that Azure Data Factory can correctly identify the activity as failed.

---

# Final Summary

The ETL logging and error-handling framework works as:

```text
ADF
 ↓
Databricks
 ↓
Write STARTED
 ↓
Run ETL
 ↓
 ┌───────────────┐
 │ Successful?   │
 └───────┬───────┘
     Yes │ No
         │
    ↓    ↓
SUCCESS  Capture Error
         ↓
       FAILED
         ↓
        raise
         ↓
ADF Receives Failure
```

The structured execution history is stored in:

```sql
audit.ETL_LOG
```

This provides reliable monitoring, debugging, and failure tracking for the complete Azure Data Engineering pipeline.

