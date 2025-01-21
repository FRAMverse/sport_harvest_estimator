# this script populates a SQLite database based on 
# a collection of R scripts
library(tidyverse)
# load and transform sources of data
source(here::here('data_prep_scripts/coho_fram.R'))
#source(here::here('data_prep_scripts/coho_regulations.R'))
#source(here::here('data_prep_scripts/coho_estimates.R'))


# comments on the data associated with this update
comment <- 'coho fram update'

# save to sqlite database
con <- DBI::dbConnect(RSQLite::SQLite(), here::here('data/coho_harvest_estimator.db'))
DBI::dbWriteTable(con, "coho_fram", fs_ps_spt, overwrite = T)
#DBI::dbWriteTable(con, "coho_regulations", coho_regulations, overwrite = T)
#DBI::dbWriteTable(con, "coho_estimates", daily_estimates, overwrite = T)
# log the update
DBI::dbExecute(con,
               glue::glue("INSERT INTO update_log (user, datetime, comment)
                 VALUES ('{Sys.getenv('USERNAME')}', '{Sys.time()}', '{comment}')"))
DBI::dbDisconnect(con)


# fisheries where there are no estimates of catch are 0's
source(here::here('data_prep_scripts/coho_na_to_zero_fisheries_no_catch.R'))



