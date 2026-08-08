# Silver Layer

## Objective
The Silver layer converts Bronze data into clean, standardized, typed, deduplicated, and incrementally maintainable datasets.

## Output Tables
```text
silver.logistic.sales_data_prior_day
silver.logistic.appointment_data
```

## Transformation Flow
```text
Bronze
  ↓
Column Mapping
  ↓
NULL Handling
  ↓
Datatype Casting
  ↓
Date Parsing
  ↓
Duplicate Removal
  ↓
Audit Columns
  ↓
Full Load / Delta MERGE
  ↓
Silver
```

## 1. Metadata-Driven Rename
Use `metadata.OBJECTS_COLUMN_MAPPING` to map source to target column names.

Example:

```text
Price → PRICE
Sell_Price → SELL_PRICE
Customer_Name → CUSTOMER_NAME
```

## 2. Null Handling
Apply configured defaults where required.

Example:

```python
df = df.withColumn("PRICE", coalesce(col("PRICE"), lit(0)))
```

Important implementation rule: transformation functions must return the DataFrame and be assigned back.

Correct:

```python
df = handle_nulls(df, mapping_df, object_name)
df = data_type_casting(df, mapping_df, object_name)
```

## 3. Datatype Casting
Examples:

```text
PRICE               → decimal(18,4)
SELL_PRICE          → decimal(18,4)
INVOICE_TOTAL       → decimal(18,4)
APPOINTMENT_NUMBER  → decimal(18,0)
```

## 4. Date Parsing
The project source contains more than one date format. Dates should be parsed explicitly instead of relying only on `cast("date")`.

Example patterns:

```text
M/d/yyyy
d-M-yyyy
yyyy-MM-dd...
```

## 5. Duplicate Removal
Sales business key:

```text
YARD,MATERIAL_CODE,COMMODITY_NAME,COMMODITY_TYPE,CUSTOMER_NAME,SALES_ORDER_ID,INVOICE_ID
```

Appointment business key:

```text
YARD_NAME,APPOINTMENT_NUMBER,CUSTOMER_ID,INBOUND_TICKET_ID,OUTBOUND_TICKET_ID,SALES_ORDER_TICKET_ID,PURCHASE_ORDER_TICKET_ID
```

Example:

```python
df = df.dropDuplicates(key_columns)
```

## 6. Incremental MERGE
First load:

```text
IS_FULL_LOAD = 1
```

Incremental load:

```text
IS_FULL_LOAD = 0
```

Use Delta MERGE for UPSERT behavior.

For nullable business-key columns, use Spark null-safe equality:

```text
<=>
```

instead of ordinary equality only.
