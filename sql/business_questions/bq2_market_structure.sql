-- BQ2 Market Structure: how do rents differ by region, dwelling type and bedrooms? (P2)

-- name: bq2_region_type
-- Median by dwelling type: NSW vs each region (shows the Simpson's paradox)
SELECT dwelling_type,
       MAX(CASE WHEN geography = 'NSW'            THEN median_rent END) AS nsw_median,
       MAX(CASE WHEN geography = 'Greater Sydney' THEN median_rent END) AS greater_sydney_median,
       MAX(CASE WHEN geography = 'Rest of NSW'    THEN median_rent END) AS rest_of_nsw_median,
       MAX(CASE WHEN geography = 'Greater Sydney' THEN n END)           AS greater_sydney_n,
       MAX(CASE WHEN geography = 'Rest of NSW'    THEN n END)           AS rest_of_nsw_n
FROM mart_region_segment
WHERE period = 'P2' AND bedroom_band = 'All'
GROUP BY dwelling_type
ORDER BY dwelling_type;

-- name: bq2_region_segment_matrix
-- Full matrix region x dwelling type x bedrooms, with the reliability of each cell
SELECT r.geography, r.dwelling_type, r.bedroom_band, s.segment_sort,
       r.n, r.p25, r.median_rent, r.p75,
       ROUND(100.0 * r.median_rent / nsw.median_rent - 100, 1) AS vs_nsw_same_segment_pct,
       CASE WHEN r.n >= 100 THEN 'Reliable (n>=100)'
            WHEN r.n >= 30  THEN 'Small sample (30-99)'
            ELSE 'Not reported (n<30)' END                 AS reliability
FROM mart_region_segment AS r
JOIN dim_segment AS s
  ON s.dwelling_type = r.dwelling_type AND s.bedroom_band = r.bedroom_band
JOIN mart_region_segment AS nsw
  ON nsw.geography = 'NSW' AND nsw.period = r.period
 AND nsw.dwelling_type = r.dwelling_type AND nsw.bedroom_band = r.bedroom_band
WHERE r.period = 'P2' AND r.geography <> 'NSW'
ORDER BY r.geography, s.segment_sort;

-- name: bq2_geo_mix
-- Where each dwelling type is let: share of NSW core lodgements in each region
SELECT period, dwelling_type, region, n, ROUND(pct_of_nsw_lodgements, 1) AS pct_of_nsw_lodgements
FROM mart_geo_mix ORDER BY dwelling_type, region, period;
