library(dplyr)

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
enumerated$error_rank <- with(enumerated, ntile(initial - final, 8))


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
