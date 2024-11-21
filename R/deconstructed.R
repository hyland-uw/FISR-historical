library(scales)
## force specific plotting order
create_geom_points <- function(data, iter_range, shape, size, alpha = 1) {
  lapply(iter_range, function(i) {
    geom_point(data = data[data$iters == i, ],
               shape = shape,
               size = size,
               alpha = alpha)
  })
}

deconstructed <- read.csv("../data/deconstructed.csv")

## from https://stackoverflow.com/a/23574127/1188479
iter_colors <- colorRampPalette(c("dodgerblue2", "red"))(length(unique(deconstructed$iters)))
ggplot(deconstructed,
       aes(x = input,
           y = initial - reference,
           color = factor(iters))) +
  create_geom_points(deconstructed, max(deconstructed$iters):1, 16, 2, 0.95) +
  guides(alpha = "none") +
  scale_color_manual(values=setNames(iter_colors, 1:max(deconstructed$iters))) +
  labs(color = "Iteration\nCount",
       title = "A poor guess can be low and still converge") +
  ylab("Error before NR Iteration") +
  xlab("Input float")

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



## artistic plot of the range of outcomes
ggplot(deconstructed,
       aes(x = magic,
           y = input,
           color = factor(iters))) +
  create_geom_points(deconstructed, 8:1, 16, 6) +
  guides(alpha = "none", color = "none", shape = "none", size = "none") +
  theme_void()

## bucketing into different sizes is arty
size_bucket <- round(runif(20, min = 0.05, max = 8), 2)

ggplot(deconstructed,
       aes(x = magic,
           y = log(input),
           color = factor(iters, levels = sort(unique(iters), decreasing = TRUE)),
           size = factor((as.numeric(rownames(deconstructed)) - 1) %% length(size_bucket) + 1))) +
  geom_point(shape = 16, alpha = 0.4) +
  guides(alpha = "none", color = "none", shape = "none", size = "none") +
  scale_size_manual(values = size_bucket) +
  xlim(1.593e+09, max(deconstructed$magic)) +
  theme_void()
