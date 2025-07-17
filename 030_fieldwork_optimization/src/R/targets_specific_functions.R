get_data <- function(
  data,
  objects = c(
    "fag_grts_calendar",
    "field_activities",
    "field_activity_sequences"
  )
) {
  # Change to a unique temporary directory
  # so .Rdata does not pollute the workspace
  # or clash with another target's .Rdata:
  dir <- tempfile()
  fs::dir_create(dir)
  withr::local_dir(dir)

  # Optional: clean up .Rdata when you are done,
  # if a lot of data in /tmp is going to be a problem:
  on.exit(unlink(".RData"), add = TRUE)

  # Write .Rdata
  #package::function_that_writes_rdata()

  # Load R data into a local environment:
  envir <- new.env(parent = emptyenv())
  projroot <- find_root(has_file("030_optimization.Rproj"))
  datapath <- file.path(projroot, "data")
  rdata_path <- file.path(
    datapath,
    data
  )
  load(rdata_path, envir = envir)
  # If you know what data objects to look for,
  # find them in the environment and return them.
  l <- map(objects, function(x) {
    get(x, envir = envir)
  })
  return(l)
  # for (x in seq_len(length(objects))) {
  #   assign(objects[x], l[[x]])
  # }
}
