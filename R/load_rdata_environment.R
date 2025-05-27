
# load the POC RData into a new environment
load_rdata_environment <- function(skip_check = FALSE){
  env_extradata <- new.env()
  load(target_sample_filepath, envir = env_extradata)
  ls(envir = env_extradata)

  if (skip_check) return(env_extradata)

  # check that some crucial objects exist
  for (var in c(
    "units_non_cell_n2khab_grts",
    "stratum_units_non_cell_n2khab",
    "scheme_moco_ps_stratum_sppost_spsamples_spares_sf"
    )) {
    tryCatch(
    {stopifnot(exists(var, envir = env_extradata))},
    error = function(wrnmsg) {
      message(paste0(
        "The variable ", var,
        " does not exist in environment `env_extradata`.",
        collapse = "")
      )
    }
    )
  }

  return(env_extradata)

}
