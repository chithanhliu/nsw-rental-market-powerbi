# SQL

Selected SQL from the project, written in the DuckDB SQL dialect. The files are published **unchanged** (byte-for-byte) from the analysis project, so file names, numbering and comments are those of the original pipeline. Steps 02–04, 08 and 10–11 (raw-file loading, dimensions, mix tables, Power BI export) belong to the private pipeline and are not included.

> **Read and discuss, not run.** These scripts need the project's DuckDB database, which is built from the raw files by a private ingestion step and is not distributed. See [Dependencies](#dependencies-why-the-scripts-do-not-run-on-their-own) below.

## Start here — five queries with a clear business answer

| # | Query (file → `-- name:` block or table) | Business question it answers | Result |
|---|---|---|---|
| 1 | [`business_questions/bq2_market_structure.sql`](business_questions/bq2_market_structure.sql) → `bq2_region_type` | Is a house cheaper than a flat? | NSW says yes ($700 vs $740); each region says no — **Simpson's paradox** |
| 2 | [`06_postcode_benchmark.sql`](06_postcode_benchmark.sql) → `mart_postcode_benchmark` | Is this postcode expensive compared with **comparable** areas? | Local rent premium vs the same region × segment × period, with a reliability tier |
| 3 | [`business_questions/bq3_location_benchmarking.sql`](business_questions/bq3_location_benchmarking.sql) → `bq3_benchmark_choice_effect` | Does the choice of benchmark change the advice? | Yes for 29.6% of Rest of NSW cells and 13.8% of Greater Sydney cells |
| 4 | [`07_unusual_movements.sql`](07_unusual_movements.sql) → `mart_movement_screen` | Which movements are unusual, and can we trust them? | 10 flags at 10 pp: 7 stable, 3 "check data" |
| 5 | [`business_questions/bq6_decision_support.sql`](business_questions/bq6_decision_support.sql) → `bq6_research_shortlist` | Where should the team research next, and why? | Priority A (market signal) / B (data check first), each with a plain-English reason |

## Supplementary technical files

| File | Purpose | SQL techniques |
|---|---|---|
| [`01_stg_lodgements.sql`](01_stg_lodgements.sql) | Staging and data quality | `TRY_CAST`, boolean quality flags, potential duplicates with `COUNT(*) OVER` / `ROW_NUMBER() OVER` and a named `WINDOW` — no rows deleted |
| [`05_region_kpis.sql`](05_region_kpis.sql) | Regional marts for BQ1, BQ2, BQ7 | `UNION ALL` to stack NSW + region levels, `GROUPING SETS`, record-level `QUANTILE_CONT`, `LAG(…, 12)` with a date check for YoY |
| [`09_validation.sql`](09_validation.sql) | 14 validation checks | One `UNION ALL` result: totals add up, a benchmark recomputed from records, rule violations = 0 |
| [`business_questions/bq1_rental_trends.sql`](business_questions/bq1_rental_trends.sql) | BQ1 | Headline change, monthly trend, YoY, Jan–Feb seasonality |
| [`business_questions/bq4_unusual_movements.sql`](business_questions/bq4_unusual_movements.sql) | BQ4 | Threshold test (5/10/15 pp), normal variation, flagged list |
| [`business_questions/bq5_distribution_composition.sql`](business_questions/bq5_distribution_composition.sql) | BQ5 | Spread, rent heaping, share of lodgements exactly at the median; mix index (supplementary) |
| [`business_questions/bq7_lodgement_activity.sql`](business_questions/bq7_lodgement_activity.sql) | BQ7, AQ8 | Activity by dwelling type, core-sample share, growth of "Other" by postcode |

## Dependencies (why the scripts do not run on their own)

**Included here** = created by a file in this folder. **Private** = created by a pipeline step that is not published.

| Object | Created by | Used by |
|---|---|---|
| `raw_lodgements_monthly` | **Private** — loads the 25 monthly Excel files | 01 |
| `stg_lodgements` | Included — 01 | 09 |
| `fct_lodgements` | **Private** (step 04) — view on `stg_lodgements` adding `period` (Base/P1/P2) and `region` | 05, 06, 07, 09, bq7 |
| `dim_date`, `dim_segment` | **Private** (step 04) — month → period lookup; segment sort order | bq1, bq2 |
| `dim_postcode` region mapping | **Private** — postcode → Greater Sydney / Rest of NSW from ABS files (≥ 90% rule, see [Methodology](../docs/Methodology.md#4-regions-greater-sydney--rest-of-nsw)) | via `fct_lodgements` |
| `v_geo_lodgements`, `mart_region_*` | Included — 05 | 06, 09, bq1, bq2, bq3, bq5, bq7 |
| `mart_postcode_cell`, `mart_postcode_benchmark`, `mart_postcode_change` | Included — 06 | 07, 09, bq3 |
| `mart_postcode_change_dedup`, `mart_movement_screen`, `mart_screen_threshold_sensitivity` | Included — 07 | 09, bq4, bq6 |
| `mart_geo_mix`, `mart_mix_index` | **Private** (step 08, mix analysis) | bq2 (`bq2_geo_mix`), bq5 (`bq5_mix_index`), 09 (checks 7) |
| `kpi_monthly` | **Private** (step 02, earlier feasibility stage) | 09 (check "NSW monthly medians equal kpi_monthly") |

Run order inside the project: 01 → *(private 02–04)* → 05 → 06 → 07 → *(private 08)* → 09 → `business_questions/`.

## Internal references in comments

Because the files are unchanged, a few comments point to things that are not in this repository:

| File · line | Comment says | Meaning |
|---|---|---|
| `business_questions/bq1_rental_trends.sql` · 2 | "marts built by `sql/05`" | [`05_region_kpis.sql`](05_region_kpis.sql) in this folder |
| `business_questions/bq1_rental_trends.sql` · 2 | "exported to `reports/analysis/<name>.csv`" | In the project each `-- name:` result was saved as a CSV in a private output folder and reconciled with Power BI. The results are summarised in [Findings](../docs/Findings_and_Recommendations.md) |
| `07_unusual_movements.sql` · 3 | "proposed in the design" | The screening rule proposed in the project's dashboard design (see [Methodology §6](../docs/Methodology.md#6-screening-unusual-movements-bq4--sql07_unusual_movementssql)) |
| `07_unusual_movements.sql` · 9 | "sensitivity scenario B" | Scenario B = keep only the first row of each group of identical records (scenario A = keep all rows) |
| `09_validation.sql` · 2, 14, 23 | "already-approved number", "approved feasibility KPIs", "feasibility mart" | The NSW medians ($690 / $720) and `kpi_monthly` were produced and reviewed in an earlier feasibility stage; this check proves the final marts did not change them |

## Conventions

- Every median and percentile is computed from individual lodgements; a median of medians is never used.
- Marts keep full precision; rounding happens only in presentation queries.
- Each `-- name:` block in `business_questions/` is one result set.
