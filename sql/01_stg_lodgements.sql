-- Staging layer: typed columns + data quality flags.
-- Nothing is deleted: every raw row is kept, and each issue is a flag.
-- Analysis population is defined by is_core_sample (see bottom).

CREATE OR REPLACE TABLE stg_lodgements AS
WITH typed AS (
    SELECT
        source_file,
        excel_row,
        reporting_period,
        CAST(strptime(reporting_period || '-01', '%Y-%m-%d') AS DATE)      AS month_start,
        lodgement_date_raw,
        TRY_CAST(lodgement_date_raw AS DATE)                               AS lodgement_date,
        postcode_raw                                                       AS postcode,      -- kept as text: a label, not a number
        dwelling_type_raw,
        bedrooms_raw,
        weekly_rent_raw,
        CASE dwelling_type_raw WHEN 'F' THEN 'Flat/Unit'
                               WHEN 'H' THEN 'House'
                               WHEN 'T' THEN 'Terrace/Townhouse'
                               WHEN 'O' THEN 'Other'
                               WHEN 'U' THEN 'Unknown'
                               ELSE 'Invalid code' END                     AS dwelling_type,
        TRY_CAST(bedrooms_raw AS INTEGER)                                  AS bedrooms,
        TRY_CAST(weekly_rent_raw AS INTEGER)                               AS weekly_rent
    FROM raw_lodgements_monthly
)
SELECT
    *,
    -- Bedroom band used for like-for-like comparisons (4+ pooled to keep samples usable)
    CASE WHEN bedrooms IS NULL THEN NULL
         WHEN bedrooms >= 4 THEN '4+'
         ELSE CAST(bedrooms AS VARCHAR) END                                AS bedroom_band,

    -- Quality flags
    dwelling_type_raw = 'U'                                                AS flag_dwelling_unknown,
    dwelling_type_raw NOT IN ('F','H','T','O','U')                         AS flag_dwelling_invalid_code,
    bedrooms_raw = 'U'                                                     AS flag_bedrooms_unknown,
    bedrooms_raw <> 'U' AND bedrooms IS NULL                               AS flag_bedrooms_invalid,
    bedrooms > 6                                                           AS flag_bedrooms_high,
    bedrooms = 0 AND dwelling_type_raw = 'H'                               AS flag_house_zero_bed,
    weekly_rent_raw = 'U'                                                  AS flag_rent_unknown,
    weekly_rent_raw <> 'U' AND weekly_rent IS NULL                         AS flag_rent_invalid,
    weekly_rent = 0                                                        AS flag_rent_zero,
    weekly_rent BETWEEN 1 AND 99                                           AS flag_rent_very_low,
    weekly_rent > 5000                                                     AS flag_rent_very_high,
    NOT regexp_full_match(postcode, '2\d{3}')                              AS flag_postcode_format,
    -- 2611/2617 are mainly ACT postcodes; 2057/2059 are PO-box/business postcodes.
    -- Flagged for review only (no official NSW postcode list is used in this phase).
    postcode IN ('2611','2617','2057','2059')                              AS flag_postcode_review,
    lodgement_date IS NULL
        OR strftime(lodgement_date, '%Y-%m') <> reporting_period           AS flag_date_outside_period,
    -- Potential duplicate: identical on all 5 raw fields within the same monthly file.
    -- There is no lodgement ID, so this flag CANNOT tell a double entry from separate
    -- tenancies with the same attributes (e.g. units in one building let on the same day).
    count(*) OVER dup_key > 1                                              AS flag_potential_duplicate,
    count(*) OVER dup_key                                                  AS dup_group_size,
    row_number() OVER (dup_key ORDER BY excel_row)                         AS dup_seq,      -- 1 = first occurrence

    -- Core analysis sample: residential dwelling with known type, bedrooms and a positive rent.
    -- 'Other' is excluded because NSW Fair Trading says it may include rooms, garages and car spaces.
    COALESCE(dwelling_type_raw IN ('F','H','T')
        AND bedrooms IS NOT NULL
        AND weekly_rent > 0, false)                                        AS is_core_sample
FROM typed
WINDOW dup_key AS (PARTITION BY reporting_period, lodgement_date_raw, postcode,
                                dwelling_type_raw, bedrooms_raw, weekly_rent_raw);
