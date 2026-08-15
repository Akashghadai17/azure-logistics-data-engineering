# Azure Data Factory Orchestration

## Overview

Azure Data Factory (ADF) is used as the **orchestration layer** of the Logistics Azure Data Engineering Project.

ADF does not perform the main PySpark transformations itself.

Instead, ADF controls:

* When the ETL pipeline runs
* Which Databricks notebook runs first
* Dependency between processing steps
* Success and failure flow
* Pipeline execution monitoring

The main data transformation work is performed in **Azure Databricks**.

---

# Role of Azure Data Factory

The responsibilities are separated as follows:

```text
Azure Data Factory
        ↓
Orchestration

Azure Databricks
        ↓
Data Processing
```

Easy way to remember:

```text
ADF = Controls the pipeline

Databricks = Processes the data
```

---

# End-to-End Project Flow

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
            ↓
 Incremental MERGE / UPSERT
            ↓
      ETL Audit Logging
```

---

# ADF Architecture

```text
                    Azure Data Factory
                           │
                           ↓
                       Pipeline
                           │
            ┌──────────────┼──────────────┐
            │              │              │
            ↓              ↓              ↓
       Databricks      Monitoring      Error Flow
        Notebooks
            │
            ↓
         Bronze
            ↓
         Silver
            ↓
       Data Quality
            ↓
          Gold
            ↓
     Incremental Load
            ↓
       ETL Logging
```

---

# Why ADF Is Used

Without orchestration, Databricks notebooks would need to be executed manually.

For example:

```text
Run Bronze Notebook
      ↓
Wait
      ↓
Run Silver Notebook
      ↓
Wait
      ↓
Run Gold Notebook
```

ADF automates this sequence.

```text
ADF Pipeline
     ↓
Automatically Execute Steps
     ↓
Track Success / Failure
```

---

# Main ADF Responsibilities

ADF is used for:

* Databricks notebook execution
* Activity sequencing
* Dependency management
* Pipeline orchestration
* Pipeline monitoring
* Failure propagation
* Parameter passing where required
* Scheduling or triggering the workflow

---

# Pipeline Execution Order

The ETL workflow should execute in the correct order.

```text
1. Bronze Processing
        ↓
2. Silver Processing
        ↓
3. Data Quality Checks
        ↓
4. Gold Processing
        ↓
5. Incremental Load / MERGE
        ↓
6. ETL Logging / Completion
```

Each downstream stage depends on successful completion of the previous required stage.

---

# Why Execution Order Matters

Silver depends on Bronze.

```text
Bronze
   ↓
Silver
```

Gold depends on clean Silver data.

```text
Silver
   ↓
Data Quality
   ↓
Gold
```

Therefore Gold should not run if Silver processing fails.

---

# ADF Pipeline Concept

The pipeline can be represented as:

```text
Start
  ↓
Bronze Notebook
  ↓
Silver Notebook
  ↓
Data Quality Notebook
  ↓
Gold Notebook
  ↓
Incremental Load Notebook
  ↓
Complete
```

---

# Azure Databricks Notebook Activity

ADF uses a Databricks Notebook activity to execute Databricks code.

Conceptually:

```text
ADF
 ↓
Databricks Notebook Activity
 ↓
Databricks Workspace
 ↓
Notebook
 ↓
Spark / PySpark Processing
```

---

# Databricks Linked Service

ADF requires a connection to Azure Databricks.

This connection is configured using an **Azure Databricks Linked Service**.

Conceptually:

```text
ADF
 ↓
Databricks Linked Service
 ↓
Azure Databricks Workspace
 ↓
Compute
```

The linked service allows ADF to execute Databricks notebook activities.

---

# Linked Service Purpose

A linked service defines how ADF connects to another service.

For this project:

```text
ADF
 ↓
Linked Service
 ↓
Azure Databricks
```

ADF then uses that connection to execute ETL notebooks.

---

# Databricks Compute

The ADF Databricks activity runs the notebook using the Databricks compute configured for the project.

```text
ADF
 ↓
Databricks Activity
 ↓
Databricks Compute
 ↓
Spark Job
```

---

# Bronze Notebook Activity

The Bronze activity processes source files from SC1 Landing.

```text
ADF
 ↓
Bronze Notebook
 ↓
SC1 Landing
 ↓
Read CSV
 ↓
Validate Schema
 ↓
Bronze Managed Tables
 ↓
Unity Catalog
 ↓
SC2
```

Bronze performs:

* Source file reading
* Schema validation
* Required-column validation
* Missing/extra column validation
* Raw or near-raw Delta loading

---

# Silver Notebook Activity

The Silver activity runs only after successful Bronze processing.

```text
Bronze Success
      ↓
