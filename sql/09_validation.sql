-- 09 KPI validation: every mart is checked against an independent recalculation from the fact view
-- or against an already-approved number. Result: one row per check with passed = true/false.

CREATE OR REPLACE TABLE validation_results AS
-- 1. Nothing lost or duplicated when labels were added
SELECT 'fact view keeps every staged row' AS check_name,
       (SELECT COUNT(*) FROM fct_lodgements) = (SELECT COUNT(*) FROM stg_lodgements) AS passed,
       (SELECT COUNT(*) FROM fct_lodgements)::VARCHAR AS observed
UNION ALL
SELECT 'all 25 months have data',
       COUNT(DISTINCT month_start) = 25, COUNT(DISTINCT month_start)::VARCHAR
FROM fct_lodgements
UNION ALL
-- 2. NSW numbers unchanged versus the approved feasibility KPIs (P1 $690, P2 $720)
SELECT 'NSW median P1 = 690 and P2 = 720 (approved values)',
       MAX(CASE WHEN period = 'P1' THEN median_rent END) = 690
   AND MAX(CASE WHEN period = 'P2' THEN median_rent END) = 720,
       MAX(CASE WHEN period = 'P1' THEN median_rent END)::VARCHAR || ' / ' ||
       MAX(CASE WHEN period = 'P2' THEN median_rent END)::VARCHAR
FROM mart_region_segment
WHERE geography = 'NSW' AND dwelling_type = 'All'
UNION ALL
SELECT 'NSW monthly medians equal kpi_monthly (feasibility mart)',
       COUNT(*) = 0, COUNT(*)::VARCHAR || ' mismatching months'
FROM mart_region_monthly AS m
JOIN kpi_monthly AS k
  ON k.month_start = m.month_start AND k.dwelling_type = 'All F/H/T'
WHERE m.geography = 'NSW' AND m.median_rent <> k.median_rent
UNION ALL
-- 3. Regions add up: GS + Rest of NSW + Mixed + Unmapped = NSW
SELECT 'region core counts + Mixed/Unmapped = NSW core count',
       SUM(CASE WHEN geography <> 'NSW' THEN n END)
         + (SELECT COUNT(*) FROM fct_lodgements WHERE is_core_sample AND period IN ('P1','P2')
            AND region IN ('Mixed', 'Unmapped'))
       = SUM(CASE WHEN geography = 'NSW' THEN n END),
       SUM(CASE WHEN geography = 'NSW' THEN n END)::VARCHAR
FROM mart_region_segment
WHERE dwelling_type = 'All'
UNION ALL
-- 4. Benchmark is record level: recompute one benchmark directly from the fact view
SELECT 'benchmark GS Flat 2-bed P2 equals direct recalculation',
       (SELECT MEDIAN(weekly_rent) FROM fct_lodgements
         WHERE is_core_sample AND period = 'P2' AND region = 'Greater Sydney'
           AND dwelling_type = 'Flat/Unit' AND bedroom_band = '2')
       = (SELECT DISTINCT region_benchmark FROM mart_postcode_benchmark
           WHERE period = 'P2' AND region = 'Greater Sydney'
             AND dwelling_type = 'Flat/Unit' AND bedroom_band = '2'),
       (SELECT DISTINCT region_benchmark FROM mart_postcode_benchmark
         WHERE period = 'P2' AND region = 'Greater Sydney'
           AND dwelling_type = 'Flat/Unit' AND bedroom_band = '2')::VARCHAR
UNION ALL
-- 5. Postcode cells add up to their region x segment x period
SELECT 'postcode cell counts add up to region counts',
       COUNT(*) = 0, COUNT(*)::VARCHAR || ' mismatching region x segment x period'
FROM (
    SELECT c.region, c.dwelling_type, c.bedroom_band, c.period, SUM(c.n) AS n_cells, MAX(c.region_n) AS n_region
    FROM mart_postcode_benchmark AS c
    GROUP BY c.region, c.dwelling_type, c.bedroom_band, c.period
) WHERE n_cells <> n_region
UNION ALL
-- 6. Premium arithmetic: zero exactly when median equals benchmark
SELECT 'premium = 0 exactly when postcode median = benchmark',
       COUNT(*) = 0, COUNT(*)::VARCHAR || ' violations'
FROM mart_postcode_benchmark
WHERE (median_rent = region_benchmark) <> (premium_pct = 0)
UNION ALL
-- 7. Mix index weights are complete (no stratum missing in P2)
SELECT 'mix-adjusted indices: P1 weights fully present in P2',
       MIN(weight_found_in_p2) > 0.999, MIN(weight_found_in_p2)::VARCHAR
FROM mart_mix_index
UNION ALL
SELECT 'mix-adjusted indices: P2 weights fully present in P1',
       MIN(p2_weight_found_in_p1) > 0.999, MIN(p2_weight_found_in_p1)::VARCHAR
FROM mart_mix_index
UNION ALL
-- 7b. Mixed / Unmapped: kept in NSW totals, excluded from region strata and benchmarks (documented count)
SELECT 'Mixed/Unmapped core rows in P1+P2 (NSW only, no region benchmark)',
       COUNT(*) < 100, COUNT(*)::VARCHAR || ' rows'
FROM fct_lodgements
WHERE is_core_sample AND period IN ('P1', 'P2') AND region IN ('Mixed', 'Unmapped')
UNION ALL
SELECT 'no Mixed/Unmapped postcode in benchmark or screen marts',
       (SELECT COUNT(*) FROM mart_postcode_benchmark WHERE region NOT IN ('Greater Sydney', 'Rest of NSW'))
     + (SELECT COUNT(*) FROM mart_movement_screen   WHERE region NOT IN ('Greater Sydney', 'Rest of NSW')) = 0,
       'checked'
UNION ALL
-- 7c. Screening uses the numeric sample-size rule, not the label
SELECT 'every screened cell has n >= 100 in P1 and in P2',
       COUNT(*) = 0, COUNT(*)::VARCHAR || ' violations'
FROM mart_movement_screen
WHERE n_p1 < 100 OR n_p2 < 100
UNION ALL
-- 8. YoY only where a base month exists: 13 months per geography
SELECT 'YoY rows = 13 per geography',
       MIN(cnt) = 13 AND MAX(cnt) = 13, MIN(cnt)::VARCHAR || '-' || MAX(cnt)::VARCHAR
FROM (SELECT geography, COUNT(*) AS cnt FROM mart_region_yoy GROUP BY geography);
