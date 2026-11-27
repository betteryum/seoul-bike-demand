find_seoul_repo_root <- function(start = getwd()) {
  criterion <- rprojroot::has_file("seoul-bike-demand.Rproj")

  tryCatch(
    normalizePath(
      rprojroot::find_root(criterion, path = start),
      winslash = "/",
      mustWork = TRUE
    ),
    error = function(e) {
      stop(
        "Could not locate the Seoul Bike repository root: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )
}

.app_read_csv <- function(path, label) {
  if (!file.exists(path)) {
    stop(label, " file does not exist: ", path, call. = FALSE)
  }

  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE
  )
}

.app_require_columns <- function(data, required, label) {
  missing_columns <- setdiff(required, names(data))

  if (length(missing_columns) > 0L) {
    stop(
      label, " is missing columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

app_demo_input_columns <- function() {
  c(
    "split",
    "target_date",
    "hour",
    "issue_timestamp",
    "weekday",
    "weekend",
    "holiday_indicator",
    "lag_48",
    "lag_168",
    "hour_of_week_mean",
    "same_hour_mean_7d",
    "same_hour_mean_28d",
    "hour_sin",
    "hour_cos",
    "day_of_year_sin",
    "day_of_year_cos"
  )
}

validate_demo_inputs <- function(data) {
  .app_require_columns(
    data,
    app_demo_input_columns(),
    "Demo forecast input"
  )

  prohibited_columns <- c(
    "rented_bike_count",
    "RENTED_BIKE_COUNT",
    "prediction",
    "residual"
  )
  present_prohibited <- intersect(prohibited_columns, names(data))

  if (length(present_prohibited) > 0L) {
    stop(
      "Demo forecast input contains prohibited outcome columns: ",
      paste(present_prohibited, collapse = ", "),
      call. = FALSE
    )
  }

  if (nrow(data) != 6792L) {
    stop("Demo forecast input must contain 6,792 rows.", call. = FALSE)
  }
  if (!setequal(unique(data$split), c("train", "validation")) ||
      any(data$split == "test")) {
    stop("Demo forecast input crossed the development boundary.", call. = FALSE)
  }
  if (anyNA(data[app_demo_input_columns()])) {
    stop("Demo forecast input contains missing values.", call. = FALSE)
  }

  date_values <- sort(unique(as.character(data$target_date)))

  if (length(date_values) != 283L) {
    stop("Demo forecast input must contain 283 development days.", call. = FALSE)
  }

  complete_days <- vapply(
    date_values,
    function(date_text) {
      current <- data[as.character(data$target_date) == date_text, , drop = FALSE]
      hours <- sort(unique(as.integer(current$hour)))

      nrow(current) == 24L &&
        identical(hours, 0:23) &&
        length(unique(current$issue_timestamp)) == 1L
    },
    logical(1)
  )

  if (!all(complete_days)) {
    stop("At least one demo date is not a complete 24-hour day.", call. = FALSE)
  }

  invisible(TRUE)
}

load_shiny_resources <- function(repo_root, inference_environment) {
  required_inference_functions <- c(
    "load_seoul_model",
    "predict_seoul_day_ahead",
    "format_seoul_prediction_display"
  )

  missing_functions <- required_inference_functions[
    !vapply(
      required_inference_functions,
      exists,
      logical(1),
      envir = inference_environment,
      inherits = FALSE
    )
  ]

  if (length(missing_functions) > 0L) {
    stop(
      "Inference environment is missing functions: ",
      paste(missing_functions, collapse = ", "),
      call. = FALSE
    )
  }

  demo_inputs <- .app_read_csv(
    file.path(repo_root, "app", "data", "demo_forecast_inputs.csv"),
    "Demo forecast input"
  )
  demo_inputs$target_date <- as.Date(demo_inputs$target_date)
  validate_demo_inputs(demo_inputs)

  test_metrics <- .app_read_csv(
    file.path(repo_root, "artifacts", "phase3", "final", "test_metrics.csv"),
    "Aggregate test metrics"
  )
  slice_audit <- .app_read_csv(
    file.path(repo_root, "artifacts", "phase3", "final", "test_slice_audit.csv"),
    "Aggregate slice audit"
  )
  validation_vs_test <- .app_read_csv(
    file.path(repo_root, "artifacts", "phase3", "final", "validation_vs_test.csv"),
    "Validation versus test comparison"
  )

  .app_require_columns(
    test_metrics,
    c("model", "metric", "estimate"),
    "Aggregate test metrics"
  )
  .app_require_columns(
    slice_audit,
    c("dimension", "slice", "n", "rmse", "mae", "mean_error"),
    "Aggregate slice audit"
  )
  .app_require_columns(
    validation_vs_test,
    c("split", "model", "metric", "estimate"),
    "Validation versus test comparison"
  )

  if (nrow(test_metrics) != 12L ||
      nrow(slice_audit) != 8L ||
      nrow(validation_vs_test) != 24L) {
    stop("An aggregate performance table has an unexpected row count.", call. = FALSE)
  }

  numeric_evidence <- c(
    test_metrics$estimate,
    slice_audit$n,
    slice_audit$rmse,
    slice_audit$mae,
    slice_audit$mean_error,
    validation_vs_test$estimate
  )
  if (any(!is.finite(numeric_evidence))) {
    stop("Aggregate performance evidence contains non-finite values.", call. = FALSE)
  }

  model <- inference_environment$load_seoul_model(
    file.path(repo_root, "artifacts", "phase3", "final", "final_model.rds")
  )

  list(
    repo_root = repo_root,
    demo_inputs = demo_inputs,
    available_dates = sort(unique(as.character(demo_inputs$target_date))),
    test_metrics = test_metrics,
    slice_audit = slice_audit,
    validation_vs_test = validation_vs_test,
    model = model,
    predict_day = inference_environment$predict_seoul_day_ahead,
    format_display = inference_environment$format_seoul_prediction_display
  )
}
