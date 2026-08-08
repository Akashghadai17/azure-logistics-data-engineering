# ADLS Gen2 Design

## Storage Account
Create a StorageV2 account with Hierarchical Namespace enabled.

Example:

```text
stlogisticdevXX
```

## Containers
```text
landing
bronze
silver
gold
logs
```

## Folder Structure
```text
landing/
└── logistic/
    ├── sales/
    │   └── Sales_Data_Prior_Day.csv
    └── appointment/
        └── AppointmentDataTest.csv

bronze/
└── logistic/

silver/
└── logistic/

gold/
└── edw/

logs/
└── logistic/
```

## Purpose of Each Layer
| Container | Purpose |
|---|---|
| landing | Incoming source files |
| bronze | Raw/near-raw Delta data |
| silver | Cleaned and standardized Delta data |
| gold | Business-ready Dimension and Fact data |
| logs | ETL and pipeline operational logs |

## Source Files
Logical source names used by the pipeline:

```text
Sales_Data_Prior_Day
AppointmentDataTest
```

The physical file name can contain a date suffix. The pipeline metadata should control the actual file/path used for each run.
