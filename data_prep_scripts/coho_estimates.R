library(tidyverse)

# This script loads stratum estimates, transforms to daily estimates
# assigns a timestep then saves them to the coho_estimator database
# Note: Allocated catch is UNIFORM across individual stratum
# Ty Garber 12/7/2022

# load estimates
print('### Intestive creel ###')

print('Loading daily intensive creel estimate file')
intense_creel <- read_csv(here::here('data/sources/daily_coho_intensive.csv')) %>%
  janitor::clean_names() %>%
  filter(area != '61') %>% # <-- Area 61 should be better covered by the coho directed estimatws (A6)
  select(-x1, -study_code)

print('Loading daily CRC estimate file')
crc <- readxl::read_excel(
  path = here::here('data/sources/crc_daily_estimates.xlsx'),
  sheet = "Sheet1",
  col_types = c('text', 'numeric', 'text', 'text', 'text','text', 'date', 'numeric')) %>%
  janitor::clean_names() %>% # no dumb names
  filter(
    !area %in% c('2-1', '2-2'), # no willipa bay
    species == 'Coho' # only want coho
  ) %>%
  mutate(
    date = as.Date(date), # don't need or want times
    area = str_remove(area, '-'), # 8-1, 8-2 -> 81, 82
    area = str_pad(area, 2, 'left', '0') # catch area padding 5 -> 05 
  ) 


print('Cleaning a prepping CRC data')
crc_est <- crc %>%
  mutate(
    species = tolower(species),
    mark = case_when(
      is.na(mark) ~ 'uk',
      mark == 'M' ~ 'ad',
      mark == 'U' ~ 'um'
    ),
    source = 'CRC',
    field = paste0(species, '_104_', mark, '_ret') # all crc are kept
  ) %>%
  select(area, date, fish, field, source) %>%
  group_by(area, date, field, source) %>%
  summarize(fish = sum(fish, na.rm=T), .groups = 'drop') %>%
  pivot_wider(names_from = field, values_from = fish, values_fill = 0)

print('Subtituting CRC estimates into creel estimates (this can take a bit)')
# bind datasets
crc_intense <- intense_creel %>%
  bind_rows(crc_est)

# substitute
daily_estimates <- crc_intense %>%
  group_by(area, date) %>%
  nest() %>%
  mutate(
    estimates = map(data, ~{
      if (nrow(.x) > 1) {
        .x %>%
          filter(source == 'CREEL')
      } else{
        .x
      }
    }
    )
  ) %>%
  unnest(estimates) %>%
  select(-data)


print('Checking for duplicate days in estimate data')

dupes <- daily_estimates %>%
  count(area, date) %>%
  filter(n > 1)


# if there are duplicates throw an error
if(nrow(dupes) > 0){
  rlang::abort(glue::glue('There are duplicated days in the crc substituted data: \n
                          {unique(dupes$date)}
                          ')
  )
}
print('Adding time steps and week day type columns prepping for db,
      this can take a few...')

# helper function to test if a monday lands on
# major holiday - sampling program stratifies
# this case as WE

is_holiday_weekend <- function(date){
  if(lubridate::wday(date) == 2) { # test if f monday
    if(
      date == as.Date(timeDate::USMemorialDay(lubridate::year(date))) |
      date == as.Date(timeDate::USLaborDay(lubridate::year(date))) |
      date == as.Date(timeDate::USChristmasDay(lubridate::year(date))) |
      date == as.Date(timeDate::USIndependenceDay(lubridate::year(date))) |
      date == as.Date(timeDate::USNewYearsDay(lubridate::year(date))) 
    ) {
      return(TRUE)
    } else {
      return(FALSE)
    }
  } else {
    return(FALSE)
  }
}

print('Adding parameters')
# this is inefficient but works well enough
daily_estimates <- daily_estimates %>%
  ungroup() %>%
  mutate(
    time_step = case_when(
      lubridate::month(date) %in% c(1,2,3,4,5,6) ~ 1L,
      lubridate::month(date)  == 7 ~ 2L,
      lubridate::month(date)  == 8 ~ 3L,
      lubridate::month(date)  == 9 ~ 4L,
      lubridate::month(date) %in% c(10, 11, 12) ~ 5L
      ),
    year = lubridate::year(date)
  ) %>%
  rowwise() %>%
  mutate(
    day_type = if_else(
      lubridate::wday(date) %in% c(2:5) & 
        !is_holiday_weekend(date), 'WD', 'WE'), # if monday is a holiday = WE
    date = as.character(date)
  ) %>% select(area_code = area, everything())

print('Removing extra environmental variables')
rm(list=c('crc', 'crc_est', 'crc_intense', 'dupes', 'intense_creel'))
print('Done!')

# checks
# sum(ests$boats) == sum(daily_ests$boats)
# sum(ests$coho_ad_k) == sum(daily_ests$coho_ad_k)
# sum(ests$coho_um_k) == sum(daily_ests$coho_um_k)
