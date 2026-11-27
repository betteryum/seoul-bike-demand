phase3_train_fold_specification <- function() {
  tibble::tribble(
    ~fold, ~analysis_end, ~assessment_start, ~assessment_end,
    "fold_1", as.Date("2018-04-30"), as.Date("2018-05-01"),
    as.Date("2018-05-31"),
    "fold_2", as.Date("2018-05-31"), as.Date("2018-06-01"),
    as.Date("2018-06-30"),
    "fold_3", as.Date("2018-06-30"), as.Date("2018-07-01"),
    as.Date("2018-07-31")
  )
}

extract_phase3_fold <- function(train_data, fold_row) {
  analysis_data <- train_data |>
    dplyr::filter(target_date <= fold_row$analysis_end)

  assessment_data <- train_data |>
    dplyr::filter(
      target_date >= fold_row$assessment_start,
      target_date <= fold_row$assessment_end
    )

  if (nrow(analysis_data) == 0L || nrow(assessment_data) == 0L) {
    stop("A Phase 3 fold has an empty analysis or assessment set.")
  }
  if (max(analysis_data$target_date) >= min(assessment_data$target_date)) {
    stop("A Phase 3 fold violates chronological ordering.")
  }

  list(
    fold = fold_row$fold,
    analysis = analysis_data,
    assessment = assessment_data
  )
}

audit_phase3_folds <- function(train_data, fold_specification) {
  audits <- lapply(
    seq_len(nrow(fold_specification)),
    function(index) {
      current <- extract_phase3_fold(
        train_data,
        fold_specification[index, , drop = FALSE]
      )
      tibble::tibble(
        fold = current$fold,
        analysis_rows = nrow(current$analysis),
        analysis_days = dplyr::n_distinct(current$analysis$target_date),
        analysis_first_date = min(current$analysis$target_date),
        analysis_last_date = max(current$analysis$target_date),
        assessment_rows = nrow(current$assessment),
        assessment_days = dplyr::n_distinct(
          current$assessment$target_date
        ),
        assessment_first_date = min(current$assessment$target_date),
        assessment_last_date = max(current$assessment$target_date),
        chronological = max(current$analysis$target_date) <
          min(current$assessment$target_date)
      )
    }
  )

  dplyr::bind_rows(audits)
}
