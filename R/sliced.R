library(tidyr)
library(dplyr)

sliced <- read.csv("../data/sliced.csv")
sliced <- sliced[!duplicated(sliced[,c("input", "magic")]), ]

## set these for equally sized ntile bins
divisble_limit <- nrow(sliced) - (nrow(sliced) %% 2048)
division <- 64

##for some reason I couldn't do the above math inside the index
sliced <- sliced[1:divisble_limit, ]


## these power some existing plots but will be phased out
sliced$error_rank <- ntile(sliced$error, 4)
sliced$input_rank <- ntile(sliced$input, division)
sliced$magic_rank <- ntile(sliced$magic, division)



find_best_magic_constants <- function(sliced, ranks) {
  rank_column <- paste0("rank_", ranks)
  
  sliced %>%
    arrange(input) %>%
    mutate(!!rank_column := ntile(input, ranks)) %>%
    group_by(!!sym(rank_column), magic) %>%
    summarize(total_error = sum(error), .groups = 'drop') %>%
    group_by(!!sym(rank_column)) %>%
    slice_min(order_by = total_error, n = 4) %>%
    summarize(best_magic = floor(mean(magic))) %>%
    arrange(!!sym(rank_column))
}

magic_by_rank <- function(sliced, ranks) {
  input_column <- paste0("input_", ranks)
  magic_column <- paste0("magic_", ranks)
  
  best_magic_df <- sliced %>%
    arrange(input) %>%
    mutate(!!input_column := ntile(input, ranks)) %>%
    group_by(!!sym(input_column), magic) %>%
    summarize(total_error = sum(error), .groups = 'drop') %>%
    group_by(!!sym(input_column)) %>%
    slice_min(order_by = total_error, n = 4) %>%
    summarize(!!magic_column := floor(mean(magic))) %>%
    ungroup()
  
  sliced %>%
    arrange(input) %>%
    mutate(!!input_column := ntile(input, ranks)) %>%
    left_join(best_magic_df, by = input_column) %>%
    select(!!sym(input_column), !!sym(magic_column))
}



## within an input rank list, what are the difference in the magic constant?
## An input rank N will have N different magic constants, this determines
## the difference of one element and the mean of all
diff_within_rank <- function(df, N, length = 256) {
  # Convert input to character if it's not already
  N <- as.character(N)
  
  # Dynamically create column names
  rank_col <- paste0("input_", N)
  value_col <- paste0("magic_", N)
  
  # Ensure required columns exist
  if (!all(c(rank_col, value_col) %in% names(df))) {
    stop("Required columns are missing from the dataframe")
  }
  
  overall_mean <- mean(df[[value_col]])
  total_rows <- nrow(df)
  
  df %>%
    group_by(!!sym(rank_col)) %>%
    summarize(
      avg_within_rank = mean(!!sym(value_col)),
      sum_within_rank = sum(!!sym(value_col)),
      count_within_rank = n(),
      .groups = "drop"
    ) %>%
    mutate(
      avg_other_ranks = (overall_mean * total_rows - sum_within_rank) / (total_rows - count_within_rank),
      diff_outside = avg_within_rank - avg_other_ranks
    ) %>%
    arrange(!!sym(rank_col)) %>%
    pull(diff_outside) -> output
  return(rep(output, each = length / as.numeric(N)))
}


## A higher rank will have more magic values
## this subtracts those from lower ranks, showing the
## difference across
diff_across_ranks <- function(df, N1, N2, length = 256) {
  # Convert inputs to character if they're not already
  N1 <- as.character(N1)
  N2 <- as.character(N2)
  
  # Dynamically create column names
  rank_col1 <- paste0("input_", N1)
  rank_col2 <- paste0("input_", N2)
  value_col1 <- paste0("magic_", N1)
  value_col2 <- paste0("magic_", N2)
  
  # Ensure all required columns exist
  required_cols <- c(rank_col1, rank_col2, value_col1, value_col2)
  if (!all(required_cols %in% names(df))) {
    stop("One or more required columns are missing from the dataframe")
  }
  
  # Perform the calculation
  df %>%
    group_by(!!sym(rank_col2)) %>%
    summarize(
      avg_value1 = mean(!!sym(value_col1)),
      avg_value2 = mean(!!sym(value_col2)),
      .groups = "drop"
    ) %>%
    mutate(diff = avg_value1 - avg_value2) %>%
    arrange(!!sym(rank_col2)) %>%
    pull(diff) -> output
  return(rep(output, each = length / as.numeric(N2)))
}


