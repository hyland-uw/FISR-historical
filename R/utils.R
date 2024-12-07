# utils.R

# Load required packages
library(tidyr)
library(dplyr)
library(ggplot2)
library(gganimate)
library(scales)
library(stringr)
library(lpSolve)
library(purrr)
library(knitr)

#### Colors and such

## from https://stackoverflow.com/a/9568659/1188479
## useful for false categorical coloring
false_categorical_25 <- c(
  "dodgerblue2", "#E31A1C", # red
  "green4",
  "#6A3D9A", # purple
  "#FF7F00", # orange
  "black", "gold1",
  "skyblue2", "#FB9A99", # lt pink
  "palegreen2",
  "#CAB2D6", # lt purple
  "#FDBF6F", # lt orange
  "gray70", "khaki2",
  "maroon", "orchid1", "deeppink1", "blue1", "steelblue4",
  "darkturquoise", "green1", "yellow4", "yellow3",
  "darkorange4", "brown"
)

#### helper functions
# Slicing Function
create_slices <- function(df, N, min_input = 0.5, max_input = 2.0) {
  slice_width <- (max_input - min_input) / N
  
  df %>%
    filter(input >= min_input, input < max_input) %>%
    mutate(slice = cut(input, 
                       breaks = seq(min_input, max_input, by = slice_width),
                       labels = FALSE,
                       include.lowest = TRUE))
}

# Optimization Function
find_optimal_magic <- function(slice_data) {
  unique_magics <- unique(slice_data$magic)
  
  results <- sapply(unique_magics, function(m) {
    slice_data %>%
      filter(magic == m) %>%
      summarise(max_error = max(error)) %>%
      pull(max_error)
  })
  
  optimal_index <- which.min(results)
  list(minimum = unique_magics[optimal_index], objective = results[optimal_index])
}
