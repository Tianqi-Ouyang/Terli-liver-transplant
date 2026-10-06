# ---------------------------------------------------------------------------
# Export the full Liver Transplant analysis dataset
#
# Builds the same dataset docs/analysis.qmd uses -- master (shared pipeline)
# + the 09SEP2026 EFU site files + this project's derived variables -- and
# writes it to ONE workbook plus an .rds companion.
#
# PATIENT-LEVEL OUTPUT: everything is written to `data/`, which .gitignore
# blocks. Never move these files into docs/, Results/ or any commit.
#
# Run:  Rscript "Code/export_analysis_data.R"    (from the project root)
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(writexl)
})

proj     <- "/Users/to909/Desktop/Terlipressin projects/Liver transplant"
master_x <- "/Users/to909/Desktop/Terlipressin projects/Terlipressin/data/final_master_01282026.xlsx"
pipeline <- "/Users/to909/Desktop/Terlipressin projects/Terlipressin/code/shared_pipeline.qmd"
efu_dir  <- "/Users/to909/Partners HealthCare Dropbox/Tianqi Ouyang/Extended Data Collection/Finalized Files/09SEP2026"
out_dir  <- file.path(proj, "data")
stamp    <- format(Sys.Date(), "%m%d%Y")

dir.create(out_dir, showWarnings = FALSE)

# -- 1. Variable provenance: the xlsx exactly as it sits on disk -------------
# NOTE: the master xlsx was itself written by the main project's Tables.Rmd, so
# it already CONTAINS the derived variables. The shared pipeline therefore adds
# almost no new column names -- it recomputes existing ones in place. Provenance
# is worked out below by comparing values, not just names.
raw_master <- read_excel(master_x)
raw_names  <- names(raw_master)

# Curated list of pipeline-derived variables (parent CLAUDE.md), used together
# with the value comparison so a variable is labelled derived even when the
# recomputation happens to reproduce the stored value exactly.
known_derived <- c(
  "baseline_scr_calculated", "baseline_scr_new", "baseline_scr_new_2", "eGFR", "ckd_baseline",
  "ratio", "delta", "akin", "discont_ratio", "discont_delta", "discont_aki_stage", "difference",
  "day0_meld", "day0_meld_na", "day0_meld_3", "admit_meld", "admit_meld_na", "admit_meld_3",
  "child_pugh_score", "clif_c_score", "clif_c_score_new", "aclf_grade", "organ_failure_sum",
  "liver_f", "brain_f", "coagulation_f", "circulatory_f", "respiratory_f", "kidney_f",
  "lowest_creatinine", "HRS_reversal_new", "hrs_responders", "hrs_responders_cat_2", "hrs_rebound",
  "time_to_death", "time_to_death_status", "time_to_death_90days", "time_to_death_status_90days",
  "time_to_death_90days_cmp", "time_to_death_status_90days_cmp",
  "transplant_lt", "transplant_lt_status", "time_to_transplant_cmp", "transplant_outcome",
  "listed_transplant", "Discont_Day", "dosechange_day", "dosechange_status", "mean_map_day0",
  "total_albumin", "terli_ae_respfail", "any_ae", "terli_7", "terli_8",
  paste0("criteria_", 1:5), "HRS_Criteria", "HRS_criteria_3", "HRS_criteria_meld",
  "race_2", "rrt_2", "fena", "bili_cal", "transplant_slkt",
  "last_scr", "last_scr_2", "discont_reason_terli", "time_to_dosechange",
  "dc_days_to_death", "after_discharge_90days_death_status", "admit_meld_3_raw", "hispanic"
)

# -- 2. Shared pipeline: `master` with all standard derived variables --------
source(knitr::purl(pipeline, output = tempfile(fileext = ".R"), quiet = TRUE))
master <- ungroup(master)

new_names <- setdiff(names(master), raw_names)

# Which shared columns did the pipeline actually change? Compare on the study
# ID so row order cannot matter; numeric columns with a tolerance.
changed_by_pipeline <- function(col) {
  a <- raw_master[[col]][match(master$subjectid, raw_master$subjectid)]
  b <- master[[col]]
  an <- suppressWarnings(as.numeric(as.character(a)))
  bn <- suppressWarnings(as.numeric(as.character(b)))
  if (!all(is.na(an) == is.na(a)) || !all(is.na(bn) == is.na(b))) {
    a <- trimws(as.character(a)); b <- trimws(as.character(b))
    any(xor(is.na(a), is.na(b)) | (!is.na(a) & !is.na(b) & a != b))
  } else {
    any(xor(is.na(an), is.na(bn)) |
          (!is.na(an) & !is.na(bn) & abs(an - bn) > 1e-8))
  }
}
shared_cols   <- intersect(raw_names, names(master))
recomputed    <- shared_cols[map_lgl(shared_cols, changed_by_pipeline)]
pipeline_names <- union(new_names, union(recomputed, intersect(known_derived, shared_cols)))

