contract_page_ui <- function() {
  shiny::tagList(
    bslib::layout_column_wrap(
      width = "320px",
      bslib::card(
        bslib::card_header("Prediction question"),
        shiny::tags$p(
          "At 00:00 Asia/Seoul on day D, predict all 24 system-wide hourly",
          "rental counts for D+1."
        ),
        shiny::tags$ul(
          shiny::tags$li("Forecast horizons: 24 through 47 hours"),
          shiny::tags$li("Prediction unit: one system-hour"),
          shiny::tags$li("Target: rented bike count")
        )
      ),
      bslib::card(
        bslib::card_header("Information allowed"),
        shiny::tags$ul(
          shiny::tags$li("Exact demand lags at 48 and 168 hours"),
          shiny::tags$li("Past-only 7-day and 28-day same-hour profiles"),
          shiny::tags$li("Past-only hour-of-week mean"),
          shiny::tags$li("Known calendar, holiday, weekday, and cyclic terms")
        )
      ),
      bslib::card(
        bslib::card_header("Information excluded"),
        shiny::tags$ul(
          shiny::tags$li("Realized target-day weather"),
          shiny::tags$li("Lag 24, which crosses the issue-time boundary"),
          shiny::tags$li("Future outcomes and full-data normalization"),
          shiny::tags$li("Any feature unavailable at the forecast issue time")
        )
      )
    ),
    bslib::layout_column_wrap(
      width = "420px",
      bslib::card(
        bslib::card_header("Frozen model"),
        shiny::tags$p(
          shiny::tags$strong("seoul_day_ahead_rf_v1"),
          "is a ranger regression workflow with 500 trees, mtry 4, minimum",
          "node size 20, and seed 32026. Negative predictions are clamped at",
          "zero; rounding is used only for display."
        )
      ),
      bslib::card(
        bslib::card_header("Evaluation boundary"),
        shiny::tags$p(
          "The model was selected on chronological development data and",
          "accessed the locked test interval once after selection was frozen."
        ),
        shiny::tags$p(
          "Primary metric: RMSE. Secondary metric: MAE. R² is supplemental."
        )
      ),
      bslib::card(
        bslib::card_header("Limitations"),
        shiny::tags$ul(
          shiny::tags$li("One city and one historical year"),
          shiny::tags$li("System-level demand rather than station-level demand"),
          shiny::tags$li("Holiday evidence is sparse in the test interval"),
          shiny::tags$li("Evening-hour errors were larger than overnight errors"),
          shiny::tags$li("No claim of live production deployment or causal effects")
        )
      )
    ),
    shiny::tags$p(
      class = "boundary-note",
      "This app is an evidence-backed historical replay. It demonstrates a",
      "reproducible prediction contract and formal inference interface; it is",
      "not a live operational forecast service."
    )
  )
}
