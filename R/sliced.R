## these will have duplicate floats by design
library(dplyr)
library(dplyr)

sliced <- read.csv("../data/sliced.csv")
sliced <- sliced[!duplicated(sliced[,c("input", "magic")]), ]
divisble_limit <- nrow(sliced) - (nrow(sliced) %% 2048)
sliced <- sliced[1:divisble_limit, ]

sliced$error_rank <- ntile(sliced$error, 4)

sliced$input_rank <- ntile(sliced$input, 128)
sliced$magic_rank <- ntile(sliced$magic, 128)


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


## plot errors against magic constant, coloring for floats
ggplot(data = sliced, aes(x = magic, y = error, color = as.factor(input))) +
  geom_point(shape = ".", alpha = 0.5) +
  scale_color_manual(values = sample(rep(c25, 250))) +
  guides(color = "none")


ggplot(data = sliced, aes(x = magic,
                          y = error,
                          color = cut(input, breaks = 64))) +
  geom_point(shape = ".", alpha = 0.5) + 
  scale_color_manual(values = sample(rep(c25, 250))) +
  guides(color = "none")

# ## facet wrap is unweildy for large numbers of floats
# ggplot(data = sliced, aes(x = magic, y = error)) +
#   geom_point(shape = ".", alpha = 0.7) +
#   facet_wrap(~ float) +
#   theme(axis.text.x=element_blank(),
#         axis.text.y=element_blank(),
#         axis.ticks=element_blank(),
#         axis.title.x=element_blank(),
#         axis.title.y=element_blank())

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



