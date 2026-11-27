seoul_model_id <- function() {
  "seoul_day_ahead_rf_v1"
}

seoul_model_md5 <- function() {
  "e4da864280d502584c8a899053193a58"
}

seoul_required_predictors <- function() {
  c(
    "lag_48",
    "lag_168",
    "hour_of_week_mean",
    "same_hour_mean_7d",
    "same_hour_mean_28d",
    "hour_factor",
    "weekday_factor",
    "hour_sin",
    "hour_cos",
    "day_of_year_sin",
    "day_of_year_cos",
    "holiday_indicator",
    "weekend"
  )
}

seoul_predictor_schema <- function() {
  data.frame(
    predictor = seoul_required_predictors(),
    type = c(
      rep("numeric", 5L),
      "factor[0:23]",
      "factor[1:7]",
      rep("numeric", 4L),
      "integer[0,1]",
      "integer[0,1]"
    ),
    source = c(
      rep("historical demand", 5L),
      "known calendar",
      "known calendar",
      rep("known calendar", 4L),
      "known calendar",
      "known calendar"
    ),
    stringsAsFactors = FALSE
  )
}

.seoul_stop <- function(...) {
  stop(..., call. = FALSE)
}

.seoul_require_namespaces <- function(packages) {
  missing_packages <- packages[
    !vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  ]

  if (length(missing_packages) > 0L) {
    .seoul_stop(
      "Missing packages required for frozen-model inference: ",
      paste(missing_packages, collapse = ", ")
    )
  }

  invisible(TRUE)
}

.seoul_numeric <- function(x, column) {
  if (is.factor(x)) {
    x <- as.character(x)
  }

  converted <- suppressWarnings(as.numeric(x))

  if (length(converted) != length(x) || any(!is.finite(converted))) {
    .seoul_stop(
      "Predictor `", column,
      "` must contain only finite numeric values."
    )
  }

  converted
}

.seoul_integer_range <- function(x, column, allowed) {
  converted <- .seoul_numeric(x, column)

  if (any(converted != floor(converted)) ||
      any(!converted %in% allowed)) {
    .seoul_stop(
      "Predictor `", column, "` must contain only: ",
      paste(allowed, collapse = ", "), "."
    )
  }

  as.integer(converted)
}

.seoul_factor <- function(x, column, allowed_levels) {
  values <- as.character(x)

  if (anyNA(values) || any(!values %in% allowed_levels)) {
    .seoul_stop(
      "Predictor `", column, "` contains missing or unsupported levels. ",
      "Allowed levels: ", paste(allowed_levels, collapse = ", "), "."
    )
  }

  factor(values, levels = allowed_levels)
}

.seoul_wall_timestamp <- function(x) {
  if (inherits(x, "POSIXt")) {
    source_tz <- attr(x, "tzone")
    if (is.null(source_tz) || length(source_tz) == 0L || !nzchar(source_tz[1])) {
      source_tz <- "UTC"
    } else {
      source_tz <- source_tz[1]
    }

    wall_time <- format(
      x,
      format = "%Y-%m-%d %H:%M:%S",
      tz = source_tz
    )
  } else {
    wall_time <- as.character(x)
  }

  as.POSIXct(
    wall_time,
    format = "%Y-%m-%d %H:%M:%S",
    tz = "Asia/Seoul"
  )
}

