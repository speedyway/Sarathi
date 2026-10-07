# SARATHI

## Smart Bus Occupancy and Rush Hour System

SARATHI is a simple R Shiny-based web application that provides bus occupancy information to passengers.

A ticket collector can enter the occupied seats for a selected bus, route, date, and timing. R calculates vacant seats, occupancy percentage, crowd level, and rush status. The record is stored in Supabase.

A public user can select the bus, route, date, and timing to view the available occupancy information.

## Main Features

- Public user bus occupancy search
- Ticket Collector login and occupancy entry
- Dynamic date selection for any year
- Bus, route, date, and timing selection
- Automatic vacant-seat calculation
- Occupancy percentage calculation
- Crowd status: Low, Moderate, High, Very High
- Rush status: Normal, Busy, Rush Hour, Peak Rush
- Supabase storage for occupancy records
- Basic input validation
- Clean and responsive user interface

## Technology Used

- R
- R Shiny
- HTML
- CSS
- Supabase REST API

## R Concepts Used

The project applies practical R concepts including:

- Variables and operators
- Conditional statements (`if`, `else if`, `else`)
- User-defined functions
- Vectors
- Lists
- Data frames
- Factors
- Indexing and subsetting
- Mathematical calculations
- Basic statistical calculations
- Reading and writing data
- Graphical representation where required

## Project Structure

```text
Sarathi/
├── app.R
├── functions.R
├── data.csv
├── manifest.json
├── README.md
└── Sarathi.Rproj
```

## Application Workflow

```text
Ticket Collector
      ↓
Login
      ↓
Select Bus + Route + Date + Timing
      ↓
Enter Occupied Seats
      ↓
R calculates Vacancy + Occupancy + Rush Status
      ↓
Save to Supabase

Public User
      ↓
Select Bus + Route + Date + Timing
      ↓
Search
      ↓
R retrieves the matching record
      ↓
Display Occupancy Information
```

## Occupancy Calculation

```text
Vacant Seats = Total Capacity - Occupied Seats

Occupancy % = (Occupied Seats / Total Capacity) × 100
```

Crowd and rush levels are determined from the calculated occupancy percentage.

## Database

Supabase is used to store bus information and occupancy records.

The application reads the Supabase URL and key through environment variables.

**Do not store Supabase secrets directly in the source code. Do not commit `.Renviron` to GitHub.**

## Running the Project Locally

1. Open `Sarathi.Rproj` in RStudio.
2. Make sure the required R packages are installed.
3. Configure the Supabase environment variables locally.
4. Run:

```r
shiny::runApp()
```

## Deployment

The application is deployed as an R Shiny application through Posit Connect Cloud.

## Notes

SARATHI is designed as a simple R-based application for recording and displaying bus occupancy information. It focuses on recorded occupancy data and basic calculations rather than complex prediction or machine learning.
