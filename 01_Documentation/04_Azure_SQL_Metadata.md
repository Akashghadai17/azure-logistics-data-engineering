# Azure SQL Metadata Design

## Database
```text
LogisticDB
```

## Metadata Schema
```sql
CREATE SCHEMA metadata;
```

## Core Metadata Tables
```text
metadata.OBJECTS_CONFIGURATION
metadata.OBJECTS_COLUMN_MAPPING
metadata.EDW_CONFIG
metadata.ETL_LOG
```

## OBJECTS_CONFIGURATION
Controls object-level ETL behavior.

Important fields:
- `OBJECT_NAME`
- `IS_RUN`
- `KEY_COLUMN_NAME`
- `OPERATION_TYPE`
- `SOURCE_NAME`
- `SOURCE_FILE_NAME`
- `BRONZE_TABLE_NAME`
- `SILVER_TABLE_NAME`
- `IDENTIFIER_COLUMN`
- `IS_FULL_LOAD`
- `LAST_PROCESSED_CHECKPOINT`

### Sales Business Key
```text
YARD,
MATERIAL_CODE,
COMMODITY_NAME,
COMMODITY_TYPE,
CUSTOMER_NAME,
SALES_ORDER_ID,
INVOICE_ID
```

### Appointment Business Key
```text
YARD_NAME,
APPOINTMENT_NUMBER,
CUSTOMER_ID,
INBOUND_TICKET_ID,
OUTBOUND_TICKET_ID,
SALES_ORDER_TICKET_ID,
PURCHASE_ORDER_TICKET_ID
```

## OBJECTS_COLUMN_MAPPING
Controls column-level transformations.

Important fields:
- `OBJECT_NAME`
- `SOURCE_COLUMN_NAME`
- `TARGET_COLUMN_NAME`
- `COLUMN_DATATYPE`
- `VALUES` for default/null handling
- `SOURCE_NAME`

Example:

| Source | Target | Datatype | Default |
|---|---|---|---|
| `Yard_Id` | `YARD_ID` | string | NULL |
| `Price` | `PRICE` | decimal(18,4) | 0 |
| `Invoice_Issue_Date` | `INVOICE_ISSUE_DATE` | date | NULL |

## EDW_CONFIG
Controls Silver-to-Gold processing.

Gold objects:

```text
DIM_APPOINTMENT_DATA
FACT_SALES
```

Correct Gold design:

```text
DIM_APPOINTMENT_DATA
- APPOINTMENT_DATA_KEY
- YARD_NAME
- SALES_ORDER_ID
- CARRIER_NAME
- ADDED_BY
- ADDED_ON
- MODIFIED_BY
- MODIFIED_ON

FACT_SALES
- SALES_KEY
- YARD_ID
- APPOINTMENT_DATA_KEY
- COMMODITY_NAME
- PRICE
- SELL_PRICE
- INVOICE_TOTAL
- ADDED_BY
- ADDED_ON
- MODIFIED_BY
- MODIFIED_ON
```

`YARD_KEY` is intentionally not used because it is not available in the Silver source design.
