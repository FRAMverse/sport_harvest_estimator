### This script views all available tables within the database
### then downloads those files to csvs

# connect to database
con <- DBI::dbConnect(RSQLite::SQLite(), here::here('data/coho_harvest_estimator.db'))

# list tables to console
DBI::dbListTables(con)

# dump tables to csv

# coho daily intensively monitored estimates w/ crc substitutions where 
# intensive monitoring not happening
coho_estimates <- DBI::dbReadTable(con, 'coho_estimates')
write.csv(coho_estimates, here::here('aux_scripts/database_to_csv/coho_estimates.csv'))

# coho regulations
coho_regulations <- DBI::dbReadTable(con, 'coho_regulations')
write.csv(coho_regulations, here::here('aux_scripts/database_to_csv/coho_regulations.csv'))


# fram pre/post season estimates
coho_fram <- DBI::dbReadTable(con, 'coho_fram')
write.csv(coho_fram, here::here('aux_scripts/database_to_csv/coho_fram.csv'))

# a view of dockside data by regulation
reg_dockside <- coho_sample_rate <- DBI::dbReadTable(con, 'vw_estimates_by_regulation')
write.csv(reg_dockside, here::here('aux_scripts/database_to_csv/estimates_by_regulation.csv'))

# log of updates to the database (whenever compile_to_database.R is run)
update_log <- coho_sample_rate <- DBI::dbReadTable(con, 'update_log')
write.csv(update_log, here::here('aux_scripts/database_to_csv/update_log.csv'))

# close connection
DBI::dbDisconnect(con)