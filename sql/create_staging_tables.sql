USE NorthStar_Staging;
GO
-- Staging table for SKUs (raw import of CSV)
IF OBJECT_ID('staging.stg_dim_skus','U') IS NOT NULL DROP TABLE staging.stg_dim_skus;
CREATE TABLE staging.stg_dim_skus (
    sku varchar(50),
    brand varchar(200),
    segment varchar(200),
    category varchar(200),
    pack_type varchar(100),
    avg_price decimal(18,6),
    avg_delivery_days decimal(8,3),
    units_per_pack int,
    packs_per_pallet int,
    units_per_pallet int,
    weight_lbs_per_pallet int,
    requires_refrigeration bit,
    shelf_life_days int
);
GO

-- Staging table for Retailers
IF OBJECT_ID('staging.stg_dim_retailers','U') IS NOT NULL DROP TABLE staging.stg_dim_retailers;
CREATE TABLE staging.stg_dim_retailers (
    retailer_id varchar(50),
    customer_id varchar(50),
    customer_name varchar(300),
    us_region varchar(100),
    channel varchar(100),
    n_stores int,
    contract_start_date date,
    annual_revenue_potential decimal(18,2),
    account_status varchar(50)
);
GO

-- Staging table for daily demand facts
IF OBJECT_ID('staging.stg_fact_sku_demand_daily','U') IS NOT NULL DROP TABLE staging.stg_fact_sku_demand_daily;
CREATE TABLE staging.stg_fact_sku_demand_daily (
    [date] date,
    sku varchar(50),
    pack_type varchar(100),
    retailer_id varchar(50),
    us_region varchar(100),
    channel varchar(100),
    units_sold int,
    delivered_qty int,
    pallets_shipped int,
    weight_lbs_shipped decimal(18,2),
    stock_available int,
    avg_price decimal(18,6),
    revenue decimal(18,4),
    promotion_flag bit,
    avg_delivery_days decimal(8,3)
);
GO
