#' Return boundary geometries for supplied list of area codes
#'
#' @param bounds_query_level area level to query for, e.g. "lsoa11cd". Needs to
#'   be the full code not an abbreviation such as "lsoa"
#' @param area_codes a vector of codes that match the level of
#'   bounds_query_level. Probably to be supplied from a column pulled from a
#'   lookup df or similar.
#' @param return_centroids whether to retrieve area centroids instead of
#'   boundaries. Default \code{FALSE}. If set to TRUE then it will override
#'   \code{return_boundaries} whether that was set TRUE or otherwise. If
#'   \code{return_boundaries} and \code{return_centroids} are both \code{FALSE},
#'   a plain summary data frame without geometry will be returned.
#' @param centroid_fields Boolean, default FALSE. Whether to include BNG
#'   eastings, northings, lat and long fields in the return. NB this *doesn't*
#'   apply to direct (population-weighted) centroid queries.
#' @param shape_fields Boolean, default FALSE. Whether to include
#'   Shape__Area and Shape__Length fields in the return when returning
#'   boundaries.
#' @param spatial_ref The (EPSG) spatial reference of any returned geometry.
#'   Default value: 4326 ("WGS 84"). This parameter is ignored peacefully if
#'   no geometry is returned/returnable, eg lookup queries
#' @param quiet_read Controls quiet parameter to sf::st_read
#'
#' @keywords internal
#' @return an sf object
#' @export
geo_get_bounds <- function(bounds_query_level,
                           area_codes,
                           return_centroids = FALSE,
                           centroid_fields = FALSE,
                           shape_fields = FALSE,
                           spatial_ref = 4326,
                           quiet_read = TRUE) {


  bounds_query_level <- bounds_query_level %>%
    stringr::str_replace_all(., c(
      wd20 = "wd21",
      lad20 = "lad21",
      rgn21 = "rgn20",
      ctry21 = "ctry20",
      ltla20 = "ltla21",
      utla20 = "utla21",
      ctyua20 = "ctyua21"
    ))


  # TODO allow customising which fields user wants
  shape_fields_list <- NULL
  if (shape_fields) {
    shape_fields_list <- c(
      "Shape__Area",
      "Shape__Length"
    )
  }

  # TODO allow customising which fields user wants
  centroid_fields_list <- NULL
  if (centroid_fields) {
    centroid_fields_list <- c(
      "BNG_E",
      "BNG_N",
      "LONG",
      "LAT"
    )
  }

  return_fields <- c(
    bounds_query_level,
    shape_fields_list,
    centroid_fields_list
  )





  ref_lookup <- dplyr::tribble(
    ~bounds_level, ~ref, ~centroids,
    "oa11cd",     10,     FALSE,
    "lsoa11cd",   11,     FALSE,
    "msoa11cd",   12,     FALSE,
    "wd21cd",     13,     FALSE,
    "lad21cd",    14,     FALSE,
    "ctyua21cd",  15,     FALSE,
    "rgn20cd",    16,     FALSE,
    "ctry20cd",   17,     FALSE,
    "oa11cd",     18,     TRUE,
    "lsoa11cd",   19,     TRUE,
    "msoa11cd",   20,     TRUE
  )


  ref <- ref_lookup %>%
    dplyr::filter(bounds_level == bounds_query_level) %>%
    # centroids is used here to filter, this is why the setting of
    # return_centroids as TRUE will override the setting of boundaries to TRUE
    dplyr::filter(centroids == return_centroids) %>%
    dplyr::pull(ref)


  bounds_queries <- area_codes %>%
    # According to the API docs, 50 is the limit for geo queries.
    # Excessively long queries return 404.
    # Playing it safe with 25
    batch_it_simple(batch_size = 25) %>% # borrowed from my myrmidon utils pkg
    purrr::map(~ build_api_query(
      ref = ref,
      where_level = bounds_query_level,
      where = .,
      fields = return_fields,
      sr = spatial_ref
    ))

  bounds_queries %>%
    purrr::map_df(~ sf::st_read(., quiet = quiet_read)) %>%
    janitor::clean_names()
}
