# Power BI Dashboard Design - NorthStar FMCG Supply Chain

## Executive Summary

This document provides a complete Power BI dashboard specification for the NorthStar FMCG Supply Chain Data Warehouse. It includes data model setup, DAX measures, visualizations, and step-by-step build instructions.

**Target Audience**: Supply Chain Managers, Executives, BI Analysts
**Refresh Frequency**: Daily (post-ETL execution)
**Report Pages**: 5 (Overview, SKU Performance, Regional Analysis, Channel Breakdown, Data Quality)

---

## Part 1: Data Model Setup

### Step 1: Connect to Data Source

1. Open **Power BI Desktop**
2. Select **Get Data → SQL Server**
3. Enter server and database:
   - Server: `Your_SQL_Server_Name`
   - Database: `NorthStar_DW`
4. Use **DirectQuery** (recommended for large datasets) or **Import** (faster for smaller datasets)
5. Navigate to `dw.dim_sku`, `dw.dim_retailer`, `dw.fact_sku_demand_daily`

### Step 2: Import Tables

Load three tables:

| Table | Purpose | Rows |
|-------|---------|------|
| `dw.dim_sku` | SKU attributes (brand, category, price) | ~150 |
| `dw.dim_retailer` | Customer/retailer attributes | ~100 |
| `dw.fact_sku_demand_daily` | Daily sales transactions | ~1M+ |

### Step 3: Configure Data Model Relationships

In **Model View**:

1. **Fact → Dim_SKU**: Drag `sku_key` from fact table to `sku_key` in dim_sku
   - Cardinality: Many-to-one
   - Cross filter: Single direction (from dim to fact)

2. **Fact → Dim_Retailer**: Drag `retailer_key` from fact to `retailer_key` in dim_retailer
   - Cardinality: Many-to-one
   - Cross filter: Single direction (from dim to fact)

3. Verify no circular dependencies

### Step 4: Set Column Data Types

| Table | Column | Type | Format |
|-------|--------|------|--------|
| dim_sku | avg_price | Decimal | Currency ($) |
| dim_sku | shelf_life_days | Whole Number | - |
| dim_retailer | annual_revenue_potential | Currency | Currency ($) |
| dim_retailer | n_stores | Whole Number | - |
| fact_sku_demand_daily | date | Date/Time | Date |
| fact_sku_demand_daily | revenue | Currency | Currency ($) |
| fact_sku_demand_daily | units_sold | Whole Number | - |

---

## Part 2: DAX Measures & KPIs

Create all measures in the **fact_sku_demand_daily** table (or dedicated Measures table).

### Basic Aggregates

```dax
-- Total Revenue (This Year)
TotalRevenue = SUMX(
    'fact_sku_demand_daily',
    'fact_sku_demand_daily'[revenue]
)

-- Total Units Sold
TotalUnitsSold = SUM('fact_sku_demand_daily'[units_sold])

-- Average Daily Revenue
AvgDailyRevenue = AVERAGEX(
    VALUES('fact_sku_demand_daily'[date]),
    CALCULATE(SUM('fact_sku_demand_daily'[revenue]))
)

-- Number of Transactions
TransactionCount = COUNTA('fact_sku_demand_daily'[fact_key])

-- Number of Unique Days
UniqueDays = DISTINCTCOUNT('fact_sku_demand_daily'[date])
```

### Advanced KPIs

```dax
-- Revenue per SKU
RevenuePerSKU = DIVIDE(
    SUM('fact_sku_demand_daily'[revenue]),
    DISTINCTCOUNT('fact_sku_demand_daily'[sku_key]),
    0
)

-- Average Units per Transaction
AvgUnitsPerTransaction = DIVIDE(
    SUM('fact_sku_demand_daily'[units_sold]),
    COUNTA('fact_sku_demand_daily'[fact_key]),
    0
)

-- Promotion Impact (% sales from promotions)
PromotionSalesPercent = DIVIDE(
    CALCULATE(
        SUM('fact_sku_demand_daily'[revenue]),
        'fact_sku_demand_daily'[promotion_flag] = 1
    ),
    SUM('fact_sku_demand_daily'[revenue]),
    0
) * 100

-- Stock Availability Rate
AvgStockAvailability = AVERAGE('fact_sku_demand_daily'[stock_available])

-- Fulfillment Rate
FulfillmentRate = DIVIDE(
    SUM('fact_sku_demand_daily'[delivered_qty]),
    SUM('fact_sku_demand_daily'[delivered_qty]) + SUM('fact_sku_demand_daily'[units_sold]),
    0
) * 100

-- Average Delivery Days
AvgDeliveryDays = AVERAGE('fact_sku_demand_daily'[avg_delivery_days])
```

### Trend & Growth Measures

