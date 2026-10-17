-- BQ7 Lodgement Activity: how did the number of new bonds change over time and by region?
-- Counts use ALL rows (every bond lodged), not only the core sample.
-- A lodgement count is new-tenancy activity, NOT rental supply or vacancy.

-- name: bq7_activity_by_type
SELECT geography, dwelling_group, lodgements_p1, lodgements_p2, ROUND(change_pct, 2) AS change_pct
FROM mart_region_activity ORDER BY geography, dwelling_group;

-- name: bq7_monthly_lodgements
SELECT geography, month_start, lodgements, valid_sample_size,
       ROUND(100.0 * valid_sample_size / lodgements, 1) AS pct_core_sample
FROM mart_region_monthly
ORDER BY geography, month_start;

-- name: bq7_other_type_postcodes
-- Analytical question AQ8: where is the growth of dwelling type 'Other' in Greater Sydney concentrated?
SELECT postcode,
       COUNT(CASE WHEN period = 'P1' THEN 1 END) AS other_p1,
       COUNT(CASE WHEN period = 'P2' THEN 1 END) AS other_p2,
       COUNT(CASE WHEN period = 'P2' THEN 1 END) - COUNT(CASE WHEN period = 'P1' THEN 1 END) AS increase
FROM fct_lodgements
WHERE dwelling_type_raw = 'O' AND region = 'Greater Sydney'
GROUP BY postcode
ORDER BY increase DESC
LIMIT 10;
