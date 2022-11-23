#AHB updated from same estimate db, adding NS back to 2003
print('### Regulation Data ###')
print('Fetching and transforming regulation data')
coho_regulations <- readxl::read_excel(
  path = here::here('data/sources/coho_regulations.xlsx'),
  sheet = "coho_regulations") |>
  select(catch_area_code, regulation_type_code, start_datetime, end_datetime) |>
  mutate(
    catch_area_code = str_pad(catch_area_code, width = 2, pad = "0"), # padding catch area with 0's allow for easy joining
    across(contains("datetime"), as.character) # convert date times to date R object
  )
print('Done!')