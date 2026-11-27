performance_module_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    bslib::layout_column_wrap(
      width = "210px",
      bslib::value_box(
        title = "Locked-test RMSE",
        value = shiny::textOutput(ns("rmse_value"), inline = TRUE),
        theme = "primary"
      ),
      bslib::value_box(
        title = "Locked-test MAE",
        value = shiny::textOutput(ns("mae_value"), inline = TRUE),
        theme = "teal"
      ),
      bslib::value_box(
        title = "Locked-test R²",
        value = shiny::textOutput(ns("rsq_value"), inline = TRUE),
        theme = "secondary"
      )
    ),
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        title = "Comparison settings",
        shiny::selectInput(
          ns("metric"),
          "Metric",
          choices = c(
            "RMSE — lower is better" = "rmse",
            "MAE — lower is better" = "mae",
            "R-squared — higher is better" = "rsq"
          ),
          selected = "rmse"
        ),
        shiny::selectInput(
          ns("slice_dimension"),
          "Slice audit",
          choices = c(
            "Hour band" = "hour_band",
            "Month" = "month",
            "Holiday group" = "holiday_group"
          ),
          selected = "hour_band"
        ),
        shiny::tags$p(
          class = "small text-muted",
          "All values are read from committed aggregate evidence. The app does",
          "not read row-level locked-test features or predictions."
        ),
        width = 290
      ),
      bslib::card(
        bslib::card_header("Model and baseline comparison"),
        shiny::plotOutput(ns("model_comparison_plot"), height = "370px"),
        full_screen = TRUE
      ),
      bslib::card(
        bslib::card_header("Selected slice RMSE"),
        shiny::plotOutput(ns("slice_plot"), height = "340px"),
        full_screen = TRUE
      )
    ),
    bslib::card(
      bslib::card_header("Frozen model: validation versus locked test"),
      shiny::tableOutput(ns("split_comparison_table"))
    ),
    shiny::tags$p(
      class = "boundary-note",
      "The late-autumn test interval was easier for every compared method than",
      "the validation interval. The test improvement supports this defined",
      "historical period; it is not evidence of universal future performance."
    )
  )
}

