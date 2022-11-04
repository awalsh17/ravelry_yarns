# Call to ravelry API

library(dplyr)
library(httr)
library(jsonlite)

# get the information on 100,000 yarns -------
# iterate over all pages (1000 results per) 100,000 total, api user/pass was saved to env
# these are the yarns with the most projects on ravelry

pages <- c(1:100)

resp <- purrr::map(pages, ~httr::GET(
  url = paste0("https://api.ravelry.com/yarns/search.json?sort=projects&page_size=1000&page=", .x),
  authenticate(Sys.getenv("RAVELRY_API_USER"), Sys.getenv("RAVELRY_API_PASS"))))

# first item is the yarn data (second is the paginator)

yarn_all <- purrr::map_dfr(resp, ~fromJSON(content(.x, as = "text"))[[1]])

# write out raw

saveRDS(yarn_all, "data/yarn_raw.Rds")

# unnest yarn_weight, remove first_photo and personal_attributes

yarn_all <- tidyr::unnest(yarn_all, yarn_weight, names_sep = "_") %>%
  select(-first_photo, -personal_attributes)

# yarn_weight_min_gauge and yarn_weight_max_gauge are always missing

yarn_all <- select(yarn_all, -yarn_weight_max_gauge, -yarn_weight_min_gauge)

# clean the texture variable

yarn_all$texture_clean <- stringr::str_trim(yarn_all$texture)
yarn_all$texture_clean <- stringr::str_to_lower(yarn_all$texture_clean)

# write out the final csv

write.csv(yarn_all, "data/yarn.csv", row.names = FALSE)




# Query for more yarn information -----

# need to split request up into chunks of 100

chunks <- dplyr::ntile(1:100000, 1000)
yarn_ids <- purrr::map(
  1:1000,
  ~paste(unique(yarn_all$id)[chunks == .x], collapse = "+"))

resp <- purrr::map(
  yarn_ids,
  ~httr::GET(url = paste0("https://api.ravelry.com/yarns.json?ids=", .x),
             authenticate(Sys.getenv("RAVELRY_API_USER"), Sys.getenv("RAVELRY_API_PASS"))))

yarn_json <- purrr::map(
  resp,
  ~parse_json(content(.x, as = "text"), simplifyVector = TRUE)$yarns)
yarn_json <- unlist(yarn_json, recursive = FALSE)

# yarn_fibers with have more than one row per yarn

yarn_fibers <- purrr::map_dfr(yarn_json, ~.x[["yarn_fibers"]], .id = "yarn_id") %>%
  tidyr::unnest(fiber_type, names_sep = "_") %>%
  select(-fiber_category, -id) %>%
  rename(id = yarn_id) # make primary key id for yarn

# yarn_attributes have more than one row per yarn (care, color, dye)

yarn_attributes <- purrr::map_dfr(yarn_json, ~.x[["yarn_attributes"]], .id = "yarn_id") %>%
  tidyr::unnest(yarn_attribute_group, names_sep = "_") %>%
  select(-id, -yarn_attribute_group_id) %>%
  rename(id = yarn_id) # make primary key id for yarn

# this has all the possible values for the yarn_attribute_group

yarn_attribute_groups <- httr::GET(
  url = "https://api.ravelry.com/yarn_attributes/groups.json",
  authenticate(Sys.getenv("RAVELRY_API_USER"), Sys.getenv("RAVELRY_API_PASS")))

yarn_attribute_groups <- fromJSON(content(yarn_attribute_groups, as = "text"))[[1]] %>%
  tidyr::unnest(yarn_attributes, names_sep = "_") %>%
  select(-children) # for construction attributes, just remove for here

# write out yarn_fibers and yarn_attributes

write.csv(yarn_fibers, "data/yarn_fibers.csv", row.names = FALSE)
write.csv(yarn_attribute_groups, "data/yarn_attribute_groups.csv", row.names = FALSE)
write.csv(yarn_attributes, "data/yarn_attributes.csv", row.names = FALSE)
