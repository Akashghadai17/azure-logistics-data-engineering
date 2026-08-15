# GitHub Repository Structure

## Overview

This document explains the folder and file structure used in the **Logistics Azure Data Engineering Project** GitHub repository.

The repository is organized so that documentation, SQL scripts, Databricks notebooks, ADF files, sample data, and architecture diagrams are kept separately.

This makes the project easier to:

* Understand
* Maintain
* Review
* Present in interviews
* Share with recruiters
* Extend in the future

---

# Recommended Repository Structure

```text
Logistics-Azure-Data-Engineering/
│
├── 01_Documentation/
│   ├── 01_Project_Overview.md
│   ├── 02_Azure_Resources.md
│   ├── 03_ADLS_Design.md
│   ├── 04_Azure_SQL_Metadata_Configuration.md
│   ├── 05_Key_Vault.md
│   ├── 06_Azure_Databricks.md
│   ├── 07_Unity_Catalog.md
│   ├── 08_Bronze_Layer.md
│   ├── 09_Silver_Layer.md
│   ├── 10_Gold_Layer.md
│   ├── 11_Data_Quality_Checks.md
│   ├── 12_Incremental_Load_Merge_Upsert.md
│   ├── 13_ETL_Logging_Error_Handling.md
│   ├── 14_ADF_Orchestration.md
│   ├── 15_End_to_End_Project_Flow.md
│   ├── 16_Interview_Explanation.md
│   ├── 17_Project_Summary.md
│   └── 18_Repository_Structure.md
│
├── 02_SQL/
│   ├── 01_Create_Schemas.sql
│   ├── 02_Create_Metadata_Tables.sql
│   ├── 03_Insert_Metadata_Configuration.sql
│   ├── 04_Insert_Column_Mapping.sql
│   ├── 05_Create_Audit_Table.sql
│   └── 06_Validation_Queries.sql
│
├── 03_Databricks_Notebooks/
│   ├── 01_Setup_Configuration.py
│   ├── 02_Read_Metadata.py
│   ├── 03_Bronze_Layer.py
│   ├── 04_Silver_Layer.py
│   ├── 05_Data_Quality.py
│   ├── 06_Gold_Layer.py
│   ├── 07_Incremental_Load.py
│   └── 08_ETL_Logging.py
│
├── 04_ADF/
│   ├── Pipeline/
│   ├── Linked_Service/
│   └── Screenshots/
│
├── 05_Sample_Data/
│   ├── Sales/
│   └── Appointment/
│
├── 06_Architecture/
│   ├── Project_Architecture.png
│   ├── Storage_Architecture.png
│   └── Medallion_Architecture.png
│
├── .gitignore
└── README.md
```

The exact file names can be adjusted according to the scripts and notebooks created in the project.

---

# 01_Documentation

The `01_Documentation` folder contains all project documentation.

```text
01_Documentation/
```

Its purpose is to explain the project step by step.

---

## Documentation Files

### 01_Project_Overview.md

Explains:

* Project objective
* Source data
* Technologies
* Medallion Architecture
* Main project features

---

### 02_Azure_Resources.md

Explains the Azure resources used in the project.

Examples:

* ADLS Gen2
* Azure SQL Database
* Azure Key Vault
* Azure Databricks
* Azure Data Factory

---

### 03_ADLS_Design.md

Explains the two-storage-account architecture.

```text
SC1
↓
Landing
Logs
Archive
```

```text
SC2
↓
Unity Catalog Managed Storage
```

---

### 04_Azure_SQL_Metadata_Configuration.md

Explains the metadata-driven ETL configuration.

Main tables:

```sql
metadata.OBJECTS_CONFIGURATION
```

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

---

### 05_Key_Vault.md

Explains secure credential management using Azure Key Vault.

---

### 06_Azure_Databricks.md

Explains the role of Databricks, Spark, PySpark, and Delta Lake.

---

### 07_Unity_Catalog.md

Explains:

* Catalog
* Schemas
* Managed tables
* Managed storage
* SC2 integration

---

### 08_Bronze_Layer.md

Explains:

* CSV ingestion
* Schema validation
* Missing and extra column checks
* Bronze managed tables

---

### 09_Silver_Layer.md

Explains:

* Metadata-driven column mapping
* Data cleaning
* Data type conversion
* NULL handling
* Duplicate removal

