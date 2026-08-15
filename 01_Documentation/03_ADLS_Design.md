# Storage Account Design

The Logistics Azure Data Engineering Project uses **two Azure Data Lake Storage Gen2 accounts** with different responsibilities.

## Storage Account 1 — Project File Storage

**SC1** is used for source files, logs, and archived files.

```text
SC1
│
├── landing
│   ├── sales
│   └── appointment
│
├── logs
│
└── archive
    ├── sales
    └── appointment
```

### Purpose of SC1

SC1 stores file-based project data.

#### Landing

The `landing` location stores incoming source CSV files.

```text
SC1
└── landing
    ├── sales
    └── appointment
```

Source datasets:

* Sales Data
* Appointment Data

#### Logs

The `logs` location stores file-based ETL or technical log information where required.

```text
SC1
└── logs
```

#### Archive

The `archive` location stores source files after successful processing.

```text
SC1
└── archive
    ├── sales
    └── appointment
```

This separates processed source files from new files waiting in Landing.

---

## Storage Account 2 — Unity Catalog Managed Storage

**SC2** is used as the managed storage location for **Databricks Unity Catalog**.

```text
SC2
│
└── Unity Catalog Managed Storage
        │
        ├── Bronze Managed Tables
        ├── Silver Managed Tables
        └── Gold Managed Tables
```

SC2 is not used as the source Landing area.

Its main responsibility is to provide storage for managed Delta tables created through Unity Catalog.

---

# Unity Catalog

Azure Databricks Unity Catalog is used to manage the processed data.

The project contains schemas such as:

```text
Unity Catalog
      │
      ├── bronze
      ├── silver
      └── gold
```

Tables created inside these schemas are managed through Unity Catalog.

Their physical Delta files are stored in **SC2 managed storage**.

---

## Bronze

Bronze contains raw or near-raw processed data.

```text
Unity Catalog
└── bronze
```

Flow:

```text
SC1 Landing CSV
       ↓
Azure Databricks
       ↓
Bronze Managed Delta Table
       ↓
Stored Physically in SC2
```

---

## Silver

Silver contains cleaned and standardized data.

```text
Unity Catalog
└── silver
```

Processing includes:

* Column mapping
* Data type conversion
* NULL handling
* Invalid-value handling
* Duplicate removal
* Data cleaning
* Data standardization

Flow:

```text
Bronze Managed Table
        ↓
PySpark Transformation
        ↓
Silver Managed Table
        ↓
Stored Physically in SC2
```

---

## Gold

Gold contains business-ready analytical data.

```text
Unity Catalog
└── gold
```

Final Gold tables include:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

Flow:

```text
Silver Managed Tables
         ↓
Gold Transformation
         ↓
DIM_APPOINTMENT_DATA
         +
FACT_SALES
         ↓
Unity Catalog Managed Tables
         ↓
Physical Storage in SC2
```

---

# Why Two Storage Accounts?

The two-storage-account design separates source/file-based storage from managed analytical storage.

### SC1

Used for:

```text
Landing
Logs
Archive
```

### SC2

Used for:

```text
Unity Catalog Managed Storage
        ↓
Bronze
Silver
Gold
```

This creates a clear separation between incoming operational files and Databricks-managed Delta tables.

---

# Correct End-to-End Storage Flow

```text
Sales CSV + Appointment CSV
             ↓
          SC1 ADLS
             ↓
           Landing
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
        /         \
       ↓           ↓
DIM_APPOINTMENT  FACT_SALES
             ↓
     Managed Delta Tables
             ↓
            SC2
```

After successful source processing:

```text
SC1 Landing
     ↓
Successful Processing
     ↓
SC1 Archive
```

Technical/file-based logs:

```text
ETL Process
     ↓
SC1 Logs
```

---

# Supporting Components

Azure SQL Database is separate from both storage accounts.

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

Azure Key Vault stores secure credentials and secrets.

```text
Azure Key Vault
      ↓
Secure Credentials
```

Azure Data Factory orchestrates the overall workflow.

```text
Azure Data Factory
       ↓
Databricks Processing
```

---

# Final Architecture

```text
                         Source CSV Files
                    Sales + Appointment
                              │
                              ↓
                    ┌──────────────────┐
                    │     SC1 ADLS     │
                    │                  │
                    │ Landing          │
                    │ Logs             │
                    │ Archive          │
                    └────────┬─────────┘
                             ↓
                    Azure Databricks
                             │
                             ↓
                      Unity Catalog
                             │
                    ┌────────┼────────┐
                    ↓        ↓        ↓
                  Bronze   Silver    Gold
                                      │
                                ┌─────┴─────┐
                                ↓           ↓
                        DIM_APPOINTMENT  FACT_SALES
                             │
                             ↓
                    ┌──────────────────┐
                    │     SC2 ADLS     │
                    │                  │
                    │ Unity Catalog    │
                    │ Managed Storage  │
                    └──────────────────┘
```

## Easy Way to Remember

```text
SC1 = Files
      Landing + Logs + Archive

SC2 = Tables
      Unity Catalog Managed
      Bronze + Silver + Gold
```
