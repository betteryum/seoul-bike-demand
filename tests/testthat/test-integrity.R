testthat::test_that("frozen model and aggregate evidence retain exact MD5", {
  frozen <- c(
    "artifacts/phase3/final/final_model.rds" = "e4da864280d502584c8a899053193a58",
    "artifacts/phase3/final/test_metrics.csv" = "057d92258d98ce275acc91edc240425e",
    "artifacts/phase3/final/test_slice_audit.csv" = "2ffe9c7c551d2ffdb08aa25d04690794",
    "artifacts/phase3/final/validation_vs_test.csv" = "d2647a8ff9eb1efc54758cefefdd8e0b"
  )
  paths <- file.path(seoul_root, names(frozen))
  testthat::expect_true(all(file.exists(paths)))
  testthat::expect_identical(
    unname(as.character(tools::md5sum(paths))), unname(frozen)
  )
})

testthat::test_that("aggregate evidence has frozen schemas and row counts", {
  base <- file.path(seoul_root, "artifacts", "phase3", "final")
  specifications <- list(
    test_metrics = list(cols = c("model", "metric", "estimate"), n = 12L),
    test_slice_audit = list(cols = c("dimension", "slice", "n", "rmse", "mae", "mean_error"), n = 8L),
    validation_vs_test = list(cols = c("split", "model", "metric", "estimate"), n = 24L)
  )
  for (name in names(specifications)) {
    data <- readr::read_csv(
      file.path(base, paste0(name, ".csv")),
      show_col_types = FALSE, progress = FALSE
    )
    testthat::expect_identical(names(data), specifications[[name]]$cols)
    testthat::expect_equal(nrow(data), specifications[[name]]$n)
    testthat::expect_false(anyNA(data))
  }
})
