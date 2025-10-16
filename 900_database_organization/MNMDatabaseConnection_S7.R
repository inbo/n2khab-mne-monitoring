# an attempt to re-implement
# the database connection "list" object in R's `S7` library.
#
# Because migration will take a while, I keep this parallel in the main branch.

# Refs:
# - https://rconsortium.github.io/S7/index.html
# - https://hypebright.nl/en/r-en/s7-a-new-object-oriented-programming-system-in-r-2
# - https://medium.com/ph-d-stories/the-use-case-of-s7-the-last-or-just-most-recent-oop-system-in-r-207b9d561509

# Initial questions:
# - should I keep the table relations in their own object?
# - class_<datatype> customizable? use list?


# CONCEPT
if (FALSE)  {
notes <- "
three is a good number.
four is even better.

(1) [generic] database connection

(2a) database structure
    (from file; possibly '.ods' conversion)

(2b) tables
    heavy use of getters and setters
    for get_namestring, etc.

(3) mnm database connection
    extending a connection by structure-aware functions


How to access tables in dbstructure?
-> overload the `.` operator or %/%?


HBV <- S7::new_class(
  "HBV",
  package = "wrmt",
  parent  = Model,
  properties = list(
    pars = S7::class_numeric,
    ptr  = S7::new_property(class = S7::class_any)),
constructor = function(
  structure = S7::class_missing,
  date      = S7::class_missing,
  r         = S7::class_missing,
  pars      = S7::class_missing,
  ptr       = S7::class_missing) S7::new_object(
    Model(
      structure = "HBV",
      date      = date,
      r         = r,
      pars      = pars,
      ptr       = wmrt::HBVcppInit())
)


`%>>%` <- S7::new_generic(
  "%>>%",
  dispatch_args = c("i", "o"),
  function(i, o) {
    S7::S7_dispatch()
})


S7::method(
  generic = `%>>%`,
  signature = list(i = Model,
                   o = Model)) <- function(i, o) {
                     x <- Model(r = i@r + o@r)
                     return(x)
}



"
}


# EXERCISE: try reproducing PathLib in R,
# mostly overloading the `/` operator
