# NorthStar FMCG Supply Chain

![Project](https://img.shields.io/badge/Project-End-to-End%20Data%20Warehouse-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Proof%20of%20Concept-brightgreen?style=for-the-badge)
![Domain](https://img.shields.io/badge/Domain-FMCG%20Supply%20Chain-orange?style=for-the-badge)

---

##  Overview

NorthStar is an end-to-end FMCG supply chain data warehouse proof of concept. It ingests CSV data, loads a staging layer, builds a star schema, applies ETL logic, validates quality, and prepares data for Power BI reporting.

##  What this repo includes

| Artifact | Purpose | Location |
|---|---|---|
| SQL DDL | Create databases, schemas, staging, dims, and facts | `sql/create_databases_and_schemas.sql` |
| Staging tables | Bronze ingest layer | `sql/create_staging_tables.sql` |
| Dim/Fact model | Star schema data warehouse | `sql/create_dim_fact_tables.sql` |
| ETL procedures | MERGE/upsert and load logic | `sql/stored_procedures.sql` |
| Data quality checks | Validation rules and integrity checks | `sql/quality_checks.sql` |
| Star schema ER | Logical dimensional model | `diagrams/dim_schema.mmd` |
| Medallion architecture | Raw → Bronze → Silver → Gold | `diagrams/medallion_architecture.mmd` |
| Orchestration plan | SSIS / SQL Agent workflow design | `docs/ssis_plan.md` |
| Dashboard guide | Power BI modeling and report guidance | `dashboard/README.md` |

---

## 🧩 Tools used

<p>
  <img src="https://img.shields.io/badge/SQL%20Server-4479A1?style=for-the-badge&logo=microsoft-sql-server" alt="SQL Server" />
  <img src="https://img.shields.io/badge/SSIS-FF6A00?style=for-the-badge&logo=microsoft-sql-server" alt="SSIS" />
  <img src="https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=power-bi" alt="Power BI" />
  <img src="https://img.shields.io/badge/Mermaid-FF6F61?style=for-the-badge&logo=mermaid" alt="Mermaid" />
  <img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github" alt="GitHub" />
  <img src="https://img.shields.io/badge/CSV-34A853?style=for-the-badge&logo=apache%20airflow" alt="CSV" />
</p>

- **SQL Server / SSMS**: database objects, stored procedures, scheduled jobs, and data validation.
- **SSIS**: ETL orchestration and staged file ingestion from CSV sources.
- **Power BI**: report-ready data model and dashboard guidance.
- **Mermaid**: architecture and schema diagrams in `diagrams/*.mmd`.
- **CSV**: source data inputs for dimensions and facts.

---

## 🏗 Architecture

### High-level flow

1. **Landing**: Source CSV files arrive in a secure landing area.
2. **Bronze / Staging**: Raw CSV data loads into staging tables.
3. **Silver / Normalization**: Dimension and fact tables are built with MERGE/upsert logic.
4. **Gold / BI**: Cleaned facts and dims support Power BI analytics.
5. **Operationalization**: SSIS packages and SQL Agent jobs automate the workflow.

### Star schema

- `dw.fact_sku_demand_daily` — fact table at the SKU × retailer × date grain
- `dw.dim_sku` — product attributes, pricing, packaging, and shelf life
- `dw.dim_retailer` — retailer/customer attributes, region, and channel

---

##  Key improvements

- Solved duplicate SKU issues by using a composite natural key: `sku + pack_type`.
- Normalized inconsistent source values during staging.
- Added data quality checks for missing keys, duplicates, orphan facts, and price mismatches.
- Built a reusable ETL process for DIM/FCT load paths.

---

## ⚡ Quick start

```sql
-- Create databases and schemas
:r .\sql\create_databases_and_schemas.sql

-- Build staging, dimensions, and facts
:r .\sql\create_staging_tables.sql
:r .\sql\create_dim_fact_tables.sql

-- Load ETL logic
USE NorthStar_DW;
EXEC dw.sp_upsert_dim_sku;
EXEC dw.sp_upsert_dim_retailer;
EXEC dw.sp_load_fact_sku_demand_daily;

-- Run data quality checks
:r .\sql\quality_checks.sql
```

<<<<<<< HEAD
Contact / Ownership
- Author: Junior Data Engineering_Mpho Mmbengwa
=======
> After setup, connect Power BI to `NorthStar_DW` and model `dw.dim_*` and `dw.fact_*` for fast visual analytics.

---

##  Recommended next steps

- Automate CSV ingestion with SSIS or Azure Data Factory.
- Schedule SSIS and quality checks with SQL Agent.
- Add incremental load logic to avoid full reloads.
- Build a Power BI report and publish to the Power BI Service.
- Monitor ETL health with row counts, error alerts, and performance checks.

---

## 📁 Helpful links

- `sql/create_databases_and_schemas.sql`
- `sql/create_staging_tables.sql`
- `sql/create_dim_fact_tables.sql`
- `sql/stored_procedures.sql`
- `sql/quality_checks.sql`
- `docs/ssis_plan.md`
- `dashboard/README.md`
- `diagrams/dim_schema.mmd`
- `diagrams/medallion_architecture.mmd`
>>>>>>> 5fc0f46 (Update repository docs with colorful badges and polished README/SSIS/dashboard guides)

