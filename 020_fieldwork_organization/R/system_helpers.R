
#' Check availability of required packages
#'
#' Takes a vector of package names and passes each name to
#' \code{\link[base:ns-load]{requireNamespace()}};
#' if package(s) are missing, returns an error message providing the basic
#' \code{install.packages()} command to install them.
#'
#' @param pkgs A character vector of package names.
#' @param quietly logical: should progress and error messages be suppressed?
#'                (from ?loadNamespace)
#' @param ... further parameters passed to `require` or `requireNamespace`
#'
#' @examples
#' \dontrun{
#'   require_pkgs(c("a", "base", "b", "magrittr"))
#'   # not_attached <- any(devtools::loaded_packages() == "magrittr") == FALSE
#' }
#'
#' @keywords internal
require_pkgs <- function(pkgs, quietly = TRUE, ...) {

  # verify user input
  assertthat::assert_that(is.character(pkgs))

  # FAILED: select the loading function
  # PROBLEM: require just attaches to this function's environment
  #  @param attach Optionally attach the package namespace to search path.
  if (FALSE) {
    the_loading_function <- \(pkg) require(
      pkg,
      quietly = quietly,
      character.only = TRUE,
      ...
    )
  } else {
    the_loading_function <- \(pkg) requireNamespace(
      pkg,
      quietly = quietly,
      ...
    )
  }

  # check availability of the package
  available <- vapply(pkgs, the_loading_function, FUN.VALUE = TRUE)

  # feedback availability
  if (!all(available)) {
    multiple <- sum(!available) > 1
    stop(ifelse(multiple, "Multiple", "A"),
         " package",
         ifelse(multiple, "s", ""),
         " needed for this function ",
         ifelse(multiple, "are", "is"),
         " missing.\nPlease install as follows: install.packages(",
         deparse(pkgs[!available]),
         ")",
         call. = FALSE
    )
  }

} # /require_pkgs