# -- 3. EFU site files (same import as docs/analysis.qmd) --------------------
norm_id <- function(x) {
  x      <- str_trim(x)
  prefix <- toupper(str_extract(x, "^[A-Za-z]+"))
  prefix <- if_else(prefix == "YAL", "YALE", prefix)   # YAL-00N vs Yale-N
  number <- as.integer(str_extract(x, "[0-9]+$"))
  paste0(prefix, "-", number)
}

efu_yesno <- c(
  "codestatus", "efu_readmit", "efu_readmit_cirrhosiscomp", "efu_readmitaki",
  "efu_status", "efu_rrt", "efu_listingstatus", "efu_listing", "efu_lt",
  "efu_slkt", "efu_kal", "efu_ltrrt", "efu_90_rrt", "efu_90lt_rrt",
  "efu_180_rrt", "efu_180lt_rrt", "efu_1yr_rrt", "efu_1yrlt_rrt"
)
efu_numeric <- c(
  "efu_daysreadmit", "efu_readmitscr", "efu_dayslastencounter", "efu_daysdod",
  "efu_daysrrtstart", "efu_dayslisting", "efu_dayswlremoval", "efu_dayslt",
  "efu_dayskal", "efu_ltna", "efu_lttbili", "efu_ltscr", "efu_lt_albumin",
  "efu_lt_inr", "efu_90_scr", "efu_90_readmit", "efu_90lt_scr", "efu_180_scr",
  "efu_180_readmit", "efu_180lt_scr", "efu_1yr_scr", "efu_1yr_readmit",
  "efu_1yrlt_scr"
)

efu_raw <- list.files(efu_dir, pattern = "_09092026\\.csv$", full.names = TRUE) %>%
  set_names(~ str_remove(basename(.x), "_09092026\\.csv$")) %>%
  map_dfr(~ read_csv(.x, col_types = cols(.default = col_character()),
                     show_col_types = FALSE), .id = "efu_center") %>%
  mutate(
    id_key = norm_id(subjectid),
    across(all_of(efu_yesno), as.integer),
    # parse_number() keeps below-detection strings such as "<0.2" (-> 0.2)
    across(all_of(efu_numeric), readr::parse_number)
  ) %>%
  rename(efu_subjectid = subjectid)

efu_names <- setdiff(names(efu_raw), "id_key")

# -- 4. Project-derived variables -------------------------------------------
map_cols <- paste0("map_terli_day0_time", 0:3)
alb_g    <- paste0("albumintotal_terli_day", 0:13)
alb_yn   <- paste0("albumin_terli_day", 0:13)

master <- master %>%
  mutate(
    id_key = norm_id(subjectid),

    # Day-0 MAP: a recorded 0 mmHg means "not measured", so blank it first.
    across(all_of(map_cols), ~ na_if(as.numeric(.x), 0)),
    map_day0_avg = rowMeans(across(all_of(map_cols)), na.rm = TRUE),
    map_day0_avg = if_else(is.nan(map_day0_avg), NA_real_, map_day0_avg),
    map_day0_n_readings = rowSums(!is.na(across(all_of(map_cols)))),

    # QC flag for total_albumin (shared pipeline: sum of albumintotal_terli_day0..13
    # with na.rm = TRUE). Albumin was recorded as given on some day but the grams
    # were never entered, so this patient's 0 g is missing data, not a true zero.
    total_albumin_incomplete = if_else(
      rowSums(across(all_of(alb_yn), ~ as.numeric(.x) == 1), na.rm = TRUE) > 0 &
        rowSums(!is.na(across(all_of(alb_g)))) == 0,
      1, 0
    ),
    albumin_days_recorded = rowSums(!is.na(across(all_of(alb_g))))
  )

project_names <- c("id_key", "map_day0_avg", "map_day0_n_readings",
                   "total_albumin_incomplete", "albumin_days_recorded",
                   "efu_available", "in_analysis_cohort", "in_table1_cohort")

# -- 5. Merge: keep all 243 master patients, flag who has EFU data -----------
analysis_data <- master %>%
  left_join(efu_raw, by = "id_key") %>%
  mutate(
    efu_available      = if_else(id_key %in% efu_raw$id_key, 1, 0),
    in_analysis_cohort = efu_available,                                  # Table 2
    in_table1_cohort   = if_else(efu_available == 1 &
                                   !is.na(efu_listingstatus), 1, 0)      # Tables 1 & 3
  ) %>%
  relocate(subjectid, id_key, efu_center, efu_subjectid,
           efu_available, in_analysis_cohort, in_table1_cohort)

