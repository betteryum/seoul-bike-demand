prepare_phase3_modeling_data <- function(data) {
  data |>
    dplyr::mutate(
      target_date = as.Date(target_date),
      hour_factor = factor(hour, levels = 0:23),
      weekday_factor = factor(weekday, levels = 1:7)
    ) |>
    dplyr::arrange(target_date, hour)
}

calendar_lag_formula <- function() {
  rented_bike_count ~
    lag_48 + lag_168 +
    hour_sin + hour_cos +
    day_of_year_sin + day_of_year_cos +
    holiday_indicator + weekend
}

engineered_linear_formula <- function() {
  rented_bike_count ~
    lag_48 + lag_168 +
    hour_of_week_mean +
    same_hour_mean_7d + same_hour_mean_28d +
    hour_factor + weekday_factor +
    day_of_year_sin + day_of_year_cos +
    holiday_indicator
}

random_forest_formula <- function() {
  rented_bike_count ~
    lag_48 + lag_168 +
    hour_of_week_mean +
    same_hour_mean_7d + same_hour_mean_28d +
    hour_factor + weekday_factor +
    hour_sin + hour_cos +
    day_of_year_sin + day_of_year_cos +
    holiday_indicator + weekend
}

make_linear_workflow <- function(model_formula) {
  model_specification <- parsnip::linear_reg() |>
    parsnip::set_engine("lm")

  workflows::workflow() |>
    workflows::add_model(model_specification) |>
    workflows::add_formula(model_formula)
}

make_random_forest_workflow <- function(
  mtry, min_n, seed, trees = 500L
) {
  model_specification <- parsnip::rand_forest(
    mtry = as.integer(mtry),
    trees = as.integer(trees),
    min_n = as.integer(min_n)
  ) |>
    parsnip::set_engine(
      "ranger",
      importance = "permutation",
      num.threads = 1L,
      seed = as.integer(seed)
    ) |>
    parsnip::set_mode("regression")

  workflows::workflow() |>
    workflows::add_model(model_specification) |>
    workflows::add_formula(random_forest_formula())
}

fit_phase3_workflow <- function(workflow, analysis_data) {
  parsnip::fit(workflow, data = analysis_data)
}

predict_phase3_workflow <- function(fitted_workflow, assessment_data) {
  raw_prediction <- stats::predict(
    fitted_workflow,
    new_data = assessment_data
  )

  clamp_nonnegative(raw_prediction$.pred)
}

evaluate_fitted_workflow <- function(
  fitted_workflow, assessment_data, model_name
) {
  prediction <- predict_phase3_workflow(
    fitted_workflow,
    assessment_data
  )

  predictions <- assessment_data |>
    dplyr::transmute(
      row_id, split, target_date, hour,
      rented_bike_count,
      model = model_name,
      prediction = prediction,
      residual = rented_bike_count - prediction
    )

  metrics <- regression_metric_table(
    truth = predictions$rented_bike_count,
    estimate = predictions$prediction
  ) |>
    dplyr::mutate(model = model_name, .before = 1)

  list(predictions = predictions, metrics = metrics)
}
