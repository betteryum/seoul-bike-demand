required_packages <- c(
  "shiny", "bslib", "ggplot2", "scales", "readr", "rprojroot",
  "tibble", "workflows", "parsnip", "ranger"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0L) {
  stop(
    "Missing packages required by the Seoul Bike Shiny app: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

repo_root <- find_seoul_repo_root(getwd())

inference_environment <- new.env(parent = globalenv())
sys.source(
  file.path(repo_root, "R", "predict.R"),
  envir = inference_environment
)

app_resources <- load_shiny_resources(
  repo_root,
  inference_environment
)

app_ui <- bslib::page_navbar(
  bslib::nav_panel(
    "Forecast Replay",
    forecast_module_ui(
      "forecast",
      app_resources$available_dates
    )
  ),
  bslib::nav_panel(
    "Model Performance",
    performance_module_ui("performance")
  ),
  bslib::nav_panel(
    "Prediction Contract",
    contract_page_ui()
  ),
  title = shiny::tags$div(
    class = "app-title",
    "Seoul Bike Demand"
  ),
  window_title = "Seoul Bike Demand — Day-Ahead Forecast Replay",
  theme = bslib::bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#0B6E4F",
    secondary = "#5B6573"
  ),
  fillable = FALSE,
  header = shiny::tags$head(
    shiny::includeCSS(file.path("www", "styles.css"))
  )
)

app_server <- function(input, output, session) {
  forecast_module_server(
    "forecast",
    demo_inputs = app_resources$demo_inputs,
    model = app_resources$model,
    predict_day = app_resources$predict_day,
    format_display = app_resources$format_display
  )

  performance_module_server(
    "performance",
    test_metrics = app_resources$test_metrics,
    slice_audit = app_resources$slice_audit,
    validation_vs_test = app_resources$validation_vs_test
  )
}

shiny::shinyApp(
  ui = app_ui,
  server = app_server
)
