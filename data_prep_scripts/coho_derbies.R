# accounting for derbies, 
# Ty Garber 1/26/2026

# pull derbies

cli::cli_alert_info('Adding derbies...')


derbies <- readxl::read_excel(here::here('data/sources/derbies.xlsx'), sheet = 'data')

# translate to daily, wrangle
derby_db <- derbies |>
  rowwise() |>
  mutate(
    date = list(seq(start_date, end_date, by = 'day')),
    days = length(date) # divisor later
  ) |>
  unnest(date) |>
  rowwise() |>
  mutate(
    area_code = str_pad(area_code, 2, 'left', '0'),
    across(starts_with('coho_'), \(x) x / days),
    time_step = case_match(lubridate::month(date),
                           1:6 ~ 1,
                           7 ~ 2,
                           8 ~ 3,
                           9 ~ 4,
                           10:12 ~ 5
                           
    
    ),
    date = as.character(date),
    year = lubridate::year(date),
    day_type = if_else(
      lubridate::wday(date) %in% c(2:5) & 
        !is_holiday_weekend(date), 'WD', 'WE'), # is_holiday... lives in coho_estimates.r
    source = 'DERBY'
  ) |>
  select(area_code, date, year, time_step, day_type, starts_with('coho_'), source)

# check for error
original_sum <- derbies |>
  select(starts_with('coho_')) |>
  sum()

mutated_sum <- derby_db  |>
  select(starts_with('coho_')) |>
  sum()

if(original_sum != mutated_sum){
  # throw error
  cli::cli_alert_warning('Error while compiling derbies to daily values, check 
                         the derby sheet and coho in `coho_derbies.r`. Derby
                         values not entered into database')
} else {
  # APPEND into database
  con <- DBI::dbConnect(RSQLite::SQLite(), here::here('data/coho_harvest_estimator.db'))

  DBI::dbWriteTable(con, "coho_estimates", derby_db, append = T)
  DBI::dbDisconnect(con)
  
  cli::cli_alert_success('Derbies added to `coho_estimates` table.')
}

  



