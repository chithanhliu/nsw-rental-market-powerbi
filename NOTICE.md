# Notice — Data Sources, Attribution and Licensing

This repository contains two kinds of material, under different terms:

| Material | Where | Terms |
|---|---|---|
| **Third-party data** (NSW Fair Trading, Australian Bureau of Statistics), transformed by this project | Embedded in `NSW_Rental_Market_Dashboard.pbix`; summarised in `docs/` and `screenshots/` | **CC BY 4.0** — conditions below |
| **Project work** (SQL, documentation, dashboard design, DAX measures) | `sql/`, `docs/`, `README.md`, the report design inside the `.pbix` | See [Project work](#project-work) |

## Third-party data

The data in this repository has been transformed (typed, flagged, aggregated and joined). It is **not an official publication** of either source, and **neither source endorses** this project. Under CC BY 4.0 anyone reusing this data must keep the attributions below, link to the licence (https://creativecommons.org/licenses/by/4.0/) and indicate that changes were made.

### NSW Fair Trading — Rental Bond Lodgements

- **Content used:** monthly residential rental bond lodgement files, August 2024 – August 2026 (lodgement date, postcode, dwelling type, bedrooms, weekly rent). No names, addresses or personal identifiers are included in the source or in this project.
- **Publisher:** NSW Fair Trading, NSW Government — https://www.nsw.gov.au/housing-and-construction/rental-forms-surveys-and-data/rental-bond-data
- **Licence:** Creative Commons Attribution 4.0 (CC BY 4.0), under the NSW Government website copyright terms (https://www.nsw.gov.au/copyright), where the files are published; the Data.NSW catalogue also lists the dataset as Creative Commons Attribution (https://data.nsw.gov.au/data/dataset/rental-bond-lodgement)
- **Attribution:** © State of New South Wales. Licensed under Creative Commons Attribution 4.0. For current information go to www.nsw.gov.au.
- **Changes made:** data types converted, quality flags added, postcodes classified into regions, records aggregated into medians, percentiles and counts.
- **Source note:** values are as provided by the agent or landlord at the time of lodgement.

### Australian Bureau of Statistics — geography

- **Content used:** Australian Statistical Geography Standard (ASGS) Edition 3 (July 2021 – June 2026) Mesh Block and Postal Area allocation files; Census of Population and Housing 2021 Mesh Block Counts (dwellings).
- **Publisher:** Australian Bureau of Statistics — https://www.abs.gov.au
- **Licence:** Creative Commons Attribution 4.0 International (CC BY 4.0), per https://www.abs.gov.au/website-privacy-copyright-and-disclaimer
- **Attribution:** Source: Australian Bureau of Statistics, *Australian Statistical Geography Standard (ASGS) Edition 3* and *Census of Population and Housing 2021, Mesh Block Counts*, licensed under CC BY 4.0.
- **Changes made:** dwelling counts aggregated from mesh blocks to postal areas to assign each postcode to Greater Sydney or Rest of NSW (≥ 90% rule).

### Used for validation only — not redistributed

- **NSW Department of Communities and Justice (DCJ) Rent Tables** were used only to check the project's figures. No DCJ data is included in this repository or in the Power BI file; only summary comparison results (for example, the percentage of postcodes with a matching median) are reported.

## Project work

No open-source licence has been applied to the project's own work (SQL, documentation, dashboard design) at this stage, so all rights are reserved by the author. You are welcome to view, download and open the files for evaluation. A licence for the SQL may be added later; it would not change the CC BY 4.0 terms of the third-party data above.
