
### joins
# these are just simple wrappers to avoid the flood of extra keywords
# because I prefer one-liners.
# Some combinations of keywords are not implemented (e.g. one-time usage).

#' wrapper for any inner join with "unmatched: error/drop"
ixxx_join <- \(...) inner_join(..., unmatched = c("error", "drop"))

#' wrapper for the many-to-one inner join with "unmatched: error/drop"
im21_join <- \(...) ixxx_join(..., relationship = "many-to-one")

#' wrapper for the one-to-one inner join with "unmatched: error/drop"
i121_join <- \(...) ixxx_join(..., relationship = "one-to-one")

#' wrapper for the many-to-many inner join with "unmatched: error/drop"
im2m_join <- \(...) ixxx_join(..., relationship = "many-to-many")

#' wrapper for the one-to-one inner join with "unmatched: drop>error"
i12mde_join <- \(...) inner_join(
  ...,
  relationship = "one-to-many",
  unmatched = c("drop", "error")
  )

i12me_join <- \(...) inner_join(
  ...,
  relationship = "one-to-many",
  unmatched = "error"
  )

#' wrapper for any left join with "unmatched: drop" ("drop" seems to be prefered for left_joins)
lxxx_join <- \(...) left_join(..., unmatched = "drop")

#' wrapper for the  one-to-one left join with "unmatched: drop"
l121_join <- \(...) lxxx_join(..., relationship = "one-to-one")

#' wrapper for the  many-to-one left join with "unmatched: drop"
lm21_join <- \(...) lxxx_join(..., relationship = "many-to-one")

#' wrapper for the  many-to-many left join with "unmatched: drop"
lm2m_join <- \(...) lxxx_join(..., relationship = "many-to-many")