---

### 10_Gold_Layer.md

Explains:

* Dimension table
* Fact table
* Surrogate key
* Final Gold model

---

### 11_Data_Quality_Checks.md

Explains:

* Row count checks
* NULL checks
* Duplicate checks
* Primary key checks
* Foreign key checks
* Schema checks
* Data type checks

---

### 12_Incremental_Load_Merge_Upsert.md

Explains:

* Full load
* Incremental load
* Delta MERGE
* UPDATE
* INSERT
* UPSERT

---

### 13_ETL_Logging_Error_Handling.md

Explains:

```sql
audit.ETL_LOG
```

and:

* STARTED
* SUCCESS
* FAILED
* try-except
* exception handling

---

### 14_ADF_Orchestration.md

Explains Azure Data Factory orchestration.

---

### 15_End_to_End_Project_Flow.md

Explains the complete pipeline from source files to Gold tables.

---

### 16_Interview_Explanation.md

Contains short and easy explanations for interview preparation.

---

### 17_Project_Summary.md

Provides the final project summary.

---

### 18_Repository_Structure.md

Explains the GitHub repository structure.

---

# 02_SQL

The `02_SQL` folder contains Azure SQL and SSMS scripts.

```text
02_SQL/
```

These scripts are used to create and configure the metadata and audit framework.

---

# SQL File Structure

```text
02_SQL/
│
├── 01_Create_Schemas.sql
├── 02_Create_Metadata_Tables.sql
├── 03_Insert_Metadata_Configuration.sql
├── 04_Insert_Column_Mapping.sql
├── 05_Create_Audit_Table.sql
└── 06_Validation_Queries.sql
```

---

# 01_Create_Schemas.sql

Creates SQL schemas.

Conceptually:

```sql
CREATE SCHEMA metadata;
CREATE SCHEMA audit;
```

---

# 02_Create_Metadata_Tables.sql

Creates metadata configuration tables such as:

```sql
metadata.OBJECTS_CONFIGURATION
```

and:

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

---

# 03_Insert_Metadata_Configuration.sql

Contains object-level metadata records.

Examples include logical objects such as:

```text
SALES_DATA_PRIOR_DAY
APPOINTMENT_DATA
```

---

# 04_Insert_Column_Mapping.sql

Contains source-to-target column mapping configuration.

Example:

```text
APPOINTMENT_TITLE
        ↓
TITLE
```

---

# 05_Create_Audit_Table.sql

Creates:

```sql
audit.ETL_LOG
```

for ETL monitoring.

---

# 06_Validation_Queries.sql

Contains SQL queries used to verify:

* Metadata configuration
* Audit logs
* Failed jobs
* Successful jobs
* Table contents

---

# Why SQL Scripts Are Separated

Keeping SQL scripts separate provides:

* Better organization
* Easier debugging
* Easier deployment
* Better version control
* Easier interview explanation

---

# 03_Databricks_Notebooks

This folder contains PySpark and Databricks ETL processing code.

```text
03_Databricks_Notebooks/
```

Recommended structure:

```text
03_Databricks_Notebooks/
│
├── 01_Setup_Configuration.py
├── 02_Read_Metadata.py
├── 03_Bronze_Layer.py
├── 04_Silver_Layer.py
├── 05_Data_Quality.py
├── 06_Gold_Layer.py
├── 07_Incremental_Load.py
└── 08_ETL_Logging.py
```

---

# 01_Setup_Configuration.py

Contains common project configuration.

Examples include:

* Catalog information
* JDBC settings
* Secret retrieval
* Utility imports

Sensitive values should not be hard-coded.

---

# 02_Read_Metadata.py

Contains logic to read Azure SQL metadata through JDBC.

Main tables:

```sql
metadata.OBJECTS_CONFIGURATION
```

```sql
metadata.OBJECTS_COLUMN_MAPPING
```

---

# 03_Bronze_Layer.py

Contains Bronze processing logic.

Main activities:

```text
Read CSV
↓
Validate Schema
↓
Check Missing / Extra Columns
↓
Create Bronze Managed Tables
```

---

# 04_Silver_Layer.py

Contains Silver transformation logic.

Main activities:

