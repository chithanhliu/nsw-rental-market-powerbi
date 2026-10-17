# Findings & Recommendations

**Data:** NSW Fair Trading rental bond lodgements, Aug 2024 – Aug 2026 (672,365 lodgements).
**Periods:** P1 = Sep 2024 – Aug 2025 · P2 = Sep 2025 – Aug 2026. Rents are weekly, core sample (flat, house, terrace with known bedrooms).

Labels used throughout:
- **Observed** — calculated and validated.
- **Hypothesis** — a possible explanation that has not been tested. The data contains no causes, so **no root cause is claimed** anywhere in this project.

---

## Executive summary

1. **Rents of new bonds rose +4.35% in NSW** (median $690 → $720, P1 → P2). Greater Sydney $750 → $780 (+4.0%); Rest of NSW $550 → $580 (+5.45%).
2. **It cannot be concluded that Rest of NSW grew faster than Greater Sydney.** The ranking reverses depending on the statistic used (P40, median, P60). After adjusting for dwelling type × bedrooms the two regions are almost equal (+4.88% vs +4.98%).
3. **Simpson's paradox.** Across NSW houses ($700) look cheaper than flats ($740); inside each region houses are more expensive (Greater Sydney $795 vs $770; Rest of NSW $600 vs $470).
4. **A regional benchmark changes the answer** to "is this area expensive?" for 29.6% of Rest of NSW cells and 13.8% of Greater Sydney cells.
5. **Screening:** 604 reliable postcode × segment cells; a 10 pp rule flags **10**, of which 7 are stable and 3 need a data/composition check.
6. **New bond lodgements fell −3.6%** (Greater Sydney −4.4%, Rest of NSW −1.4%) while rents rose. Lodgements measure new-tenancy activity, not supply.

---

## BQ1 — Rental trends

| Geography | Median P1 | Median P2 | Change | P40 change | P60 change | n P2 |
|---|---:|---:|---:|---:|---:|---:|
| NSW | $690 | $720 | **+4.35%** | +3.94% | +4.00% | 290,384 |
| Greater Sydney | $750 | $780 | **+4.00%** | +4.35% | +6.25% | 210,803 |
| Rest of NSW | $550 | $580 | **+5.45%** | +6.00% | +4.17% | 79,557 |

- **Observed:** monthly median, Greater Sydney $735 (Aug 2024) → $800 (Aug 2026); Rest of NSW $525 → $590.
- **Observed:** YoY over the 13 available months ranges from +2.9% to +7.1% for NSW.
- **Observed:** January–February medians are higher than other months **in Greater Sydney only** (P1 $750 vs $735; P2 $797.5 vs $777.5). No such pattern in Rest of NSW.
- **Hypothesis:** the Jan–Feb peak is linked to the student and moving season.

**So what:** rents of new tenancies rose about 4–6% in a year, depending on region and statistic. Month-to-month comparisons in Sydney must allow for the summer peak.

## BQ2 — Market structure

| Median P2 | NSW | Greater Sydney | Rest of NSW |
|---|---:|---:|---:|
| Flat/Unit | $740 | $770 | $470 |
| House | $700 | $795 | $600 |
| Terrace/Townhouse | $740 | $820 | $630 |

- **Observed:** 87.1% of flat lodgements are in Greater Sydney, against 56.2% of house lodgements. Flats are concentrated where rents are high, which makes the NSW-level comparison misleading.
- **Observed:** same segment, different region — Flat 2-bed $800 (Greater Sydney) vs $485 (Rest of NSW).

**So what:** never compare dwelling types at NSW level; every price table must state its region and segment.

## BQ3 — Location benchmarking

- **Observed:** reliable cells (n ≥ 100) are a minority of cells but hold most lodgements: 15.6% of Greater Sydney cells hold 75.7% of its lodgements; 7.9% of Rest of NSW cells hold 55.1%.
- **Observed:** only 42% of reliable cells are within ±10% of their benchmark.
- **Observed (Flat 2-bed, P2):** benchmark $800 in Greater Sydney, $485 in Rest of NSW. Highest premiums: 2000 ($1,380, +72.5%), 2017 ($1,200, +50%). In Rest of NSW, coastal centres sit well above the regional benchmark: 2300 Newcastle +48.5%, 2500 Wollongong +32%.
- **Observed:** using the NSW benchmark instead of the regional one flips the above/below conclusion for **29.6%** of Rest of NSW cells and **13.8%** of Greater Sydney cells.

**So what:** "is this area expensive?" can only be answered against comparable areas. The Rest of NSW benchmark is still coarse because the region mixes large coastal cities with inland towns.

## BQ4 — Unusual movements

Normal variation of the deviation from region (604 cells): P5 −4.2 pp · median +0.7 pp · P95 +6.5 pp.

| Threshold | Flagged cells | Flagged and stable |
|---:|---:|---:|
| 5 pp | 73 | 66 |
| **10 pp** | **10** | **7** |
| 15 pp | 2 | 1 |

