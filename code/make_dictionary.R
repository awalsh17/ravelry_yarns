# make_dictionary.R

# See more documentation from https://www.ravelry.com/api

# make the documentation

yarn_dictionary <- sapply(yarn_all, class) %>% tibble::enframe(value = "type") %>%
  mutate(description = c(
    "Is the yarn discontinued",
    "The number of inches that equal min_gauge to max_gauge stitches",
    "Unit weight",
    "Unique identifier for the yarn",
    "Is the yarn machine washable",
    "The max number of stitches that equal gauge_divisor",
    "The min number of stitches that equal gauge_divisor",
    "Name of the yarn",
    "The permalink to https://www.ravelry.com/yarns/library/<permalink>",
    "The average rating out of 5",
    "",
    "",
    "Texture free text",
    "Thread size",
    "Wraps per inch",
    "",
    "",
    "Crochet gauge for the yarn weight category",
    "Identifier for the yarn weight category",
    "Knit gauge for the yarn weight category",
    "Name for the yarn weight category",
    "Ply for the yarn weight category",
    "Wraps per inch for the yarn weight category",
    "Texture with some light text cleaning"
  ))

write.csv(yarn_dictionary, "data/yarn_dictionary.csv", row.names = FALSE)
