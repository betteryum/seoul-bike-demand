monday_based_weekday <- function(date) {
  ((as.POSIXlt(date, tz = "Asia/Seoul")$wday + 6L) %% 7L) + 1L
}

add_calendar_features <- function(data) {
  day_of_year <- as.integer(format(data$target_date, "%j"))

  data |>
    dplyr::mutate(
      weekday = monday_based_weekday(target_date),
      weekend = as.integer(weekday >= 6L),
      holiday_indicator = as.integer(holiday == "Holiday"),
      hour_of_week = (weekday - 1L) * 24L + hour,
      hour_sin = sin(2 * pi * hour / 24),
      hour_cos = cos(2 * pi * hour / 24),
      day_of_year_sin = sin(2 * pi * day_of_year / 365.25),
      day_of_year_cos = cos(2 * pi * day_of_year / 365.25)
    )
}

build_development_targets <- function(hourly, manifest) {
  development_days <- manifest |>
    dplyr::filter(
      eligible,
      split %in% c("train", "validation")
    ) |>
    dplyr::select(target_date, split)

  targets <- hourly |>
    dplyr::inner_join(development_days, by = "target_date") |>
    dplyr::arrange(target_date, hour) |>
    dplyr::mutate(
      row_id = dplyr::row_number(),
      issue_date = target_date - 1,
      issue_timestamp = as.POSIXct(
        paste(issue_date, "00:00:00"),
        format = "%Y-%m-%d %H:%M:%S",
        tz = "Asia/Seoul"
      ),
      lag_48_timestamp = timestamp - 48 * 60 * 60,
      lag_168_timestamp = timestamp - 168 * 60 * 60
    ) |>
    add_calendar_features()

  if (nrow(targets) != 6792L) {
    stop("Development target table must contain exactly 6,792 rows.")
  }
  if (any(targets$split == "test")) {
    stop("Locked-test rows entered the development target table.")
  }

  targets
}

add_exact_lags <- function(targets, hourly) {
  lag_48_lookup <- hourly |>
    dplyr::transmute(
      lag_48_timestamp = timestamp,
      lag_48 = rented_bike_count
    )

  lag_168_lookup <- hourly |>
    dplyr::transmute(
      lag_168_timestamp = timestamp,
      lag_168 = rented_bike_count
    )

  targets |>
    dplyr::left_join(lag_48_lookup, by = "lag_48_timestamp") |>
    dplyr::left_join(lag_168_lookup, by = "lag_168_timestamp")
}

build_one_day_profiles <- function(day_targets, hourly) {
  issue_timestamp <- unique(day_targets$issue_timestamp)
  if (length(issue_timestamp) != 1L) {
    stop("A target day has more than one issue timestamp.")
  }

  history <- hourly |>
    dplyr::filter(timestamp < issue_timestamp) |>
    add_calendar_features()

  hour_of_week_profile <- history |>
    dplyr::group_by(hour_of_week) |>
    dplyr::summarise(
      hour_of_week_mean = mean(rented_bike_count),
      hour_of_week_n = dplyr::n(),
      .groups = "drop"
    )

  same_hour_7d <- history |>
    dplyr::filter(timestamp >= issue_timestamp - 7 * 24 * 60 * 60) |>
    dplyr::group_by(hour) |>
    dplyr::summarise(
      same_hour_mean_7d = mean(rented_bike_count),
      same_hour_n_7d = dplyr::n(),
      .groups = "drop"
    )

  same_hour_28d <- history |>
    dplyr::filter(timestamp >= issue_timestamp - 28 * 24 * 60 * 60) |>
    dplyr::group_by(hour) |>
    dplyr::summarise(
      same_hour_mean_28d = mean(rented_bike_count),
      same_hour_n_28d = dplyr::n(),
      .groups = "drop"
    )

  day_targets |>
    dplyr::left_join(hour_of_week_profile, by = "hour_of_week") |>
    dplyr::left_join(same_hour_7d, by = "hour") |>
    dplyr::left_join(same_hour_28d, by = "hour")
}

add_past_only_profiles <- function(targets, hourly) {
  target_dates <- sort(unique(targets$target_date))

  pieces <- lapply(
    target_dates,
    function(current_date) {
      day_targets <- targets |>
        dplyr::filter(target_date == current_date)
      build_one_day_profiles(day_targets, hourly)
    }
  )

  dplyr::bind_rows(pieces) |>
    dplyr::arrange(row_id) |>
    dplyr::mutate(
      lag_difference_48_168 = lag_48 - lag_168
    )
}

build_development_features <- function(hourly, manifest) {
  build_development_targets(hourly, manifest) |>
    add_exact_lags(hourly) |>
    add_past_only_profiles(hourly)
}
