library(tidyr)
library(dplyr)

### functions at the top

# returns a df with rank_N and best_N columns
find_best_magic_constants <- function(df, ranks) {
  
  rank_column <- "location"
  best_column <- "best"
  
  df %>%
    arrange(df) %>%
    mutate(!!rank_column := ntile(df, ranks)) %>%
    group_by(!!sym(rank_column), magic) %>%
    summarize(total_error = sum(error), .groups = 'drop') %>%
    group_by(!!sym(rank_column)) %>%
    slice_min(order_by = total_error, n = 4) %>%
    summarize(!!best_column := floor(mean(magic))) %>%
    arrange(!!sym(rank_column))
}

create_median_dataset <- function(df) {
  df %>%
    group_by(input_rank) %>%
    summarize(
      median_input = median(input),
      median_error = median(error),
      median_magic = floor(median(magic)),
      .groups = 'drop'
    ) %>%
    arrange(input_rank)
}

magic_by_rank <- function(df, ranks) {
  input_column <- paste0("input_", ranks)
  magic_column <- paste0("magic_", ranks)
  
  best_magic_df <- df %>%
    arrange(df) %>%
    mutate(!!input_column := ntile(df, ranks)) %>%
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
  # Convert input to numeric if it's not already
  N <- as.numeric(N)
  # Call find_best_magic_constants() to get the best constants
  ### for now this calls a dataframe which is not passed in as
  ### an argument...
  best_constants <- find_best_magic_constants(sliced, N)
  # Calculate overall mean of best magic constants
  overall_mean <- mean(best_constants$best)
  total_locations <- nrow(best_constants)
  
  # Calculate differences
  diff_outside <- best_constants$best - 
    (overall_mean * total_locations - best_constants$best) / (total_locations - 1)
  
  # Repeat the differences to match the original data length
  output <- rep(diff_outside, each = length / N)
  
  return(output)
}

## A higher rank will have more magic values
## this subtracts those from lower ranks, showing the
## difference across
diff_across_ranks <- function(N1, N2, length = 256) {
  # Convert inputs to numeric
  N1 <- as.numeric(N1)
  N2 <- as.numeric(N2)
  
  # Get best magic constants for both N1 and N2
  best_constants_N1 <- find_best_magic_constants(sliced, N1)
  best_constants_N2 <- find_best_magic_constants(sliced, N2)
  
  # Ensure the number of rows in best_constants_N2 matches N2
  if (nrow(best_constants_N2) != N2) {
    stop("Number of rows in best_constants_N2 does not match N2")
  }
  
  # Calculate differences between best magic constants
  diff <- best_constants_N1$best - best_constants_N2$best
  
  # Repeat the differences to match the original data length
  output <- rep(diff, each = length / N2)
  
  return(output)
}


create_diff_dataframe <- function(diced) {
  ranks <- c(4, 8, 32, 64, 256)
  
  # Calculate within-rank differences
  within_diffs <- lapply(ranks, function(r) {
    diff_within_rank(diced, r)
  })
  names(within_diffs) <- paste0("within_", ranks)
  
  # Calculate across-rank differences
  across_diffs <- list()
  for (i in 1:(length(ranks)-1)) {
    for (j in (i+1):length(ranks)) {
      col_name <- paste0(ranks[i], "_", ranks[j])
      across_diffs[[col_name]] <- diff_across_ranks(ranks[i], ranks[j])
    }
  }
  
  # Combine all differences into a single dataframe
  result <- bind_cols(c(within_diffs, across_diffs))
  
  return(result)
}

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

diced <- magic_by_rank(sliced, 4)
diced <- cbind(diced, magic_by_rank(sliced, 8))
diced <- cbind(diced, magic_by_rank(sliced, 32))
diced <- cbind(diced, magic_by_rank(sliced, 64))
diced <- cbind(diced, magic_by_rank(sliced, 256))


## retain some older methods to search for good constants
best_magic <- find_best_magic_constants(sliced)
best_magic <- create_median_dataset(sliced) %>%
  left_join(best_magic, by = "input_rank")

magic_difference <- create_diff_dataframe(diced)


## diced is large and unwieldy for plotting
rm(diced, divisble_limit, division)

######### Plots go here

ggplot(best_magic,
       aes(x = input_rank,
           y = best_magic)) +
  geom_point()


ggplot(merged_input, aes(x = median_input, y = median_error)) + geom_point()

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

