# enumerated.R

source("utils.R")
### load data
enumerated <- read.csv("../data/enumerated.csv")

# Set these for equally sized ntile bins
divisible_limit <- nrow(enumerated) - (nrow(enumerated) %% 2048)
# Subset the dataframe to the divisible limit
enumerated <- enumerated[sample(divisible_limit), ]
rm(divisible_limit)



enumerated <- enumerated %>%
  distinct(input, magic, .keep_all = TRUE) %>%
  mutate(error = abs(reference - after_one) / reference ) %>%
  mutate(
    input_rank = ntile(input, 256),
    magic_rank = ntile(magic, 256),
    error_rank = ntile(error, 8)
  ) %>%
  arrange(input)

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
