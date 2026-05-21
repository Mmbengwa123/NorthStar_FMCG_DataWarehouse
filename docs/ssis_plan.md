SSIS Orchestration Plan (high level)

- Source: CSV files located on shared file share / ingestion landing zone.
- Package 1: Ingest -> Staging
  - Use `Flat File Source` for each CSV
  - `Data Conversion` for types (dates, ints, decimals)
  - `OLE DB Destination` to `NorthStar_Staging.dbo.staging.*` or via linked server
- Package 2: Dim Upsert
  - Execute SQL Task: `EXEC dw.sp_upsert_dim_sku` and `EXEC dw.sp_upsert_dim_retailer`
- Package 3: Load Facts
  - Execute SQL Task: `EXEC dw.sp_load_fact_sku_demand_daily`
- Package 4: Data Quality Checks & Alerts
  - Execute SQL Task: run `sql/quality_checks.sql` queries
  - Send Mail Task on failures
- Scheduling: Use SQL Agent job to trigger SSIS packages in order (Package1 -> Package2 -> Package3 -> Package4)

Notes:
- Use checkpointing and transaction control for idempotency.
- Externalize paths/connection strings to package/config.
- Consider incremental loads using last_load_date or change detection.
