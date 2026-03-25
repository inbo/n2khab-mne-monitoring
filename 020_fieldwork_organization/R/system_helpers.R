
#' require a library at some other place
#'
#' optionally loading it to namespace via `require`
#'
#' @param package_name the name of the package
#' @param load_namespace whether to use `require` (TRUE) to attach the package
#'
#' @example require_library_check("dplyr", load_namespace = TRUE)()
#' @example require_library_check("uninstalled_package")()
#'
require_library_check <- function(package_name, load_namespace = FALSE) {

  if (load_namespace) {
    stopifnot("missing library `glue`" = require("glue"))
  } else {
    stopifnot("missing library `glue`" = requireNamespace("glue"))
  }

  # ref: https://impaulchung.wordpress.com/2013/01/09/r-tip-str-command/
  text_to_eval <- glue::glue(
    ' stopifnot(
        "missing library `{package_name}`" = requireNamespace("{package_name}")
      )
    ')

  # this should better happen in the target function
  return( \() eval(parse(text = text_to_eval)) )

}