Silver Notebook
      ↓
Read Bronze
      ↓
Read Metadata
      ↓
Apply Mapping
      ↓
Clean Data
      ↓
Convert Data Types
      ↓
Remove Duplicates
      ↓
Silver Managed Tables
```

---

# Data Quality Activity

After Silver processing, Data Quality Checks validate the transformed datasets.

```text
Silver Success
      ↓
Data Quality
      ↓
Row Count
NULL Check
Duplicate Check
PK Check
FK Check
Schema Check
Data Type Check
```

If critical checks pass:

```text
PASS
 ↓
Continue to Gold
```

If they fail:

```text
FAIL
 ↓
Pipeline Failure
```

---

# Gold Notebook Activity

Gold processing starts only after the required Data Quality Checks pass.

```text
Silver
   ↓
DQ PASS
   ↓
Gold Notebook
   ↓
DIM_APPOINTMENT_DATA
   +
FACT_SALES
```

The Gold tables are stored as Unity Catalog managed Delta tables.

---

# Incremental Load Activity

The incremental processing step uses Delta Lake MERGE.

```text
New / Changed Data
        ↓
Existing Delta Table
        ↓
MERGE
      /     \
 UPDATE     INSERT
      \     /
       UPSERT
```

ADF orchestrates when this notebook or processing stage runs.

---

# ETL Logging

Execution information is recorded in Azure SQL Database.

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

Databricks writes ETL execution information while ADF tracks orchestration-level execution.

---

# ADF Monitoring vs ETL Audit Logging

ADF monitoring and Azure SQL audit logging have different purposes.

## ADF Monitoring

Shows:

* Pipeline run
* Activity run
* Activity status
* Start time
* End time
* Failure status

## Azure SQL Audit

Stores:

* ETL process name
* Object name
* Layer
* Record count
* Status
* Error details

Easy way to remember:

```text
ADF Monitoring
      ↓
What happened to the workflow?

audit.ETL_LOG
      ↓
What happened inside the ETL?
```

---

# Activity Dependencies

ADF allows one activity to run based on the result of another activity.

Common dependency conditions include:

```text
Succeeded
Failed
Completed
Skipped
```

For the normal processing flow:

```text
Bronze
  │
  └── On Success
          ↓
       Silver
```

---

# Success Dependency

A downstream notebook should run when the previous step succeeds.

```text
Bronze
   ↓
SUCCESS
   ↓
Silver
```

Similarly:

```text
Silver
   ↓
SUCCESS
   ↓
Data Quality
```

---

# Failure Dependency

If a required activity fails:

```text
Notebook Activity
       ↓
FAILED
       ↓
Stop Downstream Processing
```

The failure can then be investigated through:

* ADF Monitor
* Databricks error output
* `audit.ETL_LOG`

---

# Error Propagation

Databricks notebooks use exception handling.

Conceptually:

```python
try:
    # processing

except Exception as e:
    # write FAILED log
    raise
```

The important part is:

```python
raise
```

This sends the failure back to ADF.

---

# Error Flow

```text
Databricks Notebook
        ↓
Processing Error
        ↓
Capture Exception
        ↓
Write FAILED to audit.ETL_LOG
        ↓
raise
        ↓
ADF Notebook Activity = FAILED
        ↓
ADF Pipeline = FAILED
```

This makes the failure visible at both ETL and orchestration levels.

---

# Successful Pipeline Flow

```text
ADF Pipeline Starts
        ↓
Bronze
        ↓
SUCCESS
        ↓
Silver
        ↓
SUCCESS
        ↓
Data Quality
        ↓
PASS
        ↓
Gold
        ↓
SUCCESS
        ↓
Incremental Processing
        ↓
SUCCESS
        ↓
Pipeline Complete
```

---

# Failed Pipeline Example

Suppose Silver encounters an invalid numeric value.

```text
Bronze
  ↓
SUCCESS
  ↓
Silver
  ↓
CAST_INVALID_INPUT
  ↓
Write FAILED Log
  ↓
Raise Exception
  ↓
ADF Silver Activity = FAILED
  ↓
Gold Does Not Run
```

This protects the downstream analytical data.

---

# Pipeline Parameters

ADF pipelines can use parameters to make the workflow reusable.

Examples may include:

```text
Object Name
Processing Date
Layer
Load Type
File Name
```

Conceptually:

```text
ADF Parameter
      ↓
Databricks Notebook
      ↓
dbutils.widgets
      ↓
Reusable Processing
```

---

# Databricks Widgets

Databricks widgets can receive values passed from ADF.

Conceptually:

```python
dbutils.widgets.text(
    "object_name",
    ""
)

