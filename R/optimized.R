library(ggplot2)
library(dplyr)
library(gganimate)

optimized <- read.csv("../data/optimized.csv")

## helps with geom_path plotting
optimized <- optimized[order(optimized[, "input"]), ]

optimized$pair <- paste0("(",
                         optimized$A,
                         ", ",
                         optimized$B,
                         ")")

optimized$pair <- factor(optimized$pair)


## good artistic plot of errors by grid location
ggplot(optimized, aes(x = input,
                      y = error,
                      color = pair)) +
  geom_path() +
  guides(color = "none") +
  xlim(0.25, 1) +
  coord_polar(theta = "x") +
  theme_void() + facet_wrap(~iters)

ggplot(optimized, aes(x = iters,
                      y = error,
                      color = pair)) +
  geom_path() +
  guides(color = "none") +
  theme_void()


# Function to prepare and bin the data
prepare_binned_data <- function(data, num_bins) {
  data %>%
    mutate(input_bin = cut(input, breaks = num_bins, labels = FALSE)) %>%
    group_by(input_bin) %>%
    mutate(bin_range = paste(round(min(input), 4), "-", round(max(input), 4)),
           frame = input_bin)
}

# Function to create a single heatmap
create_single_heatmap <- function(data, title = NULL) {
  ggplot(data, aes(x = halfone, y = halfthree, fill = error)) +
    geom_tile() +
    scale_fill_gradient2(low = "blue", mid = "white", high = "red", 
                         midpoint = median(data$error)) +
    labs(title = title,
         x = "Halfone",
         y = "Halfthree") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

# Function to create small multiples
create_binned_heatmaps <- function(data, num_bins) {
  binned_data <- prepare_binned_data(data, num_bins)
  
  create_single_heatmap(binned_data, "Error Heatmaps by Input Range") +
    facet_wrap(~ bin_range, scales = "free") +
    theme(strip.text = element_text(size = 8),
          strip.background = element_rect(fill = "lightgray"))
}

# Function to create animated heatmap
create_animated_heatmap <- function(data, num_bins) {
  binned_data <- prepare_binned_data(data, num_bins)
  
  base_plot <- create_single_heatmap(binned_data, 
                                     "Error Heatmap for Input Range: {closest_state}")
  
  anim <- base_plot +
    transition_states(bin_range, 
                      transition_length = 2, 
                      state_length = 1) +
    ease_aes('linear')
  
  animate(anim, nframes = 256, fps = 10)
}

animated_plot <- create_animated_heatmap(optimized, 64)

####
# Display the animation in RStudio's viewer
####
print(animated_plot)
anim_save("../plots/animated_heatmap.gif", animation = animated_plot)

####
# Optionally, save the animation as a GIF file
# Uncomment the following line to save:
# anim_save("animated_heatmap.gif", animation = animated_plot)
####

## print a binned plot
print(create_binned_heatmaps(optimized, 9))

## generate a range of errors against params
ggplot(optimized, aes(x = A,
                      y = log(error),
                      color = B)) +
  geom_col() + guides(color = "none")

