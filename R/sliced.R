library(tidyr)
library(dplyr)
library(forcats)

# returns a df with rank_N and best_N columns
find_best_magic_constants <- function(rank, df = sliced, takeN = 4) {

  rank_column <- "location"
  best_column <- "best"

  df %>%
    arrange(df) %>%
    mutate(!!rank_column := ntile(df, rank)) %>%
    group_by(!!sym(rank_column), magic) %>%
    summarize(total_error = sum(error), .groups = 'drop') %>%
    group_by(!!sym(rank_column)) %>%
    ## select the best four and average those
    slice_min(order_by = total_error, n = takeN) %>%
    summarize(!!best_column := floor(mean(magic))) %>%
    arrange(!!sym(rank_column))
}

# returns a df with rank_N and best_N columns
find_avg_magic_constant <- function(rank, df = sliced) {
  rank_column <- "location"
  avg_column <- "average"

  df %>%
    arrange(df) %>%
    mutate(!!rank_column := ntile(input, rank)) %>%
    group_by(!!sym(rank_column)) %>%
    summarize(!!avg_column := mean(magic), .groups = 'drop') %>%
    arrange(!!sym(rank_column))
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

  df %>%
    arrange(input) %>%
    mutate(!!input_column := ntile(input, ranks)) %>%
    left_join(best_magic_df, by = input_column) %>%
    select(!!sym(input_column), !!sym(magic_column))
}


## within an input rank list, what are the difference in the magic constant?
## An input rank N will have N different magic constants, this determines
## the difference of one element and the mean of all
diff_within_rank <- function(df, N, length = 256, measure = "mean") {
  # Convert input to numeric if it's not already
  N <- as.numeric(N)

  # Choose the appropriate function based on the measure argument
  if (measure == "mean") {
    constants_func <- find_avg_magic_constant
    value_col <- "average"
  } else if (measure == "best") {
    constants_func <- find_best_magic_constants
    value_col <- "best"
  } else {
    stop("Invalid measure. Choose 'mean' or 'best'.")
  }

  # Call the appropriate function to get the constants
  constants <- constants_func(N)

  # Calculate overall mean of constants
  overall_mean <- mean(constants[[value_col]])
  total_locations <- nrow(constants)

  # Calculate differences
  diff_outside <- constants[[value_col]] -
    (overall_mean * total_locations - constants[[value_col]]) / (total_locations - 1)

  # Repeat the differences to match the original data length
  output <- rep(diff_outside, each = length / N)

  return(output)
}

## A higher rank will have more magic values
## this subtracts those from lower ranks, showing the
## difference across
diff_across_ranks <- function(N1, N2, length = 256, measure = "mean") {
  # Convert inputs to numeric
  N1 <- as.numeric(N1)
  N2 <- as.numeric(N2)

  # Choose the appropriate function based on the measure argument
  if (measure == "mean") {
    constants_func <- find_avg_magic_constant
    value_col <- "average"
  } else if (measure == "best") {
    constants_func <- find_best_magic_constants
    value_col <- "best"
  } else {
    stop("Invalid measure. Choose 'mean' or 'best'.")
  }

  # Get magic constants for both N1 and N2
  constants_N1 <- constants_func(N1)
  constants_N2 <- constants_func(N2)

  # Ensure the number of rows in constants_N2 matches N2
  if (nrow(constants_N2) != N2) {
    stop("Number of rows in constants_N2 does not match N2")
  }

  # Calculate differences between magic constants
  diff <- constants_N1[[value_col]] - constants_N2[[value_col]]

  # Repeat the differences to match the original data length
  output <- rep(diff, each = length / N2)

  return(output)
}

