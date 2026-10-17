-- BQ1 Rental Trends: how did new-bond rents change over time?
-- Reads the marts built by sql/05. Each '-- name:' block is exported to reports/analysis/<name>.csv

-- name: bq1_period_change
-- Headline: P1 vs P2 median by geography, with P40/P60 as extra distribution information
SELECT geography, n_p1, n_p2, median_p1, median_p2,
       ROUND(median_change_pct, 2) AS median_change_pct,
       ROUND(p40_change_pct, 2)    AS p40_change_pct,
       ROUND(p60_change_pct, 2)    AS p60_change_pct
FROM mart_region_change
WHERE dwelling_type = 'All' AND bedroom_band = 'All'
ORDER BY geography;

-- name: bq1_monthly_trend
-- Monthly median and P25/P75 per geography, including the base month Aug 2024
SELECT geography, month_start, valid_sample_size, p25, median_rent, p75
FROM mart_region_monthly
ORDER BY geography, month_start;

-- name: bq1_yoy
-- Year-on-year change: only the 13 months (Aug 2025 - Aug 2026) that have a same-month base
SELECT geography, month_start, median_last_year, median_rent, ROUND(yoy_pct, 2) AS yoy_pct
FROM mart_region_yoy
ORDER BY geography, month_start;

-- name: bq1_seasonality
-- Is there a summer peak? Compare Jan-Feb with the other months of the same 12-month period
SELECT m.geography, d.period,
       MEDIAN(CASE WHEN d.month_no IN (1, 2) THEN m.median_rent END)     AS median_of_jan_feb_months,
       MEDIAN(CASE WHEN d.month_no NOT IN (1, 2) THEN m.median_rent END) AS median_of_other_months
FROM mart_region_monthly AS m
JOIN dim_date AS d ON d.month_start = m.month_start
WHERE d.period IN ('P1', 'P2')
GROUP BY m.geography, d.period
ORDER BY m.geography, d.period;
