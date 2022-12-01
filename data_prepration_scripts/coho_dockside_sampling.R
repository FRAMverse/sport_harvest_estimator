# #standalone sqlite database from TG supporting estimate report
# #contains enhanced version of pssp_dev mvw_dockside_salmon
# #for coho only but with 2016
# #also has regs datasets with MSF back to 2003; NS currently only back to 2015, but AHB updated externally
print('### Sampling Data ###')

print('### Fetching dockside creel information')
dockside <- read_csv(here::here('data/sources/mvw_dockside_salmon.csv'),
                     show_col_types = F)

print('Transforming creel data')
coho_dockside <- dockside |>
  filter(
    catch_area_code %in% c("05","06","07","81","82","09","10","11","12","13")
  ) |>
  group_by(area_code = catch_area_code, survey_datetime) |>
  summarise(across(c(anglers, starts_with("coho_")), ~sum(., na.rm=T)), .groups = "drop") |>
  mutate(
    across(anglers:coho_unk_r, ~as.integer(replace_na(.,0))),
    survey_datetime = as.character(survey_datetime),
    year = lubridate::year(survey_datetime),
    yr = factor(year),
    month = lubridate::month(survey_datetime),
    m = factor(month.abb[month], levels = month.abb),
    day = lubridate::day(survey_datetime),
    day_of_week = lubridate::wday(survey_datetime, label = T) |> factor(levels = c("Thu","Wed","Tue","Mon","Sun","Sat","Fri")),
    week_day_type = if_else(day_of_week %in% c("Fri", "Sat", "Sun"), "wkend", "wkday"),
    time_step = case_when(
      m %in% month.abb[1:6] ~ 1,
      m == "Jul" ~ 2,
      m == "Aug" ~ 3,
      m == "Sep" ~ 4,
      m %in% month.abb[10:12] ~ 5),
    coho_total_kept = coho_ad_k + coho_um_k + coho_unk_k,
    kept_coho_ad_rate = coho_ad_k/(coho_ad_k + coho_um_k), # observation specific mark rate of kept
    kept_coho_ad_rate = if_else(is.nan(kept_coho_ad_rate), 0, kept_coho_ad_rate),
    coho_kept_ad = coho_ad_k + (coho_unk_k * kept_coho_ad_rate),
    coho_total_released = coho_ad_r + coho_um_r + coho_unk_r,
    coho_total_encounters = coho_total_kept + coho_total_released,
    coho_kept_per_angler = coho_total_kept / anglers,
    coho_kept_ad_per_angler = coho_kept_ad / anglers,
    coho_released_per_angler = coho_total_released / anglers,
    coho_encounters_per_angler = coho_total_encounters / anglers
  ) |>
  select(area_code, survey_datetime, year:time_step,
         anglers, coho_total_kept:coho_encounters_per_angler)

rm(dockside)

print('Done!')
