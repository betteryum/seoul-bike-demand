testthat::test_that("frozen chronological data contract is represented by the manifest", {
  contract <- yaml::read_yaml(file.path(seoul_root, "configs", "day_ahead_contract.yml"))
  manifest <- readr::read_csv(
    file.path(seoul_root, "data", "splits", "day_ahead_split_manifest.csv"),
    show_col_types = FALSE, progress = FALSE
  )
  testthat::expect_equal(contract$timezone, "Asia/Seoul")
  testthat::expect_equal(contract$forecast_issue$minimum_horizon_hours, 24)
  testthat::expect_equal(contract$forecast_issue$maximum_horizon_hours, 47)
  testthat::expect_identical(names(manifest), c(
    "target_date", "issue_date", "split", "eligible", "target_hours",
    "exact_lag_48_hours", "exact_lag_168_hours", "exclusion_reason"
  ))
  eligible <- manifest[!is.na(manifest$eligible) & manifest$eligible, , drop = FALSE]
  testthat::expect_equal(nrow(eligible), 325L)
  testthat::expect_equal(
    unname(vapply(c("train", "validation", "test"), function(s) {
      sum(eligible$split == s)
    }, integer(1))),
    c(230L, 53L, 42L)
  )
  testthat::expect_true(all(eligible$target_hours == 24L))
  testthat::expect_true(all(eligible$exact_lag_48_hours == 24L))
  testthat::expect_true(all(eligible$exact_lag_168_hours == 24L))
})

testthat::test_that("demo day is complete, outcome-free, and correctly timed", {
  day <- seoul_demo_day()
  testthat::expect_equal(nrow(day), 24L)
  testthat::expect_identical(sort(as.integer(day$hour)), 0:23)
  testthat::expect_equal(length(unique(day$target_date)), 1L)
  testthat::expect_equal(length(unique(day$issue_timestamp)), 1L)
  testthat::expect_false(anyNA(day))
  testthat::expect_true(all(day$split %in% c("train", "validation")))
  testthat::expect_length(intersect(
    names(day), c("rented_bike_count", "RENTED_BIKE_COUNT", "prediction", "residual")
  ), 0L)
  issue <- as.Date(substr(as.character(day$issue_timestamp[1]), 1L, 10L))
  testthat::expect_equal(issue, as.Date(day$target_date[1]) - 1)
  testthat::expect_identical(format(day$issue_timestamp[1], "%H:%M", tz = "UTC"), "00:00")
})

testthat::test_that("predictor preparation enforces columns, order, values and types", {
  day <- seoul_demo_day()
  prepared <- prepare_seoul_predictors(day)
  testthat::expect_identical(names(prepared), seoul_required_predictors())
  testthat::expect_equal(ncol(prepared), 13L)
  testthat::expect_false(anyNA(prepared))
  testthat::expect_true(is.factor(prepared$hour_factor))
  testthat::expect_identical(levels(prepared$hour_factor), as.character(0:23))
  testthat::expect_identical(levels(prepared$weekday_factor), as.character(1:7))

  missing <- day[, setdiff(names(day), "lag_48"), drop = FALSE]
  testthat::expect_error(prepare_seoul_predictors(missing), "lag_48")
  bad <- day
  bad$lag_48[1] <- NA_real_
  testthat::expect_error(prepare_seoul_predictors(bad), "finite numeric")
  bad <- day
  bad$lag_168[1] <- -1
  testthat::expect_error(prepare_seoul_predictors(bad), "cannot be negative")
  bad <- day
  bad$weekend[1] <- 2L
  testthat::expect_error(prepare_seoul_predictors(bad), "weekend")
  bad <- day
  bad$hour[1] <- 24L
  testthat::expect_error(prepare_seoul_predictors(bad), "hour")
})
