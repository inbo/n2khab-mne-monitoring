library(targets)
library(tarchetypes)
library(rprojroot)
projroot <- find_root(has_file("030_optimization.Rproj"))
source(paste0(projroot, "src/R/target_specific_functions.R"))
tar_source()
tar_option_set(packages = c("readr", "dplyr", "ggplot2"))
list(
  tar_target(file, "objects_panflpan5.Rdata", format = "file"),
  tar_target(
    data,
    get_data(
      data = file,
      objects = c(
        "fag_grts_calendar",
        "field_activities",
        "field_activity_sequences"
      )
    )
  ),
  tar_target(model, fit_model(data)),
  tar_target(plot, plot_model(model, data))
)
