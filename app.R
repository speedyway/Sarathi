
library(shiny)
library(httr)
library(jsonlite)

source("functions.R")

SARATHI_CSS <- "
  :root {
    --page: #F7F5FA;
    --card: #FFFFFF;
    --primary: #6C3FC5;
    --primary-dark: #4B238E;
    --accent: #8B5CF6;
    --text: #24212B;
    --secondary: #625B6D;
    --border: #E2DDEC;
    --low-bg: #EAF7EF;
    --low-text: #267044;
    --moderate-bg: #FFF5DD;
    --moderate-text: #8A6415;
    --high-bg: #FCE8E8;
    --high-text: #9A3838;
    --veryhigh-bg: #F7DDE5;
    --veryhigh-text: #8D2444;
    --info-bg: #F3EEFF;
    --error-bg: #FDEBEC;
    --success-bg: #EAF7EF;
  }

  * { box-sizing: border-box; }
  html, body { min-height: 100%; }
  body {
    margin: 0;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
    background: var(--page);
    color: var(--text);
    font-size: 17px;
    line-height: 1.5;
  }

  .container-fluid { padding-left: 0; padding-right: 0; }
  .sarathi-header {
    width: 100%;
    min-height: 96px;
    background: linear-gradient(110deg, #4B238E 0%, #6C3FC5 65%, #7C4DDB 100%);
    color: var(--card);
    padding: 16px 32px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 24px;
    box-shadow: 0 2px 8px rgba(75, 35, 142, 0.16);
  }
  .sarathi-header .brand { line-height: 1.35; }
  .sarathi-header .brand h1 {
    margin: 0;
    font-size: 36px;
    font-weight: 700;
  }
  .sarathi-header .brand p {
    margin: 2px 0 0;
    color: var(--card);
    font-size: 16px;
  }

  button, .btn {
    min-height: 50px;
    padding: 10px 32px;
    border: 1px solid var(--primary);
    border-radius: 7px;
    font-family: inherit;
    font-size: 17px;
    font-weight: 600;
    line-height: 1.4;
    box-shadow: none;
  }
  .btn-primary-sarathi, .btn-teal {
    background: var(--primary);
    color: var(--card);
    border-color: var(--primary);
    transition: background-color 0.15s ease, border-color 0.15s ease;
  }
  .btn-primary-sarathi:hover, .btn-teal:hover {
    background: var(--primary-dark);
    border-color: var(--primary-dark);
    color: var(--card);
  }
  .btn-logout {
    background: transparent;
    border-color: var(--primary);
    color: var(--primary);
  }
  .btn-login-header {
    background: transparent;
    border-color: var(--card);
    color: var(--card);
    font-size: 16px;
  }
  .sarathi-header .btn-logout {
    border-color: var(--card);
    color: var(--card);
  }

  .card {
    width: 100%;
    margin-bottom: 24px;
    padding: 30px;
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 12px;
    box-shadow: 0 2px 10px rgba(36, 33, 43, 0.05);
  }
  .card h3 {
    margin: 0 0 24px;
    padding: 0 0 16px;
    border-bottom: 1px solid var(--border);
    color: var(--primary);
    font-size: 25px;
    font-weight: 600;
  }

  .result-card {
    margin-top: 24px;
    padding: 24px;
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 12px;
    border-left: 4px solid var(--primary);
    box-shadow: 0 2px 10px rgba(36, 33, 43, 0.05);
  }
  .result-card h3 {
    margin: 0 0 16px;
    color: var(--primary);
    font-size: 21px;
    font-weight: 600;
  }
  .result-row {
    display: flex;
    align-items: center;
    justify-content: flex-start;
    gap: 16px;
    min-height: 50px;
    padding: 10px 0;
    border-bottom: 1px solid var(--border);
    font-size: 16px;
  }
  .result-row:last-child { border-bottom: none; }
  .result-label {
    flex: 0 0 210px;
    color: var(--secondary);
    font-weight: 400;
  }
  .result-value { color: var(--text); font-weight: 600; }
  .occupancy-value {
    display: flex;
    flex: 1;
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  .occupancy-progress {
    display: block;
    width: 100%;
    max-width: 420px;
    height: 12px;
    border: 0;
    border-radius: 6px;
    appearance: none;
  }
  .occupancy-progress::-webkit-progress-bar {
    background: var(--border);
    border-radius: 6px;
  }
  .occupancy-progress-low::-webkit-progress-value {
    background: var(--low-text);
    border-radius: 6px;
  }
  .occupancy-progress-moderate::-webkit-progress-value {
    background: var(--moderate-text);
    border-radius: 6px;
  }
  .occupancy-progress-high::-webkit-progress-value {
    background: var(--high-text);
    border-radius: 6px;
  }
  .occupancy-progress-veryhigh::-webkit-progress-value {
    background: var(--veryhigh-text);
    border-radius: 6px;
  }
  .occupancy-progress::-moz-progress-bar { border-radius: 6px; }
  .occupancy-progress-low::-moz-progress-bar { background: var(--low-text); }
  .occupancy-progress-moderate::-moz-progress-bar { background: var(--moderate-text); }
  .occupancy-progress-high::-moz-progress-bar { background: var(--high-text); }
  .occupancy-progress-veryhigh::-moz-progress-bar { background: var(--veryhigh-text); }

  .badge {
    display: inline-block;
    padding: 5px 12px;
    border-radius: 6px;
    font-size: 15px;
    font-weight: 600;
  }
  .badge-low, .badge-normal { background: var(--low-bg); color: var(--low-text); }
  .badge-moderate, .badge-busy { background: var(--moderate-bg); color: var(--moderate-text); }
  .badge-high, .badge-rush { background: var(--high-bg); color: var(--high-text); }
  .badge-veryhigh, .badge-peak { background: var(--veryhigh-bg); color: var(--veryhigh-text); }

  .form-section {
    width: 100%;
    max-width: 440px;
    margin: 0 auto;
  }
  .login-actions {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }
  .login-actions .btn { width: 100%; }
  .panel-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 16px;
  }
  .shiny-input-container {
    width: 100%;
    max-width: 100%;
    margin-bottom: 16px;
  }
  .shiny-input-container label {
    color: var(--text);
    font-size: 16px;
    font-weight: 500;
  }
  select, input[type='number'], input[type='text'],
  input[type='password'] {
    width: 100%;
    min-height: 50px;
    padding: 10px 14px;
    border: 1px solid var(--border);
    border-radius: 7px;
    background: var(--card);
    color: var(--text);
    font-family: inherit;
    font-size: 17px;
    box-shadow: none;
  }
  select:focus, input:focus {
    outline: none;
    border-color: var(--accent);
    box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.14);
  }
  button:focus, .btn:focus {
    outline: 2px solid var(--accent);
    outline-offset: 2px;
    box-shadow: none;
  }

  .msg-info {
    margin-top: 16px;
    padding: 16px;
    border: 1px solid var(--border);
    border-radius: 6px;
    background: var(--info-bg);
    color: var(--primary);
    font-size: 16px;
  }
  .msg-error {
    margin-top: 16px;
    padding: 16px;
    border: 1px solid var(--veryhigh-text);
    border-radius: 6px;
    background: var(--error-bg);
    color: var(--veryhigh-text);
    font-size: 16px;
  }
  .msg-success {
    margin-top: 16px;
    padding: 16px;
    border: 1px solid var(--low-text);
    border-radius: 6px;
    background: var(--success-bg);
    color: var(--low-text);
    font-size: 16px;
  }

  .preview-box {
    margin-top: 16px;
    padding: 16px;
    border: 1px solid var(--border);
    border-radius: 6px;
    background: var(--info-bg);
    font-size: 16px;
  }
  .preview-box p { margin: 8px 0; }
  .preview-label { color: var(--secondary); }
  .preview-value { color: var(--text); font-weight: 600; }

  .main-wrap {
    width: 100%;
    max-width: 1200px;
    margin: 0 auto;
    padding: 32px 24px;
  }
  .two-col {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24px;
  }
  .two-col > div { min-width: 0; }
  .card .shiny-input-container {
    width: 100%;
    max-width: 100%;
  }
  @media (max-width: 767px) {
    .two-col { grid-template-columns: 1fr; }
    .sarathi-header { min-height: 90px; padding: 16px; }
    .sarathi-header .brand h1 { font-size: 30px; }
    .sarathi-header .brand p { font-size: 15px; }
    .sarathi-header .btn { padding: 8px 12px; font-size: 15px; }
    .main-wrap { padding: 24px 16px; }
    .card { padding: 24px 20px; }
    .result-card { padding: 20px; }
    .result-label { flex-basis: 145px; }
    .result-row { gap: 12px; }
  }
  @media (max-width: 420px) {
    .sarathi-header { align-items: flex-start; gap: 8px; padding: 12px; }
    .sarathi-header .brand { min-width: 0; }
    .sarathi-header .brand p { max-width: 180px; }
    .sarathi-header .btn {
      max-width: 136px;
      min-height: 44px;
      padding: 8px 6px;
      font-size: 14px;
      white-space: normal;
    }
    .result-row { align-items: flex-start; flex-direction: column; gap: 4px; }
    .result-label { flex: initial; }
  }
