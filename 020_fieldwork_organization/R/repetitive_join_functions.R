
### joins
# these are just simple wrappers to avoid the flood of extra keywords
# because I prefer one-liners.
# Some combinations of keywords are not implemented (e.g. one-time usage).

#' wrapper for any inner join with "unmatched: error/drop"
inner_join_xxx_ed <- \(...) dplyr::inner_join(..., unmatched = c("error", "drop"))

#' wrapper for the many-to-one inner join with "unmatched: error/drop"
inner_join_m21_ed <- \(...) inner_join_xxx_ed(..., relationship = "many-to-one")

#' wrapper for the one-to-one inner join with "unmatched: error/drop"
inner_join_121_ed <- \(...) inner_join_xxx_ed(..., relationship = "one-to-one")

#' wrapper for the many-to-many inner join with "unmatched: error/drop"
inner_join_m2m_ed <- \(...) inner_join_xxx_ed(..., relationship = "many-to-many")

#' wrapper for the one-to-one inner join with "unmatched: drop>error"
inner_join_12m_de <- \(...) dplyr::inner_join(
  ...,
  relationship = "one-to-many",
  unmatched = c("drop", "error")
)

inner_join_12m_e <- \(...) dplyr::inner_join(
  ...,
  relationship = "one-to-many",
  unmatched = "error"
)

#' wrapper for any left join with "unmatched: drop" ("drop" seems to be prefered for left_joins)
left_join_xxx_d <- \(...) dplyr::left_join(..., unmatched = "drop")

#' wrapper for the  one-to-one left join with "unmatched: drop"
left_join_121_d <- \(...) left_join_xxx_d(..., relationship = "one-to-one")

#' wrapper for the  many-to-one left join with "unmatched: drop"
left_join_m21_d <- \(...) left_join_xxx_d(..., relationship = "many-to-one")

#' wrapper for the  many-to-many left join with "unmatched: drop"
left_join_m2m_d <- \(...) left_join_xxx_d(..., relationship = "many-to-many")
