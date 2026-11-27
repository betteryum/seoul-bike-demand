build_validation_baseline_predictions <- function(features) {
  validation <- features |>
    dplyr::filter(split == "validation") |>
    dplyr::select(
      row_id, target_date, hour, rented_bike_count,
      lag_48, lag_168, hour_of_week_mean
    )

  dplyr::bind_rows(
    validation |>
      dplyr::transmute(
        row_id, target_date, hour, rented_bike_count,
        model = "lag_48",
        prediction = clamp_nonnegative(lag_48)
      ),
    validation |>
      dplyr::transmute(
        row_id, target_date, hour, rented_bike_count,
        model = "lag_168",
        prediction = clamp_nonnegative(lag_168)
      ),
    validation |>
      dplyr::transmute(
        row_id, target_date, hour, rented_bike_count,
        model = "hour_of_week_mean",
        prediction = clamp_nonnegative(hour_of_week_mean)
      )
  ) |>
    dplyr::arrange(model, row_id)
}

evaluate_validation_baselines <- function(predictions) {
  model_names <- sort(unique(predictions$model))

  metric_tables <- lapply(
    model_names,
    function(model_name) {
      model_predictions <- predictions |>
        dplyr::filter(model == model_name)

      regression_metric_table(
        truth = model_predictions$rented_bike_count,
        estimate = model_predictions$prediction
      ) |>
        dplyr::mutate(model = model_name, .before = 1)
    }
  )

  dplyr::bind_rows(metric_tables) |>
    dplyr::arrange(metric, estimate)
}
