-- BQ5 Distribution & Composition: do distribution, rent heaping and mix change how we read the trend?

-- name: bq5_pooled_median_change
-- The observed headline: pooled median change (record level)
SELECT geography, median_p1, median_p2, ROUND(median_change_pct, 2) AS median_change_pct
FROM mart_region_change
WHERE dwelling_type = 'All' AND bedroom_band = 'All'
ORDER BY geography;

-- name: bq5_mix_index
-- SUPPLEMENTARY: index model only. Compare columns WITHIN a row (same strata, same medians);
-- do not subtract these numbers from the pooled median change above.
SELECT index_name,
       ROUND(index_p1, 1)                  AS index_p1,
       ROUND(index_p2, 1)                  AS index_p2_fixed_p1_weights,
       ROUND(mix_adjusted_change_pct, 2)   AS fixed_weight_change_pct,
       ROUND(actual_weight_change_pct, 2)  AS actual_weight_change_pct,
       ROUND(composition_effect_pp, 2)     AS composition_effect_pp
FROM mart_mix_index
ORDER BY index_name;

-- name: bq5_spread
-- Distribution spread: did the low end (P25) and high end (P75) move alike?
SELECT geography,
       MAX(CASE WHEN period = 'P1' THEN p25 END) AS p25_p1,
       MAX(CASE WHEN period = 'P2' THEN p25 END) AS p25_p2,
       MAX(CASE WHEN period = 'P1' THEN p75 END) AS p75_p1,
       MAX(CASE WHEN period = 'P2' THEN p75 END) AS p75_p2,
       ROUND(100.0 * (MAX(CASE WHEN period = 'P2' THEN p25 END) / MAX(CASE WHEN period = 'P1' THEN p25 END) - 1), 1) AS p25_change_pct,
       ROUND(100.0 * (MAX(CASE WHEN period = 'P2' THEN p75 END) / MAX(CASE WHEN period = 'P1' THEN p75 END) - 1), 1) AS p75_change_pct
FROM mart_region_segment
WHERE dwelling_type = 'All' AND bedroom_band = 'All'
GROUP BY geography
ORDER BY geography;

-- name: bq5_heaping
-- Rent heaping: share of core rents that are exact multiples of $50 and of $10, by geography
SELECT geography,
       COUNT(*) AS n,
       ROUND(100.0 * COUNT(CASE WHEN weekly_rent % 50 = 0 THEN 1 END) / COUNT(*), 1) AS pct_multiple_of_50,
       ROUND(100.0 * COUNT(CASE WHEN weekly_rent % 10 = 0 THEN 1 END) / COUNT(*), 1) AS pct_multiple_of_10
FROM v_geo_lodgements
WHERE is_core_sample AND period IN ('P1', 'P2')
GROUP BY geography
ORDER BY geography;

-- name: bq5_median_on_heap
-- Is each P2 median sitting on a heap? Share of lodgements exactly at the median value
WITH p2 AS (
    SELECT v.geography, v.dwelling_type, v.bedroom_band, v.weekly_rent, r.median_rent
    FROM v_geo_lodgements AS v
    JOIN mart_region_segment AS r
      ON r.geography = v.geography AND r.period = 'P2'
     AND r.dwelling_type = v.dwelling_type AND r.bedroom_band = v.bedroom_band
    WHERE v.is_core_sample AND v.period = 'P2'
)
SELECT geography, dwelling_type, bedroom_band, median_rent,
       COUNT(*) AS n,
       ROUND(100.0 * COUNT(CASE WHEN weekly_rent = median_rent THEN 1 END) / COUNT(*), 1) AS pct_exactly_at_median,
       ROUND(100.0 * COUNT(CASE WHEN weekly_rent <= median_rent THEN 1 END) / COUNT(*), 1) AS pct_at_or_below_median
FROM p2
GROUP BY geography, dwelling_type, bedroom_band, median_rent
HAVING COUNT(*) >= 1000
ORDER BY geography, dwelling_type, bedroom_band;
