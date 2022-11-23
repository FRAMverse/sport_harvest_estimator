# this script populates a SQLite database based on 
# a collection of R scripts

# load and transform sources of data
source(here::here('data_prepration_scripts/coho_crc.R'))
source(here::here('data_prepration_scripts/coho_fram.R'))
source(here::here('data_prepration_scripts/coho_dockside_sampling.R'))
source(here::here('data_prepration_scripts/coho_regulations.R'))
source(here::here('data_prepration_scripts/coho_sample_rate.R'))


# comments on the data associated with this update
comment <- 'Debugging'

# save to sqlite database
con <- DBI::dbConnect(RSQLite::SQLite(), here::here('data/coho_harvest_estimator.db'))
DBI::dbWriteTable(con, "coho_crc", crc, overwrite = T)
DBI::dbWriteTable(con, "coho_dockside", coho_dockside, overwrite = T)
DBI::dbWriteTable(con, "coho_fram", fs_ps_spt, overwrite = T)
DBI::dbWriteTable(con, "coho_sample_rate", rmis_cs, overwrite = T)
DBI::dbWriteTable(con, "coho_regulations", coho_regulations, overwrite = T)
# log the update
DBI::dbExecute(con,
                 glue::glue("INSERT INTO update_log (user, datetime, comment)
                 VALUES ('{Sys.getenv('USERNAME')}', '{Sys.time()}', '{comment}')"))

DBI::dbDisconnect(con)
