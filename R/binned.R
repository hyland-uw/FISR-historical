source("utils.R")

# Function to create logarithmically spaced bins
create_log_bins <- function(start = 0.25, end = 1.0, n_bins) {
  bins <- 2^(seq(log2(start), log2(end), length.out = n_bins + 1))
  tibble(
    bin_num = 1:n_bins,
    min = bins[-length(bins)],
    max = bins[-1]
  )
}

# Function to sample floating-point values within a bin
sample_floats <- function(min_val, max_val, n_samples) {
  sampled_data <- frsr_sample(
    n = n_samples,
    x_min = min_val,
    x_max = max_val,
    keep_params = TRUE
  )
  sampled_data$input # Extract the sampled floating-point values
}

# Function to optimize magic constants for a given float
optimize_magic_for_float <- function(float_value, magic_min, magic_max, n_samples) {
  # Sample results for a single float value across multiple magic constants
  results <- frsr_sample(
    n = n_samples,
    x_min = float_value,
    x_max = NULL,
    magic_min = magic_min,
    magic_max = magic_max,
    keep_params = TRUE
  )
  
  # Summarize errors for the given float value
  tibble(
    magic = unique(results$magic),
    avg_error = mean(results$error),
    max_error = max(results$error)
  )
}

# Function to optimize magic constants for all floats in a bin
optimize_magic_for_bin <- function(floats, magic_min, magic_max, n_samples_per_magic) {
  # Optimize for each float and combine results
  map_dfr(floats, ~optimize_magic_for_float(.x, magic_min, magic_max, n_samples_per_magic)) %>%
    group_by(magic) %>%
    summarize(
      avg_error = mean(avg_error),
      max_error = max(max_error),
      .groups = 'drop'
    ) %>%
    slice_min(max_error, n = 1) # Select the magic constant with minimum max_error
}

# Function to process a single bin
process_bin <- function(min_val, max_val, n_floats, n_samples_per_magic, magic_min, magic_max) {
  # Sample floating-point values within the bin
  floats <- sample_floats(min_val, max_val, n_floats)
  
  # Optimize magic constants for sampled floats
  optimal_magic <- optimize_magic_for_bin(floats, magic_min, magic_max, n_samples_per_magic)
  
  tibble(
    Range_Min = min_val,
    Range_Max = max_val,
    Magic = sprintf("0x%08X", optimal_magic$magic),
    Avg_Relative_Error = optimal_magic$avg_error,
    Max_Relative_Error = optimal_magic$max_error
  )
}

# Main function to generate the binned dataset
generate_binned <- function(n_values, n_floats_per_bin = 10000, n_samples_per_magic = 2048,
                            magic_min = 1596980000L, magic_max = 1598050000L) {
  
  map_dfr(n_values, function(n_bins) {
    bins <- create_log_bins(0.25, 1.0, n_bins)
    
    map2_dfr(bins$min, bins$max,
             ~process_bin(.x, .y, n_floats_per_bin, n_samples_per_magic,
                          magic_min, magic_max)) %>%
      mutate(N = n_bins)
  }) %>%
    select(N, Range_Min, Range_Max, Magic, Avg_Relative_Error, Max_Relative_Error)
}

# Generate the binned dataset with hierarchical sampling
binned <- generate_binned(n_values = c(4, 8, 16), 
                          n_floats_per_bin = 10000,
                          n_samples_per_magic = 2048)

## useful for when we mix and match to optimize
binned <- binned %>%
  group_by(N) %>%
  mutate(Slice = row_number())

## helper function for linear programming
find_optimal_buckets <- function(binned, M) {
  # Create objective vector (minimize total max error)
  obj <- binned$Max_Relative_Error
  
  # Create constraint matrix
  n_slices <- nrow(binned)
  
  # Constraint 1: Each input value must be covered exactly once
  input_points <- sort(unique(c(binned$Range_Min, binned$Range_Max)))
  coverage_matrix <- matrix(0, nrow = length(input_points) - 1, ncol = n_slices)
  
  for(i in 1:(length(input_points) - 1)) {
    mid_point <- (input_points[i] + input_points[i + 1]) / 2
    coverage_matrix[i,] <- as.numeric(
      binned$Range_Min <= mid_point & binned$Range_Max >= mid_point
    )
  }
  
  # Constraint 2: Use exactly M slices
  slice_constraint <- matrix(1, nrow = 1, ncol = n_slices)
  
  # Combine constraints
  const.mat <- rbind(coverage_matrix, slice_constraint)
  const.dir <- c(rep("==", nrow(coverage_matrix)), "==")
  const.rhs <- c(rep(1, nrow(coverage_matrix)), M)
  
  # Solve using lpSolve
  result <- lp("min", obj, const.mat, const.dir, const.rhs, all.bin = TRUE)
  
  # Extract selected slices
  selected <- binned[result$solution == 1, ]
  
  return(selected %>% arrange(Range_Min))
}


