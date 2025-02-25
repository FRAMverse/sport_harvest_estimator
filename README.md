# sport_harvest_estimator

As noted in the "About" tab, this application supports the development of preseason coho FRAM fishery inputs for [WDFW marine sport fisheries](https://wdfw.wa.gov/fishing/basics/salmon/marine-areas) in the Salish Sea.

Given a current R+RStudio installation, clone the repo or download the primary script and associated environment, then select "Run Document" to initiate a local pseudo-server that will load into an Rstudio preview window (or can be opened in an external browser).

## Updating process:

To update the sport harvest estimator for a new year:

1) Update the data files in data/sources/, including the regulations, crc, and intensive data files
2) Run `data_prep_scripts/compile_to_database.R`. This will source other scripts that pull the data together correctly
3) Run `sport_harvest_estimator.Rmd` at least once locally. This will automatically save the key data objects into `sport_harvest_estimator.Rmd`.

At this point, `sport_harvest_estimator.Rmd` can be deployed, and only relies on `sport_harvest_estimator.RData`.