```dax
-- Revenue Growth vs Previous Month
RevenueGrowthPctMoM = DIVIDE(
    SUM('fact_sku_demand_daily'[revenue]) -
    CALCULATE(
        SUM('fact_sku_demand_daily'[revenue]),
        DATEADD('fact_sku_demand_daily'[date], -1, MONTH)
    ),
    CALCULATE(
        SUM('fact_sku_demand_daily'[revenue]),
        DATEADD('fact_sku_demand_daily'[date], -1, MONTH)
    ),
    0
) * 100

-- Top 10 SKUs by Revenue
TopSkusByRevenue = RANKX(
    ALL('dim_sku'),
    CALCULATE(SUM('fact_sku_demand_daily'[revenue])),
    ,
    DESC
)

-- Revenue by Category
RevenueByCat = SUMX(
    VALUES('dim_sku'[category]),
    CALCULATE(SUM('fact_sku_demand_daily'[revenue]))
)
```

### Anomaly Detection (Data Quality)

```dax
-- Negative Units Flag
HasNegativeUnits = COUNTX(
    FILTER('fact_sku_demand_daily', 'fact_sku_demand_daily'[units_sold] < 0),
    [fact_key]
)

-- Zero Stock Days
ZeroStockDays = COUNTX(
    FILTER('fact_sku_demand_daily', 'fact_sku_demand_daily'[stock_available] = 0),
    [fact_key]
)

-- High Delivery Days (>5 days)
HighDeliveryDayCount = COUNTX(
    FILTER('fact_sku_demand_daily', 'fact_sku_demand_daily'[avg_delivery_days] > 5),
    [fact_key]
)
```

---

## Part 3: Report Pages & Visuals

### Page 1: Executive Overview

**Layout**: 2x3 grid with KPI cards and trend charts

| Visual | Type | Fields | Notes |
|--------|------|--------|-------|
| **1. Total Revenue (Today)** | Card | TotalRevenue | Use conditional formatting (green if > threshold) |
| **2. Total Units Sold** | Card | TotalUnitsSold | - |
| **3. Active SKUs** | Card | DISTINCTCOUNT(sku_key) | - |
| **4. Revenue Trend** | Line/Area Chart | Date (X), TotalRevenue (Y) | Last 30 days |
| **5. Top 5 SKUs by Revenue** | Bar Chart | Category/SKU (Y), TotalRevenue (X) | Descending |
| **6. Revenue by Channel** | Pie Chart | Channel, TotalRevenue | Donut chart |

**Slicers**: Date range, Region, Channel

---

### Page 2: SKU Performance

**Layout**: Focused on product-level analytics

| Visual | Type | Fields | Notes |
|--------|------|--------|-------|
| **1. SKU Revenue Matrix** | Matrix | Category (Rows), Pack Type (Columns), Revenue | Conditional formatting heatmap |
| **2. Units Sold vs Revenue** | Scatter | Units Sold (X), Revenue (Y), size=Avg Price | Bubble chart |
| **3. Top Performers** | Table | SKU, Brand, Segment, Revenue, Units Sold, Avg Price | Sortable |
| **4. Price vs Demand** | Line Chart | Avg Price (X), Units Sold (Y) by SKU | Identify price elasticity |
| **5. Shelf Life Impact** | Clustered Bar | Shelf Life Days (Axis), Revenue (Value) | Compare long vs short shelf life |
| **6. Promotion Effectiveness** | Bar | SKU (Axis), Revenue (with/without promo) | Side-by-side comparison |

**Slicers**: Category, Brand, Pack Type, Promotion Flag

---

### Page 3: Regional & Channel Analysis

**Layout**: Geographic and channel breakdowns

| Visual | Type | Fields | Notes |
|--------|------|--------|-------|
| **1. Revenue by Region** | Map | Region (Location), Revenue (Size/Color) | Filled map or bubble map |
| **2. Regional Trends** | Multi-line Chart | Date (X), Revenue (Y), Line per Region | Last 60 days |
| **3. Channel Distribution** | Column Chart | Channel (X), Units Sold & Revenue (Y) | Dual axis |
| **4. Store Count vs Revenue** | Scatter | N_Stores (X), Revenue (Y), Retailer (Detail) | - |
| **5. Account Status** | Pie/Donut | Account Status, Count of Retailers | Active vs Inactive |
| **6. Top Retailers** | Table | Customer Name, Region, Channel, Revenue, Account Status | Sortable |

**Slicers**: Region, Channel, Account Status

---

### Page 4: Supply Chain Metrics

**Layout**: Logistics and inventory focus

