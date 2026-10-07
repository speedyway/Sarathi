library(httr)
library(jsonlite)
library(digest)

BUS_NUMBERS <- sprintf("SB-%02d", 1:10)
BUS_CAPACITY <- c(
  "SB-01" = 45, "SB-02" = 50, "SB-03" = 40,
  "SB-04" = 50, "SB-05" = 45, "SB-06" = 40,
  "SB-07" = 50, "SB-08" = 45, "SB-09" = 40,
  "SB-10" = 50
)

ROUTES <- c(
  "Railway Station - CBS - Shahgunj",
  "Railway Station - CBS - Harsul",
  "Railway Station - CBS - CIDCO",
  "Aurangapura - CBS - Ranjangaon",
  "Aurangapura - CBS - Bajajnagar",
  "Aurangapura - CBS - Hindustan Awas",
  "Aurangapura - CBS - Waluj",
  "Aurangapura - Chikalthana",
  "Aurangapura - Kranti Chowk - Shivajinagar",
  "Aurangapura - Osmanpura - Deolai",
  "Chikalthana - Kranti Chowk - CBS",
  "Harsul - CBS - Nakshatrawadi",
  "CIDCO - TV Centre - Railway Station",
  "CIDCO - Railway Station - Waluj",
  "CIDCO - Ranjangaon - Jogeshwari"
)

TIMING_LEVELS <- c(
  "7:00 AM", "8:00 AM", "9:00 AM",
  "12:00 PM", "1:00 PM", "2:00 PM",
  "5:00 PM", "6:00 PM", "7:00 PM", "8:00 PM"
)

CROWD_LEVELS <- c("Low", "Moderate", "High", "Very High")

calculate_vacancy <- function(capacity, occupied) {
  capacity - occupied
}

calculate_occupancy <- function(capacity, occupied) {
  round((occupied / capacity) * 100, 1)
}

get_crowd_status <- function(pct) {
  if (pct <= 40) {
    "Low"
  } else if (pct <= 70) {
    "Moderate"
  } else if (pct <= 85) {
    "High"
  } else {
    "Very High"
  }
}

get_rush_status <- function(crowd) {
  if (crowd == "Low") {
    "Normal"
  } else if (crowd == "Moderate") {
    "Busy"
  } else if (crowd == "High") {
    "Rush Hour"
  } else {
    "Peak Rush"
  }
}

calculate_all <- function(capacity, occupied) {
  vacant      <- calculate_vacancy(capacity, occupied)
  pct         <- calculate_occupancy(capacity, occupied)
  crowd       <- get_crowd_status(pct)
  rush        <- get_rush_status(crowd)
  list(
    vacant = vacant, pct = pct,
    crowd  = crowd,  rush = rush
  )
}


sb_url <- function(table) {
  base <- sub("/+$", "", Sys.getenv("SUPABASE_URL"))
  paste0(base, "/rest/v1/", table)
}

sb_headers <- function(prefer = "return=representation") {
  key <- Sys.getenv("SUPABASE_KEY")
  add_headers(
    apikey        = key,
    `Content-Type` = "application/json",
    Prefer         = prefer
  )
}

sb_get <- function(table, query_params = list()) {
  if (nchar(Sys.getenv("SUPABASE_URL")) == 0 ||
      nchar(Sys.getenv("SUPABASE_KEY")) == 0) {
    return(structure(data.frame(), request_ok = FALSE))
  }

  tryCatch({
    resp <- GET(sb_url(table), sb_headers(), query = query_params)
    if (status_code(resp) %in% c(200, 206)) {
      result <- fromJSON(content(resp, "text", encoding = "UTF-8"),
                         flatten = TRUE)
      if (!is.data.frame(result)) result <- as.data.frame(result)
      attr(result, "request_ok") <- TRUE
      result
    } else {
      structure(data.frame(), request_ok = FALSE)
    }
  }, error = function(e) structure(data.frame(), request_ok = FALSE))
}