# EFU rows with no matching master patient (kept so nothing is lost)
efu_unmatched <- efu_raw %>% filter(!id_key %in% master$id_key)

# -- 6. Variable dictionary --------------------------------------------------
source_of <- function(v) {
  case_when(
    v %in% project_names  ~ "4. project derived (this script / analysis.qmd)",
    v %in% efu_names      ~ "3. EFU site files (09SEP2026)",
    v %in% pipeline_names ~ "2. derived (in xlsx, recomputed by shared pipeline)",
    v %in% raw_names      ~ "1. master xlsx (REDCap field)",
    TRUE                  ~ "other"
  )
}

variable_dictionary <- tibble(
  column      = names(analysis_data),
  source      = source_of(names(analysis_data)),
  class       = map_chr(analysis_data, ~ paste(class(.x), collapse = "/")),
  n_nonmissing = map_int(analysis_data, ~ sum(!is.na(.x))),
  n_missing    = map_int(analysis_data, ~ sum(is.na(.x))),
  pipeline_changed_stored_value = if_else(column %in% recomputed, "yes", "no")
) %>%
  mutate(pct_missing = round(100 * n_missing / nrow(analysis_data), 1)) %>%
  arrange(source, column)

# -- 7. Export log -----------------------------------------------------------
export_log <- tibble(
  item = c(
    "Exported (date)", "Master dataset", "Shared pipeline", "EFU source folder",
    "Master patients (rows)", "Total columns",
    "  raw REDCap fields (master xlsx)", "  derived (recomputed by shared pipeline)",
    "  EFU fields", "  project derived",
    "  of the derived: values CHANGED by this pipeline run",
    "EFU rows read", "EFU rows matched to master", "EFU rows NOT in master (sheet 2)",
    "Master patients without EFU data (CSF, no file)",
    "Analysis cohort: in_analysis_cohort == 1 (Table 2)",
    "Table 1 / 3 cohort: in_table1_cohort == 1",
    "total_albumin_incomplete == 1 (0 g is missing, not a true zero)",
    "Note"
  ),
  value = c(
    format(Sys.time(), "%Y-%m-%d %H:%M"), master_x, pipeline, efu_dir,
    nrow(analysis_data), ncol(analysis_data),
    sum(variable_dictionary$source == "1. master xlsx (REDCap field)"),
    sum(variable_dictionary$source == "2. derived (in xlsx, recomputed by shared pipeline)"),
    sum(variable_dictionary$source == "3. EFU site files (09SEP2026)"),
    sum(variable_dictionary$source == "4. project derived (this script / analysis.qmd)"),
    length(recomputed),
    nrow(efu_raw), sum(efu_raw$id_key %in% master$id_key), nrow(efu_unmatched),
    sum(!master$id_key %in% efu_raw$id_key),
    sum(analysis_data$in_analysis_cohort == 1),
    sum(analysis_data$in_table1_cohort == 1),
    sum(analysis_data$total_albumin_incomplete == 1),
    "PATIENT-LEVEL DATA - keep in data/ (gitignored). Never commit or publish."
  )
)

# -- 8. Write ----------------------------------------------------------------
# Excel cannot hold list columns; flatten any that survived the pipeline.
flatten_for_excel <- function(df) {
  df %>% mutate(across(where(is.list), ~ map_chr(.x, ~ paste(unlist(.x), collapse = "; "))))
}

xlsx_path <- file.path(out_dir, paste0("LT_EFU_analysis_data_", stamp, ".xlsx"))
rds_path  <- file.path(out_dir, paste0("LT_EFU_analysis_data_", stamp, ".rds"))

write_xlsx(
  list(
    analysis_data       = flatten_for_excel(analysis_data),
    efu_not_in_master   = flatten_for_excel(efu_unmatched),
    variable_dictionary = variable_dictionary,
    export_log          = export_log
  ),
  path = xlsx_path
)

# .rds keeps exact R types (factors, integers, NA vs "NA") for re-analysis
saveRDS(list(analysis_data = analysis_data, efu_unmatched = efu_unmatched,
             variable_dictionary = variable_dictionary, export_log = export_log),
        rds_path)

# Aggregate confirmation only - never print patient rows.
cat("Wrote:\n  ", xlsx_path, "\n  ", rds_path, "\n\n")
print(as.data.frame(export_log), right = FALSE, row.names = FALSE)
cat("\nColumns by source:\n")
print(count(variable_dictionary, source), n = Inf)
