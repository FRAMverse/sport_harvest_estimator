# if taking the mean, 0's are important
# crcs use the dumb 'if there's a 0 i'll not add row' 
# strategy to their data... like it's the 70's and 
# we're still entering data on punch cards
# below is adding 0's back in to the means,
# being mindful that if dataset is incomplete
# to preserve NA's

print('Fisheries where there was no catch will now be zeros \n
      inseted of NA')


con <- DBI::dbConnect(RSQLite::SQLite(), here::here('data/coho_harvest_estimator.db'))
# pull necessary tables and view

# puget sound creel information merged to regulation
pssp <- DBI::dbReadTable(con, 'vw_estimates_by_regulation')


# puget sound creel information merged to regulation
regs <- DBI::dbReadTable(con, 'coho_regulations')



# this is specifically dealing with cases where there was no coho catch in 
# entire fisheries  - nearly all time step 5/1
fisheries_no_catch <- pssp %>%
  filter(is.na(day_type)) %>%
  select(area_code = catch_area_code, regulation_type_code, 
         start_datetime, end_datetime, starts_with('coho')) %>%
  mutate(
    across(starts_with('coho'), ~replace_na(.x, 0))
  ) %>%
  rowwise() %>%
  mutate(
    date = list(seq(as.Date(start_datetime), as.Date(end_datetime), by = '1 day'))
  ) %>%
  unnest_longer(date) %>% # explode stratum
  mutate(
    day_type = if_else(lubridate::wday(date) %in% c(1,6,7), 'WE', 'WD'), # weekday / weekend
    time_step = case_when(
      lubridate::month(date) %in% c(1,2,3,4,5,6) ~ 1L,
      lubridate::month(date)  == 7 ~ 2L,
      lubridate::month(date)  == 8 ~ 3L,
      lubridate::month(date)  == 9 ~ 4L,
      lubridate::month(date) %in% c(10, 11, 12) ~ 5L
    ),
    year = lubridate::year(date),
    date = as.character(date),
    source = 'CRC'
  )

# crc estimate cycles should be continuous up to 3/31 of the preceding management year
# we shouldn't have regulations into the future (this is what this tool does)
# to figure out the management year take the max year in the regulations
# say 2022 - everything after 2022-03-31 should either be intensive monitoring estimates
# or covered by crcs we don't have yet (NA)

# figure out most recent management year
# DO NOT PUT FUTURE DATES IN THE REGULATIONS FILE
management_year <- lubridate::year(max(regs$end_datetime))

no_catch_no_estimate <- fisheries_no_catch %>%
  mutate(
    across(starts_with('coho'),
           ~if_else(date >= as.Date(glue::glue('{management_year}-04-01')), NA_real_, .x)
    )
  )

# this should be a list of fisheries where we don't have CRC estimates yet
# no_catch_no_estimate %>%
#   filter(is.na(coho_104_ad_ret)) %>%
#   count(area_code, start_datetime, end_datetime)

# this is a list of fisheries where the catch has been zero'd out (from CRC data)
no_catch_no_estimate %>%
  filter(!is.na(coho_104_ad_ret)) %>%
  count(area_code, start_datetime, end_datetime) %>%
  print(n=100)

# remove fisheries where there were no catch from estimates (added back in later dailyfied)
daily_estimates_fisheries_no_catch <- pssp %>%
  filter(!is.na(day_type)) %>%
  mutate(date = as.character(date)) %>%
  bind_rows(no_catch_no_estimate) %>%
  filter(year >= 2004) %>% # crc weirdness with 2003
  select(area_code, date, starts_with('coho'), year, time_step, day_type, source)
# now means make sense

DBI::dbWriteTable(con, "coho_estimates", daily_estimates_fisheries_no_catch, overwrite = T)
DBI::dbDisconnect(con)

rm('con', 'fisheries_no_catch', 'no_catch_no_estimate', 'pssp', 'regs')
