```text
Read Bronze
↓
Read Metadata
↓
Apply Mapping
↓
Clean Data
↓
Convert Types
↓
Handle NULL
↓
Remove Duplicates
↓
Write Silver
```

---

# 05_Data_Quality.py

Contains reusable Data Quality Checks.

Examples:

* Row count
* NULL
* Duplicate
* PK
* FK
* Schema
* Data type

---

# 06_Gold_Layer.py

Contains Gold processing logic.

Creates:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

---

# 07_Incremental_Load.py

Contains Delta Lake MERGE logic.

```text
Match
↓
UPDATE

No Match
↓
INSERT
```

---

# 08_ETL_Logging.py

Contains reusable ETL logging and error-handling functions.

Main audit table:

```sql
audit.ETL_LOG
```

---

# Databricks Notebook Naming

Notebook names should be numbered based on processing order.

For example:

```text
01_
02_
03_
```

This makes the execution sequence easy to understand.

---

# 04_ADF

The `04_ADF` folder contains Azure Data Factory-related project artifacts.

```text
04_ADF/
```

Recommended structure:

```text
04_ADF/
│
├── Pipeline/
├── Linked_Service/
└── Screenshots/
```

---

# Pipeline

Contains exported pipeline definitions or documentation related to the ADF pipeline.

Conceptually:

```text
ADF Pipeline
     ↓
Databricks Activities
```

---

# Linked_Service

Contains configuration documentation or exported definitions related to linked services.

Example:

```text
ADF
↓
Databricks Linked Service
↓
Azure Databricks
```

Do not commit passwords, tokens, or secrets.

---

# Screenshots

Contains useful screenshots of:

* Pipeline design
* Successful pipeline run
* Failed pipeline run
* Activity dependencies
* ADF Monitor

Only upload screenshots that do not expose sensitive information.

---

# 05_Sample_Data

The `05_Sample_Data` folder can contain small sample datasets used to demonstrate the project.

```text
05_Sample_Data/
│
├── Sales/
│
└── Appointment/
```

---

# Sales Sample Data

Contains a small example Sales CSV.

Do not upload large production datasets.

---

# Appointment Sample Data

Contains a small Appointment CSV example.

Sensitive or personal information should not be uploaded.

---

# Why Use Sample Data

Sample data helps recruiters or developers understand:

* Source structure
* Column names
* Data format
* How the ETL pipeline works

without requiring access to Azure.

---

# 06_Architecture

The `06_Architecture` folder contains project architecture diagrams.

```text
06_Architecture/
```

Recommended files:

```text
Project_Architecture.png
Storage_Architecture.png
Medallion_Architecture.png
```

---

# Project_Architecture.png

Should show the complete flow:

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
Gold
↓
SC2
```

along with Azure SQL and Key Vault.

---

# Storage_Architecture.png

Should show:

```text
SC1
│
├── landing
├── logs
└── archive
```

and:

```text
SC2
↓
Unity Catalog Managed Storage
```

---

# Medallion_Architecture.png

Should show:

```text
Bronze
↓
Silver
↓
Gold
```

with the main responsibility of each layer.

---

# README.md

The root-level `README.md` is the first file a recruiter or developer sees.

It should provide a short project overview.

Recommended content:

* Project title
* Architecture diagram
* Objective
* Technologies
* Pipeline flow
* Main features
* Final Gold tables
* Repository structure
* Documentation links

---

# README Flow

A good README should quickly answer:

```text
What is the project?
        ↓
What technologies are used?
        ↓
How does the architecture work?
        ↓
What features were implemented?
        ↓
