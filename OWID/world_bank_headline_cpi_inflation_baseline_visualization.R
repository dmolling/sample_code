### Creates a baseline visualization of World Bank Annual Headline CPI Inflation Data
### 
### Author: Daniel Molling
### email:  daniel.molling@gmail.com
### date:   March 2, 2022
### 
### Note 1: this file uses relative paths, and so should be run from the folder 
### in which it is located
### 
### Note 2: In practice, changing the countries or date range on this chart and 
### keeping good axis and label placement would require some tinkering as this is a very
### noisy series. It is possible to make this type of adjustment automatic, 
### but would require additional work. This chart can be thought of as a prototype. 

library(readr)
library(dplyr)
library(ggplot2)
library(scales)
library(ggtext)
library(ggrepel)

##### Importing cleaned  data ----
df_hcpi_a = read_csv(file = "worldbank_inflation/output/datapoints/datapoints_headline_consumer_price_inflation.csv")

##### 
##### 
theme_set(theme_minimal()) 
theme_update(
  axis.title = element_blank(),
  axis.text = element_text(color = "grey40"),
  axis.text.x = element_text(size = 20, margin = margin(t = 5)),
  axis.text.y = element_text(size = 17, margin = margin(r = 5)),
  axis.ticks = element_line(color = "grey91", size = .5),
  axis.ticks.length.x = unit(1.3, "lines"),
  axis.ticks.length.y = unit(.7, "lines"),
  panel.grid = element_blank(),
  plot.margin = margin(20, 40, 20, 40),
  plot.background = element_rect(fill = "grey98", color = "grey98"),
  panel.background = element_rect(fill = "grey98", color = "grey98"),
  plot.title = element_text(color = "grey10", size = 32, face = "bold",
                            margin = margin(t = 15)),
  plot.subtitle = element_markdown(color = "grey30", size = 17, 
                                   lineheight = 1.35,
                                   margin = margin(t = 15, b = 40)),
  plot.title.position = "plot",
  plot.caption.position = "plot",
  plot.caption = element_text(color = "grey30", size = 15,
                              lineheight = 1.2, hjust = 0, 
                              margin = margin(t = 40)),
  legend.position = "none"
)
##### Creating baseline visualization and writing to disk -----

#selecting a handful of countries to plot for the baseline visualization
selected_countries = c("Germany", "China", "India", "Botswana", "Bolivia")

#creating a new, filtered dataset for visualization
df_chart = df_hcpi_a %>%
  filter(country %in% selected_countries, year >= 1990) %>%
  mutate(country_label = if_else(year == 2020, country, NA_character_))

#creating the baseline visualization
chart = df_chart %>%
  ggplot(aes(x = year, 
             y = value, 
             color = country,
             label = country)) +
  geom_vline(
    xintercept = seq(min(df_plot$year), max(df_plot$year), by = 5),
    color = "grey91", 
    size = .6
  ) +
  geom_segment(
    data = tibble(y = seq(-5, 25, by = 5), 
                  x1 = min(df_plot$year), 
                  x2 = max(df_plot$year)),
    aes(x = x1, xend = x2, y = y, yend = y),
    inherit.aes = FALSE,
    color = "grey91",
    size = .6
  ) +
  geom_segment(
    data = tibble(y = 0, x1 = min(df_plot$year), x2 = max(df_plot$year)),
    aes(x = x1, xend = x2, y = y, yend = y),
    inherit.aes = FALSE,
    color = "grey60",
    size = .8
  ) +
  geom_line(size = 0.9) + 
  geom_point() +
  geom_text_repel(
    aes(color = country, label = country_label),
    fontface = "bold",
    size = 6.5,
    direction = "y",
    xlim = c(2020.8, NA),
    hjust = 0,
    segment.size = .7,
    segment.alpha = .5,
    segment.linetype = "dotted",
    box.padding = .4,
    segment.curvature = -0.1,
    segment.ncp = 3,
    segment.angle = 20
  ) +
  scale_x_continuous(
    expand = c(0, 0),
    limits = c(min(df_plot$year), max(df_plot$year)+9), 
    breaks = seq(min(df_plot$year), max(df_plot$year), by = 5)
  ) + 
  scale_y_continuous(
    expand = c(0, 0),
    breaks = seq(-5, 25, by = 5),
    labels = glue::glue("{format(seq(-5, 25, by = 5), nsmall = 0)}%")
  ) +
  labs(
    title = "Annual Inflation, 1990 to 2020",
    subtitle = "Percent change in headline consumer price index",
    caption = "Source: Data compiled from multiple sources by World Bank"
  )
  
#writing the baseline visualization to disk
ggsave(plot = chart, filename = "annual_headline_cpi_inflation.png")

#####