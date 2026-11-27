clamp_nonnegative <- function(prediction) {
  pmax(as.numeric(prediction), 0)
}

regression_metric_table <- function(truth, estimate) {
  tibble::tibble(
    metric = c("rmse", "mae", "rsq"),
    estimate = c(
      yardstick::rmse_vec(truth = truth, estimate = estimate),
      yardstick::mae_vec(truth = truth, estimate = estimate),
      yardstick::rsq_vec(truth = truth, estimate = estimate)
    )
  )
}
