# sport_harvest_estimator

As noted in the "About" tab, this application supports the development of preseason coho FRAM fishery inputs for [WDFW marine sport fisheries](https://wdfw.wa.gov/fishing/basics/salmon/marine-areas) in the Salish Sea.

Given a current R+RStudio installation, clone the repo or download the primary script and associated environment, then select "Run Document" to initiate a local pseudo-server that will load into an Rstudio preview window (or can be opened in an external browser).

The governing concept is to define an estimated harvest input as the product of days fished *df*, anglers per day *apd*, and harvest-per-angler-per-day *hapd* or: *harvest = df x apd x hapd*

Puget Sound dockside creel observations are used to inform the values for anglers per day *apd*, and harvest-per-angler-per-day *hapd*.

Annual sample distribution data are presented when the user selects a focal WDFW Puget Sound catch area and coho FRAM time step from the upper left radio buttons.

The anticipated season length determines the upper *df* days fished slider, optionally differentiating between weekday and weekend "day types".

The median (q50) and upper range (q95) of the anglers-per-day are used to shape the middle *apd* slider. The raw values and a sample-rate based expansion are shown, with the slider choices based on latter.

The median and interquartile range (IQR) are used to shape the lower harvest-per-angler-per-day *hapd* slider. Adjusting the slider modifies the vertical reference line shown in the "PSSP kept obs" plots.

The harvest estimate (i.e., potential FRAM input) resulting from the current slider values is shown in the upper middle green box. 

After reaching an acceptable input, the user enters a brief description of the rationale and clicks the "Keep estimates" button, thereby preserving this text, the input, and the associated underlying *df*, *apd*, and *hapd*. After all desired inputs have been generated, a csv recording each area-timestep can be downloaded. 
