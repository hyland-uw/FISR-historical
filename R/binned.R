library(tidyr)
binned <- read.csv("../data/binned.csv")

binned <- binned %>%
  group_by(N) %>%
  mutate(Slice = row_number())

library(knitr)
kable(binned, format = "simple")


### plots


ggplot(binned, aes(x = (Range_Min + Range_Max) /2 )) +
  geom_step(aes(y = Avg_Relative_Error, color = "Avg Error")) +
  geom_step(aes(y = Max_Relative_Error, color = "Max Error")) +
  facet_wrap(~N, scales = "free_y") +
  scale_color_manual(values = c("Avg Error" = "blue", "Max Error" = "red")) +
  labs(title = "Error Trends Across Input Range",
       x = "Input Value",
       y = "Error",
       color = "Error Type") +
  scale_x_continuous(breaks = seq(0.25, 1, by = 0.25)) +
  theme_minimal()


# First create the horizontal segments dataset as before
segments_h <- binned %>%
  pivot_longer(
    cols = c(Avg_Relative_Error, Max_Relative_Error),
    names_to = "Error_Type",
    values_to = "Error"
  ) %>%
  mutate(Error_Type = factor(Error_Type, 
                             levels = c("Avg_Relative_Error", "Max_Relative_Error"),
                             labels = c("Avg Error", "Max Error")))s

# Plot with corrected color mapping
ggplot() +
  geom_segment(data = segments_h,
               aes(x = Range_Min, xend = Range_Max,
                   y = Error, yend = Error,
                   color = Error_Type),
               linewidth = 1.15) +
  facet_wrap(~N, scales = "free_y") +
  scale_color_manual(values = c("Avg Error" = "blue", "Max Error" = "red")) +
  labs(title = "Error Trends Across Input Range",
       x = "Input Value",
       y = "Error") +
  scale_x_continuous(breaks = seq(0.25, 1, by = 0.25),
                     limits = c(0.25, 1.0)) +
  theme_minimal()



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
         y = "Max Relative Error") +
    theme_minimal()
}


## working single slice visualization
plot_single_n <- function(binned, n_value) {
  # Create horizontal segments dataset
  segments_h <- binned %>%
    filter(N == n_value) %>%
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
    binned %>%
      filter(N == n_value) %>%
      slice(1:(n()-1)) %>%
      transmute(
        x = Range_Max,
        y_start = Avg_Relative_Error,
        y_end = Max_Relative_Error
      ),
    # Segments for the starting ranges
    binned %>%
      filter(N == n_value) %>%
      slice(2:n()) %>%
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
                 color = "black") +
    scale_color_manual(values = c("Avg Error" = "blue", "Max Error" = "red")) +
    labs(title = sprintf("Error Trends for N=%d",
                         n_value),
         x = "Input Value",
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
                     y = y_start, yend = y_end),
                 linetype = "dotted",
                 color = "black") +
    facet_wrap(~N, scales = "free_y") +
    scale_color_manual(values = c("Avg Error" = "blue", "Max Error" = "red")) +
    labs(title = "Error Trends Across Input Range",
         x = "Input Value",
         y = "Error") +
    scale_x_continuous(breaks = seq(0.25, 1, by = 0.25),
                       limits = c(0.25, 1.0)) +
    theme_minimal()
}
