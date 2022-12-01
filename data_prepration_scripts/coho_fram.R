# fram fisheries, refactored from DA's sport estimator script
# framr::read_coho_fish_sclr refactored into a SQL query

print('### FRAM Databases ###')

pre_season_fram_db <- here::here("data/sources/PSC_CoTC_Preseason_CohoFRAMDB_thru2022.mdb")
post_season_fram_db <- here::here("data/sources/PSC_CoTC_PostSeason_CohoFRAMDB_thru2020_021622.mdb")

# sql to query pre and post-season fram databases, should be able to copy and paste directly into access
sql <- "SELECT RunID.RunYear,
        Fishery.FisheryName,
        FisheryScalers.FisheryFlag,
        FisheryScalers.TimeStep, 
        FisheryScalers.Quota, 
        FisheryScalers.MSFQuota
        FROM Fishery
        RIGHT JOIN (RunID RIGHT JOIN FisheryScalers ON RunID.RunID = FisheryScalers.RunID) ON
        Fishery.FisheryID = FisheryScalers.FisheryID
        WHERE (((RunID.RunYear)>='2009') AND 
        ((Fishery.Species)='COHO') AND 
        ((FisheryScalers.FisheryID) In (91,92,93,107,118,129,152,136,106,115)));"

print('Fetching data from pre-season FRAM')
# execute above query on pre-season fram db
db_con <- DBI::dbConnect(
  drv = odbc::odbc(),
  .connection_string = paste0("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=", pre_season_fram_db, ";"))
pre_fram <- DBI::dbGetQuery(db_con, sql)
DBI::dbDisconnect(db_con)


print('Fetching data from post-season FRAM')
# execute above query on post-season fram db
db_con <- DBI::dbConnect(
  drv = odbc::odbc(),
  .connection_string = paste0("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=", post_season_fram_db, ";"))

post_fram <- DBI::dbGetQuery(db_con, sql)
DBI::dbDisconnect(db_con)


print('Transforming FRAM data')
fs_ps_spt <- bind_rows( # append post-season data to pre-season date
  pre_fram |> mutate(type = "pre"),
  post_fram |> mutate(type = "pst")
) |>
  filter(RunYear >= 2009, FisheryFlag != 0) |> #count(type)
  select(type, yr = RunYear, FisheryName, ts = TimeStep, ff = FisheryFlag, Quota, MSFQuota) |>
  mutate(
    area_code = str_remove_all(FisheryName, "Area|Spt|Ar|-") |> str_trim() |> str_pad(width = 2, pad = "0"),
    yr = factor(yr)
  ) |>
  unite("yr_type", yr, type, remove = FALSE) |>
  pivot_longer(names_to = "var", values_to = "val", Quota:MSFQuota) |>
  filter(
    !(ff %in% 1:2 & var=="MSFQuota"),
    !(ff %in% 7:8 & var=="Quota")
  )
  

print('Removed extra environmental variables')
rm(list=c('db_con', 'post_fram', 'pre_fram'))
print('Done!')