prepare_seoul_predictors <- function(new_data) {
  if (!is.data.frame(new_data)) {
    .seoul_stop("`new_data` must be a data frame.")
  }
  if (nrow(new_data) < 1L) {
    .seoul_stop("`new_data` must contain at least one row.")
  }

  prepared <- as.data.frame(new_data, stringsAsFactors = FALSE)

  if (!"hour_factor" %in% names(prepared)) {
    if (!"hour" %in% names(prepared)) {
      .seoul_stop(
        "`new_data` must contain `hour` or a valid `hour_factor`."
      )
    }
    hour <- .seoul_integer_range(prepared$hour, "hour", 0:23)
    prepared$hour_factor <- factor(hour, levels = 0:23)
  } else {
    prepared$hour_factor <- .seoul_factor(
      prepared$hour_factor,
      "hour_factor",
      as.character(0:23)
    )
  }

  if (!"weekday_factor" %in% names(prepared)) {
    if (!"weekday" %in% names(prepared)) {
      .seoul_stop(
        "`new_data` must contain `weekday` or a valid `weekday_factor`."
      )
    }
    weekday <- .seoul_integer_range(prepared$weekday, "weekday", 1:7)
    prepared$weekday_factor <- factor(weekday, levels = 1:7)
  } else {
    prepared$weekday_factor <- .seoul_factor(
      prepared$weekday_factor,
      "weekday_factor",
      as.character(1:7)
    )
  }

  required <- seoul_required_predictors()
  missing_predictors <- setdiff(required, names(prepared))

  if (length(missing_predictors) > 0L) {
    .seoul_stop(
      "Prediction data are missing required predictors: ",
      paste(missing_predictors, collapse = ", "), "."
    )
  }

  numeric_predictors <- c(
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

  for (column in numeric_predictors) {
    prepared[[column]] <- .seoul_numeric(prepared[[column]], column)
  }

  nonnegative_predictors <- c(
    "lag_48",
    "lag_168",
    "hour_of_week_mean",
    "same_hour_mean_7d",
    "same_hour_mean_28d"
  )

  for (column in nonnegative_predictors) {
    if (any(prepared[[column]] < 0)) {
      .seoul_stop(
        "Historical-demand predictor `", column,
        "` cannot be negative."
      )
    }
  }

  cyclic_predictors <- c(
    "hour_sin",
    "hour_cos",
    "day_of_year_sin",
    "day_of_year_cos"
  )

  for (column in cyclic_predictors) {
    if (any(abs(prepared[[column]]) > 1 + 1e-10)) {
      .seoul_stop(
        "Cyclic predictor `", column,
        "` must remain within [-1, 1]."
      )
    }
  }

  prepared$holiday_indicator <- .seoul_integer_range(
    prepared$holiday_indicator,
    "holiday_indicator",
    0:1
  )
  prepared$weekend <- .seoul_integer_range(
    prepared$weekend,
    "weekend",
    0:1
  )

  prepared$hour_factor <- .seoul_factor(
    prepared$hour_factor,
    "hour_factor",
    as.character(0:23)
  )
  prepared$weekday_factor <- .seoul_factor(
    prepared$weekday_factor,
    "weekday_factor",
    as.character(1:7)
  )

  prepared <- prepared[, required, drop = FALSE]

  if (anyNA(prepared)) {
    .seoul_stop("Prepared prediction data contain missing values.")
  }

  tibble::as_tibble(prepared)
}

.validate_seoul_workflow <- function(model) {
  .seoul_require_namespaces(c("workflows", "parsnip", "ranger"))

  if (!inherits(model, "workflow")) {
    .seoul_stop("Frozen model artifact is not a tidymodels workflow.")
  }

  mold <- tryCatch(
    workflows::extract_mold(model),
    error = function(e) {
      .seoul_stop("Could not extract the workflow predictor contract: ", conditionMessage(e))
    }
  )

  artifact_predictors <- names(mold$blueprint$ptypes$predictors)
  expected_predictors <- seoul_required_predictors()

  if (!identical(artifact_predictors, expected_predictors)) {
    .seoul_stop(
      "Frozen workflow predictor names or order do not match the ",
      "declared inference contract."
    )
  }

  hour_levels <- levels(mold$blueprint$ptypes$predictors$hour_factor)
  weekday_levels <- levels(mold$blueprint$ptypes$predictors$weekday_factor)

  if (!identical(hour_levels, as.character(0:23)) ||
      !identical(weekday_levels, as.character(1:7))) {
    .seoul_stop("Frozen workflow factor levels do not match the contract.")
  }

  fitted <- tryCatch(
    workflows::extract_fit_parsnip(model),
    error = function(e) {
      .seoul_stop("Could not extract the fitted ranger model: ", conditionMessage(e))
    }
  )

  engine <- fitted$fit
  engine_ok <- inherits(engine, "ranger") &&
    identical(as.integer(engine$num.trees), 500L) &&
    identical(as.integer(engine$mtry), 4L) &&
    identical(as.integer(engine$min.node.size), 20L)

  if (!engine_ok) {
    .seoul_stop("Frozen workflow engine or hyperparameters do not match v1.")
  }

  invisible(TRUE)
}

load_seoul_model <- function(
  path,
  expected_md5 = seoul_model_md5()
) {
  if (length(path) != 1L || is.na(path) || !nzchar(path)) {
    .seoul_stop("`path` must identify one model artifact.")
  }
  if (!file.exists(path)) {
    .seoul_stop("Frozen model artifact does not exist: ", path)
  }

  actual_md5 <- unname(as.character(tools::md5sum(path)))

  if (!identical(actual_md5, expected_md5)) {
    .seoul_stop(
      "Frozen model artifact checksum mismatch. Expected ",
      expected_md5, " but found ", actual_md5, "."
    )
  }

  model <- tryCatch(
    readRDS(path),
    error = function(e) {
      .seoul_stop("Frozen model artifact could not be read: ", conditionMessage(e))
    }
  )

  .validate_seoul_workflow(model)
  model
}

predict_seoul_demand <- function(model, new_data) {
  .validate_seoul_workflow(model)
  prepared <- prepare_seoul_predictors(new_data)

  raw_prediction <- tryCatch(
    stats::predict(model, new_data = prepared),
    error = function(e) {
      .seoul_stop("Frozen model prediction failed: ", conditionMessage(e))
    }
  )

  if (!".pred" %in% names(raw_prediction)) {
    .seoul_stop("Frozen model did not return a `.pred` column.")
  }

  prediction <- as.numeric(raw_prediction$.pred)

  if (length(prediction) != nrow(prepared) ||
      any(!is.finite(prediction))) {
    .seoul_stop("Frozen model returned invalid predictions.")
  }

  tibble::tibble(
    model_id = seoul_model_id(),
    prediction = pmax(prediction, 0)
  )
}

predict_seoul_day_ahead <- function(model, new_data) {
  required_metadata <- c("target_date", "hour", "issue_timestamp")
  missing_metadata <- setdiff(required_metadata, names(new_data))

  if (length(missing_metadata) > 0L) {
    .seoul_stop(
      "Day-ahead prediction data are missing metadata: ",
      paste(missing_metadata, collapse = ", "), "."
    )
  }
  if (nrow(new_data) != 24L) {
    .seoul_stop("A day-ahead request must contain exactly 24 rows.")
  }

  target_date <- as.Date(new_data$target_date)
  hour <- .seoul_integer_range(new_data$hour, "hour", 0:23)
  issue_timestamp <- .seoul_wall_timestamp(new_data$issue_timestamp)

  if (anyNA(target_date) || length(unique(target_date)) != 1L) {
    .seoul_stop("A day-ahead request must contain one valid target date.")
  }
  if (!identical(sort(hour), 0:23)) {
    .seoul_stop("A day-ahead request must contain each hour 0 through 23 once.")
  }
  if (anyNA(issue_timestamp) || length(unique(issue_timestamp)) != 1L) {
    .seoul_stop("A day-ahead request must contain one valid issue timestamp.")
  }

  issue_date <- as.Date(unique(issue_timestamp), tz = "Asia/Seoul")
  issue_hour <- as.integer(format(unique(issue_timestamp), "%H", tz = "Asia/Seoul"))

  if (!identical(issue_date, unique(target_date) - 1) || issue_hour != 0L) {
    .seoul_stop(
      "Issue timestamp must be 00:00 Asia/Seoul on the day before target_date."
    )
  }

  order_index <- order(hour)
  ordered_data <- new_data[order_index, , drop = FALSE]
  predictions <- predict_seoul_demand(model, ordered_data)

  tibble::tibble(
    model_id = predictions$model_id,
    target_date = as.Date(ordered_data$target_date),
    issue_timestamp = issue_timestamp[order_index],
    hour = as.integer(ordered_data$hour),
    prediction = predictions$prediction
  )
}

format_seoul_prediction_display <- function(predictions) {
  if (!is.data.frame(predictions) ||
      !"prediction" %in% names(predictions)) {
    .seoul_stop("`predictions` must contain a numeric `prediction` column.")
  }

  values <- .seoul_numeric(predictions$prediction, "prediction")
  result <- tibble::as_tibble(predictions)
  result$prediction_display <- as.integer(round(values, digits = 0))
  result
}