create_diff_dataframe <- function(diced, measure = "mean") {
  ranks <- c(4, 8, 16, 32, 64, 128, 256)
  output_size <- max(ranks)

  # Calculate within-rank differences
  within_diffs <- lapply(ranks, function(r) {
    diff_within_rank(diced, r, measure = measure)
  })
  names(within_diffs) <- paste0("within_", ranks)

  # Calculate across-rank differences
  across_diffs <- list()
  for (i in 1:(length(ranks)-1)) {
    for (j in (i+1):length(ranks)) {
      col_name <- paste0(ranks[i], "_", ranks[j])
      across_diffs[[col_name]] <- diff_across_ranks(ranks[i], ranks[j], measure = measure)
    }
  }

  # Combine all differences into a single dataframe
  result <- bind_cols(c(within_diffs, across_diffs))

  # Add rank columns
  rank_columns <- lapply(ranks, function(r) {
    rep(1:r, each = output_size/r)
  })
  names(rank_columns) <- paste0("rank_", ranks)

  result <- bind_cols(result, rank_columns)
  result  %>%
    mutate(index = row_number()) %>%
    pivot_longer(
      cols = -c(index, starts_with("rank_")),
      names_to = "comparison",
      values_to = "Difference"
    ) %>%
    mutate(
      Target = case_when(
        str_starts(comparison, "within_") ~ "self",
        TRUE ~ str_extract(comparison, "^\\d+")
      ),
      Pool = as.numeric(str_extract(comparison, "\\d+$")),
      Comparison = if_else(str_starts(comparison, "within_"), "within", "across")
    ) %>%
    select(index, Target, Pool, Comparison, Difference) %>%
    mutate(Type = paste(Target, Pool, sep = "_")) %>%
    select(-Target, -Pool)
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

sliced <- read.csv("../data/sliced.csv") %>%
  # Remove duplicates based on input and magic
  distinct(input, magic, .keep_all = TRUE) %>%
  # Order by input
  arrange(input)

division <- 256
# Set these for equally sized ntile bins
divisible_limit <- nrow(sliced) - (nrow(sliced) %% 2048)
# Subset the dataframe to the divisible limit
sliced <- sliced[1:divisible_limit, ]

## these power some existing plots but will be phased out
sliced$error_rank <- ntile(sliced$error, 4)
sliced$input_rank <- ntile(sliced$input, division)
sliced$magic_rank <- ntile(sliced$magic, division)

diced <- sliced %>%
  mutate(
    !!!magic_by_rank(., 4),
    !!!magic_by_rank(., 8),
    !!!magic_by_rank(., 16),
    !!!magic_by_rank(., 32),
    !!!magic_by_rank(., 64),
    !!!magic_by_rank(., 128),
    !!!magic_by_rank(., 256)
  )


magic_grid <- create_diff_dataframe(diced, measure = "mean")
magic_grid$Type <- factor(magic_grid$Type,
                          ordered = TRUE,
                          levels = unique(magic_grid$Type))

subtrahends <- c("magic_4", "magic_8", "magic_16", "magic_32")

# Prepare the data
diced_long <- diced %>%
  pivot_longer(cols = all_of(subtrahends), names_to = "subtrahend", values_to = "subtrahend_value") %>%
  mutate(
    difference = magic - subtrahend_value,
    # Convert subtrahend to an ordered factor
    subtrahend = factor(subtrahend, levels = subtrahends, ordered = TRUE)
  )


## diced is large and unwieldy for plotting
rm(divisble_limit, division,
   magic_avg_difference, magic_best_difference,
   diced)

######### Plots go here

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

### useful plots of differences in constants by error
error_col <- colorRampPalette(c("dodgerblue2", "red"))(length(unique(diced$error_rank)))
ggplot(diced,
       aes(x = input_rank,
           y = magic - magic_4,
           group = input_8, fill = factor(error_rank))) +
  geom_col(position = "dodge") +
  scale_fill_manual(values=setNames(error_col, 1:max(diced$error_rank)))

### good faceted plot of the differences in magic constants
ggplot(diced_long,
       aes(x = input_rank,
           y = difference,
           group = input_8,
           fill = factor(error_rank))) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = setNames(error_col, 1:max(diced$error_rank))) +
  facet_wrap(~ subtrahend, ncol = 1) +
  labs(title = "Magic Differences Across Ranks",
       x = "Input Rank",
       y = "Difference",
       fill = "Error Rank") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

### fun use of subtrahend
ggplot(diced_long, aes(x = input_rank, y = difference, color = factor(subtrahend))) + geom_point(shape = ".") + guides(color = "none") + theme_void()


custom_labeller <- function(x) {
  sapply(x, function(label) {
    parts <- strsplit(label, "_")[[1]]
    if(length(parts) == 2) {
      paste(parts[2], "from", parts[1])
    } else {
      label  # Return original label if it doesn't match the expected format
    }
  })
}

magic_grid %>%
  filter(Type %in% c("4_8", "4_16", "4_32", "4_64", "4_128", "4_256")) %>%
  ggplot(aes(x = index, y = Difference, color = Type)) +
  geom_line() +
  facet_wrap(~ Type, ncol = 1,
             labeller = labeller(Type = custom_labeller)) +
  theme_minimal() +
  labs(x = "Float Range",
       y = "Diff",
       title = "Smaller Grid Sizes Approximate More Closely") +
  scale_x_continuous(breaks = c(1, 64, 128, 192, 256)) +
  theme(legend.position = "none") + scale_y_continuous(labels = NULL)


magic_grid %>%
  filter(Comparison == "within") %>%
  ggplot(aes(x = index,
             y = Difference,
             color = Type,
             linewidth = unclass(fct_rev(Type)))) +
  geom_step() +
  scale_linewidth(transform = "exp", breaks = 28:22, name = "Bins", labels = c("4", "8", "16", "32", "64", "128", "256") ) +
  scale_y_continuous(labels = NULL) + scale_x_continuous(labels = NULL) +
  labs(title = "Smaller grid sizes mean larger absolute differences") +
  ylab(NULL) + xlab(NULL) + scale_color_discrete(breaks = 22:28)

magic_grid %>%
  filter(str_detect(Type, "^4_")) %>%
  ggplot(aes(x = index, y = Difference, color = Type)) +
  geom_line(aes(linewidth = unclass(fct_rev(Type)))) +
  scale_linewidth(transform = "exp",
                  breaks = 21:16,
                  name = "Bins",
                  labels = c("8", "16", "32", "64", "128", "256")) +
  guides(color = "none") +
  scale_y_continuous(labels = NULL, name = "") +
  scale_x_continuous(labels = NULL, name = "")