### plots

## pseudo-waterfall

compare_n_values <- function(binned, n_small, n_large) {
  # Create a combined dataset with error values from both N
  combined_data <- binned %>%
    filter(N %in% c(n_small, n_large)) %>%
    mutate(N_type = if_else(N == n_small, "small", "large")) %>%
    pivot_wider(
      names_from = N_type,
      values_from = c(Range_Min, Range_Max, Max_Relative_Error),
      id_cols = c(Magic)
    ) %>%
    # Add reference values by matching ranges
    filter(!is.na(Range_Min_small) & !is.na(Range_Min_large))
  
  ggplot() +
    # Horizontal segments for smaller N
    geom_segment(data = filter(binned, N == n_small),
                 aes(x = Range_Min, xend = Range_Max,
                     y = Max_Relative_Error, yend = Max_Relative_Error),
                 color = "red", linewidth = 0.5) +
    # Horizontal segments for larger N
    geom_segment(data = filter(binned, N == n_large),
                 aes(x = Range_Min, xend = Range_Max,
                     y = Max_Relative_Error, yend = Max_Relative_Error),
                 color = "blue", linewidth = 0.5) +
    # Rectangles showing difference
    geom_rect(data = filter(binned, N == n_large),
              aes(xmin = Range_Min, xmax = Range_Max,
                  ymin = Max_Relative_Error, 
                  ymax = filter(binned, N == n_small)$Max_Relative_Error[
                    findInterval(Range_Min, 
                                 filter(binned, N == n_small)$Range_Min)]),
              fill = "blue", alpha = 0.3) +
    scale_x_continuous(breaks = seq(0.25, 1, by = 0.25),
                       limits = c(0.25, 1.0)) +
    labs(title = sprintf("Comparison of Max Relative Error N=%d vs N=%d",
                         n_small, n_large),
         x = "Input Value",
         y = "Max Relative Error")
}

compare_buckets <- function(bucket1, bucket2, error = "max") {
  error_col <- if(error == "max") "Max_Relative_Error" else "Avg_Relative_Error"
  
  # Get all unique x-points where rectangles should start or end
  x_points <- sort(unique(c(
    bucket1$Range_Min, bucket1$Range_Max,
    bucket2$Range_Min, bucket2$Range_Max
  )))
  
  # Create rectangles for each adjacent pair of x-points
  rectangles <- tibble(
    xmin = x_points[-length(x_points)],
    xmax = x_points[-1]
  ) %>%
    mutate(
      # Find error values for each range
      error1 = sapply(xmin, function(x) {
        bucket1[[error_col]][x >= bucket1$Range_Min & x < bucket1$Range_Max][1]
      }),
      error2 = sapply(xmin, function(x) {
        bucket2[[error_col]][x >= bucket2$Range_Min & x < bucket2$Range_Max][1]
      }),
      # Determine rectangle properties
      ymin = pmin(error1, error2),
      ymax = pmax(error1, error2),
      fill_color = if_else(error2 < error1, "blue", "red")
    )
  
  # Create horizontal segments for both buckets
  segments_h1 <- bucket1 %>%
    select(Range_Min, Range_Max, Error = !!sym(error_col))
  
  segments_h2 <- bucket2 %>%
    select(Range_Min, Range_Max, Error = !!sym(error_col))
  
  ggplot() +
    # Horizontal segments for both buckets
    geom_segment(data = segments_h1,
                 aes(x = Range_Min, xend = Range_Max,
                     y = Error, yend = Error),
                 color = "black", linewidth = 0.5) +
    geom_segment(data = segments_h2,
                 aes(x = Range_Min, xend = Range_Max,
                     y = Error, yend = Error),
                 color = "black", linewidth = 0.5) +
    # Rectangles
    geom_rect(data = rectangles,
              aes(xmin = xmin, xmax = xmax,
                  ymin = ymin, ymax = ymax,
                  fill = fill_color),
              alpha = 0.3) +
    scale_fill_identity() +
    scale_x_continuous(breaks = seq(0.25, 1, by = 0.25),
                       limits = c(0.25, 1.0)) +
    labs(title = "Comparison of Error Values Between Base and Extension",
         x = "Input Value",
         y = paste(error, "Relative Error")) +
    theme_minimal()
}


