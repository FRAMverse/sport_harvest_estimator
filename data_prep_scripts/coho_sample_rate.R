# coho sample rates from RMIS catch sample table
print('### Sample Rate Data ###')
print('Fetching and transforming sample rate data from RMIS')
rmis_cs <- readxl::read_excel(here::here('data/sources/SportSampleRateCoho2000_2020_creel_subs.xlsx'), sheet = "creel_est_subs") |> 
  mutate(
    area_code = str_pad(str_squish(str_remove_all(catch_location_name, "MARINE SPORT AREA |MARINE SPORT PCA|\\.")), width = 2, pad = "0"),
    yr = factor(year),
    sample_rate = if_else(is.na(sr_creel_sub), sr, sr_creel_sub)
  ) |> 
  select(FisheryID, area_code, year, yr, ts, caught, sampled, sample_rate) |> 
  filter(
    !is.na(area_code),
    caught > 10, sampled > 10
  )

print('Done!')