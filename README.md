# SARATHI – Smart Bus Occupancy & Rush Hour System

A clean, beginner-friendly academic R Shiny application for tracking bus occupancy and rush hour conditions, built strictly with **R, Shiny, httr, jsonlite, and digest** without external frontend frameworks or machine learning complexity.

---

## 1. Overview & Workflow

SARATHI provides two streamlined views:
- **Public Passenger View (Default):** Select a bus number, route, date, and timing to check real-time occupancy percentage, crowd status badge, vacancy count, and rush hour category. An analysis card displays average occupancy by timing and general peak hours via a base-R bar chart.
- **Ticket Collector Panel:** Secure login (SHA-256 password hashing) allowing collectors to submit or update occupied seat counts with live vacancy and rush hour calculations. Upserts avoid duplicate records for the same bus, route, date, and timing.

---

## 2. Technology Stack & Constraints

- **Language:** R (>= 4.2)
- **UI & Layout:** R Shiny, HTML, and inline CSS in `app.R` (responsive, clean transit design system)
- **Allowed Packages:** `shiny`, `httr`, `jsonlite`, `digest`
- **Database:** Supabase PostgreSQL via REST API (`httr` / `jsonlite`)
- **Graphics:** Base R `barplot()`
- **Deployment:** `manifest.json` generated for Posit Connect / shinyapps.io

Install dependencies:

```r
install.packages(c("shiny", "httr", "jsonlite", "digest", "rsconnect"))
```

---

## 3. Project File Structure

```
Sarathi/
├── app.R              # Shiny UI, server logic, and inline CSS theme
├── functions.R        # Calculation helpers, fixed vectors, and Supabase REST wrappers
├── data.csv           # Sample seed dataset (160 rows) & automatic offline fallback
├── manifest.json      # Deployment manifest capturing dependencies and files
├── .Renviron          # Environment variables (ignored by Git)
├── .Renviron.example  # Template for environment credentials
├── .gitignore         # Prevents credential leaks and session cache commits
└── README.md          # Project setup, database schema, and run instructions
```

---

## 4. Supabase Database Setup

### 4a. SQL Schema

Open **Supabase Dashboard → SQL Editor** and execute the following DDL:

```sql
-- 1. Ticket Collectors Table
CREATE TABLE ticket_collectors (
  id        BIGSERIAL PRIMARY KEY,
  username  TEXT UNIQUE NOT NULL,
  password  TEXT        NOT NULL   -- SHA-256 hash (never plain text)
);
ALTER TABLE ticket_collectors ENABLE ROW LEVEL SECURITY;

-- 2. Buses Reference Table
CREATE TABLE buses (
  id         BIGSERIAL PRIMARY KEY,
  bus_number TEXT UNIQUE NOT NULL,
  route      TEXT NOT NULL,
  capacity   INTEGER NOT NULL CHECK (capacity > 0)
);
ALTER TABLE buses ENABLE ROW LEVEL SECURITY;

-- 3. Occupancy Records Table
CREATE TABLE occupancy_records (
  id                   BIGSERIAL PRIMARY KEY,
  bus_number           TEXT    NOT NULL,
  route                TEXT    NOT NULL,
  travel_date          DATE    NOT NULL,
  timing               TEXT    NOT NULL,
  capacity             INTEGER NOT NULL,
  occupied             INTEGER NOT NULL CHECK (occupied >= 0 AND occupied <= capacity),
  vacant               INTEGER NOT NULL,
  occupancy_percentage NUMERIC(5,1) NOT NULL,
  rush_status          TEXT    NOT NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_record UNIQUE (bus_number, route, travel_date, timing)
);
ALTER TABLE occupancy_records ENABLE ROW LEVEL SECURITY;
```

### 4b. Seed Reference Buses

```sql
INSERT INTO buses (bus_number, route, capacity) VALUES
  ('SB-01', 'Railway Station - CBS - Shahgunj', 45),
  ('SB-02', 'Railway Station - CBS - Harsul', 50),
  ('SB-03', 'Railway Station - CBS - CIDCO', 40),
  ('SB-04', 'Aurangapura - CBS - Ranjangaon', 50),
  ('SB-05', 'Aurangapura - CBS - Bajajnagar', 45),
  ('SB-06', 'Aurangapura - CBS - Hindustan Awas', 40),
  ('SB-07', 'Aurangapura - CBS - Waluj', 50),
  ('SB-08', 'Aurangapura - Chikalthana', 45),
  ('SB-09', 'Aurangapura - Kranti Chowk - Shivajinagar', 40),
  ('SB-10', 'Aurangapura - Osmanpura - Deolai', 50)
ON CONFLICT (bus_number) DO UPDATE
SET route = EXCLUDED.route, capacity = EXCLUDED.capacity;
```

### 4c. Create Ticket Collector Account

Generate the SHA-256 password hash in R:

```r
library(digest)
digest("your_secure_password", algo = "sha256", serialize = FALSE)
```

Insert the collector record:

```sql
INSERT INTO ticket_collectors (username, password)
VALUES ('collector1', '<paste_generated_sha256_hash>');
```

### 4d. Security & Access Policy (RLS)

- Sensitive credentials remain server-side in `.Renviron`.
- The R server communicates over HTTPS using REST endpoints.
- Configure appropriate policies in Supabase so `occupancy_records` can be queried by public readers and written only by the application backend.

---

## 5. Configuration (`.Renviron`)

Create a `.Renviron` file in the root directory:

```bash
cp .Renviron.example .Renviron
```

Define your Supabase credentials:

```ini
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_KEY=your-supabase-key
```

*Note: Restart your R session after updating `.Renviron`.*

---

## 6. Seed Data & Offline Fallback

If Supabase is unreachable or credentials are not yet configured, SARATHI automatically loads `data.csv` as an offline fallback so testing and grading can proceed uninterrupted.

To upload all records from `data.csv` into Supabase:

```r
source("functions.R")
sample_data <- read.csv("data.csv", stringsAsFactors = FALSE)
for (i in seq_len(nrow(sample_data))) {
  r <- sample_data[i, ]
  save_occupancy(
    r$bus_number, r$route, r$travel_date, r$timing,
    r$capacity, r$occupied
  )
}
```

---

## 7. Running the Application

### Locally via R Console or RStudio

```r
shiny::runApp("app.R", port = 4848, launch.browser = TRUE)
```

### Deployment with `manifest.json`

The included `manifest.json` records the R environment, dependencies, and file hashes for reproducibility and direct Git-backed deployment to **Posit Connect**, **shinyapps.io**, or cloud hosting platforms.

To regenerate or update `manifest.json` at any time:

```r
rsconnect::writeManifest(appFiles = c("app.R", "functions.R", "data.csv"))
```

---

## 8. Calculation & Logic Summary

| Metric | Rule / Formula |
|---|---|
| **Vacant Seats** | `capacity - occupied` |
| **Occupancy %** | `(occupied / capacity) * 100` (1 decimal place) |
| **Crowd Status** | `0–40%`: Low \| `41–70%`: Moderate \| `71–85%`: High \| `86–100%`: Very High |
| **Rush Status** | `Low` → Normal \| `Moderate` → Busy \| `High` → Rush Hour \| `Very High` → Peak Rush |
| **Rush-Hour Analysis** | Mean occupancy per timing via `tapply()`, ordered factors, and base R bar chart |
