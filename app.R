# ============================================================
# app.R  –  SARATHI: Smart Bus Occupancy & Rush Hour System
# ============================================================
# Steps covered:
#   1  Skeleton, header, CSS theme
#   2  Public user UI (dropdowns, result card)
#   3  Ticket Collector login button + form
#   4  Ticket Collector panel layout
#   5  Calculation functions (in functions.R, sourced here)
#   6  Supabase connection
#   7  Save occupancy data
#   8  Retrieve occupancy for public card
#   9  Rush-hour analysis table
#  10  Base-R bar chart
#  11  Validation and friendly error messages
#  12  Sample-data fallback, cleanup

library(shiny)
library(httr)
library(jsonlite)

source("functions.R")   # load all helper functions and fixed data

# ==============================================================
#  CSS  –  inline, inside app.R as required
# ==============================================================
SARATHI_CSS <- "
  :root {
    --page: #F4F6F8;
    --card: #FFFFFF;
    --primary: #0B4F8A;
    --accent: #0F8B8D;
    --text: #1F2933;
    --secondary: #52606D;
    --border: #D9E0E5;
    --low-bg: #E5F3E8;
    --low-text: #27633A;
    --moderate-bg: #FFF3D6;
    --moderate-text: #805B10;
    --high-bg: #FCE9DB;
    --high-text: #91451D;
    --veryhigh-bg: #F9E1E1;
    --veryhigh-text: #8B3030;
    --info-bg: #E8F0F7;
    --error-bg: #F9E8E8;
    --success-bg: #E5F3E8;
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
    background: var(--primary);
    color: var(--card);
    padding: 16px 32px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 24px;
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
  .btn-primary-sarathi {
    background: var(--primary);
    color: var(--card);
  }
  .btn-teal {
    background: var(--accent);
    border-color: var(--accent);
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
    border-radius: 7px;
    box-shadow: 0 1px 3px rgba(31, 41, 51, 0.04);
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
    border-radius: 7px;
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
  .analysis-description {
    margin: 0 0 16px;
    color: var(--secondary);
    font-size: 16px;
  }
  .peak-note { margin-top: 16px; }
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
    border-radius: 6px;
    background: var(--card);
    color: var(--text);
    font-family: inherit;
    font-size: 17px;
    box-shadow: none;
  }
  select:focus, input:focus, button:focus, .btn:focus {
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

  .analysis-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 16px;
    font-size: 16px;
  }
  .analysis-table th {
    padding: 12px 16px;
    background: var(--primary);
    color: var(--card);
    text-align: left;
    font-weight: 500;
  }
  .analysis-table td {
    padding: 12px 16px;
    border-bottom: 1px solid var(--border);
    color: var(--text);
  }
  .analysis-table tr:last-child td { border-bottom: none; }

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
    .analysis-table { table-layout: fixed; }
    .analysis-table th, .analysis-table td { padding: 8px 4px; font-size: 15px; }
    .analysis-table .badge { padding: 3px 4px; font-size: 13px; }
  }
"

# ==============================================================
#  Named vector: date display -> stored value (for conversion)
# ==============================================================
DATE_MAP <- setNames(DATES_STORED, DATES_DISPLAY)

# ==============================================================
#  UI
# ==============================================================
ui <- fluidPage(
  # Inject inline CSS
  tags$head(
    tags$style(HTML(SARATHI_CSS)),
    tags$meta(name = "viewport",
              content = "width=device-width, initial-scale=1")
  ),

  # ---- Header ----
  div(class = "sarathi-header",
    div(class = "brand",
      tags$h1("SARATHI"),
      tags$p("Smart Bus Occupancy & Rush Hour Information")
    ),
    # Login / Logout button (toggled by server logic)
    uiOutput("header_btn")
  ),

  # ---- Main content area (public vs TC panel) ----
  uiOutput("main_content")
)

