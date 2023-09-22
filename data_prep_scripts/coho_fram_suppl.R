library(tidyverse)

# some older fisheries didn't include NS catch in pre-season FRAM when
# they were mixed regulations, this attempts to rectify that with 
# inputs provided by Angelika

supp <- readxl::read_excel('data/sources/reg_area_year_ts_with_MSF.xlsx') %>%
  janitor::clean_names()


supp_to_db <- supp %>%
  filter(!is.na(ns_catch)) %>%
  mutate(
    yr = as.character(year),
    yr_type = paste0(yr, '_pre'),
    FisheryName = NULL,
    type = 'pre',
    ts = time_step,
    ff = 2,
    area_code = str_pad(as.character(catch_area_code),width = 2,side = 'left',pad = '0'),
    var = 'Quota', # marking this as non-selective
    val = ns_catch
  ) %>%
  select(yr:val)

con <- DBI::dbConnect(RSQLite::SQLite(), here::here('data/coho_harvest_estimator.db'))
DBI::dbWriteTable(con, "coho_fram", supp_to_db, append = T, verbose = T)
DBI::dbExecute(con,
               glue::glue("INSERT INTO update_log (user, datetime, comment)
                 VALUES ('{Sys.getenv('USERNAME')}', '{Sys.time()}', 'appending fram table with supplement fram numbers')"))
DBI::dbDisconnect(con)