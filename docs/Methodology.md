# Methodology

## 1. Data

| Item | Detail |
|---|---|
| Source | NSW Fair Trading — Residential Rental Bond Lodgements, monthly files (see [NOTICE](../NOTICE.md)) |
| Scope | 25 monthly files, August 2024 – August 2026 · **672,365 lodgements** (one row per bond lodged) |
| Fields | Lodgement date, postcode, dwelling type (F/H/T/O/U), bedrooms, weekly rent |
| Not in the data | Address, property ID, lodgement ID, floor area, property age or quality |
| Geography | ABS ASGS Edition 3 (2021) postal areas and mesh blocks, with Census 2021 dwelling counts |

Postcodes are reported by the agent or landlord at lodgement; they are not geocoded.

## 2. Staging and data quality ([`sql/01_stg_lodgements.sql`](../sql/01_stg_lodgements.sql))

- **No row is deleted.** Every issue becomes a boolean flag: unknown/invalid dwelling type, unknown/invalid bedrooms, more than 6 bedrooms, 0-bedroom houses, unknown/zero/very low (< $100)/very high (> $5,000) rent, postcode format, postcodes to review, lodgement date outside the reporting month.
- **Potential duplicates** are rows identical on all five fields within the same monthly file: **68,458 rows (10.2%)**. Without a lodgement ID it is impossible to tell a double entry from separate tenancies with the same attributes (for example several units in one building let on the same day). They are therefore **flagged, not removed**, and every key result is tested with and without them (see §6).
- **Core sample** (population for rent KPIs): dwelling type F, H or T, known bedrooms, rent > 0. Dwelling type "Other" is excluded because NSW Fair Trading notes it may include rented rooms, garages and car spaces.

## 3. Periods

| Period | Months | Core-sample rows |
|---|---|---:|
| Base month | Aug 2024 (used only for the monthly trend and YoY) | 27,999 |
| **P1** | Sep 2024 – Aug 2025 | 298,441 |
| **P2** | Sep 2025 – Aug 2026 | 290,384 |

Each period covers every season once, so **P1 → P2 is the headline change**. Year-on-year change exists for only 13 months (Aug 2025 – Aug 2026) and is used for direction only.

## 4. Regions (Greater Sydney / Rest of NSW)

- Each postcode is assigned to a region when **≥ 90% of its 2021 dwellings** lie in that region (ABS postal areas × mesh blocks × Census 2021 dwelling counts).
- Coverage: **600 of 610 postcodes (98.4%)**, **99.99% of lodgements**. Greater Sydney: 257 postcodes, 73.2% of lodgements; Rest of NSW: 343 postcodes, 26.8%.
- 4 *Mixed* postcodes (border areas) and 6 *Unmapped* postcodes (no ABS postal area) — 72 lodgements in total — count towards NSW totals but are excluded from regional benchmarks.
- No LGA or suburb mapping is made. "Greater Sydney" follows the ABS definition, which includes the Central Coast and the Blue Mountains.
- Checks: the NSW row count and the NSW medians are unchanged after the join; region core counts plus Mixed/Unmapped equal the NSW core count.

## 5. Like-for-like benchmarking (BQ3) — [`sql/06_postcode_benchmark.sql`](../sql/06_postcode_benchmark.sql)

- **Segment** = dwelling type × bedroom band (0, 1, 2, 3, 4+).
- **Regional benchmark** = median of **all individual lodgements** in the same region × segment × period.
  A "median of postcode medians" was tested and rejected: it differed from the record-level benchmark by between −$275 and +$290 depending on the segment.
- **Local rent premium** = postcode median / regional benchmark − 1.
- **Reliability tiers:** n ≥ 100 *Reliable*, 30–99 *Small sample*, < 30 *Not reported*.
- Why a regional benchmark matters: switching from an NSW benchmark to the regional benchmark **flips the conclusion** (above ↔ below benchmark) for 29.6% of Rest of NSW cells and 13.8% of Greater Sydney cells (n ≥ 30, P2).

## 6. Screening unusual movements (BQ4) — [`sql/07_unusual_movements.sql`](../sql/07_unusual_movements.sql)

