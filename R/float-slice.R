sliced <- read.csv("~/Desktop/FISR-historical/data/sliced.csv")
sliced <- sliced[order(sliced$float), ]

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
ggplot(data = sliced, aes(x = magic, y = error, color = as.factor(float))) +
  geom_point(shape = ".", alpha = 0.5) +
  scale_color_manual(values = sample(rep(c25, 25))) +
  guides(color = "none") + xlim(1.575e+09, 1.6105e+09)

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

ggplot(aggregate(error ~ float, sliced, range)) +
  geom_line(aes(x = float,
                y = aggregate(error ~ float, sliced, quantile, probs = 0.1)[,2]),
            col = easy_blues[1]) +
  geom_line(aes(x = float,
                y = aggregate(error ~ float, sliced, quantile, probs = 0.2)[,2]),
            col = easy_blues[2]) +
  geom_line(aes(x = float,
                y = aggregate(error ~ float, sliced, quantile, probs = 0.3)[,2]),
            col = easy_blues[3]) +
  geom_line(aes(x = float,
                y = aggregate(error ~ float, sliced, quantile, probs = 0.4)[,2]),
            col = easy_blues[4]) +
  geom_line(aes(x = float,
                y = aggregate(error ~ float, sliced, quantile, probs = 0.5)[,2]),
            col = easy_blues[5]) +
  geom_line(aes(x = float,
                y = aggregate(error ~ float, sliced, quantile, probs = 0.6)[,2]),
            col = easy_blues[6]) +
  geom_line(aes(x = float,
                y = aggregate(error ~ float, sliced, quantile, probs = 0.7)[,2]),
            col = easy_blues[7]) +
  geom_line(aes(x = float,
                y = aggregate(error ~ float, sliced, quantile, probs = 0.8)[,2]),
            col = easy_blues[8]) +
  geom_line(aes(x = float,
                y = aggregate(error ~ float, sliced, quantile, probs = 0.9)[,2]),
            col = easy_blues[9]) +
  theme(axis.title.y = element_blank())






