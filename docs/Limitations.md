# Known Limitations

## Data

| Limitation | Consequence |
|---|---|
| Only **new** bonds lodged with NSW Fair Trading | Rents describe new tenancies, not all current rents. Lodgement counts measure new-tenancy activity — **not** rental supply or vacancy |
| No address, property ID or lodgement ID | Duplicates can only be flagged (10.2% of rows are identical on all fields), never confirmed; causes of movements cannot be identified |
| No floor area, age or quality | The local rent premium compares medians; it is not a quality-adjusted valuation |
| Rent heaping (48.6% of rents are multiples of $50) | Medians move in steps; small data differences can shift a median by one step |
| Year-on-year change exists for 13 months only | YoY is used for direction; P1 → P2 is the headline |
| Postcodes are self-reported, not geocoded; geography is ABS 2021 | Postcodes created or redeveloped after 2021 may be classified with older dwelling counts (risk assessed as low) |
| Rest of NSW is heterogeneous | A single regional benchmark mixes coastal cities (Newcastle, Wollongong) with inland towns |
| No LGA or suburb mapping | Results are at postcode level only |
| Dwelling type "Other" is excluded from rent KPIs | Rent KPIs represent inner-city postcodes with many rooms/co-living lodgements (e.g. 2033) less well |
| Reliability | Only 8–16% of postcode × segment cells reach n ≥ 100 (they hold most lodgements); small areas are not screened for unusual movements |

## Dashboard (V1, frozen)

| # | Limitation | Where |
|---|---|---|
| 1 | Titles, subtitles and insight text are written in **Vietnamese** (target audience: Vietnam). KPI labels are in English because the card visual drops Vietnamese diacritics in upper-case labels. All repository documentation is in English | All pages |
| 2 | **Some medians and premiums of cells with n < 30 are still shown** in the Postcode Profile segment table. The *Tier* column marks them "Not reported (n<30)", but the values are visible — this breaks the design rule "n < 30 → do not show the median" | Page 6 |
| 3 | Numbers inside titles and insight boxes are **static text** (verified against the data); they do not change with slicers | All pages |
| 4 | The segment matrix needs vertical scrolling | Page 2 |
| 5 | Single-select slicers (Period, Segment) can be cleared. Page 2 then pools P1 + P2; page 4 premium visuals go blank (guarded — no wrong numbers) | Pages 2, 4, 6 |
| 6 | The page 4 scatter is correct only when exactly one segment is selected (enforced by a benchmark filter) | Page 4 |
| 7 | No conditional formatting, tooltip pages or error bars; no mobile layout | — |
| 8 | **Refresh** is not needed to use the file (data is embedded). Refresh on another computer will fail because the data source folder is a local path; the source Parquet files are not part of this repository | Whole file |
