# KPI Dictionary

**Applies to every KPI**
- Rent KPIs use the **core sample**: dwelling type Flat/Unit, House or Terrace/Townhouse, a known number of bedrooms, and weekly rent > 0.
- Count KPIs use **every row** (every bond lodged).
- Every median and percentile is computed from **individual lodgements** (`QUANTILE_CONT` in SQL, `PERCENTILE.INC` in DAX — the same linear interpolation). A median of medians is never used.
- **Type** shows where a number comes from: *Direct* = computed from the data · *Comparison* = compares two Direct numbers · *Adjusted* = depends on a modelling assumption · *Sensitivity* = measures stability.

| KPI | Type | Definition / formula | Grain | Computed in | Interpretation and caveats |
|---|---|---|---|---|---|
| **Bond Lodgement Count** | Direct | `COUNT(*)` of all rows | Month / period × region × postcode | DAX (SQL for reconciliation) | Number of new tenancies with a bond. **Not** rental supply or vacancy |
| **Valid Sample Size (n)** | Direct | `COUNT(*)` of core-sample rows | Every reported cell | DAX + SQL | Shown with every median. Tier: ≥ 100 *Reliable* · 30–99 *Small sample* · < 30 *Not reported* |
| **Median Weekly Rent** | Direct | Median of `weekly_rent`, core sample | Any filter context | **DAX** (dynamic); SQL to verify | Main KPI. Moves in steps because of rent heaping |
| **Rent P25 / P75** | Direct | 25th / 75th percentile | As median | DAX | Range of the middle 50% of lodgements |
| **Rent P40 / P60** | Direct | 40th / 60th percentile | As median | DAX / SQL | Extra information about the distribution around the median. **Not a confidence interval** |
| **P1 → P2 Change %** | Comparison | `Median P2 / Median P1 − 1` (P1 = Sep 2024–Aug 2025, P2 = Sep 2025–Aug 2026) | Region × segment; postcode × segment | DAX + SQL | Headline change: each period covers every season once |
| **YoY %** | Comparison | `Median(m) / Median(m − 12) − 1`, only when month m − 12 is in scope | Month × region | DAX + SQL | Only 13 months (Aug 2025–Aug 2026). Noisy; use for direction only |
| **Regional Benchmark** | Direct | Median of **all lodgements** in the same region × segment × period | Region × segment × period | SQL (mart); DAX removes the postcode filter and keeps the region filter | Never a median of postcode medians |
| **Local Rent Premium %** | Comparison | `Postcode median / Regional benchmark − 1` | Postcode × segment × period | SQL (mart) + DAX | Greater Sydney and Rest of NSW only; shown when n ≥ 30. A relative price level, **not** a quality-adjusted valuation |
| **Property Mix Share %** | Direct | n of a segment / n of the region × period | Region × period | SQL + DAX | Composition by dwelling type × bedrooms |
| **Geographic Mix %** | Direct | n of a region / n of NSW, by dwelling type | Dwelling type × period | SQL | Example: 87.1% of flat lodgements are in Greater Sydney (P2) |
| **Mix-adjusted Change %** *(supplementary)* | **Adjusted** | `Σ(w_P1 × median_stratum_P2) / Σ(w_P1 × median_stratum_P1) − 1` | NSW / region | SQL | "What if the mix had stayed as in P1?" **Not a median**; do not compare directly with the pooled median change |
| **Composition Effect (pp)** *(supplementary)* | **Adjusted** | `[Σ(w_P2 × m_P2) − Σ(w_P1 × m_P2)] / Σ(w_P1 × m_P1)`, inside one index model | NSW / region | SQL | Effect of the mix change within the index model. NSW, strata region × type × bedrooms: −0.17 pp |
| **Deviation (pp)** | Comparison | Postcode change % − change % of its region, same segment | Postcode × segment | SQL | Used to screen movements |
| **Duplicate Sensitivity (pp)** | Sensitivity | \|change keeping only the first row of each identical group − original change\| | Postcode × segment | SQL | < 2 pp = stable. It does **not** prove which rows are true duplicates |
| **P25 Gap (pp)** | Sensitivity | \|P25 change − median change\| | Postcode × segment | SQL | ≥ 10 pp: the low end of the market moved differently from the median |
| **Screen Result** | Classification | *Unusual* if \|deviation\| ≥ 10 pp and n ≥ 100 in both periods; then labelled *stable* or *check composition / data* | Postcode × segment | SQL | A reason to investigate, **not** a conclusion |
| **Region** | Dimension | Greater Sydney / Rest of NSW when ≥ 90% of the postcode's 2021 dwellings fall in that region; otherwise *Mixed*; no postal area → *Unmapped* | Postcode | SQL (`dim_postcode`) | ABS ASGS 2021. Greater Sydney includes the Central Coast and the Blue Mountains |
