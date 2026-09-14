# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

HARMONY Terlipressin **Liver Transplant** sub-project — 1-year extended follow-up (EFU) of transplant listing, liver transplantation, RRT, readmission and survival in HRS-AKI patients treated with terlipressin. Shared context (master dataset, shared pipeline, derived variables, coding conventions) lives in the parent `CLAUDE.md` one level up and applies here.

## Data Sources

| Source | Path | Notes |
|:--|:--|:--|
| Master dataset | `/Users/to909/Desktop/Terlipressin projects/Terlipressin/data/final_master_01282026.xlsx` (via shared pipeline) | n = 243, locked |
| EFU site files | `/Users/to909/Partners HealthCare Dropbox/Tianqi Ouyang/Extended Data Collection/Finalized Files/09SEP2026/*_09092026.csv` | 13 sites, 222 rows, 42 columns; no dates (only `efu_days*` counts from index admission) |
| EFU data dictionary | `EFU_DataDictionary.csv` (repo root) | REDCap export; rendered on the *EFU Variables* page |

**Never commit patient-level data.** The EFU CSVs and the master xlsx are loaded by absolute path at render time; `.gitignore` blocks `data/` and `*.xlsx`. The GitHub repo is public.

## Cohort & Join

- EFU rows are joined to `master` on a **normalized study ID** (`id_key`: upper-case prefix + integer; `YAL` → `YALE`) because the EFU export formats Yale IDs as `YAL-00N` while the master uses `Yale-N`.
- 222 EFU rows → **221** analyzable patients: one CCF row is not in the master; the 22 CSF master patients have no EFU file (`MCX` = Mayo + MCM).
- `listed_transplant` (index hospitalization, shared pipeline) and `efu_listingstatus` (any time ≤ 1 yr, EFU) are different stratifiers — see the cross-tab in `docs/analysis.qmd`.

## Analysis Scope (`docs/analysis.qmd`)

| # | Output | Stratifier | Rows |
|:--|:--|:--|:--|
| 1 | Demographics Table 1 | `efu_listingstatus` | 40 baseline / treatment variables incl. `map_day0_avg`, `total_albumin` |
| 2 | EFU summary | `listed_transplant` | all 40 EFU fields |
| 3 | EFU summary | `efu_listingstatus` | same minus stratifier |

Tables use the shared pipeline's `create_table_one()` (table1 HTML + tableone CSV in `docs/tables/`).

## Data Caveats

- `map_terli_day0_time0..3` contain `0` placeholders; `map_day0_avg` recodes `0` → `NA` before averaging.
- The shared pipeline's `mean_map_day0` collides with a same-named column in the master xlsx and comes out as `mean_map_day0.x` / `.y` — do not reference it; use `map_day0_avg`.
- `albumintotal_terli_dayN` = grams of albumin **given** on day N (→ `total_albumin`); `alb_terli_dayN` = **serum** albumin. The legacy `.Rmd`s confused the two.
- One `efu_lttbili` value is a below-detection string; `parse_number()` keeps the limit value.

## Repository Layout

| Path | Description |
|:---|:---|
| `docs/analysis.qmd` | Canonical analysis — sources the shared pipeline |
| `docs/index.qmd` | Project summary page |
| `docs/efu_variables.qmd` | EFU data dictionary page |
| `docs/_quarto.yml` | Site config |
| `docs/{redcap,derived}_variables.qmd` | Symlinks to the main project's variable dictionaries |
| `docs/tables/` | CSV table outputs |
| `Code/*.Rmd` | Legacy analyst scripts (Sep–Nov 2025) — superseded; the errors found in them are listed at the top of `docs/analysis.qmd` |
| `Requests/*.docx` | Original analysis request documents |
| `Results/` | Legacy outputs |

## Rendering & Git

```bash
# Render the Quarto site (outputs to docs/_site/)
quarto render docs/

# Publish to GitHub Pages (builds into the gh-pages branch)
quarto publish gh-pages docs/ --no-prompt --no-browser
```

The GitHub remote is <https://github.com/Tianqi-Ouyang/Terli-liver-transplant.git>; the site is served from the `gh-pages` branch.