object_name = dbutils.widgets.get(
    "object_name"
)
```

ADF can pass the object name during notebook execution.

---

# Why Parameters Are Useful

Without parameters:

```text
Notebook A → Sales

Notebook B → Appointment
```

With reusable parameters:

```text
Generic Notebook
       ↓
object_name
       ↓
Sales / Appointment
```

This supports a more metadata-driven design.

---

# Metadata-Driven Orchestration

Azure SQL metadata contains configuration such as:

```sql
metadata.OBJECTS_CONFIGURATION
```

The pipeline can use this configuration to determine which objects should be processed.

Conceptually:

```text
ADF
 ↓
Object Configuration
 ↓
Databricks
 ↓
Process Object
```

---

# OBJECTS_CONFIGURATION

The metadata table provides object-level configuration.

It can help identify:

* Source object
* Target object
* Processing layer
* Load type
* Active status
* Other ETL configuration

This reduces hard-coded processing logic.

---

# Metadata and ADF

The overall metadata-driven concept is:

```text
Azure SQL Metadata
        ↓
Configuration
        ↓
ADF / Databricks
        ↓
Reusable Processing
```

---

# ADF and SC1

SC1 is used for:

```text
Landing
Logs
Archive
```

ADF orchestrates Databricks processing of files from the SC1 Landing area.

```text
SC1 Landing
     ↓
ADF
     ↓
Databricks
```

---

# ADF and SC2

ADF does not directly manage Bronze/Silver/Gold physical table files.

Databricks and Unity Catalog manage those tables.

```text
ADF
 ↓
Databricks
 ↓
Unity Catalog
 ↓
Managed Delta Tables
 ↓
SC2
```

---

# Correct Two-Storage-Account Flow

```text
SC1
│
├── landing
├── logs
└── archive
      │
      ↓
     ADF
      ↓
Databricks
      ↓
Unity Catalog
      ↓
Bronze
Silver
Gold
      ↓
SC2 Managed Storage
```

---

# Azure Key Vault Role

Sensitive credentials are stored in Azure Key Vault.

Examples:

* Azure SQL credentials
* Service Principal credentials
* Storage-related secrets
* Other secure connection values

The security design is:

```text
Azure Key Vault
      ↓
Secure Secrets
      ↓
Databricks / Required Azure Services
```

Secrets should never be hard-coded in ADF or Databricks code.

---

# Azure SQL Role

Azure SQL Database provides two supporting functions.

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

ADF orchestrates the process while Databricks interacts with these tables where required.

---

# Unity Catalog Role

Unity Catalog manages the processed tables.

```text
Unity Catalog
      │
      ├── bronze
      ├── silver
      └── gold
```

The physical storage for managed tables is located in SC2.

---

# Complete ADF Integration Architecture

```text
                        Azure Data Factory
                               │
                               ↓
                         Pipeline Start
                               │
                               ↓
                     Databricks Notebook
                               │
                               ↓
                           SC1 Landing
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
                               │
                               ↓
                    Incremental MERGE
                               │
                               ↓
                         Unity Catalog
                               │
                               ↓
                      SC2 Managed Storage
```

Supporting services:

```text
Azure SQL Database
        │
        ├── Metadata
        └── Audit
```

```text
Azure Key Vault
        │
        └── Secure Secrets
```

---

# Pipeline Monitoring

ADF provides a Monitor section where pipeline runs can be inspected.

The pipeline execution can show:

```text
Succeeded
Failed
In Progress
Cancelled
```

For each activity, ADF can show:

* Start time
* End time
* Duration
* Status
* Input
* Output
* Error details

---

# Troubleshooting Process

If the ADF pipeline fails:

```text
ADF Monitor
    ↓
Find Failed Activity
    ↓
Open Activity Error
    ↓
Check Databricks Notebook
    ↓
Check audit.ETL_LOG
    ↓
Identify Root Cause
```

This provides multiple levels of troubleshooting.

---

# ADF Trigger

ADF pipelines can be executed manually or through a trigger.

Conceptually:

```text
Manual Run
   OR
Scheduled Trigger
       ↓
ADF Pipeline
```

For automated production-style processing, a schedule trigger can run the pipeline at a required frequency.

---

# Daily Processing Concept

Since the project contains a Sales object such as:

```text
SALES_DATA_PRIOR_DAY
```

the architecture supports scheduled periodic processing.

Conceptually:

```text
Daily Trigger
     ↓
ADF Pipeline
     ↓
Process New Data
     ↓
Incremental MERGE
```

The actual trigger frequency should match the configured project schedule.

---

# Source File Lifecycle

The source file lifecycle is:

```text
Source File
    ↓
