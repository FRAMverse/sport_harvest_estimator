library(tidyverse)

# This script loads stratum estimates, transforms to daily estimates
# assigns a timestep then saves them to the coho_estimator database
# Note: Allocated catch is UNIFORM across individual stratum
# Ty Garber 12/7/2022

# load estimates
print('### Intestive creel ###')

print('Loading intensive creel estimate file')
ests <- read_csv(here::here('data/sources/coho_inseason_estimates.csv'),
                 show_col_types = F)


print('Converting stata estimates to daily estimates')
daily_ests <- ests %>%
  rowwise() %>%
  mutate(
    survey_datetime = list(seq(start_date, end_date, by = '1 day')), # sequence of days within stratum
    day_delta = length(survey_datetime), # number of days within stratum
    across(coho_ad_k:coho_unk_r, ~.x / day_delta) # divide estimates by number of days
  ) %>%
  unnest_longer(survey_datetime) %>% # explode stratum
  mutate(
    catch_area_code = str_pad(catch_area_code, width = 2, side = 'left', pad = '0'),
    year = lubridate::year(survey_datetime),
    survey_datetime = as.Date(survey_datetime)
  ) %>% select(survey_datetime, year, area_code = catch_area_code, everything(), -day_delta, -start_date, -end_date)

# QAQC code, if there are any falses there are errors in the 
# estimate file... likely the start/enddates
# after_daily <- daily_ests %>%
#    filter(year >= 2022) %>%
#    group_by(area_code) %>%
#    summarize(across(coho_ad_k:coho_unk_r, sum))
#  
# before_daily <- ests %>%
#    mutate(
#      area_code = str_pad(catch_area_code, width = 2, side = 'left', pad = '0')
#    ) %>%
#    filter(start_date >= as.Date('2022-01-01')) %>%
#    group_by(area_code) %>%
#    summarize(across(coho_ad_k:coho_unk_r, sum))
# 
# before_daily == after_daily

# daily_ests %>%
#   filter(area_code == '10') %>%
#   print(n=100)

# regulations %>%
#   filter(catch_area_code == '10',
#          `Start  Yr` == 2022) %>%
#   print(n)

# pull in daily crc files, filter wrangle the data for joining
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

# pull in regulation data
regulations <- readxl::read_excel(
  path = here::here('data/sources/coho_regulations.xlsx'),
  sheet = "coho_regulations") %>%
  mutate(across(ends_with('_datetime'), as.Date))

# explode the fishery start/end, each row has a day the fishery was open
regs_long <- regulations %>%
  janitor::clean_names() %>% # no dumb column names
  rowwise() %>%
  mutate(
    days = list(seq(start_datetime, end_datetime, '1 day')), # nested list, continuous series of dates between start and end
    catch_area_code = str_pad(catch_area_code, 2, 'left', '0') # catch area padding 5 -> 05 
    ) %>%
  unnest_longer(days) %>%
  select(fishery_description, regulation_type_code, catch_area_code,
         start_datetime, end_datetime, days)

# figure out which days need to be covered by crc by area
# this identifies where there is no intensive creel coverage
# in the fishery defined in the regulations
crc_days <- regs_long %>%
  anti_join(
    daily_ests %>%
      select(survey_datetime, area_code),
    by = c('catch_area_code' = 'area_code', 'days' = 'survey_datetime')
  ) %>%
  filter(
    days >= '2015-06-01' # intensive monitoring goes back 1/1/2021 currently
  )

# QAQC
# the table below should not include any intensive monitoring
# crc_days %>%
#   group_by(fishery_description, regulation_type_code) %>%
#   summarize(start = min(days), end=max(days))


# join crc_days to crc data; this effectively is a filter...
crc_sub <- crc_days %>%
  inner_join(crc, by = c('days' = 'date', 'catch_area_code' = 'area'))


# wrangle the crc data for prepration to be 
# row bound to the intensive monitoring
crc_substitutions <- crc_sub %>%
  mutate(
    species = tolower(species),
    mark = case_when(
      is.na(mark) ~ 'unk',
      mark == 'M' ~ 'ad',
      mark == 'U' ~ 'um'
    ),
    year = lubridate::year(days),
    field = paste0(species, '_', mark, '_k'), # all crc are kept
    source = 'CRC'
  ) %>%
  select(regulation_type_code, survey_datetime = days, year, area_code = catch_area_code, source, field, fish) %>%
  group_by( regulation_type_code, survey_datetime,year,  area_code, field, source) %>%
  summarize(fish = sum(fish), .groups = 'drop') %>%
  pivot_wider(names_from = field, values_from = fish, values_fill = 0)


# intensive estimates joined to regulations
ests_regs <- regs_long %>%
  inner_join(daily_ests,
             by = c('catch_area_code' = 'area_code', 
                    'days' = 'survey_datetime') # effectively a filter
             ) %>%
  mutate(source = 'CREEL') %>%
  select(regulation_type_code, survey_datetime = days, area_code = catch_area_code, year, coho_ad_k:coho_unk_r, source)
  

ests_comp <- ests_regs %>%
  bind_rows(crc_substitutions) %>%
  mutate(
    survey_datetime = as.character(survey_datetime),
    time_step = case_when(
      lubridate::month(survey_datetime) %in% c(1,2,3,4,5,6) ~ 1L,
      lubridate::month(survey_datetime)  == 7 ~ 2L,
      lubridate::month(survey_datetime)  == 8 ~ 3L,
      lubridate::month(survey_datetime)  == 9 ~ 4L,
      lubridate::month(survey_datetime)  %in% c(10, 11, 12) ~ 5L
    )
  )

# ests_comp %>%
#   filter(survey_datetime >= as.Date('2022-10-01')) %>%
#   print(n=100)
# QAQC, every fishery listed here
# should either be CRC estimates / no catch = no row
# or haven't occured
# regs_long %>%
#   filter(
#     days >= as.Date('2021-01-01')
#     ) %>%
#   anti_join(ests_comp,
#             by = c('catch_area_code' = 'area_code',
#                    'days' = 'survey_datetime')) %>%
#   count(fishery_description)

#write.csv(ests_comp, 'estimates.csv')
# save to database
print('Removed extra environmental variables')
rm(list=c('ests'))
print('Done!')

# checks
# sum(ests$boats) == sum(daily_ests$boats)
# sum(ests$coho_ad_k) == sum(daily_ests$coho_ad_k)
# sum(ests$coho_um_k) == sum(daily_ests$coho_um_k)