| Visual | Type | Fields | Notes |
|--------|------|--------|-------|
| **1. Avg Delivery Days (KPI)** | Card + Gauge | AvgDeliveryDays | Target: < 3 days |
| **2. Fulfillment Rate (KPI)** | Card + Gauge | FulfillmentRate | Target: > 95% |
| **3. Stock Availability** | Card | AvgStockAvailability | Current stock level |
| **4. Pallets Shipped Trend** | Area Chart | Date (X), Sum(Pallets Shipped) (Y) | Volume over time |
| **5. Delivery Performance** | Histogram | Avg_Delivery_Days (X), Count (Y) | Distribution |
| **6. Stock Levels by Category** | Stacked Bar | Category (X), Stock Available (Y by Pack Type) | - |

**Slicers**: SKU, Region, Date Range

---

### Page 5: Data Quality Dashboard

**Layout**: Monitoring for ETL health and data anomalies

| Visual | Type | Fields | Notes |
|--------|------|--------|-------|
| **1. Last Load Time** | Card | Max(load_date) | Formatted as time-ago |
| **2. Row Counts** | Table | Dim_SKU, Dim_Retailer, Fact rows | Verify no zeroes |
| **3. Negative Units Alert** | Card | HasNegativeUnits | Red if > 0 |
| **4. Zero Stock Days** | Card | ZeroStockDays | Warning indicator |
| **5. High Delivery Days Alert** | Card | HighDeliveryDayCount | Out-of-SLA indicator |
| **6. Data Completeness** | Column Chart | Table name (X), % Non-Null (Y) | Identify missing data |

**Slicers**: None (read-only monitoring)

---

## Part 4: SQL Queries for Power BI

These queries can be used as DirectQuery sources or imported tables.

### Query 1: Sales Summary by SKU

```sql
SELECT 
    d.sku,
    d.pack_type,
    d.brand,
    d.category,
    COUNT(DISTINCT f.date) AS trading_days,
    SUM(f.units_sold) AS total_units,
    SUM(f.revenue) AS total_revenue,
    AVG(f.avg_price) AS avg_price_per_unit,
    SUM(f.delivered_qty) AS total_delivered,
    AVG(f.stock_available) AS avg_stock
FROM dw.fact_sku_demand_daily f
JOIN dw.dim_sku d ON f.sku_key = d.sku_key
GROUP BY d.sku, d.pack_type, d.brand, d.category
ORDER BY total_revenue DESC;
```

### Query 2: Regional Performance

```sql
SELECT 
    r.us_region,
    r.channel,
    COUNT(DISTINCT r.retailer_id) AS retailer_count,
    SUM(f.units_sold) AS total_units,
    SUM(f.revenue) AS total_revenue,
    AVG(f.avg_delivery_days) AS avg_delivery_days,
    SUM(CASE WHEN f.promotion_flag = 1 THEN f.revenue ELSE 0 END) AS promo_revenue,
    COUNT(DISTINCT f.date) AS trading_days
FROM dw.fact_sku_demand_daily f
JOIN dw.dim_retailer r ON f.retailer_key = r.retailer_key
GROUP BY r.us_region, r.channel
ORDER BY total_revenue DESC;
```

### Query 3: Category Trends (Last 30 Days)

```sql
SELECT 
    f.date,
    d.category,
    SUM(f.units_sold) AS units,
    SUM(f.revenue) AS revenue,
    COUNT(DISTINCT d.sku) AS sku_count
FROM dw.fact_sku_demand_daily f
JOIN dw.dim_sku d ON f.sku_key = d.sku_key
WHERE f.date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
GROUP BY f.date, d.category
ORDER BY f.date, d.category;
```

---

## Part 5: Step-by-Step Build Instructions

### Prerequisites

- Power BI Desktop (latest version)
- SQL Server connection configured
- NorthStar_DW database populated and running

### Build Steps

#### Step 1: Create New Report

1. Open **Power BI Desktop**
2. **File → New**
3. **Get Data → SQL Server**
4. Server: `your_server`
5. Database: `NorthStar_DW`
6. Select `dw.dim_sku`, `dw.dim_retailer`, `dw.fact_sku_demand_daily`
7. Click **Load**

#### Step 2: Configure Data Model

1. Switch to **Model View** (left sidebar)
2. Verify relationships are auto-detected
3. If not, manually create relationships:
   - Fact `sku_key` → Dim_SKU `sku_key`
   - Fact `retailer_key` → Dim_Retailer `retailer_key`
4. Switch back to **Report View**

#### Step 3: Create Measures

1. Right-click on **fact_sku_demand_daily** table → **New Measure**
2. Copy-paste each DAX formula from **Part 2**
3. Verify syntax (no red squiggles)
4. Test by dragging measures to cards

Example:
```dax
TotalRevenue = SUMX('fact_sku_demand_daily', 'fact_sku_demand_daily'[revenue])
```

#### Step 4: Build Page 1 - Overview

