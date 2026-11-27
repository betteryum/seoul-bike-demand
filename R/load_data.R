load_clean_hourly <- function(path, latest_allowed_date) {
  required_columns <- c(
    "DATE", "RENTED_BIKE_COUNT", "HOUR", "SEASONS", "HOLIDAY",
    "FUNCTIONING_DAY"
  )

  hourly <- readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE
  )

  missing_columns <- setdiff(required_columns, names(hourly))
  if (length(missing_columns) > 0) {
    stop(
      "Clean hourly data are missing columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }

  hourly <- hourly |>
    dplyr::transmute(
      target_date = as.Date(DATE, format = "%d/%m/%Y"),
      hour = as.integer(HOUR),
      timestamp = as.POSIXct(
        paste(
          format(target_date, "%Y-%m-%d"),
          sprintf("%02d:00:00", hour)
        ),
        format = "%Y-%m-%d %H:%M:%S",
        tz = "Asia/Seoul"
      ),
      rented_bike_count = as.numeric(RENTED_BIKE_COUNT),
      season = as.character(SEASONS),
      holiday = as.character(HOLIDAY),
      functioning_day = as.character(FUNCTIONING_DAY)
    ) |>
    dplyr::filter(target_date <= latest_allowed_date) |>
    dplyr::arrange(timestamp)

  if (anyNA(hourly$target_date) || anyNA(hourly$timestamp)) {
    stop("DATE or HOUR failed to parse in the development source.")
  }
  if (anyDuplicated(hourly$timestamp)) {
    stop("Development source contains duplicate timestamps.")
  }
  if (anyNA(hourly$rented_bike_count)) {
    stop("Development source contains missing target values.")
  }

  hourly
}

load_split_manifest <- function(path) {
  manifest <- readr::read_csv(
    path,
    col_types = readr::cols(
      target_date = readr::col_date(),
      issue_date = readr::col_date(),
      split = readr::col_character(),
      eligible = readr::col_logical(),
      target_hours = readr::col_integer(),
      exact_lag_48_hours = readr::col_integer(),
      exact_lag_168_hours = readr::col_integer(),
      exclusion_reason = readr::col_character()
    ),
    progress = FALSE
  )

  required_columns <- c(
    "target_date", "split", "eligible", "target_hours",
    "exact_lag_48_hours", "exact_lag_168_hours"
  )
  if (!all(required_columns %in% names(manifest))) {
    stop("Split manifest schema is incomplete.")
  }

  manifest
}
