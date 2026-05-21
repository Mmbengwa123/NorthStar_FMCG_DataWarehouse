USE NorthStar_DW;
GO
-- 1. Row counts
SELECT 'dim_sku' AS object_name, COUNT(*) AS rows FROM dw.dim_sku;
SELECT 'dim_retailer' AS object_name, COUNT(*) AS rows FROM dw.dim_retailer;
SELECT 'fact_sku_demand_daily' AS object_name, COUNT(*) AS rows FROM dw.fact_sku_demand_daily;

-- 2. Null checks on natural keys
SELECT COUNT(*) AS missing_sku
FROM dw.dim_sku
WHERE sku IS NULL OR sku = '';

SELECT COUNT(*) AS missing_retailer_id
FROM dw.dim_retailer
WHERE retailer_id IS NULL OR retailer_id = '';

-- 3. Duplicate natural keys in dims
SELECT sku, pack_type, COUNT(*) cnt FROM dw.dim_sku GROUP BY sku, pack_type HAVING COUNT(*)>1;

-- 4. Referential integrity: facts without matching dims
SELECT COUNT(*) AS orphan_facts
FROM dw.fact_sku_demand_daily f
LEFT JOIN dw.dim_sku d ON f.sku_key = d.sku_key
LEFT JOIN dw.dim_retailer r ON f.retailer_key = r.retailer_key
WHERE d.sku_key IS NULL OR r.retailer_key IS NULL;

-- 5. Business rules / anomalies
-- negative units
SELECT COUNT(*) AS negative_units FROM dw.fact_sku_demand_daily WHERE units_sold < 0;
-- price mismatch: avg_price in fact differs significantly (>50%) from dim avg_price
SELECT f.fact_key, f.avg_price AS fact_price, d.avg_price AS dim_price,
       CASE WHEN d.avg_price = 0 THEN NULL ELSE ABS(f.avg_price - d.avg_price) / d.avg_price END AS pct_diff
FROM dw.fact_sku_demand_daily f
LEFT JOIN dw.dim_sku d ON f.sku_key = d.sku_key
WHERE d.avg_price IS NOT NULL AND d.avg_price>0 AND (ABS(f.avg_price - d.avg_price) / d.avg_price) > 0.5;

-- 6. Simple data freshness check (most recent date in facts)
SELECT MAX([date]) AS max_fact_date FROM dw.fact_sku_demand_daily;
GO
