# Power BI Dashboard Guide

![Project](https://img.shields.io/badge/Project-End-to-End%20Data%20Warehouse-blue?style=for-the-badge)
![Power BI](https://img.shields.io/badge/Power%20BI-visualization-yellow?style=for-the-badge&logo=power-bi)
![Mermaid](https://img.shields.io/badge/Mermaid-diagrams-pink?style=for-the-badge&logo=mermaid)
![CSV](https://img.shields.io/badge/Data-CSV-green?style=for-the-badge)

## Overview

This dashboard guide describes the recommended reporting layer for the NorthStar FMCG supply chain warehouse.
Use the `dw.dim_*` and `dw.fact_*` model to build analytical visuals for sales performance, inventory, and customer segmentation.

## Recommended visuals

- **Time series line charts** for daily SKU demand and revenue trends
- **Clustered bar charts** for region / channel comparisons
- **Matrix tables** for retailer-level performance and SKU aggregates
- **Card visuals** for KPI metrics like total units, revenue, and average price
- **Slicer filters** for date range, region, retailer, brand, and pack type

## Data model

Connect Power BI to the `NorthStar_DW` database and import the following tables:

- `dw.dim_sku`
- `dw.dim_retailer`
- `dw.fact_sku_demand_daily`

Then create relationships on the natural keys and date fields to support cross-filtering.

## Useful reference

- DAX formulas and measure examples: `dashboard/DAX_FORMULAS_LIBRARY.txt`
- ETL and warehouse design: `README.md`
- Data quality validation: `sql/quality_checks.sql`

## Best practices

- Use star schema relationships rather than importing the source CSVs directly
- Apply consistent date hierarchies and locale settings
- Avoid many-to-many joins by modeling SKU and retailer dimensions cleanly
- Use incremental refresh if your dataset grows beyond a few million rows
