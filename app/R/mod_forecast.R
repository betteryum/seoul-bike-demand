forecast_module_ui <- function(id, available_dates) {
  ns <- shiny::NS(id)

  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Replay settings",
      shiny::selectInput(
        ns("target_date"),
        "Target date",
        choices = available_dates,
        selected = tail(available_dates, 1L),
        width = "100%"
      ),
      shiny::tags$p(
        class = "small text-muted",
        "Every option is a complete development-period day. The app removes",
        "the outcome and calls the frozen prediction interface."
      ),
      shiny::tags$hr(),
      shiny::tags$strong("Forecast issued"),
      shiny::textOutput(ns("issue_time")),
      shiny::tags$strong("Development split"),
      shiny::textOutput(ns("development_split")),
      width = 290
    ),
    bslib::layout_column_wrap(
      width = "210px",
      bslib::value_box(
        title = "Predicted daily rentals",
        value = shiny::textOutput(ns("daily_total"), inline = TRUE),
        theme = "primary"
      ),
      bslib::value_box(
        title = "Peak hour",
        value = shiny::textOutput(ns("peak_hour"), inline = TRUE),
        theme = "teal"
      ),
      bslib::value_box(
        title = "Peak hourly demand",
        value = shiny::textOutput(ns("peak_demand"), inline = TRUE),
        theme = "secondary"
      )
    ),
    bslib::card(
      bslib::card_header("24-hour day-ahead forecast"),
      shiny::plotOutput(ns("forecast_plot"), height = "390px"),
      full_screen = TRUE
    ),
    bslib::card(
      bslib::card_header("Forecast values"),
      shiny::tableOutput(ns("forecast_table"))
    ),
    shiny::tags$p(
      class = "boundary-note",
      "This is a historical forecast replay, not a performance calculation.",
      "Formal performance is reported only from the frozen aggregate test evidence."
    )
  )
}

forecast_module_server <- function(
  id,
  demo_inputs,
  model,
  predict_day,
  format_display
) {
  shiny::moduleServer(id, function(input, output, session) {
    selected_rows <- shiny::reactive({
      shiny::req(input$target_date)

      selected_date <- as.Date(input$target_date)
      rows <- demo_inputs[
        demo_inputs$target_date == selected_date,
        ,
        drop = FALSE
      ]

      shiny::validate(
        shiny::need(
          nrow(rows) == 24L,
          "The selected demo date is not a complete 24-hour day."
        )
      )

      rows
    })

    forecast_data <- shiny::reactive({
      predict_day(model, selected_rows())
    })

    forecast_display <- shiny::reactive({
      format_display(forecast_data())
    })

    forecast_summary <- shiny::reactive({
      data <- forecast_data()
      peak_index <- which.max(data$prediction)

      list(
        daily_total = sum(data$prediction),
        peak_hour = data$hour[peak_index],
        peak_demand = data$prediction[peak_index]
      )
    })

    output$issue_time <- shiny::renderText({
      issue <- unique(forecast_data()$issue_timestamp)
      format(issue, "%Y-%m-%d 00:00 Asia/Seoul", tz = "Asia/Seoul")
    })

    output$development_split <- shiny::renderText({
      split <- unique(selected_rows()$split)
      paste0(
        tools::toTitleCase(split),
        " — demonstration only, not app-based evaluation"
      )
    })

    output$daily_total <- shiny::renderText({
      scales::comma(round(forecast_summary()$daily_total))
    })

    output$peak_hour <- shiny::renderText({
      sprintf("%02d:00", forecast_summary()$peak_hour)
    })

    output$peak_demand <- shiny::renderText({
      scales::comma(round(forecast_summary()$peak_demand))
    })

    output$forecast_plot <- shiny::renderPlot({
      data <- forecast_data()

      hour_label_data <- data.frame(
        hour = c(seq(0, 21, by = 3), 23),
        prediction = -0.075 * max(data$prediction),
        label = sprintf("%02d:00", c(seq(0, 21, by = 3), 23)),
        hjust = c(0, rep(0.5, 7), 1)
      )

      demand_label_data <- data[
        data$hour %in% c(0, 6, 12, 18, 23),
        ,
        drop = FALSE
      ]
      demand_label_data$label <- scales::comma(
        round(demand_label_data$prediction)
      )
      demand_label_data$hjust <- ifelse(
        demand_label_data$hour == 0,
        0,
        ifelse(demand_label_data$hour == 23, 1, 0.5)
      )

      ggplot2::ggplot(
        data,
        ggplot2::aes(x = hour, y = prediction)
      ) +
        ggplot2::geom_area(
          fill = "#B7E4C7",
          alpha = 0.65
        ) +
        ggplot2::geom_line(
          color = "#0B6E4F",
          linewidth = 1.15
        ) +
        ggplot2::geom_point(
          color = "#084C3A",
          size = 2
        ) +
        ggplot2::geom_label(
          data = demand_label_data,
          ggplot2::aes(
            x = hour,
            y = prediction,
            label = label,
            hjust = hjust
          ),
          inherit.aes = FALSE,
          vjust = -0.7,
          size = 3.5,
          linewidth = 0,
          label.padding = grid::unit(0.12, "lines"),
          fill = scales::alpha("white", 0.82),
          color = "#17342B",
          fontface = "bold"
        ) +
        ggplot2::geom_text(
          data = hour_label_data,
          ggplot2::aes(
            x = hour,
            y = prediction,
            label = label,
            hjust = hjust
          ),
          inherit.aes = FALSE,
          vjust = 0.5,
          size = 3.4,
          color = "#263238",
          fontface = "bold"
        ) +
        ggplot2::scale_x_continuous(
          breaks = seq(0, 23, by = 3),
          labels = function(x) sprintf("%02d:00", x),
          limits = c(0, 23)
        ) +
        ggplot2::scale_y_continuous(
          labels = scales::label_comma(),
          limits = c(-0.11 * max(data$prediction), NA),
          expand = ggplot2::expansion(mult = c(0, 0.13))
        ) +
        ggplot2::labs(
          x = "Hour of target day",
          y = "Predicted rentals",
          subtitle = paste(
            "Target date:",
            format(unique(data$target_date), "%Y-%m-%d")
          )
        ) +
        ggplot2::theme_minimal(base_size = 13) +
        ggplot2::theme(
          panel.grid.minor = ggplot2::element_blank(),
          axis.text = ggplot2::element_text(
            color = "#263238",
            size = 11
          ),
          axis.title = ggplot2::element_text(
            color = "#263238",
            face = "bold"
          ),
          plot.subtitle = ggplot2::element_text(color = "#5B6573"),
          plot.background = ggplot2::element_rect(
            fill = "white",
            color = NA
          ),
          panel.background = ggplot2::element_rect(
            fill = "white",
            color = NA
          ),
          plot.margin = ggplot2::margin(10, 18, 12, 12)
        )
    })

    output$forecast_table <- shiny::renderTable({
      data <- forecast_display()

      data.frame(
        Hour = sprintf("%02d:00", data$hour),
        `Predicted rentals` = data$prediction_display,
        check.names = FALSE
      )
    }, striped = TRUE, bordered = FALSE, spacing = "s")

    list(
      selected_rows = selected_rows,
      forecast_data = forecast_data,
      forecast_display = forecast_display,
      forecast_summary = forecast_summary
    )
  })
}
