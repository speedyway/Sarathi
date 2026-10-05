# ============================================================
# functions.R  –  SARATHI helper functions and fixed data
# ============================================================

library(httr)
library(jsonlite)
library(digest)

# ------------------------------------------------------------
# 1. Fixed reference data (stored as vectors / named vector)
# ------------------------------------------------------------

BUS_NUMBERS <- sprintf("SB-%02d", 1:10)
# Give each bus a capacity (40, 45, or 50 seats)
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

# Display labels for the UI (DD-MM-YYYY)
DATES_DISPLAY <- c(
  "01-10-2026", "02-10-2026", "03-10-2026",
  "04-10-2026", "05-10-2026", "06-10-2026", "07-10-2026"
)
# Stored values (YYYY-MM-DD)
DATES_STORED <- c(
  "2026-10-01", "2026-10-02", "2026-10-03",
  "2026-10-04", "2026-10-05", "2026-10-06", "2026-10-07"
)

# Timings as an ordered factor (for analysis)
TIMING_LEVELS <- c(
  "7:00 AM", "8:00 AM", "9:00 AM",
  "12:00 PM", "1:00 PM", "2:00 PM",
  "5:00 PM", "6:00 PM", "7:00 PM", "8:00 PM"
)

# Crowd status ordered factor levels
CROWD_LEVELS <- c("Low", "Moderate", "High", "Very High")

# ------------------------------------------------------------
# 2. Core calculation functions
# ------------------------------------------------------------

# Returns number of vacant seats
calculate_vacancy <- function(capacity, occupied) {
  capacity - occupied
}

# Returns occupancy percentage, rounded to 1 decimal place
calculate_occupancy <- function(capacity, occupied) {
  round((occupied / capacity) * 100, 1)
}

# Returns crowd status string based on occupancy %
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

# Returns rush status string based on crowd status
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

# Convenience: compute all fields from capacity + occupied
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

# ------------------------------------------------------------
# 3. SHA-256 password hashing (uses digest package)
# ------------------------------------------------------------

hash_password <- function(plain_text) {
  digest(plain_text, algo = "sha256", serialize = FALSE)
}

# ------------------------------------------------------------
# 4. Supabase connection helpers
# ------------------------------------------------------------

# Build the base URL for a Supabase REST table endpoint
sb_url <- function(table) {
  base <- sub("/+$", "", Sys.getenv("SUPABASE_URL"))
  paste0(base, "/rest/v1/", table)
}

# Common headers required by every Supabase REST call
sb_headers <- function(prefer = "return=representation") {
  key <- Sys.getenv("SUPABASE_KEY")
  add_headers(
    apikey        = key,
    Authorization = paste("Bearer", key),
    `Content-Type`  = "application/json",
    Prefer          = prefer
  )
}

# GET rows from a table; returns a data frame (or empty df on error)
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

# POST a new row; returns TRUE on success
sb_post <- function(table, body_list, query_params = list(),
                    prefer = "return=representation") {
  if (nchar(Sys.getenv("SUPABASE_URL")) == 0 ||
      nchar(Sys.getenv("SUPABASE_KEY")) == 0) {
    return(FALSE)
  }

  tryCatch({
    resp <- POST(
      sb_url(table),
      sb_headers(prefer),
      query = query_params,
      body = charToRaw(as.character(toJSON(list(body_list), auto_unbox = TRUE))),
      encode = "raw"
    )
    status_code(resp) %in% c(200, 201)
  }, error = function(e) FALSE)
}

# ------------------------------------------------------------
# 5. Application-level database functions
# ------------------------------------------------------------

# Verify ticket collector credentials; returns TRUE if valid
verify_collector <- function(username, password) {
  hashed <- hash_password(password)
  rows   <- sb_get("ticket_collectors",
                   list(username = paste0("eq.", username),
                        password = paste0("eq.", hashed),
                        select   = "id"))
  if (!isTRUE(attr(rows, "request_ok"))) return(NA)
  is.data.frame(rows) && nrow(rows) > 0
}

# Look up capacity for a bus number from the buses table
# Falls back to BUS_CAPACITY vector if DB unreachable
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

# Save or update an occupancy record using the unique key
save_occupancy <- function(bus_number, route, travel_date,
                           timing, capacity, occupied) {
  # Calculate derived fields
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

# Fetch one occupancy record for the public result card
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

# Fetch all records for a bus (for the analysis chart)
fetch_all_for_bus <- function(bus_number) {
  sb_get("occupancy_records", list(
    bus_number = paste0("eq.", bus_number),
    select     = "timing,occupancy_percentage"
  ))
}

# ------------------------------------------------------------
# 6. Rush-hour analysis helpers
# ------------------------------------------------------------

# Compute mean occupancy % per timing from a data frame
mean_by_timing <- function(df) {
  if (!is.data.frame(df) || nrow(df) == 0) return(NULL)
  # Use tapply to get means, then convert to data frame
  means <- tapply(df$occupancy_percentage, df$timing, mean, na.rm = TRUE)
  result <- data.frame(
    timing  = names(means),
    avg_pct = round(as.numeric(means), 1),
    stringsAsFactors = FALSE
  )
  # Sort by the fixed timing order (treat timing as ordered factor)
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

# Returns the timing with the highest average occupancy
peak_timing <- function(analysis_df) {
  if (is.null(analysis_df) || nrow(analysis_df) == 0) return("N/A")
  analysis_df$timing[which.max(analysis_df$avg_pct)]
}

# ------------------------------------------------------------
# 7. CSV fallback loader
# ------------------------------------------------------------

# Load data.csv as a fallback when DB is unreachable
load_csv_fallback <- function() {
  path <- "data.csv"
  if (file.exists(path)) {
    tryCatch(read.csv(path, stringsAsFactors = FALSE),
             error = function(e) data.frame())
  } else {
    data.frame()
  }
}

# Fetch occupancy from CSV fallback
fetch_occupancy_csv <- function(bus_number, route, travel_date, timing) {
  df <- load_csv_fallback()
  if (nrow(df) == 0) return(data.frame())
  df[df$bus_number  == bus_number  &
     df$route       == route       &
     df$travel_date == travel_date &
     df$timing      == timing, ]
}

# Fetch all records for a bus from CSV fallback
fetch_all_for_bus_csv <- function(bus_number) {
  df <- load_csv_fallback()
  if (nrow(df) == 0) return(data.frame())
  df[df$bus_number == bus_number,
     c("timing", "occupancy_percentage")]
}