1. Right-click blank area → **Insert Page** (name: "Overview")
2. Add KPI Cards (top row):
   - Card 1: Drag **TotalRevenue** measure
   - Card 2: Drag **TotalUnitsSold** measure
   - Card 3: Drag **UniqueDays** measure (or DISTINCTCOUNT(sku_key))
3. Format cards:
   - Right-click → **Format visual**
   - Set data labels, font size, colors
4. Add visuals (middle/bottom rows):
   - Line Chart: `date` (X) vs `TotalRevenue` (Y)
   - Bar Chart: Top 5 SKUs by revenue
   - Pie Chart: Revenue by channel

#### Step 5: Add Slicers to Page 1

1. **Insert → Slicer**
2. Date Range: Drag `date` field
3. Region: Drag `us_region` field
4. Channel: Drag `channel` field
5. Format slicers (colors, fonts)

#### Step 6: Build Pages 2-5

Repeat Step 4 for each page, following the visual specs in **Part 3**.

#### Step 7: Formatting & Branding

1. **View → Themes** (select corporate theme or create custom)
2. **Insert → Image** (add logo/banner)
3. Consistent colors:
   - Primary: Company color
   - KPI Good: Green
   - KPI Warning: Yellow
   - KPI Bad: Red
4. Set page background colors

#### Step 8: Publish to Power BI Service

1. **File → Publish**
2. Select workspace (create "NorthStar Supply Chain" workspace)
3. Set refresh schedule: Daily at 3 AM (post-ETL)
4. Share with stakeholders: Users → Add

---

## Part 6: Interactivity & Best Practices

### Enable Cross-Filtering

- Click a bar in "Revenue by Channel" → all other visuals filter
- Use **Ctrl+Click** to select multiple values in slicers
- Drill-down: Double-click bars to see detail

### Conditional Formatting

- KPI Cards: Green (above 90% of history), Yellow (70-90%), Red (<70%)
- Tables: Heat map on Revenue and Units columns

### Performance Optimization

- Use **aggregations** on fact table (summarize by date, category, region)
- Set query folding in Power Query
- Use **DirectQuery** for real-time data or **Import** for speed
- Archive old data (>2 years) to separate table

### Mobile-Friendly Design

- Create **mobile layout**: 1 visual per screen
- Use **Bookmarks** for drill-down navigation
- Large buttons and slicers for touch

---

## Part 7: Sample KPI Targets

Set these as guidelines for alerts:

| KPI | Target | Warning | Critical |
|-----|--------|---------|----------|
| Daily Revenue | Baseline + 5% | -5% | -10% |
| Units Sold | Baseline | -10% | -20% |
| Avg Delivery Days | < 3 days | 4-5 days | > 5 days |
| Fulfillment Rate | > 95% | 90-95% | < 90% |
| Stock Availability | > 80 units | 50-80 | < 50 |
| Promotion Revenue % | 20-30% | 15-20% | < 15% |

---

## Part 8: Troubleshooting

### Report Shows No Data

- ✓ Verify SQL Server connection (Get Data → recent connections)
- ✓ Check relationships in Model view
- ✓ Run DAX queries in DAX Studio to debug

### Slow Performance

- ✓ Use **Analyze in Excel** to check row count
- ✓ Add aggregations: Data → Aggregations
- ✓ Switch to Import mode if DirectQuery is slow
- ✓ Archive fact table data older than 1 year

### Refresh Fails

- ✓ Check credentials: **File → Options → Data Source Settings**
- ✓ Verify Power BI Gateway is running (if on-premises)
- ✓ Check SQL Server Agent ETL job status

---

## Part 9: Advanced Features (Optional)

### R/Python Visualizations

```python
# Example: Anomaly detection in Python
import pandas as pd
from sklearn.ensemble import IsolationForest

# Detect anomalies in revenue
clf = IsolationForest(random_state=0)
anomalies = clf.fit_predict(revenue_data)
```

### Q&A (Natural Language Queries)

Enable in **File → Options → Preview Features → Q&A**

Users can ask: "What is revenue by region?"

### AI Visuals

- **Decomposition Tree**: Drill down into drivers of revenue decline
- **Key Influencers**: What factors drive high sales?

---

## Delivery Checklist

- [ ] Data model created with relationships
- [ ] All DAX measures defined
- [ ] Page 1 (Overview) complete with KPI cards
- [ ] Page 2 (SKU Performance) complete
- [ ] Page 3 (Regional Analysis) complete
- [ ] Page 4 (Supply Chain) complete
- [ ] Page 5 (Data Quality) complete
- [ ] Slicers added and tested
- [ ] Conditional formatting applied
- [ ] Report published to Power BI Service
- [ ] Refresh schedule configured
- [ ] Users trained on dashboard
- [ ] Bookmarks/drill-down navigation added

---

**Last Updated**: May 21, 2026
**Version**: 1.0
**Next Review**: Monthly (after 30 days of production use)
