#AHB updated from same estimate db, adding NS back to 2003
print('### Regulation Data ###')
print('Fetching and transforming regulation data')
coho_regulations <- readr::read_csv(here::here('data/sources/coho_regulations_back_up.csv')) |>
  select(catch_area_code, regulation_type_code, start_datetime, end_datetime) |>
  mutate(
    across(start_datetime:end_datetime, \(x) as.Date(x, '%m/%d/%Y')),
    catch_area_code = str_pad(catch_area_code, width = 2, pad = "0"), # padding catch area with 0's allow for easy joining
    across(contains("datetime"), as.character) # convert date times to date R object
  )
print('Done!')