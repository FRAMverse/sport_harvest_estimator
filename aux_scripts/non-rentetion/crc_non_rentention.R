library(tidyverse)

# this script will produce non-retention estimates from daily crc estimates
# a better option would probably be just using the marine estimates
# that eric kraig distributes, he highlights illegal catch
# and they're not weighted by raw CRC catch like the daily
# crcs are
# Ty Garber 3/1/2023

# connect to database
con <- DBI::dbConnect(RSQLite::SQLite(), here::here('data/coho_harvest_estimator.db'))


# pull out regulations
pssp <- DBI::dbReadTable(con, 'coho_regulations')

# disconnect from database
DBI::dbDisconnect(con)


# pull and explode regulation days from the database
# these are only days when the fisheries have been open
open <- pssp %>%
  rowwise() %>%
  mutate(
    day = list(seq(as.Date(start_datetime), as.Date(end_datetime), by = 'day'))
  ) %>%
  unnest(day) %>%
  select(
    catch_area_code, day
  )

# read in daily crcs
crc <- readxl::read_excel(
  path = here::here('data/sources/crc_daily_estimates.xlsx'),
  sheet = "Sheet1",
  col_types = c('text', 'numeric', 'text', 'text', 'text','text', 'date', 'numeric')) %>%
  janitor::clean_names() %>% # no dumb names
  filter(
    !area %in% c('2-1', '2-2', '22'), # no willipa bay
    species == 'Coho' # only want coho
  ) %>%
  mutate(
    date = as.Date(date), # don't need or want times
    area = str_remove(area, '-'), # 8-1, 8-2 -> 81, 82
    area = str_pad(area, 2, 'left', '0') # catch area padding 5 -> 05 
  ) 

# find where there is crc catch when the fisheries are closed
# dump to a csv
crc %>%
  anti_join(open, by = c('area' = 'catch_area_code', 'date' = 'day')) %>%
  filter(year >= 2003,
         !area %in% c('21', '22')
         ) %>%
  arrange(-fish) %>%
  write.csv(., 'crc_coho_non_ret.csv')

