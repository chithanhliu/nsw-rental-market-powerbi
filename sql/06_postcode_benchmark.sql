-- 06 Postcode benchmarking (BQ3, input for BQ4).
-- Like-for-like rule: a postcode is only compared with its OWN region, for the SAME
-- dwelling type x bedroom band and the SAME period. Mixed / Unmapped postcodes are excluded.
-- Reliability tiers: n >= 100 Reliable | 30-99 Small sample | < 30 Not reported.

-- Step 1: postcode x segment x period statistics (core sample, record level)
CREATE OR REPLACE TABLE mart_postcode_cell AS
SELECT
    postcode,
    region,
    dwelling_type,
    bedroom_band,
    period,
    COUNT(*)                          AS n,
    QUANTILE_CONT(weekly_rent, 0.25)  AS p25,
    MEDIAN(weekly_rent)               AS median_rent,
    QUANTILE_CONT(weekly_rent, 0.75)  AS p75
FROM fct_lodgements
WHERE is_core_sample
  AND period IN ('P1', 'P2')
  AND region IN ('Greater Sydney', 'Rest of NSW')
GROUP BY postcode, region, dwelling_type, bedroom_band, period;

-- Step 2: attach the regional benchmark (median of ALL lodgements in region x segment x period,
--         taken from mart_region_segment) and compute the Local Rent Premium
CREATE OR REPLACE TABLE mart_postcode_benchmark AS
SELECT
    c.*,
    b.median_rent                                           AS region_benchmark,
    b.n                                                     AS region_n,
    100.0 * (c.median_rent / b.median_rent - 1)             AS premium_pct,   -- full precision
    CASE WHEN c.n >= 100 THEN 'Reliable (n>=100)'
         WHEN c.n >= 30  THEN 'Small sample (30-99)'
         ELSE 'Not reported (n<30)' END                     AS reliability
FROM mart_postcode_cell AS c
JOIN mart_region_segment AS b
  ON  b.geography     = c.region
  AND b.dwelling_type = c.dwelling_type
  AND b.bedroom_band  = c.bedroom_band
  AND b.period        = c.period;

-- Step 3: P1 -> P2 change per postcode x segment, next to the change of its region x segment.
--         deviation_pp = how many percentage points the postcode moved more (or less) than its region.
CREATE OR REPLACE TABLE mart_postcode_change AS
SELECT
    p2.postcode,
    p2.region,
    p2.dwelling_type,
    p2.bedroom_band,
    p1.n                                                        AS n_p1,
    p2.n                                                        AS n_p2,
    p1.median_rent                                              AS median_p1,
    p2.median_rent                                              AS median_p2,
    -- full precision: thresholds are applied to unrounded values (rounding only for display)
    100.0 * (p2.median_rent / p1.median_rent - 1)               AS change_pct,
    rc.median_change_pct                                        AS region_change_pct,
    100.0 * (p2.median_rent / p1.median_rent - 1) - rc.median_change_pct AS deviation_pp,
    100.0 * (p2.p25 / p1.p25 - 1)                               AS p25_change_pct,
    p2.premium_pct                                              AS premium_p2_pct,
    CASE WHEN LEAST(p1.n, p2.n) >= 100 THEN 'Reliable (n>=100)'
         WHEN LEAST(p1.n, p2.n) >= 30  THEN 'Small sample (30-99)'
         ELSE 'Not reported (n<30)' END                         AS reliability
FROM mart_postcode_benchmark AS p2
JOIN mart_postcode_benchmark AS p1
  ON  p1.postcode      = p2.postcode
  AND p1.dwelling_type = p2.dwelling_type
  AND p1.bedroom_band  = p2.bedroom_band
  AND p1.period        = 'P1'
JOIN mart_region_change AS rc
  ON  rc.geography     = p2.region
  AND rc.dwelling_type = p2.dwelling_type
  AND rc.bedroom_band  = p2.bedroom_band
WHERE p2.period = 'P2';
