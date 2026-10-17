-- 05 Regional KPIs (BQ1, BQ2, BQ7).
-- Every median / percentile is computed from individual lodgements (never a median of medians).
-- Geography levels: 'NSW' (all postcodes, incl. Mixed/Unmapped) + 'Greater Sydney' + 'Rest of NSW'.
-- Mixed (4 postcodes) and Unmapped (6 postcodes) count towards NSW only, never towards a region.

-- Step 1: stack the rows once per geography level they belong to.
--         Each lodgement appears as 'NSW', and again under its region if it has one.
CREATE OR REPLACE VIEW v_geo_lodgements AS
SELECT 'NSW' AS geography, * FROM fct_lodgements
UNION ALL
SELECT region AS geography, * FROM fct_lodgements
WHERE region IN ('Greater Sydney', 'Rest of NSW');

-- Step 2: period KPIs by geography x segment (core sample only).
-- GROUPING SETS = three GROUP BYs in one pass: all dwellings, by dwelling type, by type x bedrooms.
CREATE OR REPLACE TABLE mart_region_segment AS
SELECT
    geography,
    period,
    COALESCE(dwelling_type, 'All')                  AS dwelling_type,
    COALESCE(bedroom_band, 'All')                   AS bedroom_band,
    COUNT(*)                                        AS n,
    QUANTILE_CONT(weekly_rent, 0.25)                AS p25,
    QUANTILE_CONT(weekly_rent, 0.40)                AS p40,
    MEDIAN(weekly_rent)                             AS median_rent,
    QUANTILE_CONT(weekly_rent, 0.60)                AS p60,
    QUANTILE_CONT(weekly_rent, 0.75)                AS p75
FROM v_geo_lodgements
WHERE is_core_sample
  AND period IN ('P1', 'P2')
GROUP BY GROUPING SETS (
    (geography, period),
    (geography, period, dwelling_type),
    (geography, period, dwelling_type, bedroom_band)
);

-- Step 3: P1 -> P2 change, one row per geography x segment (P1 and P2 side by side via JOIN)
CREATE OR REPLACE TABLE mart_region_change AS
SELECT
    p1.geography,
    p1.dwelling_type,
    p1.bedroom_band,
    p1.n            AS n_p1,
    p2.n            AS n_p2,
    p1.median_rent  AS median_p1,
    p2.median_rent  AS median_p2,
    -- full precision is kept in every mart; rounding happens only in presentation queries
    100.0 * (p2.median_rent / p1.median_rent - 1)           AS median_change_pct,
    100.0 * (p2.p40 / p1.p40 - 1)                           AS p40_change_pct,
    100.0 * (p2.p60 / p1.p60 - 1)                           AS p60_change_pct,
    p2.p25          AS p25_p2,
    p2.p75          AS p75_p2,
    CASE WHEN LEAST(p1.n, p2.n) >= 100 THEN 'Reliable (n>=100)'
         WHEN LEAST(p1.n, p2.n) >= 30  THEN 'Small sample (30-99)'
         ELSE 'Not reported (n<30)' END             AS reliability
FROM mart_region_segment AS p1
JOIN mart_region_segment AS p2
  ON  p1.geography     = p2.geography
  AND p1.dwelling_type = p2.dwelling_type
  AND p1.bedroom_band  = p2.bedroom_band
WHERE p1.period = 'P1'
  AND p2.period = 'P2';

-- Step 4: monthly trend by geography. Counts use ALL rows (every bond lodged);
--         rent statistics use the core sample only.
CREATE OR REPLACE TABLE mart_region_monthly AS
SELECT
    geography,
    month_start,
    COUNT(*)                                                       AS lodgements,
    COUNT(CASE WHEN is_core_sample THEN 1 END)                     AS valid_sample_size,
    QUANTILE_CONT(CASE WHEN is_core_sample THEN weekly_rent END, 0.25) AS p25,
    MEDIAN(CASE WHEN is_core_sample THEN weekly_rent END)          AS median_rent,
    QUANTILE_CONT(CASE WHEN is_core_sample THEN weekly_rent END, 0.75) AS p75,
    100.0 * COUNT(CASE WHEN is_core_sample AND dwelling_type = 'Flat/Unit' THEN 1 END)
          / COUNT(CASE WHEN is_core_sample THEN 1 END)             AS pct_flat_unit
FROM v_geo_lodgements
GROUP BY geography, month_start;

-- Step 5: year-on-year change. LAG(..., 12) = same month last year; the extra check on the
--         date guarantees we really compare with the month 12 months earlier.
CREATE OR REPLACE TABLE mart_region_yoy AS
WITH with_lag AS (
    SELECT
        geography,
        month_start,
        median_rent,
        LAG(median_rent, 12) OVER (PARTITION BY geography ORDER BY month_start) AS median_last_year,
        LAG(month_start, 12) OVER (PARTITION BY geography ORDER BY month_start) AS month_last_year
    FROM mart_region_monthly
)
SELECT
    geography,
    month_start,
    median_rent,
    median_last_year,
    100.0 * (median_rent / median_last_year - 1)           AS yoy_pct
FROM with_lag
WHERE month_last_year = month_start - INTERVAL 12 MONTH;

-- Step 6: lodgement activity (BQ7) by geography x dwelling type code, all rows (F/H/T/O/U)
CREATE OR REPLACE TABLE mart_region_activity AS
SELECT
    geography,
    CASE dwelling_type_raw WHEN 'F' THEN 'Flat/Unit' WHEN 'H' THEN 'House'
                           WHEN 'T' THEN 'Terrace/Townhouse' WHEN 'O' THEN 'Other'
                           ELSE 'Unknown / invalid' END                AS dwelling_group,
    COUNT(CASE WHEN period = 'P1' THEN 1 END)                         AS lodgements_p1,
    COUNT(CASE WHEN period = 'P2' THEN 1 END)                         AS lodgements_p2,
    100.0 * (COUNT(CASE WHEN period = 'P2' THEN 1 END)
           / COUNT(CASE WHEN period = 'P1' THEN 1 END) - 1)           AS change_pct
FROM v_geo_lodgements
GROUP BY geography, dwelling_group;
