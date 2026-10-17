-- BQ6 Decision Support: which areas / movements deserve deeper research, and why?
-- Built only from screened results (BQ4) - a priority is a reason to investigate, not a conclusion.

-- name: bq6_research_shortlist
SELECT
    CASE screen_result
        WHEN 'Unusual - stable' THEN 'A. Market signal to verify'
        ELSE 'B. Data / composition check first'
    END                                          AS priority,
    postcode, region, dwelling_type, bedroom_band,
    n_p1, n_p2, median_p1, median_p2,
    change_pct, region_change_pct, deviation_pp,
    ROUND(dup_sensitivity_pp, 1)                 AS dup_sensitivity_pp,
    ROUND(p25_gap_pp, 1)                         AS p25_gap_pp,
    CASE
        WHEN screen_result = 'Unusual - stable' AND deviation_pp > 0
            THEN 'Rose faster than region; stable to duplicates and low-end shift'
        WHEN screen_result = 'Unusual - stable'
            THEN 'Rose slower than region; stable to duplicates and low-end shift'
        WHEN dup_sensitivity_pp >= 2
            THEN 'Change depends on potential duplicates'
        ELSE 'Low end of the distribution moved differently from the median'
    END                                          AS reason
FROM mart_movement_screen
WHERE is_unusual
ORDER BY priority, ABS(deviation_pp) DESC;
