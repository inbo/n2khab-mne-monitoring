add_compartment_col <- function(df) {
  df %>%
    mutate(
      compartment = str_extract(scheme, "^[A-Z]+") %>%
        factor(levels = c("GW", "SURF", "SOIL")) %>%
        fct_recode(
          grondwater = "GW",
          oppervlaktewater = "SURF",
          bodem = "SOIL"
        )
    )
}

relevel_domain_part <- function(df) {
  df %>%
    mutate(
      domain_part = factor(
        domain_part,
        levels = levels(domainpart_grts_n2khab$domain_part)
      ) %>%
        fct_relevel("SAC_network_remainder", "Flanders_remainder", after = Inf)
    )
}

aggregate_fieldwork <- function(df) {
  df %>%
    add_compartment_col() %>%
    mutate(
      end_2025 = date_visit <= make_date(year = 2025, month = 12, day = 31)
    ) %>%
    # rejoining domain_part since NAs appeared in domain_part column
    select(-domain_part) %>%
    inner_join(
      domainpart_grts_n2khab,
      join_by(grts_address),
      relationship = "many-to-one",
      unmatched = c("error", "drop")
    ) %>%
    relevel_domain_part() %>%
    distinct(sampleunit_id, domain_part, end_2025, compartment) %>%
    arrange(
      compartment,
      domain_part
    )
}
