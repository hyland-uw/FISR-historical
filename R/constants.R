constants <- read.csv("~/Desktop/FISR-historical/data/constants.csv")
constants <- constants[order(constants$input), ]
constants <- constants[!duplicated(constants[, "input"]), ]
rownames(constants) <- NULL

constants -> df

# Assuming your data is in a data frame called 'df'
# with columns: input, int_input, system, NR0, int_NR0, magic

# 1. Binning by exponent
df$exponent <- floor(log2(df$input))

# 2. Clustering
library(stats)
k <- 100  # number of clusters, adjust as needed
clusters <- kmeans(cbind(df$int_input, df$magic), centers = k)
df$cluster <- clusters$cluster

# 3. Sliding window analysis
window_size <- 1000
sliding_window <- function(data, window_size) {
  n <- nrow(data)
  result <- numeric(n)
  for (i in 1:(n - window_size + 1)) {
    window <- data$magic[i:(i + window_size - 1)]
    result[i] <- sd(window)
  }
  return(result)
}
df$magic_stability <- sliding_window(df, window_size)

# 4. Error tolerance grouping
error_tolerance <- 1e-6
df$error <- abs(df$NR0 - df$system) / df$system
df$error_group <- cut(df$error, breaks = seq(0, max(df$error), by = error_tolerance))

# Analyze results
library(dplyr)

# Group by exponent and summarize
exponent_summary <- df %>%
  group_by(exponent) %>%
  summarize(
    min_magic = min(magic),
    max_magic = max(magic),
    mean_magic = mean(magic),
    magic_range = max_magic - min_magic
  )

# Find regions with stable magic constants
stable_regions <- df %>%
  arrange(input) %>%
  filter(magic_stability < quantile(magic_stability, 0.1)) %>%
  mutate(region_id = cumsum(c(1, diff(row_number()) > 1)))

# Analyze clusters
cluster_summary <- df %>%
  group_by(cluster) %>%
  summarize(
    min_input = min(input),
    max_input = max(input),
    mean_magic = mean(magic),
    magic_range = max(magic) - min(magic)
  )

# Analyze error groups
error_group_summary <- df %>%
  group_by(error_group) %>%
  summarize(
    min_input = min(input),
    max_input = max(input),
    mean_magic = mean(magic),
    magic_range = max(magic) - min(magic)
  )

# Print summaries
print(exponent_summary)
print(head(stable_regions))
print(head(cluster_summary))
print(head(error_group_summary))