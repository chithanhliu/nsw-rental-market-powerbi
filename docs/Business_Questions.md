# Business Questions & Requirements

## Business problem

A property consultancy (hypothetical) advises investors, landlords and tenants in New South Wales. It needs to:

1. **compare rents between areas fairly** (like-for-like),
2. **spot unusual rent movements** worth investigating, and
3. **know when a number is reliable enough** to put in front of a client.

### Why this is not a simple "median by area" exercise

- **The NSW-wide median misleads.** Across NSW a house ($700/week) looks cheaper than a flat ($740). Inside each region the opposite is true: Greater Sydney $795 vs $770, Rest of NSW $600 vs $470 (Simpson's paradox). Comparisons must be made within the same region and segment.
- **A large movement is not necessarily a real price change.** Postcode 2008, House 1-bed rose +73%; the figure falls to +34% if potential duplicate records are removed, and to +4.4% if lodgements of $400 or less are excluded.
- **Medians jump between round numbers (rent heaping).** A difference of 0.16% of records is enough to move the NSW median by $10.

## Users

| User | Needs | Decision supported |
|---|---|---|
| Consultant (primary) | Benchmark an area against comparable areas, with a reliability level | Advise on rent levels; choose areas to invest in or to rent |
| Manager / client | The overall picture in a few minutes | Which areas to research further |
| Analyst | A screened list of unusual movements with stability checks | Build a further-research shortlist |

## Requirements

**Functional**
1. Track rents of **new** bonds: median, P25/P75, period-on-period change (P1 → P2) and year-on-year change where a base month exists.
2. Compare by **Region × Dwelling Type × Bedrooms**, and compare each postcode with the benchmark of its own region and segment.
3. Screen **unusual movements** with sample-size and sensitivity checks.
4. **Drill through** from overview pages to a single postcode.
5. Show **data limitations** on the dashboard itself (new bonds only, not vacancy or supply; sample-size thresholds).

**Non-functional**
- Every KPI shown in Power BI is reconciled against an independent SQL calculation.
- Fixed scope: August 2024 – August 2026. No causal claims.
- The main message of the overview page should be readable in about 60 seconds.

**Out of scope:** forecasting, vacancy rates, rental supply, LGA/suburb mapping, boundary maps, additional data sources.

## Business questions → KPIs → dashboard pages

| # | Business question | Main KPIs | Dashboard page |
|---|---|---|---|
| **BQ1** | How did rents of new bonds change over time? | Median weekly rent, P25/P75, P1 → P2 change (with P40/P60), YoY (13 months) | 1 Executive Overview · 3 Rent Change & Distribution |
| **BQ2** | How do rents differ by region, dwelling type and bedrooms? | Median by segment, valid sample size, geographic mix | 2 Market Structure |
| **BQ3** | Which postcodes are above or below the benchmark of the **same region and segment**? | Regional benchmark, local rent premium, reliability tier | 4 Location Benchmarking · 6 Postcode Profile |
| **BQ4** | Which postcode × segment cells moved unusually, and is the movement stable? | Deviation from region (pp), duplicate sensitivity, P25 gap | 5 Unusual Movements · 6 Postcode Profile |
| **BQ5** | Do distribution shape, rent heaping and property mix change how the trend should be read? | P40/P60, share of rents on $50 multiples, mix-adjusted index (supplementary) | 3 Rent Change & Distribution · 7 Data & Methodology |
| **BQ6** | Which areas or movements deserve further research, and why? | Research shortlist (priority A / B) | 5 Unusual Movements |
| **BQ7** | How did the number of new bond lodgements change by period and region? | Lodgement count, P1 → P2 change | 1 Executive Overview |

**Additional analytical question (AQ8):** where is the growth of dwelling type "Other" in Greater Sydney concentrated? (Answered in [Findings](Findings_and_Recommendations.md#bq7--lodgement-activity).)

## Analytical flow of the dashboard

What happened (page 1) → Market structure (2) → Rent change and distribution (3) → Location benchmarking (4) → Unusual movements (5) → Investigation of one postcode (6, drill-through) → How far the numbers can be trusted (7).