sb_post <- function(table, body_list, query_params = list(),
                    prefer = "return=representation") {
  missing_config <- c(
    if (nchar(Sys.getenv("SUPABASE_URL")) == 0) "SUPABASE_URL",
    if (nchar(Sys.getenv("SUPABASE_KEY")) == 0) "SUPABASE_KEY"
  )
  if (length(missing_config) > 0) {
    return(list(
      ok = FALSE,
      status = NA_integer_,
      body = paste(
        "Request not sent; missing environment variable(s):",
        paste(missing_config, collapse = ", ")
      )
    ))
  }

  redact_error <- function(message) {
    message <- as.character(message)
    key <- Sys.getenv("SUPABASE_KEY")
    if (nzchar(key)) {
      message <- gsub(key, "[REDACTED]", message, fixed = TRUE)
    }
    gsub(
      "(?i)(apikey|api[_-]?key|authorization|supabase[_-]?key|secret|password|credential|access[_-]?token|refresh[_-]?token)([\"']?\\s*[:=]\\s*[\"']?)[^\"'\\r\\n,}]+",
      "\\1\\2[REDACTED]",
      message,
      perl = TRUE
    )
  }

  tryCatch({
    resp <- POST(
      sb_url(table),
      sb_headers(prefer),
      query = query_params,
      body = charToRaw(as.character(toJSON(list(body_list), auto_unbox = TRUE))),
      encode = "raw"
    )
    status <- status_code(resp)
    ok <- status %in% c(200, 201)
    response_body <- content(resp, "text", encoding = "UTF-8")
    if (!ok) {
      response_body <- redact_error(response_body)
      if (!nzchar(response_body)) {
        response_body <- "(empty response body)"
      }
    }
    list(
      ok = ok,
      status = status,
      body = response_body
    )
  }, error = function(e) {
    list(
      ok = FALSE,
      status = NA_integer_,
      body = redact_error(conditionMessage(e))
    )
  })
}


verify_collector <- function(username, password) {
  if (!is.character(username) || !is.character(password)) {
    return(FALSE)
  }

  expected_hash <- digest("Sarathi123", algo = "sha256", serialize = FALSE)
  username == "collector1" &&
    digest(password, algo = "sha256", serialize = FALSE) == expected_hash
}

get_capacity <- function(bus_number) {
  rows <- sb_get("buses",
                 list(bus_number = paste0("eq.", bus_number),
                      select     = "capacity"))
  if (is.data.frame(rows) && nrow(rows) > 0) {
    as.integer(rows$capacity[1])
  } else {
    as.integer(BUS_CAPACITY[bus_number])
  }
}

save_occupancy <- function(bus_number, route, travel_date,
                           timing, capacity, occupied) {
  res <- calculate_all(capacity, occupied)

  body <- list(
    bus_number         = bus_number,
    route              = route,
    travel_date        = travel_date,
    timing             = timing,
    capacity           = capacity,
    occupied           = as.integer(occupied),
    vacant             = res$vacant,
    occupancy_percentage = res$pct,
    rush_status        = res$rush
  )

  sb_post(
    "occupancy_records",
    body,
    query_params = list(on_conflict = "bus_number,route,travel_date,timing"),
    prefer = "resolution=merge-duplicates,return=representation"
  )
}

fetch_occupancy <- function(bus_number, route, travel_date, timing) {
  sb_get("occupancy_records", list(
    bus_number  = paste0("eq.", bus_number),
    route       = paste0("eq.", route),
    travel_date = paste0("eq.", travel_date),
    timing      = paste0("eq.", timing),
    select      = paste(
      "bus_number,route,travel_date,timing,capacity,",
      "occupied,vacant,occupancy_percentage,rush_status",
      sep = ""
    )
  ))
}

fetch_all_for_bus <- function(bus_number) {
  sb_get("occupancy_records", list(
    bus_number = paste0("eq.", bus_number),
    select     = "timing,occupancy_percentage"
  ))
}

mean_by_timing <- function(df) {
  if (!is.data.frame(df) || nrow(df) == 0) return(NULL)
  means <- tapply(df$occupancy_percentage, df$timing, mean, na.rm = TRUE)
  result <- data.frame(
    timing  = names(means),
    avg_pct = round(as.numeric(means), 1),
    stringsAsFactors = FALSE
  )
  result$timing <- factor(result$timing,
                          levels = TIMING_LEVELS, ordered = TRUE)
  result$crowd_status <- factor(
    vapply(result$avg_pct, get_crowd_status, character(1)),
    levels = CROWD_LEVELS,
    ordered = TRUE
  )
  result <- result[order(result$timing), ]
  result
}

peak_timing <- function(analysis_df) {
  if (is.null(analysis_df) || nrow(analysis_df) == 0) return("N/A")
  analysis_df$timing[which.max(analysis_df$avg_pct)]
}


load_csv_fallback <- function() {
  path <- "data.csv"
  if (file.exists(path)) {
    tryCatch(read.csv(path, stringsAsFactors = FALSE),
             error = function(e) data.frame())
  } else {
    data.frame()
  }
}

fetch_occupancy_csv <- function(bus_number, route, travel_date, timing) {
  df <- load_csv_fallback()
  if (nrow(df) == 0) return(data.frame())
  df[df$bus_number  == bus_number  &
     df$route       == route       &
     df$travel_date == travel_date &
     df$timing      == timing, ]
}

fetch_all_for_bus_csv <- function(bus_number) {
  df <- load_csv_fallback()
  if (nrow(df) == 0) return(data.frame())
  df[df$bus_number == bus_number,
     c("timing", "occupancy_percentage")]
}