diced <- magic_by_rank(sliced, 4)
diced <- cbind(diced, magic_by_rank(sliced, 8))
diced <- cbind(diced, magic_by_rank(sliced, 32))
diced <- cbind(diced, magic_by_rank(sliced, 64))
diced <- cbind(diced, magic_by_rank(sliced, 256))

# Usage
best_magic <- find_best_magic_constants(sliced)

ggplot(best_magic,
       aes(x = input_rank,
           y = best_magic)) +
  geom_point()


create_median_dataset <- function(sliced) {
  sliced %>%
    group_by(input_rank) %>%
    summarize(
      median_input = median(input),
      median_error = median(error),
      median_magic = floor(median(magic)),
      .groups = 'drop'
    ) %>%
    arrange(input_rank)
}

# Usage
median_dataset <- create_median_dataset(sliced)

merged_input <- median_dataset %>%
  left_join(best_magic, by = "input_rank")

ggplot(merged_input, aes(x = median_input, y = median_error)) + geom_point()

## from https://stackoverflow.com/a/9568659/1188479
## useful for false categorical coloring
c25 <- c(
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

ggplot(sliced,
       aes(x = input_rank,
           y = magic_rank,
           fill = error_rank)) +
  geom_tile() +
  theme_void() + guides(fill = "none")

ggplot(sliced, aes(x = input_rank,
                   fill = factor(error_rank))) +
  geom_bar(position = "stack") +
  guides(fill = "none") +
  theme_void()



## plot errors against magic constant, coloring for floats
ggplot(data = sliced, aes(x = magic, y = error, color = as.factor(input_rank))) +
  geom_point(shape = ".", alpha = 0.5) +
  scale_color_manual(values = sample(rep(c25, 250))) +
  guides(color = "none")

##brush strokes
ggplot(sliced, aes(x = magic, y = error)) + geom_point(shape= ".") + theme_void() + facet_wrap(~ input_rank)


ggplot(data = sliced, aes(x = magic,
                          y = error,
                          color = cut(input, breaks = 64))) +
  geom_point(shape = ".", alpha = 0.5) + 
  scale_color_manual(values = sample(rep(c25, 250))) +
  guides(color = "none")

# ## facet wrap is unweildy for large numbers of floats
ggplot(sliced,
       aes(x = magic,
           y = error,
           color = factor(error_rank))) +
  geom_point(shape= ".") +
  facet_wrap(~ input_rank) +
  theme_void() +
  guides(color = "none")

## quartile error plots by float sampled

## useful for the quartile plot
easy_blues <- colors()[589:598]

ggplot(aggregate(error ~ input, sliced, range)) +
  geom_line(aes(x = input,
                y = aggregate(error ~ input, sliced, quantile, probs = 0.1)[,2]),
            col = easy_blues[1]) +
  geom_line(aes(x = input,
                y = aggregate(error ~ input, sliced, quantile, probs = 0.2)[,2]),
            col = easy_blues[2]) +
  geom_line(aes(x = input,
                y = aggregate(error ~ input, sliced, quantile, probs = 0.3)[,2]),
            col = easy_blues[3]) +
  geom_line(aes(x = input,
                y = aggregate(error ~ input, sliced, quantile, probs = 0.4)[,2]),
            col = easy_blues[4]) +
  geom_line(aes(x = input,
                y = aggregate(error ~ input, sliced, quantile, probs = 0.5)[,2]),
            col = easy_blues[5]) +
  geom_line(aes(x = input,
                y = aggregate(error ~ input, sliced, quantile, probs = 0.6)[,2]),
            col = easy_blues[6]) +
  geom_line(aes(x = input,
                y = aggregate(error ~ input, sliced, quantile, probs = 0.7)[,2]),
            col = easy_blues[7]) +
  geom_line(aes(x = input,
                y = aggregate(error ~ input, sliced, quantile, probs = 0.8)[,2]),
            col = easy_blues[8]) +
  geom_line(aes(x = input,
                y = aggregate(error ~ input, sliced, quantile, probs = 0.9)[,2]),
            col = easy_blues[9]) +
  ylab("Relative error") + xlab("Input") + 
  labs(title = "Deciles of error for all constants by input float")





error_col <- colorRampPalette(c("dodgerblue2", "red"))(length(unique(sliced$error_rank)))

ggplot(sliced, aes(x = input_rank,
                   y = error,
                   color = factor(error_rank))) +
  geom_col() + guides(color = "none") +
  scale_color_manual(values=setNames(error_col, 1:max(sliced$error_rank)))



length <- 256

df <- data.frame(input_4 = rep(1:4, each = length/4),
                 magic_4 = rep(sample(1:20, 4), each = length/4),
                 input_8 = rep(1:8, each = length/8),
                 magic_8 = rep(sample(1:20, 8), each = length/8))