1. Only postcode × segment cells with **n ≥ 100 in both P1 and P2** are screened (604 cells).
2. **Deviation** = postcode P1 → P2 change − region P1 → P2 change, same segment (percentage points).
3. **Unusual** when |deviation| ≥ **10 pp**.
   The threshold was chosen from the observed distribution of deviations (P5 = −4.2 pp, P95 = +6.5 pp): 5 pp produces 73 flags (inside normal variation), 15 pp only 2, 10 pp gives a workable shortlist of 10.
4. Two stability checks label each flag:
   - **Duplicate sensitivity** — recompute the change keeping only the first row of each identical group; *stable* if it moves < 2 pp.
   - **P25 gap** — the 25th percentile must move within 10 pp of the median; otherwise the low end of the market shifted.
5. Result: *In line with region* / *Unusual – stable* / *Unusual – check composition / data*. A flag is a reason to investigate, never a conclusion about cause.

## 7. Distribution and composition (BQ5)

- **Rent heaping:** 48.6% of core rents are multiples of $50. When many lodgements sit on round values, the median moves in steps, so P40 and P60 are reported next to the median as distribution context (not as a confidence interval).
- **Mix-adjusted index (supplementary):** a weighted average of stratum medians with fixed P1 weights. It answers "what if the mix had stayed as in P1?". It is not a median, so it is only compared within the same index model (fixed vs actual weights), never subtracted from the pooled median change.

## 8. Validation

| Layer | Result | What is checked |
|---|---|---|
| **SQL validation** ([`sql/09_validation.sql`](../sql/09_validation.sql)) | **14 / 14 PASS** | Row counts preserved; 25 months present; approved NSW medians ($690 / $720); monthly medians match an earlier independent mart; regions add up to NSW; one benchmark recomputed directly from records; postcode cells add up to region totals; premium arithmetic; mix-index weights complete; Mixed/Unmapped excluded from benchmarks; screening uses the numeric n ≥ 100 rule; 13 YoY months per geography |
| **Independent recalculation** | 8 / 8 match | Key KPIs recomputed with pandas, independently of SQL: zero difference |
| **DAX ↔ SQL** | **161 / 161 PASS** | Every number the Power BI model produces for the tested filter contexts (totals, periods, months, segments, benchmarks, Mixed/Unmapped, threshold slicer, premium guard, each dashboard page) is compared with an independent SQL query (relative difference ≤ 1e-9). Re-run on the published `.pbix` with its data source folder hidden |
| **External check — DCJ Rent Tables** (NSW Department of Communities and Justice, June quarter 2026, same bond source) | Median identical for **66.6%** of 347 comparable postcodes; within ±2% for **90.2%**; within ±5% for 97.7%. NSW Q1 and Q3 identical ($570 / $900) | Differences are small and consistent with documented differences: DCJ geocodes addresses and drops ~2% of records; extraction dates differ. The NSW median differs by $10 ($710 vs $720) because the 50% point sits exactly on the $710/$720 boundary — 0.16% of records is enough to move it. The project definition was **not** changed to force a match. DCJ data is used for comparison only and is not redistributed |

## 9. Power BI model

- **Import mode, star schema, 9 tables:** `fact_lodgements` (672,365 rows, one per lodgement) · `dim_date` (25 months) · `dim_period` (Base / P1 / P2) · `dim_postcode` (610, with region) · `dim_segment` (16) · `mart_postcode_benchmark` (postcode × segment × period) · `mart_movement_screen` (604 screened cells) · `mart_mix_index` · `Threshold` (5 / 10 / 15 pp, disconnected table for the slicer).
- All relationships are many-to-one, single direction. Auto date/time is off.
- **32 DAX measures** in five folders: Base (counts, median and percentiles, sample tier) · Period (P1/P2 medians and change) · Month (YoY) · Benchmark (regional benchmark, local rent premium) · Screening (selected threshold, flagged/stable/check cells).
- Medians in Power BI are computed from fact rows (`PERCENTILE.INC`), never from pre-aggregated tables, so they stay correct under any filter.