SC1 Landing
    ↓
ADF Orchestration
    ↓
Databricks Processing
    ↓
Successful Processing
    ↓
SC1 Archive
```

This separates new source files from already processed files.

---

# Archive Purpose

After successful processing:

```text
Landing
  ↓
Archive
```

The Archive area helps:

* Avoid accidental reprocessing
* Preserve source history
* Keep Landing organized
* Support debugging
* Support reprocessing if required

---

# ADF vs Databricks

| Azure Data Factory    | Azure Databricks            |
| --------------------- | --------------------------- |
| Orchestrates workflow | Processes data              |
| Runs activities       | Runs Spark/PySpark          |
| Controls sequence     | Performs transformations    |
| Supports triggers     | Performs Delta MERGE        |
| Monitors pipeline     | Performs Data Quality logic |
| Handles dependencies  | Creates Bronze/Silver/Gold  |

---

# ADF vs Unity Catalog

ADF:

```text
Controls Processing
```

Unity Catalog:

```text
Controls Data Objects and Governance
```

They have different roles.

---

# ADF vs Azure SQL Audit

ADF provides orchestration monitoring.

Azure SQL provides detailed ETL history.

```text
ADF
 ↓
Pipeline Monitoring
```

```text
audit.ETL_LOG
 ↓
ETL Execution Monitoring
```

---

# ADF vs SC1 Logs

SC1 may contain file-based technical logs.

ADF has pipeline monitoring.

Azure SQL has structured ETL audit logs.

```text
SC1 logs
    ↓
File-Based Logs

ADF Monitor
    ↓
Pipeline Activity Logs

audit.ETL_LOG
    ↓
Structured ETL Logs
```

These provide different levels of observability.

---

# Complete Project Orchestration

```text
                    Source CSV Files
                 Sales + Appointment
                         │
                         ↓
                       SC1
                         │
                      Landing
                         │
                         ↓
                Azure Data Factory
                         │
                         ↓
                 Azure Databricks
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
                  /               \
                 ↓                 ↓
      DIM_APPOINTMENT_DATA    FACT_SALES
                  \               /
                   \             /
                         ↓
                 Incremental MERGE
                         ↓
                   Unity Catalog
                         ↓
                SC2 Managed Storage
```

Supporting services:

```text
Azure SQL
│
├── metadata
└── audit
```

```text
Azure Key Vault
│
└── Secure Secrets
```

---

# Pipeline Reliability

The orchestration design improves reliability because downstream processing only continues after successful upstream processing.

For example:

```text
Bronze Failed
     ↓
Silver Does Not Run
     ↓
Gold Does Not Run
```

This prevents incomplete or invalid datasets from reaching downstream layers.

---

# Key ADF Concepts Used

The important ADF concepts demonstrated in this project include:

* Pipeline
* Activities
* Databricks Notebook Activity
* Linked Service
* Dependencies
* Parameters
* Triggering
* Monitoring
* Success flow
* Failure flow
* Orchestration

---

# Easy Explanation

Remember ADF as the **manager of the ETL pipeline**.

```text
ADF
 ↓
Run Bronze
 ↓
Run Silver
 ↓
Check Data Quality
 ↓
Run Gold
 ↓
Run MERGE
 ↓
Monitor Everything
```

ADF decides:

```text
When to run
What to run
What runs next
What happens if something fails
```

---

# Interview Explanation

> In my Logistics Azure Data Engineering project, I used Azure Data Factory as the orchestration layer. ADF executes the Databricks processing workflow in the required sequence. The source Sales and Appointment files are stored in the Landing area of the first ADLS account. Databricks processes them through Bronze, Silver, Data Quality, Gold, and incremental Delta MERGE stages. Bronze, Silver, and Gold are Unity Catalog managed Delta tables whose managed storage is configured in the second ADLS account. I also integrated Azure SQL metadata and audit logging, Azure Key Vault for secrets, and failure handling so that Databricks exceptions propagate back to ADF and failed activities are visible in ADF Monitor.

---

# Final Summary

Azure Data Factory provides the orchestration required to connect all major components of the project.

```text
SC1 Landing
     ↓
ADF
     ↓
Databricks
     ↓
Bronze
     ↓
Silver
     ↓
Data Quality
     ↓
Gold
     ↓
MERGE / UPSERT
     ↓
Unity Catalog
     ↓
SC2
```

Along with:

```text
Azure SQL
→ Metadata + Audit

Azure Key Vault
→ Security

ADF Monitor
→ Pipeline Monitoring
```

ADF therefore acts as the **central workflow controller** for the complete Logistics Azure Data Engineering pipeline.