| Postcode | Segment | Median P1 → P2 | Change | Region | Deviation | Without potential duplicates | Result |
|---|---|---|---:|---:|---:|---:|---|
| 2008 | House 1-bed | $375 → $650 | +73.3% | +4.2% | +69.2 pp | +34.2% | Check composition / data |
| 2038 | Flat 1-bed | $480 → $582.5 | +21.4% | +6.1% | +15.3 pp | +20.2% | Stable |
| 2486 | House 4+ | $950 → $1,112.5 | +17.1% | +3.6% | +13.5 pp | +18.4% | Stable |
| 2165 | Flat 2-bed | $470 → $550 | +17.0% | +5.3% | +11.8 pp | +17.0% | Stable (lodgements +50.5%) |
| 2122 | Flat 1-bed | $500 → $587.5 | +17.5% | +6.1% | +11.4 pp | +17.0% | Stable |
| 2130 | Flat 1-bed | $560 → $655 | +17.0% | +6.1% | +10.9 pp | +12.7% | Check (moves 4.3 pp without duplicates) |
| 2640 | Flat 1-bed | $280 → $320 | +14.3% | +4.1% | +10.2 pp | +14.3% | Stable (low price: one $40 step) |
| 2032 | Flat 3-bed | $1,280 → $1,200 | −6.3% | +4.6% | −10.8 pp | −6.3% | Stable |
| 2049 | Flat 2-bed | $800 → $750 | −6.3% | +5.3% | −11.5 pp | −6.3% | Stable |
| 2304 | Flat 1-bed | $400 → $370 | −7.5% | +4.1% | −11.5 pp | −10.0% | Check (P25 −20.6%) |

- **Observed:** more than 98% of reliable cells moved in line with their region.
- **Observed:** postcode 2008 House 1-bed is the clearest example of a large but unstable number: in P1, 52.6% of its lodgements were at $400 or less; in P2, 5.6%.
- **Hypothesis:** cells whose lodgement count changed strongly (2165 +50.5%, 2304 +39.1%) may contain different stock, for example a new building.

## BQ5 — Distribution and composition

- **Observed:** 48.6% of core rents are multiples of $50 (Greater Sydney 50.9%, Rest of NSW 42.5%). Medians therefore move in steps.
- **Observed:** Greater Sydney's pooled median (+4.0%) is **below** its other measures (P25 and P75 both +6.7%, mix-adjusted +4.88%); Rest of NSW's pooled median (+5.45%) is **above** its other measures. This is why the two regions cannot be ranked on the median alone.
- **Supplementary (mix-adjusted index):** within each index model, the change in mix moves the result by only −0.17 pp to +0.25 pp.

## BQ6 — Decision support (research shortlist)

| Priority | Postcode, segment | Why |
|---|---|---|
| **A. Market signal to verify** | 2038 Flat 1-bed · 2486 House 4+ · 2165 Flat 2-bed · 2122 Flat 1-bed · 2640 Flat 1-bed | Rose 10–15 pp faster than the region; stable on both checks |
| | 2032 Flat 3-bed · 2049 Flat 2-bed | Fell about 6% while the region rose about 5%; stable |
| **B. Check data / composition first** | 2008 House 1-bed | Change depends on potential duplicates (+73% vs +34%) and on a large shift in the price distribution |
| | 2130 Flat 1-bed | Change moves 4.3 pp without potential duplicates |
| | 2304 Flat 1-bed | P25 fell 20.6% against a median fall of 7.5% |
| **Context** | 2033, dwelling type "Other" | 190 → 914 lodgements (see AQ8) |

## BQ7 — Lodgement activity

| P1 → P2 | Total | Flat | House | Terrace | Other | Unknown/invalid |
|---|---:|---:|---:|---:|---:|---:|
| NSW | 326,975 → 315,128 (**−3.6%**) | −3.8% | −1.0% | −6.3% | +13.5% | −32.1% |
| Greater Sydney | 240,016 → 229,403 (**−4.4%**) | −4.1% | −2.9% | −7.1% | +18.1% | −33.9% |
| Rest of NSW | 86,916 → 85,698 (**−1.4%**) | −1.4% | +1.5% | −4.8% | −4.0% | −28.1% |

- **Observed:** seasonal peaks in February and July; the core sample is 86–95% of lodgements each month.
- **AQ8 — Observed:** in Greater Sydney, "Other" lodgements grew by 1,622; postcode **2033** alone grew by 724 (190 → 914), followed by 2008, 2016 and 2000.
- **Hypothesis:** new student accommodation or co-living. Because "Other" is excluded from rent KPIs, rent KPIs represent these inner-city postcodes less well.

---

## Recommendations

1. **Always benchmark an area against the same region and segment.** An NSW-wide benchmark gives the wrong answer for 14–30% of cells.
2. **Report rent change as "median, with the P40–P60 range", using P1 → P2.** Do not quote a single month's YoY.
3. **Do not claim that one region is growing faster.** Both regions rose about 4–6%, and the order depends on the statistic.
4. **Use the 10 pp screening rule.** Research the 7 priority-A cells with information outside this dataset (listings, new developments) before advising clients; check the data for the 3 priority-B cells first.
5. **Monitor dwelling type "Other" in inner Sydney** (2033, 2008, 2016, 2000), as it sits outside the rent KPIs.
