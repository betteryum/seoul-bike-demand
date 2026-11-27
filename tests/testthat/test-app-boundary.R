testthat::test_that("App source names no row-level locked-test file", {
  sources <- c("app/app.R", "app/R/app_data.R", "app/R/mod_contract.R",
               "app/R/mod_forecast.R", "app/R/mod_performance.R")
  testthat::expect_true(all(file.exists(file.path(seoul_root, sources))))
  code <- paste(unlist(lapply(file.path(seoul_root, sources), readLines,
                              warn = FALSE)), collapse = "\n")
  forbidden <- paste0(c("test_features", "test_predictions"), ".csv")
  testthat::expect_false(any(vapply(forbidden, grepl, logical(1), x = code,
                                   fixed = TRUE)))
})

testthat::test_that("App demo has no observed outcome and no test split", {
  sys.source(file.path(seoul_root, "app", "R", "app_data.R"),
             envir = environment())
  demo <- readr::read_csv(
    file.path(seoul_root, "app", "data", "demo_forecast_inputs.csv"),
    show_col_types = FALSE, progress = FALSE
  )
  testthat::expect_equal(nrow(demo), 6792L)
  testthat::expect_identical(
    names(demo), c("split", "target_date", "hour", "issue_timestamp",
                   "weekday", "weekend", "holiday_indicator", "lag_48",
                   "lag_168", "hour_of_week_mean", "same_hour_mean_7d",
                   "same_hour_mean_28d", "hour_sin", "hour_cos",
                   "day_of_year_sin", "day_of_year_cos")
  )
  testthat::expect_false(any(demo$split == "test"))
  testthat::expect_false(anyNA(demo))
  testthat::expect_invisible(validate_demo_inputs(demo))
})