# ==============================================================
#  Server
# ==============================================================
server <- function(input, output, session) {

  # ---- Reactive values ----
  rv <- reactiveValues(
    logged_in     = FALSE,   # is TC logged in?
    show_login    = FALSE,   # is login modal visible?
    login_msg     = "",      # message on login form
    public_result = NULL,    # result data frame for public card
    public_msg    = "",      # message for public panel
    save_msg      = "",      # message after saving
    save_ok       = FALSE
  )

  # =============================================================
  #  HEADER BUTTON (Login / Logout)
  # =============================================================
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

  # Show login modal
  observeEvent(input$btn_show_login, {
    rv$show_login <- TRUE
    rv$login_msg  <- ""
  })

  # Logout
  observeEvent(input$btn_logout, {
    rv$logged_in  <- FALSE
    rv$show_login <- FALSE
    rv$save_msg   <- ""
    rv$save_ok    <- FALSE
  })

  # =============================================================
  #  MAIN CONTENT SWITCH
  # =============================================================
  output$main_content <- renderUI({
    if (rv$show_login && !rv$logged_in) {
      # ---- LOGIN FORM ----
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
          # Login message
          uiOutput("login_msg_ui")
        )
      )

    } else if (rv$logged_in) {
      # ---- TICKET COLLECTOR PANEL ----
      div(class = "main-wrap",
        div(class = "card",
          tags$h3("SARATHI - Ticket Collector Panel"),
          div(class = "two-col",
            # Left column: inputs
            div(
              selectInput("tc_bus",    "Bus Number",
                          choices = BUS_NUMBERS),
              selectInput("tc_route",  "Route",
                          choices = ROUTES),
              selectInput("tc_date",   "Date",
                          choices = DATES_DISPLAY),
              selectInput("tc_timing", "Timing",
                          choices = TIMING_LEVELS)
            ),
            # Right column: capacity + occupied + live preview
            div(
              numericInput("tc_occupied", "Occupied Seats",
                           value = NA, min = 0, step = 1),
              # Live preview box
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
      # ---- PUBLIC PAGE ----
      div(class = "main-wrap",

        # Check Occupancy form
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
              selectInput("pub_date",   "Date",
                          choices = DATES_DISPLAY),
              selectInput("pub_timing", "Timing",
                          choices = TIMING_LEVELS)
            )
          ),
          actionButton("btn_check", "Check Occupancy",
                       class = "btn-primary-sarathi"),
          uiOutput("public_result_ui")
        ),

        # Analysis section (chart + table)
        div(class = "card",
          tags$h3("Average Occupancy by Timing"),
          tags$p(class = "analysis-description",
            "Average occupancy % for the selected bus across all available records."),
          plotOutput("timing_chart", height = "340px"),
          uiOutput("analysis_table_ui"),
          uiOutput("peak_timing_ui")
        )
      )
    }
  })

  # =============================================================
  #  LOGIN LOGIC
  # =============================================================
  output$login_msg_ui <- renderUI({
    if (nchar(rv$login_msg) == 0) return(NULL)
    div(class = "msg-error", rv$login_msg)
  })

  observeEvent(input$btn_login, {
    un <- trimws(input$tc_username)
    pw <- input$tc_password

    # Basic validation
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

  # =============================================================
  #  TICKET COLLECTOR – LIVE PREVIEW
  # =============================================================
  # Reactive: get capacity for selected bus
  tc_capacity <- reactive({
    req(input$tc_bus)
    cap <- tryCatch(get_capacity(input$tc_bus), error = function(e) NA)
    if (is.na(cap) || is.null(cap)) BUS_CAPACITY[input$tc_bus]
    else cap
  })

  output$tc_preview <- renderUI({
    cap <- tc_capacity()
    occ <- input$tc_occupied

    # Show capacity always; rest only when occupied is entered
    if (is.null(occ) || is.na(occ)) {
      return(div(class = "preview-box",
        tags$p(tags$span(class = "preview-label", "Capacity: "),
               tags$span(class = "preview-value", cap, " seats"))
      ))
    }

    # Validation
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

    # Choose badge class
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

  # =============================================================
  #  TICKET COLLECTOR – SAVE
  # =============================================================
  output$save_msg_ui <- renderUI({
    if (nchar(rv$save_msg) == 0) return(NULL)
    cls <- if (rv$save_ok) "msg-success" else "msg-error"
    div(class = cls, rv$save_msg)
  })

  save_action <- function() {
    bus    <- input$tc_bus
    route  <- input$tc_route
    date_d <- DATE_MAP[input$tc_date]   # convert DD-MM-YYYY -> YYYY-MM-DD
    timing <- input$tc_timing
    occ    <- input$tc_occupied
    cap    <- tc_capacity()

    # Validate inputs
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
    ok <- tryCatch(
      save_occupancy(bus, route, date_d, timing, cap, occ),
      error = function(e) FALSE
    )

    if (ok) {
      rv$save_msg <- paste0("\u2713 Record saved for ", bus,
                            " on ", input$tc_date, " at ", timing, ".")
      rv$save_ok  <- TRUE
    } else {
      rv$save_msg <- paste0(
        "Could not save the record. Please check your connection",
        " and try again.")
      rv$save_ok  <- FALSE
    }
  }

  observeEvent(input$btn_save, { save_action() })
  observeEvent(input$btn_logout2, {
    rv$logged_in <- FALSE
    rv$save_msg  <- ""
    rv$save_ok   <- FALSE
  })

  # =============================================================
  #  PUBLIC – CHECK OCCUPANCY
  # =============================================================
  output$public_result_ui <- renderUI({
    if (is.null(rv$public_result) && nchar(rv$public_msg) == 0)
      return(NULL)

    if (nchar(rv$public_msg) > 0) {
      return(div(class = "msg-info", rv$public_msg))
    }

    df  <- rv$public_result
    row <- df[1, ]   # one matching record

    # Build status badges
    crowd_badge <- switch(as.character(row$rush_status),
      "Normal"    = "badge badge-normal",
      "Busy"      = "badge badge-busy",
      "Rush Hour" = "badge badge-rush",
      "Peak Rush" = "badge badge-peak",
      "badge"
    )
    # Derive crowd status from rush status (reverse map)
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

    # Format date for display (YYYY-MM-DD -> DD-MM-YYYY)
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
    bus    <- input$pub_bus
    route  <- input$pub_route
    date_d <- DATE_MAP[input$pub_date]
    timing <- input$pub_timing

    rv$public_result <- NULL
    rv$public_msg    <- ""

    # Try DB first, fall back to CSV
    df <- tryCatch(
      fetch_occupancy(bus, route, date_d, timing),
      error = function(e) data.frame()
    )

    # Fallback to CSV if DB returned nothing
    if (!is.data.frame(df) || nrow(df) == 0) {
      df <- fetch_occupancy_csv(bus, route, date_d, timing)
    }

    if (!is.data.frame(df) || nrow(df) == 0) {
      rv$public_msg <- paste0(
        "No occupancy record found for ", bus,
        " on ", input$pub_date, " at ", timing,
        ". Please try a different combination or check back later.")
    } else {
      rv$public_result <- df
    }
  })

  # =============================================================
  #  ANALYSIS – timing chart and table
  #  (triggered by the public bus selector changing)
  # =============================================================
  analysis_data <- reactive({
    req(input$pub_bus)
    df <- tryCatch(
      fetch_all_for_bus(input$pub_bus),
      error = function(e) data.frame()
    )
    if (!is.data.frame(df) || nrow(df) == 0) {
      df <- fetch_all_for_bus_csv(input$pub_bus)
    }
    mean_by_timing(df)
  })

  output$timing_chart <- renderPlot({
    adf <- analysis_data()
    if (is.null(adf) || nrow(adf) == 0) {
      # Empty placeholder
      par(mar = c(1,1,2,1))
      plot.new()
      title("No data available for this bus yet.", cex.main = 1,
            col.main = "#52606D")
      return()
    }

    # Colours by avg occupancy level
    bar_cols <- sapply(adf$avg_pct, function(p) {
      if (p <= 40)      "#27633A"
      else if (p <= 70) "#805B10"
      else if (p <= 85) "#91451D"
      else              "#8B3030"
    })

    par(mar = c(4, 4, 2, 1), bg = "transparent")
    bp <- barplot(
      adf$avg_pct,
      names.arg  = as.character(adf$timing),
      col        = bar_cols,
      border     = NA,
      ylim       = c(0, 110),
      ylab       = "Avg Occupancy (%)",
      xlab       = "Timing",
      las        = 2,           # rotate x labels
      cex.names  = 0.9,
      cex.axis   = 0.95,
      main       = paste("Average Occupancy % by Timing –", input$pub_bus),
      cex.main   = 1,
      col.main   = "#0B4F8A"
    )
    # Add value labels on bars
    text(bp, adf$avg_pct + 3,
         labels = paste0(adf$avg_pct, "%"),
         cex = 0.9, col = "#1F2933")
  })

  output$analysis_table_ui <- renderUI({
    adf <- analysis_data()
    if (is.null(adf) || nrow(adf) == 0) return(NULL)

    # Build HTML table rows
    rows_html <- ""
    for (i in seq_len(nrow(adf))) {
      crowd <- as.character(adf$crowd_status[i])
      badge_cls <- switch(crowd,
        "Low"       = "badge badge-low",
        "Moderate"  = "badge badge-moderate",
        "High"      = "badge badge-high",
        "Very High" = "badge badge-veryhigh", "badge"
      )
      rows_html <- paste0(rows_html,
        "<tr>",
        "<td>", as.character(adf$timing[i]), "</td>",
        "<td>", adf$avg_pct[i], "%</td>",
        "<td><span class='", badge_cls, "'>", crowd, "</span></td>",
        "</tr>"
      )
    }

    HTML(paste0(
      "<table class='analysis-table'>",
      "<thead><tr>",
      "<th>Timing</th><th>Avg Occupancy %</th><th>Crowd Level</th>",
      "</tr></thead><tbody>",
      rows_html,
      "</tbody></table>"
    ))
  })

  output$peak_timing_ui <- renderUI({
    adf <- analysis_data()
    if (is.null(adf) || nrow(adf) == 0) return(NULL)
    pt <- peak_timing(adf)
    div(class = "msg-info",
        class = "msg-info peak-note",
        paste0("The generally most crowded timing for ",
               input$pub_bus, " is ", pt, "."))
  })

} # end server

# ==============================================================
#  Launch
# ==============================================================
shinyApp(ui = ui, server = server)
