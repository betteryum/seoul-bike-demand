phase5_acceptance <- function() {
  started <- Sys.time()
  root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  if (!file.exists(file.path(root, "seoul-bike-demand.Rproj"))) {
    stop("Run from the independent Seoul Bike project root.", call. = FALSE)
  }
  if (!requireNamespace("testthat", quietly = TRUE) ||
      !requireNamespace("readr", quietly = TRUE)) {
    stop("This acceptance requires installed testthat and readr.", call. = FALSE)
  }

  output_dir <- file.path(root, "artifacts", "phase5", "acceptance")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  checkpoint <- path.expand("~/Desktop/seoul_phase5_tests_checkpoint.txt")
  checks <- data.frame(
    check = character(), status = character(), detail = character(),
    stringsAsFactors = FALSE
  )
  record <- function(name, condition, detail, skipped = FALSE) {
    checks[nrow(checks) + 1L, ] <<- list(
      name,
      if (skipped) "SKIP" else if (isTRUE(condition)) "PASS" else "FAIL",
      detail
    )
  }

  needed <- c(
    "R/predict.R", "configs/day_ahead_contract.yml",
    "data/splits/day_ahead_split_manifest.csv",
    "app/data/demo_forecast_inputs.csv",
    "artifacts/phase3/final/final_model.rds"
  )
  missing <- needed[!file.exists(file.path(root, needed))]
  record("required_inputs", length(missing) == 0L,
         if (length(missing)) paste(missing, collapse = ", ") else "All present")

  frozen <- c(
    "artifacts/phase3/final/final_model.rds" = "e4da864280d502584c8a899053193a58",
    "artifacts/phase3/final/test_metrics.csv" = "057d92258d98ce275acc91edc240425e",
    "artifacts/phase3/final/test_slice_audit.csv" = "2ffe9c7c551d2ffdb08aa25d04690794",
    "artifacts/phase3/final/validation_vs_test.csv" = "d2647a8ff9eb1efc54758cefefdd8e0b"
  )
  current <- unname(as.character(tools::md5sum(file.path(root, names(frozen)))))
  for (i in seq_along(frozen)) {
    record(paste0("frozen_md5_", i),
           !is.na(current[i]) && identical(current[i], unname(frozen[i])),
           paste(names(frozen)[i], "expected", unname(frozen[i]),
                 "actual", current[i]))
  }

  app_files <- c("app/app.R", "app/R/app_data.R", "app/R/mod_contract.R",
                 "app/R/mod_forecast.R", "app/R/mod_performance.R")
  if (all(file.exists(file.path(root, app_files)))) {
    app_source <- paste(unlist(lapply(file.path(root, app_files), readLines,
                                      warn = FALSE)), collapse = "\n")
    forbidden <- paste0(c("test_features", "test_predictions"), ".csv")
    found <- forbidden[vapply(forbidden, grepl, logical(1),
                              x = app_source, fixed = TRUE)]
    record("app_no_row_level_test_reference", length(found) == 0L,
           if (length(found)) paste(found, collapse = ", ") else "No forbidden references")
  } else {
    record("app_no_row_level_test_reference", FALSE, "App source missing")
  }

  forbidden_paths <- c(
    "data/modeling/test_features.csv",
    "artifacts/phase3/final/test_predictions.csv",
    "artifacts/phase1/baseline/test_predictions.csv",
    "course-recovery", ".Renviron", ".env", ".httr-oauth",
    "credentials.json"
  )
  present <- forbidden_paths[file.exists(file.path(root, forbidden_paths))]
  record("forbidden_files_absent", length(present) == 0L,
         if (length(present)) paste(present, collapse = ", ") else "None present")

  sql_files <- c("scripts/audit_sql.py", "sql/01_exact_lag_audit.sql",
                 "sql/02_development_day_audit.sql")
  python <- Sys.which("python3")
  if (!nzchar(python) || any(!file.exists(file.path(root, sql_files)))) {
    record("sql_contract_audit", FALSE,
           "python3 or independent SQL audit files are unavailable")
  } else {
    sql_output <- suppressWarnings(system2(
      python, shQuote(file.path(root, "scripts", "audit_sql.py")),
      stdout = TRUE, stderr = TRUE
    ))
    sql_status <- attr(sql_output, "status")
    if (is.null(sql_status)) sql_status <- 0L
    expected_sql <- c(
      "SQL_EXACT_LAG_FIXTURE_PASS: 2 synthetic targets",
      paste0("SQL_DEVELOPMENT_DAY_AUDIT_PASS: train=230/5520, ",
             "validation=53/1272, invalid=0")
    )
    record("sql_contract_audit",
           identical(as.integer(sql_status), 0L) &&
             identical(as.character(sql_output), expected_sql),
           paste(sql_output, collapse = " | "))
  }

  old_root <- Sys.getenv("SEOUL_PHASE5_ROOT", unset = NA_character_)
  Sys.setenv(SEOUL_PHASE5_ROOT = root)
  on.exit({
    if (is.na(old_root)) Sys.unsetenv("SEOUL_PHASE5_ROOT")
    else Sys.setenv(SEOUL_PHASE5_ROOT = old_root)
  }, add = TRUE)

  suite_logs <- character()
  groups <- c("contract", "inference-integration", "integrity", "app-boundary")
  test_directory <- file.path(root, "tests", "testthat")
  for (group in groups) {
    warnings <- character()
    error_message <- NULL
    log <- if (!dir.exists(test_directory)) {
      error_message <- "tests/testthat is missing"
      character()
    } else {
      capture.output(
        tryCatch(
          withCallingHandlers(
            testthat::test_dir(test_directory, filter = group,
                               reporter = "summary", stop_on_failure = TRUE,
                               stop_on_warning = TRUE),
            warning = function(w) {
              warnings <<- c(warnings, conditionMessage(w))
              invokeRestart("muffleWarning")
            }
          ),
          error = function(e) {
            error_message <<- conditionMessage(e)
          }
        )
      )
    }
    record(paste0("testthat_", group),
           is.null(error_message) && !length(warnings),
           if (!is.null(error_message)) error_message
           else if (length(warnings)) paste("Warnings:", paste(warnings, collapse = " | "))
           else "Passed without warnings")
    suite_logs <- c(suite_logs, paste0("## ", group), log,
                    if (!is.null(error_message)) paste("ERROR:", error_message),
                    if (length(warnings)) paste("WARNINGS:", paste(warnings, collapse = " | ")),
                    "")
  }

  passed <- all(checks$status == "PASS")
  seconds <- round(as.numeric(difftime(Sys.time(), started, units = "secs")), 2)
  readr::write_csv(checks, file.path(output_dir, "checks.csv"))
  writeLines(suite_logs, file.path(output_dir, "test_log.txt"), useBytes = TRUE)
  md <- c(
    "# Independent Phase 5 inference acceptance",
    "",
    paste("Generated:", format(Sys.time(), tz = "America/New_York", usetz = TRUE)),
    paste("R:", R.version.string),
    paste("Runtime seconds:", seconds),
    paste("Result:", if (passed) "PASS" else "FAIL"),
    paste("Checks:", sum(checks$status == "PASS"), "passed;",
          sum(checks$status == "FAIL"), "failed;",
          sum(checks$status == "SKIP"), "skipped"),
    "", "## Checks", "",
    "| Check | Status | Detail |", "|---|---|---|",
    vapply(seq_len(nrow(checks)), function(i) {
      paste0("| ", checks$check[i], " | ", checks$status[i], " | ",
             gsub("[|\r\n]", " ", checks$detail[i]), " |")
    }, character(1)),
    "", "## Scope", "",
    "Only the split manifest, outcome-free demo inputs, synthetic SQL fixture,",
    "aggregate evidence, App source, and frozen model are used.",
    "No training or locked-test row access occurs.",
    "This local testing gate does not claim independent renv restore or GitHub Actions success."
  )
  writeLines(md, file.path(output_dir, "acceptance.md"), useBytes = TRUE)
  checkpoint_lines <- c(
    "SEOUL BIKE PHASE 5 INFERENCE TESTING CHECKPOINT",
    paste("Generated:", format(Sys.time(), tz = "America/New_York", usetz = TRUE)),
    paste("R:", R.version.string),
    paste("Runtime seconds:", seconds),
    paste("Result:", if (passed) "PASS" else "FAIL"),
    "", capture.output(print(checks, row.names = FALSE)),
    "", "SUITE LOG", suite_logs,
    "", "SESSION", capture.output(utils::sessionInfo()),
    "", "LOCKED TEST ROW FILES OPENED: NO",
    "MODEL REFIT OR TRAINING: NO",
    "COMMIT/PUSH/PUBLISH AUTHORIZED: NO"
  )
  writeLines(checkpoint_lines, checkpoint, useBytes = TRUE)
  cat(paste(checkpoint_lines, collapse = "\n"), "\n", sep = "")
  cat("Checkpoint: ", checkpoint, "\n", sep = "")
  if (!passed) stop("Phase 5 testing gate failed; upload checkpoint.", call. = FALSE)
  invisible(checks)
}

phase5_acceptance()
