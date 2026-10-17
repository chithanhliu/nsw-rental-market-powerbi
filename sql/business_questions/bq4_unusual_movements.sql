-- BQ4 Unusual Movements: which postcode x segment moved differently from its region, and is it stable?

-- name: bq4_threshold_test
-- Number of flags at 5 / 10 / 15 pp, and how many survive the stability checks
SELECT t.threshold_pp,
       COUNT(*)                                                           AS reliable_cells,
       COUNT(CASE WHEN ABS(s.deviation_pp) >= t.threshold_pp THEN 1 END)  AS flagged,
       COUNT(CASE WHEN ABS(s.deviation_pp) >= t.threshold_pp
                   AND s.dup_sensitivity_pp < 2 AND s.p25_gap_pp < 10 THEN 1 END) AS flagged_and_stable
FROM mart_movement_screen AS s
CROSS JOIN (VALUES (5), (10), (15)) AS t(threshold_pp)
GROUP BY t.threshold_pp
ORDER BY t.threshold_pp;

-- name: bq4_normal_variation
-- What does "normal" deviation from the region look like? (all reliable cells)
SELECT COUNT(*) AS reliable_cells,
       QUANTILE_CONT(deviation_pp, 0.05) AS p05,
       QUANTILE_CONT(deviation_pp, 0.25) AS p25,
       MEDIAN(deviation_pp)              AS median,
       QUANTILE_CONT(deviation_pp, 0.75) AS p75,
       QUANTILE_CONT(deviation_pp, 0.95) AS p95
FROM mart_movement_screen;

-- name: bq4_flagged_movements
-- Final screen (10 pp, n >= 100 both periods) with every check needed to read a flag
SELECT postcode, region, dwelling_type, bedroom_band,
       n_p1, n_p2,
       ROUND(100.0 * (n_p2 * 1.0 / n_p1 - 1), 1) AS lodgement_change_pct,
       median_p1, median_p2,
       ROUND(change_pct, 1)          AS change_pct,
       ROUND(region_change_pct, 1)   AS region_change_pct,
       ROUND(deviation_pp, 1)        AS deviation_pp,
       ROUND(change_pct_dedup, 1)    AS change_pct_dedup,
       ROUND(dup_sensitivity_pp, 1)  AS dup_sensitivity_pp,
       ROUND(p25_change_pct, 1)      AS p25_change_pct,
       ROUND(p25_gap_pp, 1)          AS p25_gap_pp,
       ROUND(premium_p2_pct, 1)      AS premium_p2_pct,
       screen_result
FROM mart_movement_screen
WHERE is_unusual
ORDER BY deviation_pp DESC;
