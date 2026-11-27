seoul_root <- Sys.getenv("SEOUL_PHASE5_ROOT", unset = "")
if (!nzchar(seoul_root)) {
  stop("Run tests through scripts/90_phase5_acceptance.R from the project root.")
}
seoul_root <- normalizePath(seoul_root, winslash = "/", mustWork = TRUE)
sys.source(file.path(seoul_root, "R", "predict.R"), envir = environment())

seoul_demo_day <- function() {
  readr::read_csv(
    file.path(seoul_root, "app", "data", "demo_forecast_inputs.csv"),
    n_max = 24L, show_col_types = FALSE, progress = FALSE
  )
}

seoul_frozen_file <- function() {
  file.path(seoul_root, "artifacts", "phase3", "final", "final_model.rds")
}
