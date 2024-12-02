library(dplyr)
library(purrr)

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


### load data
enumerated <- read.csv("../data/enumerated.csv")

# Set these for equally sized ntile bins
divisible_limit <- nrow(enumerated) - (nrow(enumerated) %% 2048)
# Subset the dataframe to the divisible limit
enumerated <- enumerated[sample(divisible_limit), ]
rm(divisible_limit)



enumerated <- enumerated %>%
  distinct(input, magic, .keep_all = TRUE) %>%
  arrange(input)


## rank input and magic
## these can make plotting easier. 
## note that these ranks rank DIFFERENT things
## than the similar ones in sliced,
## which records good and bad constants
enumerated$input_rank <- ntile(enumerated$input, 256)
enumerated$magic_rank <- ntile(enumerated$magic, 256)
enumerated$error_rank <- with(enumerated,
                              ntile(abs(initial - reference) / reference, 8))


# Data Preparation
enumerated <- enumerated %>% 
  arrange(input) %>%
  mutate(error = abs(reference - final))


# Main Analysis

results <- enumerated %>%
  create_slices(N = 4, min_input = 0.5, max_input = 2.0) %>%
  group_by(slice) %>%
  nest() %>%
  mutate(
    optimal = map(data, find_optimal_magic),
    magic = map_dbl(optimal, "minimum"),
    max_error = map_dbl(optimal, "objective")
  ) %>%
  select(-data, -optimal)

print(results)




######## Plotting
ggplot(enumerated,
       aes(x = magic,
           y = (initial - reference) / reference )) +
  geom_point(shape = ".") +
  geom_density_2d(linewidth = 1.25, bins = 15) +
  xlab("Magic Constant") + 
  ylab("Relative Error") + 
  labs(title = "Distribution of error across generated constants")

## one possibly takeaway
ggplot(enumerated,
       aes(x = log(input) ,
           y = initial - final,
           color = factor(magic_rank))) +
  geom_point(shape = ".") +
  ylab("Error") +
  labs(title = "Smaller inputs lead to higher overall error, regardless of constant choice") +
  scale_color_discrete(name = "Magic constant\nvalue",
                       breaks = 1:8,
                       labels = 1:8)
