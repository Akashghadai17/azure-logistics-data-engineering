# Azure Databricks Unity Catalog Implementation

## Overview

Azure Databricks **Unity Catalog** is used in the Logistics Azure Data Engineering Project to centrally manage and govern the Bronze, Silver, and Gold data tables.

Unity Catalog provides centralized management for:

* Catalogs
* Schemas
* Tables
* Managed storage
* Permissions
* Data governance
* Access control

The project uses Unity Catalog together with **Storage Account 2 (SC2)** for managed Delta table storage.

---

# Unity Catalog Role in the Project

The high-level design is:

```text
SC1 Landing
     ↓
Azure Databricks
     ↓
Unity Catalog
     ↓
Bronze
     ↓
Silver
     ↓
Gold
     ↓
Managed Delta Tables
     ↓
SC2
```

SC1 and SC2 have different responsibilities.

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
↓
Bronze
Silver
Gold
```

---

# Why Unity Catalog Is Used

Without Unity Catalog, tables and permissions can be managed separately inside individual Databricks workspaces.

Unity Catalog provides a centralized structure.

```text
Unity Catalog
      ↓
Catalog
      ↓
Schemas
      ↓
Tables
```

This makes the data platform easier to:

* Organize
* Secure
* Govern
* Maintain
* Query

---

# Unity Catalog Hierarchy

Unity Catalog follows a three-level namespace:

```text
Catalog.Schema.Table
```

Example:

```text
<catalog>.bronze.<table_name>
```

```text
<catalog>.silver.<table_name>
```

```text
<catalog>.gold.DIM_APPOINTMENT_DATA
```

```text
<catalog>.gold.FACT_SALES
```

---

# Project Unity Catalog Structure

The project uses one main catalog containing three schemas.

```text
Unity Catalog
      │
      └── Project Catalog
              │
              ├── bronze
              │
              ├── silver
              │
              └── gold
```

The schemas represent the three layers of the Medallion Architecture.

---

# Bronze Schema

The Bronze schema stores raw or near-raw processed data.

```text
<catalog>
   ↓
bronze
```

Bronze data is created after source CSV files are read from SC1 Landing.

Flow:

```text
SC1 Landing
     ↓
Databricks
     ↓
Schema Validation
     ↓
Bronze Managed Delta Table
     ↓
Unity Catalog
     ↓
SC2 Managed Storage
```

---

# Silver Schema

The Silver schema stores cleaned and standardized data.

```text
<catalog>
   ↓
silver
```

Silver processing includes:

* Metadata-driven column mapping
* Column renaming
* Data type conversion
* NULL handling
* Invalid data handling
* Duplicate removal
* Data cleaning
* Data standardization

Flow:

```text
Bronze Managed Table
        ↓
PySpark Transformations
        ↓
Silver Managed Table
        ↓
Unity Catalog
        ↓
SC2 Managed Storage
```

---

# Gold Schema

The Gold schema stores business-ready analytical data.

```text
<catalog>
   ↓
gold
```

Final Gold tables include:

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
Join / Business Logic
        ↓
FACT_SALES
```

Both tables are managed using Unity Catalog.

---

# Managed Tables

The project uses **Unity Catalog managed Delta tables** for Bronze, Silver, and Gold.

A managed table means Databricks and Unity Catalog manage both:

* Table metadata
* Physical storage location

Conceptually:

```text
Create Managed Table
        ↓
Unity Catalog
        ↓
Table Metadata
        +
Delta Files
        ↓
SC2 Managed Storage
```

Because these are managed tables, the project does not manually specify an SC1 Bronze, Silver, or Gold folder.

---

# Storage Account Design

The project uses two Azure Data Lake Storage Gen2 accounts.

## SC1

SC1 stores file-based data.

```text
SC1
│
├── landing
├── logs
└── archive
```

SC1 is used for:

* Sales CSV source files
* Appointment CSV source files
* Technical/file logs
* Archived processed files

---

## SC2

SC2 is dedicated to Unity Catalog managed storage.

```text
SC2
      ↓
Managed Storage
      ↓
Unity Catalog
      ↓
Bronze
Silver
Gold
```

This provides separation between raw source files and managed analytical tables.

---

# Managed Location

A managed storage location is configured for Unity Catalog using SC2.

Conceptually:

```text
SC2 ADLS Gen2
      ↓
Managed Container
      ↓
Unity Catalog Managed Location
```

When managed tables are created, Unity Catalog automatically stores their physical Delta files under the configured managed storage.

---

# Why SC2 Is Separate

Using SC2 for managed storage provides a clear separation of responsibilities.

```text
SC1 = File Storage
```

```text
SC2 = Managed Table Storage
```

This makes the architecture easier to understand and manage.

---

# Storage Credential

Unity Catalog requires secure access to Azure storage.

A **Storage Credential** is created to represent the Azure identity used to access storage.

Conceptually:

```text
Azure Identity
      ↓
Storage Credential
      ↓
Unity Catalog
      ↓
Azure Storage
```

The project uses a secure Azure identity rather than directly embedding storage keys in table definitions.

---

# Service Principal

A Service Principal is used as an application identity for Azure authentication where required.

It contains information such as:

```text
Tenant ID
Client ID
Client Secret
```

The Service Principal is granted the required Azure Storage permissions.

Conceptually:

```text
Service Principal
```