Where is the code?
```

---

# .gitignore

`.gitignore` prevents unwanted files from being committed to GitHub.

Examples that may be excluded:

```text
.env
*.log
__pycache__/
.vscode/
.DS_Store
```

Credentials must never be committed.

---

# Security Rules for the Repository

Do not upload:

* SQL passwords
* Storage account keys
* Service Principal secrets
* Access tokens
* Connection strings containing secrets
* Databricks tokens
* Private keys
* Personal credentials

Use placeholders instead.

Correct:

```text
<sql-password>
```

Incorrect:

```text
ActualPassword123
```

---

# Azure Key Vault and GitHub

Actual secret values remain in Azure Key Vault.

GitHub contains only code that retrieves the secret.

Conceptually:

```python
password = dbutils.secrets.get(
    scope="<scope>",
    key="<sql-password-secret>"
)
```

The actual password must never appear in the repository.

---

# Naming Convention

Use consistent file naming.

Recommended:

```text
01_Project_Overview.md
02_Azure_Resources.md
03_ADLS_Design.md
```

instead of inconsistent names such as:

```text
project overview.md
AzureResourceFINAL.md
adls_NEW_v2.md
```

Consistent names make the project more professional.

---

# Folder Numbering

The repository uses numbered folders:

```text
01_Documentation
02_SQL
03_Databricks_Notebooks
04_ADF
05_Sample_Data
06_Architecture
```

This keeps the repository organized in a logical order.

---

# Project Processing Order

The repository structure also reflects the actual ETL process.

```text
Source
 ↓
SQL Metadata
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
Incremental Load
 ↓
Logging
 ↓
ADF Orchestration
```

---

# Recommended Final Repository

```text
Logistics-Azure-Data-Engineering/
│
├── README.md
│
├── .gitignore
│
├── 01_Documentation/
│   ├── 01_Project_Overview.md
│   ├── 02_Azure_Resources.md
│   ├── 03_ADLS_Design.md
│   ├── 04_Azure_SQL_Metadata_Configuration.md
│   ├── 05_Key_Vault.md
│   ├── 06_Azure_Databricks.md
│   ├── 07_Unity_Catalog.md
│   ├── 08_Bronze_Layer.md
│   ├── 09_Silver_Layer.md
│   ├── 10_Gold_Layer.md
│   ├── 11_Data_Quality_Checks.md
│   ├── 12_Incremental_Load_Merge_Upsert.md
│   ├── 13_ETL_Logging_Error_Handling.md
│   ├── 14_ADF_Orchestration.md
│   ├── 15_End_to_End_Project_Flow.md
│   ├── 16_Interview_Explanation.md
│   ├── 17_Project_Summary.md
│   └── 18_Repository_Structure.md
│
├── 02_SQL/
│   ├── 01_Create_Schemas.sql
│   ├── 02_Create_Metadata_Tables.sql
│   ├── 03_Insert_Metadata_Configuration.sql
│   ├── 04_Insert_Column_Mapping.sql
│   ├── 05_Create_Audit_Table.sql
│   └── 06_Validation_Queries.sql
│
├── 03_Databricks_Notebooks/
│   ├── 01_Setup_Configuration.py
│   ├── 02_Read_Metadata.py
│   ├── 03_Bronze_Layer.py
│   ├── 04_Silver_Layer.py
│   ├── 05_Data_Quality.py
│   ├── 06_Gold_Layer.py
│   ├── 07_Incremental_Load.py
│   └── 08_ETL_Logging.py
│
├── 04_ADF/
│   ├── Pipeline/
│   ├── Linked_Service/
│   └── Screenshots/
│
├── 05_Sample_Data/
│   ├── Sales/
│   └── Appointment/
│
└── 06_Architecture/
    ├── Project_Architecture.png
    ├── Storage_Architecture.png
    └── Medallion_Architecture.png
```

---

# Why This Structure Is Good for GitHub

This repository structure separates:

```text
Documentation
SQL
Databricks
ADF
Sample Data
Architecture
```

This makes it easy for someone reviewing the project to find the required information.

---

# Recruiter View

A recruiter can start with:

```text
README.md
```

Then:

```text
01_Project_Overview.md
```

and:

```text
Project_Architecture.png
```

This provides a quick understanding of the project without reading every technical file.

---

# Technical Interviewer View

A technical interviewer can review:

```text
02_SQL
```

for metadata and audit implementation.

Then:

```text
03_Databricks_Notebooks
```

for PySpark processing.

Then:

```text
04_ADF
```

for orchestration.

This demonstrates the complete Data Engineering workflow.

---

# Easy Way to Remember the Repository

```text
01 = Documentation

02 = SQL

03 = Databricks

04 = ADF

05 = Sample Data

06 = Architecture
```

---

# Final Summary

The GitHub repository is organized to clearly separate project documentation, SQL configuration, Databricks processing code, ADF orchestration, sample source data, and architecture diagrams.

A well-structured repository makes the Logistics Azure Data Engineering Project easier to understand, maintain, and explain during interviews.
