# CRC database


print('### CRC Records ###')
crc_db <- here::here("data/sources/Sport Harvest Estimates 20221101.mdb")

sql <- "SELECT Catch.CatchYear, 
          Catch.CatchStatMonth,
          Catch.CatchPeriod, 
          Catch.CatchPeriodType,
          Area.AreaCode,
          Catch.CatchPeriodStartDate, 
          Catch.CatchPeriodEndDate, 
          Catch.MarkType, 
          Catch.Species, 
          Catch.CatchEst
        FROM Area INNER JOIN Catch ON Area.AreaID = Catch.AreaID
        WHERE (((Catch.CatchYear)>=2009));
        "
print('Fetching CRC records')
db_con <- DBI::dbConnect(
  drv = odbc::odbc(),
  .connection_string = paste0("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=", crc_db, ";"))
crc_data <- DBI::dbGetQuery(db_con, sql)
DBI::dbDisconnect(db_con)


#lowercase names
names(crc_data) <- tolower(names(crc_data))

print('Transforming CRC data')
crc <- crc_data |>
  filter(
    species == "Coho", 
    catchyear >= 2009,
    areacode %in% c("5","6","7","81","82","9","10","11","12","13")
  ) |>
  mutate(area_code = str_pad(areacode, width = 2, pad = "0")) |>
  select(area_code, catchyear, catchstatmonth, catchperiodstartdate, catchperiodenddate, catchest) |>
  group_by(area_code, catchyear, catchstatmonth) |> 
  summarise(catchest = sum(catchest), .groups = "drop") |> 
  mutate(
    m = factor(month.abb[catchstatmonth], levels = month.abb),
    yr = factor(catchyear),
    ts = case_when(
      m %in% month.abb[1:6] ~ 1,
      m == "Jul" ~ 2,
      m == "Aug" ~ 3,
      m == "Sep" ~ 4,
      m %in% month.abb[10:12] ~ 5)
  )
print('Removed extra environmental variables')
rm(list=c('db_con', 'crc_data'))
print('Done!')
