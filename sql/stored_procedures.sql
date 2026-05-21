USE NorthStar_DW;
GO
-- Upsert dim_sku from staging
IF OBJECT_ID('dw.sp_upsert_dim_sku','P') IS NOT NULL DROP PROC dw.sp_upsert_dim_sku;
GO
CREATE PROCEDURE dw.sp_upsert_dim_sku
AS
BEGIN
    SET NOCOUNT ON;
    MERGE INTO dw.dim_sku AS target
    USING (
        SELECT sku, pack_type, brand, segment, category, units_per_pack, packs_per_pallet, units_per_pallet, weight_lbs_per_pallet, requires_refrigeration, shelf_life_days, avg_price, avg_delivery_days
        FROM NorthStar_Staging..staging.stg_dim_skus
    ) AS src
    ON target.sku = src.sku AND target.pack_type = src.pack_type
    WHEN MATCHED THEN
        UPDATE SET brand = src.brand, segment = src.segment, category = src.category, units_per_pack = src.units_per_pack, packs_per_pallet = src.packs_per_pallet, units_per_pallet = src.units_per_pallet, weight_lbs_per_pallet = src.weight_lbs_per_pallet, requires_refrigeration = src.requires_refrigeration, shelf_life_days = src.shelf_life_days, avg_price = src.avg_price, avg_delivery_days = src.avg_delivery_days, load_date = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (sku, pack_type, brand, segment, category, units_per_pack, packs_per_pallet, units_per_pallet, weight_lbs_per_pallet, requires_refrigeration, shelf_life_days, avg_price, avg_delivery_days)
        VALUES (src.sku, src.pack_type, src.brand, src.segment, src.category, src.units_per_pack, src.packs_per_pallet, src.units_per_pallet, src.weight_lbs_per_pallet, src.requires_refrigeration, src.shelf_life_days, src.avg_price, src.avg_delivery_days);
END
GO

-- Upsert dim_retailer
IF OBJECT_ID('dw.sp_upsert_dim_retailer','P') IS NOT NULL DROP PROC dw.sp_upsert_dim_retailer;
GO
CREATE PROCEDURE dw.sp_upsert_dim_retailer
AS
BEGIN
    SET NOCOUNT ON;
    MERGE INTO dw.dim_retailer AS target
    USING (
        SELECT retailer_id, customer_id, customer_name, us_region, channel, n_stores, contract_start_date, annual_revenue_potential, account_status
        FROM NorthStar_Staging..staging.stg_dim_retailers
    ) AS src
    ON target.retailer_id = src.retailer_id
    WHEN MATCHED THEN
        UPDATE SET customer_id = src.customer_id, customer_name = src.customer_name, us_region = src.us_region, channel = src.channel, n_stores = src.n_stores, contract_start_date = src.contract_start_date, annual_revenue_potential = src.annual_revenue_potential, account_status = src.account_status, load_date = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (retailer_id, customer_id, customer_name, us_region, channel, n_stores, contract_start_date, annual_revenue_potential, account_status)
        VALUES (src.retailer_id, src.customer_id, src.customer_name, src.us_region, src.channel, src.n_stores, src.contract_start_date, src.annual_revenue_potential, src.account_status);
END
GO

-- Load facts from staging into fact table (lookup dim keys)
IF OBJECT_ID('dw.sp_load_fact_sku_demand_daily','P') IS NOT NULL DROP PROC dw.sp_load_fact_sku_demand_daily;
GO
CREATE PROCEDURE dw.sp_load_fact_sku_demand_daily
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dw.fact_sku_demand_daily ([date], sku_key, retailer_key, units_sold, delivered_qty, pallets_shipped, weight_lbs_shipped, stock_available, avg_price, revenue, promotion_flag, avg_delivery_days)
    SELECT
        s.[date],
        d.sku_key,
        r.retailer_key,
        s.units_sold,
        s.delivered_qty,
        s.pallets_shipped,
        s.weight_lbs_shipped,
        s.stock_available,
        s.avg_price,
        s.revenue,
        s.promotion_flag,
        s.avg_delivery_days
    FROM NorthStar_Staging..staging.stg_fact_sku_demand_daily s
    LEFT JOIN dw.dim_sku d ON d.sku = s.sku AND d.pack_type = s.pack_type
    LEFT JOIN dw.dim_retailer r ON r.retailer_id = s.retailer_id
    WHERE d.sku_key IS NOT NULL AND r.retailer_key IS NOT NULL;
END
GO
