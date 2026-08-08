# Gold Layer

## Objective
The Gold layer publishes business-ready Dimension and Fact tables from standardized Silver data.

## Gold Tables
```text
gold.edw.dim_appointment_data
gold.edw.fact_sales
```

# DIM_APPOINTMENT_DATA

## Source
```text
silver.logistic.appointment_data
```

## Columns
```text
APPOINTMENT_DATA_KEY
YARD_NAME
SALES_ORDER_ID
CARRIER_NAME
ADDED_BY
ADDED_ON
MODIFIED_BY
MODIFIED_ON
```

## Latest Record Rule
Keep the latest appointment row for each `YARD_NAME` using a Window specification ordered by `UPDATED_AT`.

```python
window_spec = (
    Window
    .partitionBy("YARD_NAME")
    .orderBy(col("UPDATED_AT").desc_nulls_last())
)
```

Create a surrogate key named `APPOINTMENT_DATA_KEY`.

# FACT_SALES

## Sources
```text
silver.logistic.sales_data_prior_day
gold.edw.dim_appointment_data
```

## Join
```text
Sales.YARD = Dimension.YARD_NAME
```

Use a left join so that Sales rows are preserved even when no Appointment record exists.

```python
fact_df = (
    sales.alias("s")
    .join(
        appointment_dim.alias("d"),
        col("s.YARD") == col("d.YARD_NAME"),
        "left"
    )
)
```

## Fact Columns
```text
SALES_KEY
YARD_ID
APPOINTMENT_DATA_KEY
COMMODITY_NAME
PRICE
SELL_PRICE
INVOICE_TOTAL
ADDED_BY
ADDED_ON
MODIFIED_BY
MODIFIED_ON
```

## Source-Data Join Note
The current Appointment sample contains yards `1012` and `1013`. The Sales source includes `1012` but does not contain `1013`. Therefore many Sales rows can legitimately have a NULL `APPOINTMENT_DATA_KEY`. This is a source-data coverage issue, not a PySpark join failure.

## Design Correction
`YARD_KEY` is not used because no such key exists in the Silver data model.
