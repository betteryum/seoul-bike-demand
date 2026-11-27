testthat::test_that("frozen workflow loads and scores one real development demo day", {
  model <- load_seoul_model(seoul_frozen_file())
  testthat::expect_s3_class(model, "workflow")
  day <- seoul_demo_day()
  output <- predict_seoul_day_ahead(model, day[24:1, , drop = FALSE])

  testthat::expect_identical(names(output), c(
    "model_id", "target_date", "issue_timestamp", "hour", "prediction"
  ))
  testthat::expect_equal(nrow(output), 24L)
  testthat::expect_identical(output$hour, 0:23)
  testthat::expect_true(all(output$model_id == "seoul_day_ahead_rf_v1"))
  testthat::expect_true(inherits(output$target_date, "Date"))
  testthat::expect_true(inherits(output$issue_timestamp, "POSIXct"))
  testthat::expect_false(anyNA(output))
  testthat::expect_true(is.numeric(output$prediction))
  testthat::expect_true(all(is.finite(output$prediction)))
  testthat::expect_true(all(output$prediction >= 0))

  displayed <- format_seoul_prediction_display(output)
  testthat::expect_identical(displayed$prediction, output$prediction)
  testthat::expect_identical(
    displayed$prediction_display,
    as.integer(round(output$prediction))
  )
})

testthat::test_that("day-ahead boundary rejects incomplete and repeated hours", {
  model <- load_seoul_model(seoul_frozen_file())
  day <- seoul_demo_day()
  testthat::expect_error(
    predict_seoul_day_ahead(model, day[-1, , drop = FALSE]), "exactly 24"
  )
  bad <- day
  bad$hour[1] <- bad$hour[2]
  testthat::expect_error(
    predict_seoul_day_ahead(model, bad), "each hour 0 through 23 once"
  )
})
