size_bucket <- round(runif(20, min = 0.1, max = 10), 2)

ggplot(deconstructed,
       aes(x = magic,
           y = input,
           color = factor(iters, levels = sort(unique(iters), decreasing = TRUE)),
           size = factor((as.numeric(rownames(deconstructed)) - 1) %% length(size_bucket) + 1))) +
  geom_point(shape = 15, alpha = 0.4) +
  guides(alpha = "none", color = "none", shape = "none", size = "none") +
  scale_size_manual(values = size_bucket) + theme_void()



## force specific plotting order
create_geom_points <- function(data, iter_range, shape, size, alpha = 1) {
  lapply(iter_range, function(i) {
    geom_point(data = data[data$iters == i, ],
               shape = shape,
               size = size,
               alpha = alpha)
  })
}

## artistic plot of the range of outcomes
ggplot(deconstructed,
       aes(x = magic,
           y = input,
           color = factor(iters))) +
  create_geom_points(deconstructed, 8:1, 16, 6) +
  guides(alpha = "none", color = "none", shape = "none", size = "none") +
  theme_void()
