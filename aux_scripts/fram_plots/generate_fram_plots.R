### This script reproduces the fram figures from the shiny application
### Ty Garber 12/12/2022


library(tidyverse)
# connect to database
con <- DBI::dbConnect(RSQLite::SQLite(), here::here('data/coho_harvest_estimator.db'))

# compilation of FRAM parameters from post-season and pre-season databases
fs_ps_spt <- DBI::dbReadTable(con, 'coho_fram')

# intensive monitoring / substituted with crc (hopefully)
coho_ests <- DBI::dbReadTable(con, 'coho_estimates')

# disconnect from database
DBI::dbDisconnect(con)




# apportion unk coho from estimates, row bind to fram pre/post
fram_ests <- coho_ests |>
  rowwise() |>
  mutate(
    # apportion unk mark-status to ad/um for retention
    coho_ad_k = coho_ad_k + (coho_unk_k * (coho_ad_k / sum(coho_ad_k,coho_um_k, na.rm=T))),
    coho_ad_k = replace_na(coho_ad_k, 0),
    coho_um_k = coho_um_k + (coho_unk_k * (coho_um_k / sum(coho_ad_k,coho_um_k, na.rm=T))),
    coho_um_k = replace_na(coho_um_k, 0),
    total_retained_coho = sum(coho_ad_k, coho_um_k)
  ) |>
  group_by(year, time_step, area_code, source) |>
  summarize(across(c(coho_ad_k, coho_um_k, total_retained_coho), sum, na.rm=T), .groups = 'drop') |>
  mutate(
    yr_type = paste0(year, '_pst_ests'),
    yr = as.character(year),
    ts = time_step,
    type = 'ests'
  ) |>
  select(yr_type, yr, ts, type, area_code, var = source, val = total_retained_coho)     |>
  bind_rows(fs_ps_spt)

# generate plots of each area and save them
fram_ests |>
  group_by(area_code) %>%
  nest() %>%
  mutate(
    plot = map(data,
               ~ggplot(data=.x, aes(yr_type, val, fill = var)) +
                 geom_col(position = position_stack(), alpha = 0.7) +
                 geom_col(data = filter(.x, type == "ests"), position = position_stack(), alpha = .6) +
                 geom_col(data = filter(.x, type == "pst"), position = position_stack(), alpha = 1) +
                 scale_y_continuous("FRAM inputs", sec.axis = dup_axis(), labels = scales::comma) +
                 scale_fill_manual(values = c(
                   "Quota" = "#D2A554",
                   "MSFQuota" = "#A4BADF",
                   "CRC" = "#04a43c",
                   "CREEL" = "#014218"
                 )) +
                 facet_grid(cols = vars(ts)) +
                 theme(
                   text = element_text(size = 20),
                   axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
                 )
    )
  ) %>%
  select(area_code, plot) %>%
  pwalk(~ggsave(plot = .y, file = here::here('aux_scripts/fram_plots/', paste0('fram_plot_area_', .x , '.png')), 
                height=20, width=80, units='cm', dpi=300 ))