"



ui <- fluidPage(
  tags$head(
    tags$style(HTML(SARATHI_CSS)),
    tags$meta(name = "viewport",
              content = "width=device-width, initial-scale=1")
  ),

  div(class = "sarathi-header",
    div(class = "brand",
      tags$h1("SARATHI"),
      tags$p("Smart Bus Occupancy & Rush Hour Information")
    ),
    uiOutput("header_btn")
  ),

  uiOutput("main_content")
)


server <- function(input, output, session) {

  rv <- reactiveValues(
    logged_in     = FALSE,
    show_login    = FALSE,
    login_msg     = "",
    public_result = NULL,
    public_msg    = "",
    save_msg      = "",
    save_ok       = FALSE
  )

  
  output$header_btn <- renderUI({
    if (rv$logged_in) {
      actionButton("btn_logout", "Logout",
                   class = "btn-logout")
    } else {
      actionButton("btn_show_login",
                   "Ticket Collector Login",
                   class = "btn-login-header")
    }
  })

  observeEvent(input$btn_show_login, {
    rv$show_login <- TRUE
    rv$login_msg  <- ""
  })

  observeEvent(input$btn_logout, {
    rv$logged_in  <- FALSE
    rv$show_login <- FALSE
    rv$save_msg   <- ""
    rv$save_ok    <- FALSE
  })

  output$main_content <- renderUI({
    if (rv$show_login && !rv$logged_in) {
      div(class = "main-wrap",
        div(class = "card form-section",
          tags$h3("Ticket Collector Login"),
          tags$br(),
          textInput("tc_username", "Username", placeholder = "Enter username"),
          passwordInput("tc_password", "Password", placeholder = "Enter password"),
          tags$br(),
          div(class = "login-actions",
            actionButton("btn_login", "Login", class = "btn-primary-sarathi"),
            actionButton("btn_cancel_login", "Cancel", class = "btn-logout")
          ),
          uiOutput("login_msg_ui")
        )
      )

    } else if (rv$logged_in) {
      div(class = "main-wrap",
        div(class = "card",
          tags$h3("SARATHI - Ticket Collector Panel"),
          div(class = "two-col",
            div(
              selectInput("tc_bus",    "Bus Number",
                          choices = BUS_NUMBERS),
              selectInput("tc_route",  "Route",
                          choices = ROUTES),
              dateInput("tc_date",   "Date",
                        value = Sys.Date(),
                        format = "dd-mm-yyyy"),
              selectInput("tc_timing", "Timing",
                          choices = TIMING_LEVELS)
            ),
            div(
              numericInput("tc_occupied", "Occupied Seats",
                           value = NA, min = 0, step = 1),
              uiOutput("tc_preview"),
              tags$br(),
              div(class = "panel-actions",
                actionButton("btn_save", "Save Occupancy Data",
                             class = "btn-teal"),
                actionButton("btn_logout2", "Logout",
                             class = "btn-logout")
              ),
              uiOutput("save_msg_ui")
            )
          )
        )
      )

    } else {
      div(class = "main-wrap",
        div(class = "card",
          tags$h3("Check Bus Occupancy"),
          div(class = "two-col",
            div(
              selectInput("pub_bus",    "Bus Number",
                          choices = BUS_NUMBERS),
              selectInput("pub_route",  "Route",
                          choices = ROUTES)
            ),
            div(
              dateInput("pub_date",   "Date",
                        value = Sys.Date(),
                        format = "dd-mm-yyyy"),
              selectInput("pub_timing", "Timing",
                          choices = TIMING_LEVELS)
            )
          ),
          actionButton("btn_check", "Check Occupancy",
                       class = "btn-primary-sarathi"),
          uiOutput("public_result_ui")
        )
      )
    }
  })

  
  output$login_msg_ui <- renderUI({
    if (nchar(rv$login_msg) == 0) return(NULL)
    div(class = "msg-error", rv$login_msg)
  })

  observeEvent(input$btn_login, {
    un <- trimws(input$tc_username)
    pw <- input$tc_password

    if (nchar(un) == 0 || nchar(pw) == 0) {
      rv$login_msg <- "Please enter both username and password."
      return()
    }

    ok <- tryCatch(
      verify_collector(un, pw),
      error = function(e) FALSE
    )

    if (is.na(ok)) {
      rv$login_msg <- "Login is temporarily unavailable. Please try again later."
    } else if (ok) {
      rv$logged_in  <- TRUE
      rv$show_login <- FALSE
      rv$login_msg  <- ""
    } else {
      rv$login_msg <- "Incorrect username or password. Please try again."
    }
  })

  observeEvent(input$btn_cancel_login, {
    rv$show_login <- FALSE
    rv$login_msg  <- ""
  })

  
  tc_capacity <- reactive({
    req(input$tc_bus)
    cap <- tryCatch(get_capacity(input$tc_bus), error = function(e) NA)
    if (is.na(cap) || is.null(cap)) BUS_CAPACITY[input$tc_bus]
    else cap
  })

  output$tc_preview <- renderUI({
    cap <- tc_capacity()
    occ <- input$tc_occupied

    if (is.null(occ) || is.na(occ)) {
      return(div(class = "preview-box",
        tags$p(tags$span(class = "preview-label", "Capacity: "),
               tags$span(class = "preview-value", cap, " seats"))
      ))
    }

    if (occ < 0) {
      return(div(class = "preview-box msg-error",
        "Occupied seats cannot be negative."))
    }
    if (occ != floor(occ)) {
      return(div(class = "preview-box msg-error",
        "Occupied seats must be a whole number."))
    }
    if (occ > cap) {
      return(div(class = "preview-box msg-error",
        paste0("Occupied seats (", occ,
               ") cannot exceed capacity (", cap, ").")))
    }

    occ <- as.integer(occ)
    res <- calculate_all(cap, occ)

    crowd_badge <- switch(res$crowd,
      "Low"       = "badge badge-low",
      "Moderate"  = "badge badge-moderate",
      "High"      = "badge badge-high",
      "Very High" = "badge badge-veryhigh",
      "badge"
    )
    rush_badge <- switch(res$rush,
      "Normal"    = "badge badge-normal",
      "Busy"      = "badge badge-busy",
      "Rush Hour" = "badge badge-rush",
      "Peak Rush" = "badge badge-peak",
      "badge"
    )

    div(class = "preview-box",
      tags$p(tags$span(class="preview-label","Capacity: "),
             tags$span(class="preview-value", cap, " seats")),
      tags$p(tags$span(class="preview-label","Vacant: "),
             tags$span(class="preview-value", res$vacant, " seats")),
      tags$p(tags$span(class="preview-label","Occupancy: "),
             tags$span(class="preview-value",
                       paste0(res$pct, "%"))),
      tags$p(tags$span(class="preview-label","Crowd: "),
             tags$span(class = crowd_badge, res$crowd)),
      tags$p(tags$span(class="preview-label","Rush: "),
             tags$span(class = rush_badge, res$rush))
    )
  })

  
  output$save_msg_ui <- renderUI({
    if (nchar(rv$save_msg) == 0) return(NULL)
    cls <- if (rv$save_ok) "msg-success" else "msg-error"
    div(class = cls, rv$save_msg)
  })

  save_action <- function() {
    bus    <- input$tc_bus
    route  <- input$tc_route
    date_d <- format(input$tc_date, "%Y-%m-%d")
    timing <- input$tc_timing
    occ    <- input$tc_occupied
    cap    <- tc_capacity()

    if (is.null(input$tc_date) || is.na(input$tc_date)) {
      rv$save_msg <- "Please select a valid date."
      rv$save_ok  <- FALSE
      return()
    }
    if (is.null(occ) || is.na(occ)) {
      rv$save_msg <- "Please enter the number of occupied seats."
      rv$save_ok  <- FALSE
      return()
    }
    if (occ < 0) {
      rv$save_msg <- "Occupied seats cannot be negative."
      rv$save_ok  <- FALSE
      return()
    }
    if (occ != floor(occ)) {
      rv$save_msg <- "Occupied seats must be a whole number."
      rv$save_ok  <- FALSE
      return()
    }
    if (occ > cap) {
      rv$save_msg <- paste0("Occupied seats (", occ,
                            ") cannot exceed bus capacity (", cap, ").")
      rv$save_ok  <- FALSE
      return()
    }

    occ <- as.integer(occ)
    result <- tryCatch(
      save_occupancy(bus, route, date_d, timing, cap, occ),
      error = function(e) {
        list(ok = FALSE, status = NA_integer_,
             body = conditionMessage(e))
      }
    )

    if (isTRUE(result$ok)) {
      date_display <- format(input$tc_date, "%d-%m-%Y")
      rv$save_msg <- paste0("\u2713 Record saved for ", bus,
                            " on ", date_display, " at ", timing, ".")
      rv$save_ok  <- TRUE
    } else {
      status <- if (is.na(result$status)) {
        "no HTTP response"
      } else {
        paste("HTTP", result$status)
      }
      rv$save_msg <- paste0("Supabase save failed (", status, "): ",
                            result$body)
      rv$save_ok  <- FALSE
    }
  }

  observeEvent(input$btn_save, { save_action() })
  observeEvent(input$btn_logout2, {
    rv$logged_in <- FALSE
    rv$save_msg  <- ""
    rv$save_ok   <- FALSE
  })

  
  
  
  output$public_result_ui <- renderUI({
    if (is.null(rv$public_result) && nchar(rv$public_msg) == 0)
      return(NULL)

    if (nchar(rv$public_msg) > 0) {
      return(div(class = "msg-info", rv$public_msg))
    }

    df  <- rv$public_result
    row <- df[1, ]   

    
    crowd_badge <- switch(as.character(row$rush_status),
      "Normal"    = "badge badge-normal",
      "Busy"      = "badge badge-busy",
      "Rush Hour" = "badge badge-rush",
      "Peak Rush" = "badge badge-peak",
      "badge"
    )
    
    crowd_label <- switch(as.character(row$rush_status),
      "Normal"    = "Low",
      "Busy"      = "Moderate",
      "Rush Hour" = "High",
      "Peak Rush" = "Very High",
      "Unknown"
    )
    crowd_badge_cls <- switch(crowd_label,
      "Low"       = "badge badge-low",
      "Moderate"  = "badge badge-moderate",
      "High"      = "badge badge-high",
      "Very High" = "badge badge-veryhigh",
      "badge"
    )

    
    date_display <- format(as.Date(row$travel_date), "%d-%m-%Y")

    div(class = "result-card",
      tags$h3("Bus Occupancy Details"),
      div(class = "result-row",
        span(class = "result-label", "Bus Number"),
        span(class = "result-value", row$bus_number)
      ),
      div(class = "result-row",
        span(class = "result-label", "Route"),
        span(class = "result-value", row$route)
      ),
      div(class = "result-row",
        span(class = "result-label", "Date"),
        span(class = "result-value", date_display)
      ),
      div(class = "result-row",
        span(class = "result-label", "Timing"),
        span(class = "result-value", row$timing)
      ),
      div(class = "result-row",
        span(class = "result-label", "Total Capacity"),
        span(class = "result-value", paste(row$capacity, "seats"))
      ),
      div(class = "result-row",
        span(class = "result-label", "Occupied Seats"),
        span(class = "result-value", paste(row$occupied, "seats"))
      ),
      div(class = "result-row",
        span(class = "result-label", "Vacant Seats"),
        span(class = "result-value", paste(row$vacant, "seats"))
      ),
      div(class = "result-row",
        span(class = "result-label", "Occupancy"),
        div(
          class = "result-value occupancy-value",
          span(paste0(row$occupancy_percentage, "%")),
          tags$progress(
            class = paste0(
              "occupancy-progress occupancy-progress-",
              switch(crowd_label,
                "Low" = "low",
                "Moderate" = "moderate",
                "High" = "high",
                "Very High" = "veryhigh",
                "low"
              )
            ),
            value = as.numeric(row$occupancy_percentage),
            max = 100,
            paste0(row$occupancy_percentage, "% occupancy")
          )
        )
      ),
      div(class = "result-row",
        span(class = "result-label", "Crowd Status"),
        tags$span(class = crowd_badge_cls, crowd_label)
      ),
      div(class = "result-row",
        span(class = "result-label", "Basic Rush Information"),
        tags$span(class = crowd_badge, as.character(row$rush_status))
      )
    )
  })

  observeEvent(input$btn_check, {
    if (is.null(input$pub_date) || is.na(input$pub_date)) {
      rv$public_result <- NULL
      rv$public_msg    <- "Please select a valid date."
      return()
    }

    bus    <- input$pub_bus
    route  <- input$pub_route
    date_d <- format(input$pub_date, "%Y-%m-%d")
    timing <- input$pub_timing

    rv$public_result <- NULL
    rv$public_msg    <- ""

    
    df <- tryCatch(
      fetch_occupancy(bus, route, date_d, timing),
      error = function(e) data.frame()
    )

    
    if (!is.data.frame(df) || nrow(df) == 0) {
      df <- fetch_occupancy_csv(bus, route, date_d, timing)
    }

    if (!is.data.frame(df) || nrow(df) == 0) {
      date_display <- format(input$pub_date, "%d-%m-%Y")
      rv$public_msg <- paste0(
        "No occupancy record found for ", bus,
        " on ", date_display, " at ", timing,
        ". Please try a different combination or check back later.")
    } else {
      rv$public_result <- df
    }
  })

} 




shinyApp(ui = ui, server = server)
