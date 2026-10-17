-- BQ3 Location Benchmarking: which postcodes differ from their own region, same segment? (P2)

-- name: bq3_reliability_coverage
-- How many postcode x segment cells can be benchmarked at each reliability level
SELECT region, reliability,
       COUNT(*)                  AS cells,
       COUNT(DISTINCT postcode)  AS postcodes,
       SUM(n)                    AS lodgements
FROM mart_postcode_benchmark
WHERE period = 'P2'
GROUP BY region, reliability
ORDER BY region, reliability;

-- name: bq3_premium_distribution
-- Spread of the Local Rent Premium among reliable cells
SELECT region,
       COUNT(*)                                             AS reliable_cells,
       QUANTILE_CONT(premium_pct, 0.10)                     AS premium_p10,
       QUANTILE_CONT(premium_pct, 0.25)                     AS premium_p25,
       MEDIAN(premium_pct)                                  AS premium_median,
       QUANTILE_CONT(premium_pct, 0.75)                     AS premium_p75,
       QUANTILE_CONT(premium_pct, 0.90)                     AS premium_p90,
       COUNT(CASE WHEN ABS(premium_pct) <= 10 THEN 1 END)   AS cells_within_10pct
FROM mart_postcode_benchmark
WHERE period = 'P2' AND reliability = 'Reliable (n>=100)'
GROUP BY region
ORDER BY region;

-- name: bq3_top_bottom_flat2
-- Example segment for the dashboard default (Flat 2-bed): highest and lowest premium per region
WITH ranked AS (
    SELECT region, postcode, n, median_rent, region_benchmark, premium_pct,
           ROW_NUMBER() OVER (PARTITION BY region ORDER BY premium_pct DESC) AS rank_high,
           ROW_NUMBER() OVER (PARTITION BY region ORDER BY premium_pct ASC)  AS rank_low
    FROM mart_postcode_benchmark
    WHERE period = 'P2' AND reliability = 'Reliable (n>=100)'
      AND dwelling_type = 'Flat/Unit' AND bedroom_band = '2'
)
SELECT region, postcode, n, median_rent, region_benchmark, ROUND(premium_pct, 1) AS premium_pct,
       CASE WHEN rank_high <= 5 THEN 'Top 5' ELSE 'Bottom 5' END AS position
FROM ranked
WHERE rank_high <= 5 OR rank_low <= 5
ORDER BY region, premium_pct DESC;

-- name: bq3_benchmark_choice_effect
-- Value of the regional benchmark: how many cells change side (above/below) vs an NSW benchmark
WITH compared AS (
    SELECT b.region, b.median_rent, b.region_benchmark, nsw.median_rent AS nsw_benchmark
    FROM mart_postcode_benchmark AS b
    JOIN mart_region_segment AS nsw
      ON nsw.geography = 'NSW' AND nsw.period = b.period
     AND nsw.dwelling_type = b.dwelling_type AND nsw.bedroom_band = b.bedroom_band
    WHERE b.period = 'P2' AND b.reliability <> 'Not reported (n<30)'
)
SELECT region,
       COUNT(*) AS cells_n_ge_30,
       COUNT(CASE WHEN SIGN(median_rent - nsw_benchmark) <> SIGN(median_rent - region_benchmark) THEN 1 END) AS cells_changing_side,
       ROUND(100.0 * COUNT(CASE WHEN SIGN(median_rent - nsw_benchmark) <> SIGN(median_rent - region_benchmark) THEN 1 END)
             / COUNT(*), 1) AS pct_changing_side
FROM compared
GROUP BY region
ORDER BY region;
