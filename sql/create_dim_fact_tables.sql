USE NorthStar_DW;
GO
-- Dimension tables (ODS / DW layer)
IF OBJECT_ID('dw.dim_sku','U') IS NOT NULL DROP TABLE dw.dim_sku;
CREATE TABLE dw.dim_sku (
    sku_key INT IDENTITY(1,1) PRIMARY KEY,
    sku varchar(50) NOT NULL,
    pack_type varchar(100) NOT NULL,
    brand varchar(200),
    segment varchar(200),
    category varchar(200),
    units_per_pack int,
    packs_per_pallet int,
    units_per_pallet int,
    weight_lbs_per_pallet int,
    requires_refrigeration bit,
    shelf_life_days int,
    avg_price decimal(18,6),
    avg_delivery_days decimal(8,3),
    load_date datetime DEFAULT GETDATE(),
    CONSTRAINT ux_dim_sku_natural UNIQUE (sku,pack_type)
);
GO

IF OBJECT_ID('dw.dim_retailer','U') IS NOT NULL DROP TABLE dw.dim_retailer;
CREATE TABLE dw.dim_retailer (
    retailer_key INT IDENTITY(1,1) PRIMARY KEY,
    retailer_id varchar(50) NOT NULL UNIQUE,
    customer_id varchar(50),
    customer_name varchar(300),
    us_region varchar(100),
    channel varchar(100),
    n_stores int,
    contract_start_date date,
    annual_revenue_potential decimal(18,2),
    account_status varchar(50),
    load_date datetime DEFAULT GETDATE()
);
GO

-- Fact table: daily demand
IF OBJECT_ID('dw.fact_sku_demand_daily','U') IS NOT NULL DROP TABLE dw.fact_sku_demand_daily;
CREATE TABLE dw.fact_sku_demand_daily (
    fact_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    [date] date NOT NULL,
    sku_key int NOT NULL,
    retailer_key int NOT NULL,
    units_sold int,
    delivered_qty int,
    pallets_shipped int,
    weight_lbs_shipped decimal(18,2),
    stock_available int,
    avg_price decimal(18,6),
    revenue decimal(18,4),
    promotion_flag bit,
    avg_delivery_days decimal(8,3),
    load_date datetime DEFAULT GETDATE(),
    CONSTRAINT fk_fact_sku FOREIGN KEY (sku_key) REFERENCES dw.dim_sku(sku_key),
    CONSTRAINT fk_fact_retailer FOREIGN KEY (retailer_key) REFERENCES dw.dim_retailer(retailer_key)
);
GO