performance_module_server <- function(
  id,
  test_metrics,
  slice_audit,
  validation_vs_test
) {
  shiny::moduleServer(id, function(input, output, session) {
    selected_model_metrics <- shiny::reactive({
      test_metrics[
        test_metrics$model == "seoul_day_ahead_rf_v1",
        ,
        drop = FALSE
      ]
    })

    metric_data <- shiny::reactive({
      shiny::req(input$metric)

      data <- test_metrics[
        test_metrics$metric == input$metric,
        ,
        drop = FALSE
      ]

      shiny::validate(
        shiny::need(nrow(data) == 4L, "Metric comparison is incomplete.")
      )

      data$model_label <- c(
        seoul_day_ahead_rf_v1 = "Frozen random forest",
        hour_of_week_mean = "Hour-of-week mean",
        lag_168 = "Lag 168 hours",
        lag_48 = "Lag 48 hours"
      )[data$model]

      data$is_selected <- data$model == "seoul_day_ahead_rf_v1"
      data
    })

    slice_data <- shiny::reactive({
      shiny::req(input$slice_dimension)

      data <- slice_audit[
        slice_audit$dimension == input$slice_dimension,
        ,
        drop = FALSE
      ]

      shiny::validate(
        shiny::need(nrow(data) > 0L, "No slice evidence is available.")
      )

      data
    })

    split_comparison <- shiny::reactive({
      data <- validation_vs_test[
        validation_vs_test$model == "seoul_day_ahead_rf_v1",
        c("split", "metric", "estimate"),
        drop = FALSE
      ]

      data$metric <- toupper(
        ifelse(data$metric == "rsq", "R²", data$metric)
      )
      data$estimate <- round(data$estimate, 3)
      data[order(data$metric, data$split), , drop = FALSE]
    })

    metric_value <- function(metric_name) {
      selected <- selected_model_metrics()
      selected$estimate[selected$metric == metric_name]
    }

    output$rmse_value <- shiny::renderText({
      sprintf("%.1f", metric_value("rmse"))
    })
    output$mae_value <- shiny::renderText({
      sprintf("%.1f", metric_value("mae"))
    })
    output$rsq_value <- shiny::renderText({
      sprintf("%.3f", metric_value("rsq"))
    })

    output$model_comparison_plot <- shiny::renderPlot({
      data <- metric_data()
      metric_name <- unique(data$metric)

      data$label_position <- 0.018 * max(data$estimate)

      data$model_label <- factor(
        data$model_label,
        levels = data$model_label[order(data$estimate)]
      )

      ggplot2::ggplot(
        data,
        ggplot2::aes(
          x = model_label,
          y = estimate,
          fill = is_selected
        )
      ) +
        ggplot2::geom_col(width = 0.68) +
        ggplot2::geom_text(
          ggplot2::aes(
            y = label_position,
            label = model_label
          ),
          hjust = 0,
          size = 4.2,
          color = "white",
          fontface = "bold"
        ) +
        ggplot2::geom_text(
          ggplot2::aes(
            label = if (metric_name == "rsq") {
              sprintf("%.3f", estimate)
            } else {
              sprintf("%.1f", estimate)
            }
          ),
          hjust = 1.12,
          size = 4.2,
          color = "white",
          fontface = "bold"
        ) +
        ggplot2::coord_flip() +
        ggplot2::scale_fill_manual(
          values = c(`TRUE` = "#0B6E4F", `FALSE` = "#9AA4B2"),
          guide = "none"
        ) +
        ggplot2::scale_y_continuous(
          labels = scales::label_number(accuracy = 0.1),
          expand = ggplot2::expansion(mult = c(0, 0.18))
        ) +
        ggplot2::labs(
          x = NULL,
          y = toupper(ifelse(metric_name == "rsq", "R²", metric_name))
        ) +
        ggplot2::theme_minimal(base_size = 13) +
        ggplot2::theme(
          panel.grid.major.y = ggplot2::element_blank(),
          axis.text = ggplot2::element_text(
            color = "#263238",
            size = 11
          ),
          axis.title = ggplot2::element_text(
            color = "#263238",
            face = "bold"
          ),
          plot.background = ggplot2::element_rect(
            fill = "white",
            color = NA
          ),
          panel.background = ggplot2::element_rect(
            fill = "white",
            color = NA
          ),
          plot.margin = ggplot2::margin(10, 16, 10, 16)
        )
    })

    output$slice_plot <- shiny::renderPlot({
      data <- slice_data()
      data$label_position <- 0.018 * max(data$rmse)
      data$slice <- factor(data$slice, levels = data$slice[order(data$rmse)])

      ggplot2::ggplot(
        data,
        ggplot2::aes(x = slice, y = rmse)
      ) +
        ggplot2::geom_col(fill = "#2D6A4F", width = 0.68) +
        ggplot2::geom_text(
          ggplot2::aes(
            y = label_position,
            label = slice
          ),
          hjust = 0,
          size = 4.2,
          color = "white",
          fontface = "bold"
        ) +
        ggplot2::geom_text(
          ggplot2::aes(label = sprintf("%.1f", rmse)),
          hjust = 1.12,
          size = 4.2,
          color = "white",
          fontface = "bold"
        ) +
        ggplot2::coord_flip() +
        ggplot2::scale_y_continuous(
          labels = scales::label_number(accuracy = 1),
          expand = ggplot2::expansion(mult = c(0, 0.2))
        ) +
        ggplot2::labs(x = NULL, y = "RMSE") +
        ggplot2::theme_minimal(base_size = 13) +
        ggplot2::theme(
          panel.grid.major.y = ggplot2::element_blank(),
          axis.text = ggplot2::element_text(
            color = "#263238",
            size = 11
          ),
          axis.title = ggplot2::element_text(
            color = "#263238",
            face = "bold"
          ),
          plot.background = ggplot2::element_rect(
            fill = "white",
            color = NA
          ),
          panel.background = ggplot2::element_rect(
            fill = "white",
            color = NA
          ),
          plot.margin = ggplot2::margin(10, 16, 10, 16)
        )
    })

    output$split_comparison_table <- shiny::renderTable({
      data <- split_comparison()
      names(data) <- c("Split", "Metric", "Estimate")
      data
    }, striped = TRUE, bordered = FALSE, spacing = "s")

    list(
      selected_model_metrics = selected_model_metrics,
      metric_data = metric_data,
      slice_data = slice_data,
      split_comparison = split_comparison
    )
  })
}
