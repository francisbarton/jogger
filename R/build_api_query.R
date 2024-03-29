#' Helper Function to Build Queries to the Open Geography API
#'
#' A function called by create_custom_lookup.R and geo_get.R to build a
#' valid query.
#'
#' @param ref an integer, passed by the calling function, that
#'   indicates which url_string to use.
#' @param where_level The variable name associated with the
#'   locations filter. e.g. \code{"lsoa11nm"} or \code{"rgn20cd"}
#' @param where A vector of names or codes to filter the data by. If nothing is
#' provided then the full table should be returned.
#' @param fields The fields of the data to be returned. Defaults to \code{"*"}
#'   (all); can instead be a set of column names/variables.
#' @param sr The (EPSG) spatial reference of any returned geometry.
#'   4326 ("WGS 84") by default. Can be specified as numeric or character.
#'
#' @return a string that should function as a valid API query
#' @export
#' @examples
#' build_api_query(ref = 4,
#'   where_level = "cauth20nm",
#'   where = "Greater Manchester",
#'   fields = c("lad20cd", "lad20nm", "cauth20cd", "cauth20nm")
#' )
#' build_api_query(ref = 12,
#'   where_level = "lad20nm",
#'   where = c(
#'     "Cheltenham", "Gloucester",
#'     "Stroud", "Cotswold",
#'     "Tewkesbury", "Forest of Dean"
#'   ),
#'   fields = c("lad20cd", "lad20nm")
#' )
build_api_query <- function(ref,
                            where_level,
                            where = NULL,
                            fields = "*",
                            sr = 4326) {


  # TODO: set up a test/check for all URLs here, to auto-flag if the specific
  # code has changed (if ONS have updated and versioned their data).

  # create a list of codes for the main function.
  # Source URLs are included as comments.
  url_strings <- c(

    ### LOOKUPS (1 - 9)
    #########################################################################

    # https://geoportal.statistics.gov.uk/datasets/output-area-to-lower-layer-super-output-area-to-middle-layer-super-output-area-to-local-authority-district-december-2020-lookup-in-england-and-wales
    "OA11_LSOA11_MSOA11_LAD20_RGN20_EW_LU",

    # https://geoportal.statistics.gov.uk/datasets/output-area-to-ward-to-local-authority-district-december-2020-lookup-in-england-and-wales-v2
    "OA11_WD20_LAD20_EW_LU_v2",

    # https://geoportal.statistics.gov.uk/datasets/ons::ward-to-local-authority-district-to-county-to-region-to-country-december-2020-lookup-in-united-kingdom-v2
    "WD20_LAD20_CTY20_OTH_UK_LU_v2",

    # https://geoportal.statistics.gov.uk/datasets/local-authority-district-to-combined-authority-december-2020-lookup-in-england
    "LAD20_CAUTH20_EN_LU",

    # https://geoportal.statistics.gov.uk/datasets/lower-layer-super-output-area-2011-to-upper-tier-local-authorities-2021-lookup-in-england-and-wales-/
    "LSOA11_UTLA21_EW_LU",

    # https://geoportal.statistics.gov.uk/datasets/ons::lower-tier-local-authority-to-upper-tier-local-authority-april-2021-lookup-in-england-and-wales
    "LTLA21_UTLA21_EW_LU",

    # https://geoportal.statistics.gov.uk/datasets/lower-layer-super-output-area-2011-to-ward-2020-to-lad-2020-lookup-in-england-and-wales-v2/
    "LSOA11_WD20_LAD20_EW_LU_v2",

    # https://geoportal.statistics.gov.uk/datasets/local-authority-district-to-region-april-2021-lookup-in-england/
    "LAD21_RGN21_EN_LU",

    # https://geoportal.statistics.gov.uk/datasets/local-authority-district-to-country-april-2021-lookup-in-the-united-kingdom/
    "LAD21_CTRY21_UK_LU",


    ### BOUNDARIES (10 - 17)
    ########################################################################

    # Output Areas (December 2011) Boundaries EW BGC
    "Output_Areas_December_2011_Boundaries_EW_BGC",

    # Lower Layer Super Output Areas (December 2011) Boundaries (BGC) EW V3
    "Lower_Layer_Super_Output_Areas_DEC_2011_EW_BGC_V3",

    # Middle Layer Super Output Areas (December 2011) Boundaries Full Clipped (BGC) EW V3
    "Middle_Layer_Super_Output_Areas_DEC_2011_EW_BGC_V3",

    # Wards (May 2021) Boundaries UK BGC
    "Wards_May_2021_UK_BGC",

    # Local Authority Districts (May 2021) UK BGC
    "LAD_MAY_2021_UK_BGC",

    # Counties and Unitaries
    "Counties_and_Unitary_Authorities_May_2021_UK_BGC_v2",

    # Regions (December 2020) UK BUC
    "Regions_December_2020_EN_BUC_V2",

    # Countries (December 2020) UK BUC
    "Countries_December_2020_UK_BUC_V3",



    ### CENTROIDS (18 - 20)
    ##################################################################

    # Output Areas (December 2011) Population Weighted Centroids
    # https://geoportal.statistics.gov.uk/datasets/ons::output-areas-december-2011-population-weighted-centroids-1/
    "Output_Area_December_2011_Centroids",


    # Lower Layer Super Output Areas (December 2011) Population Weighted Centroids
    # https://geoportal.statistics.gov.uk/datasets/ons::lower-layer-super-output-areas-december-2011-population-weighted-centroids
    "Lower_Super_Output_Areas_December_2011_Centroids",


    # Middle Layer Super Output Areas (December 2011) Population Weighted Centroids
    # https://geoportal.statistics.gov.uk/datasets/middle-layer-super-output-areas-december-2011-population-weighted-centroids
    "Middle_Super_Output_Areas_December_2011_Centroids"
    )



  ####################################################################
  # set up commonly used string variables for query URL construction;
  # just for neatness & easier updating. These are just taken from the
  # "API Explorer" tab on each Open Geography Portal page.
  ####################################################################


  # pull table code from list above
  url_string <- url_strings[[ref]]

  # standard
  if (ref < 18) {
    url_base <- "https://services1.arcgis.com/ESMARspQHYMw9BZ9/"
    part_2 <- ""
    server_line <- "/FeatureServer/0/"
    distinct <- "&returnDistinctValues=true"
  }

  # centroids only
  if (ref %in% 18:20) {
    url_base <- "https://ons-inspire.esriuk.com/"
    part_2 <- "Census_Boundaries/"
    server_line <- "/MapServer/0/"
    distinct <- ""
  }

  # mothballed for now (maybe needed for things like CCG boundaries...)
  # if (type == "admin") {
  #   part_2 <- "Administrative_Boundaries/"
  # }
  #
  # if (type == "other") {
  #   part_2 <- "Other_Boundaries/"
  # }



  # upper or lower case field names? it seems to depend on the server, or
  # maybe the type, haven't managed to check yet.
  # NB the queries seem to actually work fine either way, I am just going
  # for 100% fidelity for the sake of the function tests!

  # if (server == "feature") {
  fields <- toupper(fields)
  where_level <- toupper(where_level)
  # }

  # format 'locations' correctly
  # I'm manually putting in percent-encoded strings instead of calling
  # utils::URLencode because I found that it wasn't encoding
  # all the things as I needed it to for the query to be valid

  if (is.null(where)) {
    where <- "1%3D1"
  } else {
    where <- where %>%
      stringr::str_replace_all(" ", "%20") %>%

      # don't think this is needed but it's what the site itself does
      toupper() %>%


      # surround each location in ''
      # ' seems to be OK without being escaped as %27 in queries
      paste0("'", ., "'") %>%
      stringr::str_c(
        where_level, # area level code eg WD20CD
        # "%3D", # "="
        "=", # trying this instead of %3D doesn't seem to matter
        .,     # vector of 'where'
        # using "+" instead of a space also seems to be good for the API
        sep = "%20", # Open Geog website puts spaces in, so so will I
        collapse = "%20OR%20" # collapse multiple locations with an " OR "
      )
  }


  # collapse a vector of fields to a single string
  # (it should usually be more than one)
  # fields is the columns to retrieve, if only some are wanted
  if (length(fields) > 1) {
    fields <- fields %>%
      stringr::str_c(collapse = ",")
  }


  # for simple lookup queries we can use "standard" result type;
  # CRS is irrelevant
  # "7" will need to be changed if list above incorporates more lookup options
  if (ref %in% 1:7) {
    result_type <- "standard"
    sr_line <- ""
  } else {

    # this result_type is needed for spatial queries, "standard" doesn't agree
    # see examples six and seven here:
    # https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service-layer-.htm
    result_type <- "none"
    sr_line <- paste0("&outSR=", sr)
  }


  arcgis_base <- "arcgis/rest/services/"

  query_line <- "query?where="
  where_open <- "%20("
  where_close <- ")%20"
  fields_line <- "&outFields="
  result_type_line <- "&resultType="
  return_format <- "&f=json"

  # in theory there are several other options that could be customised here
  # if it were worth the candle.
  # maybe I should bother to allow that, in order better to replicate the API

  # create the query
  paste0(
    url_base,
    arcgis_base,
    part_2,
    url_string,
    server_line,
    query_line,
    where_open,
    where,
    where_close,
    fields_line,
    fields,
    sr_line,
    result_type_line,
    result_type,
    distinct,
    return_format
  )
}
