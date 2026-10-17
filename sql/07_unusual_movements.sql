-- 07 Unusual movement screen (BQ4, BQ6).
-- A movement is only screened when the postcode x segment has n >= 100 in BOTH periods.
-- Screening rule (proposed in the design, tested here):
--   unusual  : |postcode change - region change| >= 10 percentage points
--   stable   : the change moves < 2 pp when only the first row of each identical group is kept
--   shape    : P25 moved >= 10 pp differently from the median (the low end of the market shifted)
-- A flag means "look closer", never "the market changed" - causes are not in this data.

-- Step 1: the same P1 -> P2 change, recomputed without potential duplicates (sensitivity scenario B)
CREATE OR REPLACE TABLE mart_postcode_change_dedup AS
WITH cell AS (
    SELECT postcode, dwelling_type, bedroom_band, period,
           MEDIAN(weekly_rent) AS median_rent
    FROM fct_lodgements
    WHERE is_core_sample
      AND dup_seq = 1                       -- keep first row of each identical group only
      AND period IN ('P1', 'P2')
      AND region IN ('Greater Sydney', 'Rest of NSW')
    GROUP BY postcode, dwelling_type, bedroom_band, period
)
SELECT
    p1.postcode, p1.dwelling_type, p1.bedroom_band,
    100.0 * (p2.median_rent / p1.median_rent - 1)           AS change_pct_dedup   -- full precision
FROM cell AS p1
JOIN cell AS p2
  ON  p1.postcode = p2.postcode
  AND p1.dwelling_type = p2.dwelling_type
  AND p1.bedroom_band = p2.bedroom_band
WHERE p1.period = 'P1' AND p2.period = 'P2';

-- Step 2: screen every reliable postcode x segment
CREATE OR REPLACE TABLE mart_movement_screen AS
WITH checks AS (
    SELECT
        c.*,
        d.change_pct_dedup,
        ABS(d.change_pct_dedup - c.change_pct)          AS dup_sensitivity_pp,
        ABS(c.p25_change_pct - c.change_pct)            AS p25_gap_pp
    FROM mart_postcode_change AS c
    LEFT JOIN mart_postcode_change_dedup AS d
      ON  d.postcode = c.postcode
      AND d.dwelling_type = c.dwelling_type
      AND d.bedroom_band = c.bedroom_band
    WHERE c.n_p1 >= 100          -- sample-size rule checked on the numbers themselves,
      AND c.n_p2 >= 100          -- not on the text of a label
)
SELECT
    *,
    ABS(deviation_pp) >= 10                             AS is_unusual,
    dup_sensitivity_pp < 2                              AS is_stable_to_duplicates,
    p25_gap_pp >= 10                                    AS low_end_shifted,
    CASE
        WHEN ABS(deviation_pp) < 10 THEN 'In line with region'
        WHEN dup_sensitivity_pp < 2 AND p25_gap_pp < 10 THEN 'Unusual - stable'
        ELSE 'Unusual - check composition / data'
    END                                                 AS screen_result
FROM checks;

-- Step 3: how sensitive is the number of flags to the 10 pp threshold?
CREATE OR REPLACE TABLE mart_screen_threshold_sensitivity AS
SELECT
    t.threshold_pp,
    COUNT(*)                                                         AS reliable_cells,
    COUNT(CASE WHEN ABS(s.deviation_pp) >= t.threshold_pp THEN 1 END) AS flagged_cells,
    ROUND(100.0 * COUNT(CASE WHEN ABS(s.deviation_pp) >= t.threshold_pp THEN 1 END) / COUNT(*), 1) AS pct_flagged
FROM mart_movement_screen AS s
CROSS JOIN (VALUES (5), (10), (15)) AS t(threshold_pp)
GROUP BY t.threshold_pp
ORDER BY t.threshold_pp;