## working single slice visualization
plot_bucket <- function(df) {
  # Create horizontal segments dataset
  segments_h <- df %>%
    pivot_longer(
      cols = c(Avg_Relative_Error, Max_Relative_Error),
      names_to = "Error_Type",
      values_to = "Error"
    ) %>%
    mutate(Error_Type = factor(Error_Type, 
                               levels = c("Avg_Relative_Error", "Max_Relative_Error"),
                               labels = c("Avg Error", "Max Error")))
  
  # Create vertical segments dataset - now including both ends of each range
  segments_v <- bind_rows(
    # Segments for the ending ranges
    df %>%
      transmute(
        x = Range_Max,
        y_start = Avg_Relative_Error,
        y_end = Max_Relative_Error
      ),
    # Segments for the starting ranges
    df %>%
      transmute(
        x = Range_Min,
        y_start = Avg_Relative_Error,
        y_end = Max_Relative_Error
      )
  )
  ggplot() +
    # Horizontal segments
    geom_segment(data = segments_h,
                 aes(x = Range_Min, xend = Range_Max,
                     y = Error, yend = Error,
                     color = Error_Type),
                 linewidth = 0.5) +
    # Vertical segments at range breaks
    geom_segment(data = segments_v,
                 aes(x = x, xend = x,
                     y = y_start, yend = y_end),
                 linetype = "dotted",
                 color = "black",
                 linewidth = 0.25,
                 alpha = 0.75) +
    scale_color_manual(values = c("Avg Error" = "blue", "Max Error" = "red")) +
    labs(x = "Input Value",
         y = "Error") +
    scale_x_continuous(breaks = seq(0.25, 1, by = 0.25),
                       limits = c(0.25, 1.0)) +
    theme_minimal()
}

## working multiple via facet_wrap
plot_multiple_n <- function(binned, n_values = unique(binned$N)) {
  # Create horizontal segments dataset
  segments_h <- binned %>%
    filter(N %in% n_values) %>%
    pivot_longer(
      cols = c(Avg_Relative_Error, Max_Relative_Error),
      names_to = "Error_Type",
      values_to = "Error"
    ) %>%
    mutate(Error_Type = factor(Error_Type, 
                               levels = c("Avg_Relative_Error", "Max_Relative_Error"),
                               labels = c("Avg Error", "Max Error")))
  
  # Create vertical segments dataset
  segments_v <- bind_rows(
    # Segments for the ending ranges
    binned %>%
      filter(N %in% n_values) %>%
      group_by(N) %>%
      slice(1:(n()-1)) %>%
      transmute(
        N = N,
        x = Range_Max,
        y_start = Avg_Relative_Error,
        y_end = Max_Relative_Error
      ),
    # Segments for the starting ranges
    binned %>%
      filter(N %in% n_values) %>%
      group_by(N) %>%
      slice(2:n()) %>%
      transmute(
        N = N,
        x = Range_Min,
        y_start = Avg_Relative_Error,
        y_end = Max_Relative_Error
      )
  )
  
  ggplot() +
    # Horizontal segments
    geom_segment(data = segments_h,
                 aes(x = Range_Min, xend = Range_Max,
                     y = Error, yend = Error,
                     color = Error_Type),
                 linewidth = 0.5) +
    # Vertical segments at range breaks
    geom_segment(data = segments_v,
                 aes(x = x, xend = x,
                     y = y_start, y_end = y_end),
                 linetype = "dotted",
                 color = "black",
                 linewidth = 0.25,
                 alpha= 0.75) +
    facet_grid(cols = vars(N)) +
    scale_color_manual(values = c("Avg Error" = "blue", "Max Error" = "red")) +
    labs(title = "Error Trends Across Input Range",
         x = "Input Value",
         y = "Error") +
    scale_x_continuous(breaks = seq(0.25, 1, by = 0.25),
                       limits = c(0.25, 1.0)) +
    theme_minimal()
}


## "weight" error by the fraction of the domain
## it covers. 
norm_errorN <- function(df, bins) {
  bucket <- find_optimal_buckets(df, bins)
  ## the things we do to leave tibbles
  bucket$Width <- ((bucket[, "Range_Max"] - bucket[, "Range_Min"]) /0.75)[,1]
  bucket <- bucket %>%
    # if you don't pick N, dplyr complains and does it anyway
    select(N, Max_Relative_Error, Width) %>%
    rename(Error = Max_Relative_Error)
  ## avoids privileging small bucket sizes
  sum_err <- with(bucket, sum(Error*Width))
  return(sum_err)
}

# Use purrr::map_dfr to apply the function to each bin value
# why this is better than a for loop is unclear
map_dfr(4:36, ~tibble(bins = .x, error = norm_errorN(binned, .x))) %>%
ggplot(aes(x = bins, y = error)) +
  geom_line() +
  geom_point() +
  labs(x = "Bins",
       y = "Normalized Error",
       title = "Optimal bucket selection error reduction slows after 24 bins") +
  scale_x_continuous(breaks = seq(4, 36, by = 4))

