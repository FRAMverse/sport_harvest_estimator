#Calculating CPD for area 10 ts 1
#We need to calculate separately for March-April and for June, as those are likely to have distinct CPDs.

pssp |> 
  filter(area_code == "10",
          time_step == 1,
         year %in% 2019:2024) |>
  mutate(month = month(date),
         coho_total = coho_104_ad_ret + coho_104_um_ret + coho_104_uk_ret) |> 
  filter(month %in% 1:4) |> 
  group_by(year, regulation_type_code, day_type) |> 
  summarize(coho_total = sum(coho_total),
            days = n()) |> 
  ungroup() |> 
  mutate(cpd = coho_total/days) |> 
  select(-coho_total, -days) |> 
  pivot_wider(names_from = day_type,
              values_from = cpd) |> 
  clipr::write_clip()


pssp |> 
  filter(area_code == "10",
         time_step == 1,
         year %in% 2019:2024) |> 
  mutate(month = month(date),
         coho_total = coho_104_ad_ret + coho_104_um_ret + coho_104_uk_ret) |> 
  filter(month %in% 6) |> 
  group_by(year, regulation_type_code, day_type) |> 
  summarize(coho_total = sum(coho_total),
            days = n()) |> 
  ungroup() |> 
  mutate(cpd = coho_total/days) |> 
  select(-coho_total, -days) |> 
  pivot_wider(names_from = day_type,
              values_from = cpd)|> 
  clipr::write_clip()


#Calculating CPD for area 10 ts 5
#We need to calculate separately for Oct and for Nov, as those are likely to have distinct CPDs.

## October
pssp |> 
  filter(area_code == "10",
         time_step == 5,
         year %in% 2021:2024) |>
  mutate(month = month(date),
         coho_total = coho_104_ad_ret + coho_104_um_ret + coho_104_uk_ret) |> 
  filter(month %in% 10) |> 
  group_by(year, regulation_type_code, day_type) |> 
  summarize(coho_total = sum(coho_total),
            days = n()) |> 
  ungroup() |> 
  mutate(cpd = coho_total/days) |> 
  select(-coho_total, -days) |> 
  pivot_wider(names_from = day_type,
              values_from = cpd) |> 
  clipr::write_clip()

## Nov
pssp |> 
  filter(area_code == "10",
         time_step == 5,
         year %in% 2021:2024) |> 
  mutate(month = month(date),
         coho_total = coho_104_ad_ret + coho_104_um_ret + coho_104_uk_ret) |> 
  filter(month %in% 11) |> 
  group_by(year, regulation_type_code, day_type) |> 
  summarize(coho_total = sum(coho_total),
            days = n()) |> 
  ungroup() |> 
  mutate(cpd = coho_total/days) |> 
  select(-coho_total, -days) |> 
  pivot_wider(names_from = day_type,
              values_from = cpd)|> 
  clipr::write_clip()


#Calculating CPD for area 11 ts 5
#We need to calculate separately for Oct and for Nov, as those are likely to have distinct CPDs.

## October
pssp |> 
  filter(area_code == "11",
         time_step == 5,
         year %in% c(2017, 2020:2024)) |> 
  mutate(month = month(date),
         coho_total = coho_104_ad_ret + coho_104_um_ret + coho_104_uk_ret) |> 
  filter(month %in% 10) |> 
  group_by(year, regulation_type_code, day_type) |> 
  summarize(coho_total = sum(coho_total),
            days = n()) |> 
  ungroup() |> 
  mutate(cpd = coho_total/days) |> 
  select(-coho_total, -days) |> 
  pivot_wider(names_from = day_type,
              values_from = cpd) |> 
  clipr::write_clip()

## Nov
pssp |> 
  filter(area_code == "11",
         time_step == 5,
         year %in% c(2017, 2020:2024)) |> 
  mutate(month = month(date),
         coho_total = coho_104_ad_ret + coho_104_um_ret + coho_104_uk_ret) |> 
  filter(month %in% 11) |> 
  group_by(year, regulation_type_code, day_type) |> 
  summarize(coho_total = sum(coho_total),
            days = n()) |> 
  ungroup() |> 
  mutate(cpd = coho_total/days) |> 
  select(-coho_total, -days) |> 
  pivot_wider(names_from = day_type,
              values_from = cpd)|> 
  clipr::write_clip()
