

# tag activities for the different monitoring taskforces
# (biotic location evaluation/loceval, groundwater/gw, surfacewater/surf)
associate_grouped_activities_with_fieldtaskforces <- function(grouped_activities) {

  require_pkgs("dplyr")
  require("magrittr") %>% suppressPackageStartupMessages()

  grouped_activities %>%
    dplyr::mutate(
      is_loceval_activity = activity_group %in% c(
        "LOCEVALAQ",
        "LOCEVALTERR",
        "LSVIAQ",
        "LSVITERR",
        "SURFLENTLOCEVALSAMPLPOINT",
        "SURFLOTLOCEVALSAMPLPOINT"
      ),
      is_gw_activity = activity_group %in% c(
        "GWINSTWELLDIVER",
        "GWINSTPIEZNODIVER",
        "GWINSTPIEZWELL",
        "GWINSTWELLDIVERDEEP",
        "GWLEVREADDIVER",
        "GWLEVREADDIVERMAN",
        "GWLEVREADDIVERDEEP",
        "GWSHALLCLEAN",
        "GWSHALLSAMP",
        "GWSHALLSAMPREADMAN",
        "GWSURFLEVREADDIVERMAN",
        "GWSURFSHALLSAMPREADMAN",
        "SPATPOSITPIPE",
        "SPATPOSITGAUGE",
        "ADHOCDIVERREPLACE",
        "ADHOCPIPEREPLACE"
      ),
      is_surf_activity = activity_group %in% c(
        "ADHOCDIVERREPLACE",
        "ADHOCPIPEREPLACE",
        "GWSURFINSTALLMAT",
        "GWSURFLEVREADDIVERMAN",
        "GWSURFSHALLSAMPREADMAN",
        "SPATPOSITGAUGE",
        "SPATPOSITPIPE",
        "SURFADHOCGAUGEREPLACE",
        "SURFINSTGAUGE",
        "SURFINSTWELLDIVER",
        "SURFLENTDATACOLL",
          "SURFLENTLOCEVALSAMPLPOINT",
        "SURFLEVREADDIVER",
        "SURFLOTDATACOLL",
          "SURFLOTLOCEVALSAMPLPOINT"
      )
    ) %>%
    return()

}
