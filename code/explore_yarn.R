# Plot some yarn information

library(dplyr)    # data manipulation
library(readr)    # reading and writing data
library(ggplot2)  # plots
library(ggridges) # create "ridgeplots"

theme_set(theme_minimal(base_family = "Karla"))  # plot style

# load data

yarn <- read_csv("data/yarn.csv",
                 col_types = cols(
                   discontinued = col_logical(),
                   gauge_divisor = col_double(),
                   grams = col_double(),
                   id = col_double(),
                   machine_washable = col_logical(),
                   max_gauge = col_double(),
                   min_gauge = col_double(),
                   name = col_character(),
                   permalink = col_character(),
                   rating_average = col_double(),
                   rating_count = col_double(),
                   rating_total = col_double(),
                   texture = col_character(),
                   thread_size = col_character(),
                   wpi = col_double(),
                   yardage = col_double(),
                   yarn_company_name = col_character(),
                   yarn_weight_crochet_gauge = col_logical(),
                   yarn_weight_id = col_double(),
                   yarn_weight_knit_gauge = col_character(),
                   yarn_weight_name = col_character(),
                   yarn_weight_ply = col_double(),
                   yarn_weight_wpi = col_character(),
                   texture_clean = col_character()
                 ))

# yarn_fibers could have useful information

yarn_fibers <- read_csv("data/yarn_fibers.csv")

# we could include all fibers per yarn or just the top one.

# note: some percentages do not add to 100!

# create a "wide" dataset with each fiber as a column, values are percent
yarn_fibers_wide <- yarn_fibers %>%
  distinct(yarn_id, percentage, fiber_type_name) %>%
  group_by(yarn_id) %>%
  mutate(total = sum(percentage)) %>%
  ungroup() %>%
  filter(total == 100) %>%
  distinct(yarn_id, fiber_type_name, .keep_all = TRUE) %>%
  tidyr::pivot_wider(names_from = fiber_type_name, values_from = percentage, values_fill = 0)

# decided to just get the "top" fiber per yarn!
yarn_fibers_top <- yarn_fibers %>%
  group_by(yarn_id) %>%
  slice_max(percentage, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  distinct(yarn_id, top_fiber = fiber_type_name)

# if we want to plot yarn ratings (in yarn) and fiber (in yarn_fibers_top)
# we need to combine those data sets

yarn_more <- yarn %>%
  left_join(yarn_fibers_top, by = c("id" = "yarn_id"))

# plot by fiber - first try a ridgeplot

yarn_more %>%
  filter(rating_count > 19) %>%
  filter(!is.na(top_fiber), !is.na(rating_average)) %>%
  add_count(top_fiber) %>%
  filter(n > 100) %>%
  mutate(top_fiber = forcats::fct_reorder(top_fiber, rating_average)) %>%
  ggplot(aes(y = top_fiber, x = rating_average, fill = top_fiber)) +
  ggridges::geom_density_ridges2(rel_min_height = 0.01) +
  scale_fill_viridis_d() +
  scale_y_discrete(expand = c(0.01, 0)) +
  scale_x_continuous(expand = c(0.01, 0)) +
  theme(legend.position = "none") +
  labs(title = "We love merino and cashmere!",
       y = "Fiber (main fiber per yarn)",
       x = "Average rating on Ravelry",
       caption = "Data: ravelry.com | yarns with 20+ ratings")

# ridgeplot does not show all the data, so could do a jitter point

yarn_more %>%
  filter(rating_count > 19) %>%
  filter(!is.na(top_fiber), !is.na(rating_average), !is.na(yardage)) %>%
  add_count(top_fiber) %>%
  filter(n > 100) %>%
  mutate(top_fiber = forcats::fct_reorder(top_fiber, rating_average)) %>%
  ggplot(aes(x = top_fiber, y = rating_average, size = log10(yardage))) +
  geom_jitter(alpha = 0.1, width = 0.3, shape = 1, show.legend = F) +
  scale_size_continuous(range = c(.1,2)) +
  coord_flip() +
  labs(title = "We love merino and cashmere!",
       x = NULL,
       y = "Average rating on Ravelry",
       caption = "Data: ravelry.com | yarns with 20+ ratings")

# use yarn icons? to make a plot instead?

library(ggimage) # to plot images on a ggplot

# found a yarn icon online, need to credit the creator!

png_file <- "images/yarn_small.png"


yarn_palette <- c(rep("#9b9c9b",4), # these are gray for the synthetic
                  "#f94144", "#f3722c", "#f8961e", "#f9844a",
                  "#f9c74f", "#90be6d", "#43aa8b", "#4d908e", "#577590", "#277da1"
                  )

yarn_more %>%
  filter(rating_count > 19) %>%
  filter(!is.na(top_fiber), !is.na(rating_average), !is.na(yardage)) %>%
  add_count(top_fiber) %>%
  filter(n > 100) %>%
  mutate(top_fiber = forcats::fct_reorder(top_fiber, rating_average)) %>%
  group_by(top_fiber) %>%
  summarise(n = n(),
            mean = mean(rating_average),
            median = median(rating_average),
            upper = quantile(rating_average, 0.75),
            lower = quantile(rating_average, 0.25)) %>%
  ggplot(aes(x = top_fiber, y = median, color = top_fiber)) +
  geom_segment(aes(y = lower, yend = median - 0.02, xend = top_fiber),
               size = 0.5) +
  geom_segment(aes(y = median + 0.02, yend = upper, xend = top_fiber),
               size = 0.5) +
  geom_image(image = png_file) +
  scale_color_manual(values = yarn_palette) +
  scale_size_continuous(range = c(1, 2)) +
  scale_y_continuous(expand = expansion(add = c(0, 0.25)),
                     breaks = c(3.5, 4.0, 4.5, 5.0)) +
  coord_flip() +
  annotate("text", x = "Acrylic", y = 4.6,
           family = "Karla",
           size = 3,
           color = "gray10",
           label = "Synthetic fibers\nare lower rated") +
  theme(plot.background = element_rect(fill = "#fefae0", colour = "#fefae0"),
        plot.title.position = "plot",
        plot.title = element_text(hjust = 0.5),
        legend.position = "none",
        plot.caption.position = "plot",
        plot.caption = element_text(margin = margin(t = 10, b = 10),
                                    size = 9,
                                    hjust = 0.5),
        axis.text.y = element_text(size = 14),
        axis.line.x = element_line(size = 0.5, color = "gray50"),
        axis.ticks.x = element_line(size = 0.5, color = "gray50"),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.x = element_blank()) +
  labs(title = "We love merino and cashmere!",
       x = NULL,
       y = "Median average rating (+ IQR)",
       caption = "data: ravelry.com | icon: ColourCreatype on freeicons.io\nyarns with 20+ ratings")

# save this out

ggsave("we_love_merino.png", width = 4, height = 4)
