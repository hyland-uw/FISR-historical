library(scales)
library(ggplot2)
library(tidyr)
library(dplyr)
library(stringr)

deconstructed <- read.csv("../data/deconstructed.csv")

# Subset the dataframe to the divisible limit
# keeps ntile bins equal size
divisible_limit <- nrow(deconstructed) - (nrow(deconstructed) %% 2048)
deconstructed <- deconstructed[sample(divisible_limit), ]
rm(divisible_limit)

## iterations over 6 have a markedly different structure 
## than 1-6. Why they converge might be different
## dropping these from the plot is a temporary measure
deconstructed <- deconstructed %>%
  filter(iters <= 6) %>%
  mutate(iters = factor(iters, levels = 1:max(iters), labels = 1:max(iters)))

### rank input and magic values for easier binning
deconstructed <- deconstructed %>%
  mutate(
    input_rank = ntile(input, 128),
    magic_rank = ntile(magic, 128),
    frac_rank = ntile(partial_fraction, 128),
    initial_rank = ntile(initial, 128),
    after_rank = ntile(after_one, 128)
  )

deconstructed$iter_rank <- cut(as.numeric(deconstructed$iters), 
                         breaks = c(0, 1, 2, 3, 4, 24, 60, 94),
                         labels = c("1", "2", "3", "4", "5-24", "25-60", "61-94"))
#### wide plot data loading
widened <- read.csv("../data/deconstructed-wide.csv")

# Subset the dataframe to the divisible limit
# keeps ntile bins equal size
divisible_limit <- nrow(widened) - (nrow(widened) %% 2048)
widened <- widened[sample(divisible_limit), ]
rm(divisible_limit)

## We want to keep all the iterations for the wide plot
widened <- widened %>%
  filter(iters <= 94) %>%
  mutate(iters = factor(iters, levels = 1:max(iters), labels = 1:max(iters)))

widened$iter_rank <- cut(as.numeric(widened$iters), 
                         breaks = c(0, 1, 2, 3, 4, 24, 60, 94),
                         labels = c("1", "2", "3", "4", "5-24", "25-60", "61-94"))

mc_annotate <- function(magic_value, label, color, x_start = -0.035, x_end = 0.036, text_size = 8) {
  list(
    annotate("segment", x = x_start, xend = x_end, y = magic_value, yend = magic_value, 
             color = color, linetype = 2, linewidth = 1.5),
    annotate("point", x = x_end, y = magic_value, color = color, size = 3),
    annotate("text", x = x_end + 0.002, y = magic_value, label = label, 
             hjust = -0.05, vjust = 0.5, color = color, size = text_size)
  )
}

## force specific plotting order
create_geom_points <- function(data, iter_range, shape, size, alpha = 1) {
  lapply(iter_range, function(i) {
    geom_point(data = data[data$iters == i, ],
               shape = shape,
               size = size,
               alpha = alpha)
  })
}

## from https://stackoverflow.com/a/23574127/1188479
iter_colors <- colorRampPalette(c("dodgerblue2", "red"))(as.numeric(max(levels(deconstructed$iters))))

iter_rank_hue <- c("lightblue", colorRampPalette(c("white", "orange1", "red"))(7))

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

### plots here

ggplot(deconstructed,
       aes(x = input,
           y = initial - reference,
           color = iters)) +
  create_geom_points(deconstructed, as.numeric(max(levels(deconstructed$iters))):1, 16, 2, 0.95) +
  guides(alpha = "none") +
  scale_color_manual(values=setNames(iter_colors, 1:as.numeric(max(levels(deconstructed$iters))))) +
  labs(color = "Iteration\nCount",
       title = "A poor guess can be low and still converge") +
  ylab("Error before NR Iteration") +
  xlab("Input float")

## good plot to show what ranges are probably optimal for the constant


### clear plot of behavior by constant range
deconstructed %>%
  group_by(iters) %>%
  summarize(min_magic = min(magic),
            max_magic = max(magic)) %>%
  ggplot(aes(x = iters, ymin = min_magic, ymax = max_magic)) +
  scale_y_continuous(labels = function(x) sprintf("0x%X", as.integer(x))) +
  geom_errorbar(width = 0.5) +
  geom_point(aes(y = min_magic), color = "blue") +
  geom_point(aes(y = max_magic), color = "red") +
  labs(x = "Iterations until convergence",
       y = "Integer value",
       title = "Good constants exist only in a narrow range") +
  theme_minimal()

## plot relationship between 0th and 1st iteration
## it's quadratic! 
ggplot(deconstructed,
       aes(x = (initial - reference) / reference,
           y = (after_one - reference) / reference,
           color = iter_rank)) +
  geom_point(shape = 16, size = 0.8, alpha = 0.9) +
  scale_color_manual(values = iter_rank_hue,
                     guide = guide_legend(override.aes = list(size = 1.5))) +
  labs(title = "NR converges quadratically",
       x = "Relative error before Newton-Raphson",
       y = "Relative error after one iteration",
       color = "Iterations\nuntil\neventual\nconvergence") + 
  ylim(-0.75, NA)

## artistic plot of the range of outcomes
ggplot(deconstructed,
       aes(x = magic,
           y = input,
           color = iters)) +
  create_geom_points(deconstructed, 6:1, 16, 6) +
  guides(alpha = "none", color = "none", shape = "none", size = "none") +
  theme_void()

## metroid villain

ggplot(deconstructed,
       aes(x = initial - reference,
           y = after_one,
           color = iters)) +
  geom_point(shape = ".") +
  guides(color = "none") +
  coord_polar(theta = "x") +
  theme_void()


# plot to be subset

subset_plot <- deconstructed %>% 
  filter(iters %in% levels(iters)[1:5]) %>%
  ggplot(aes(x = (initial - reference) / reference, y = magic, color = iters)) +
  geom_point(shape = 16, size = 0.65, alpha = 0.95) +
  labs(color = "Iterations\nto converge",
       title = "Shaded region is 0.024% of the 32 bit integers") +
  guides(colour = "none") + 
  scale_color_manual(values = iter_rank_hue[1:5]) + 
  scale_x_continuous(breaks = c(0), limits = c(-0.25, 0.25)) +
  ylim(1.5935e9, 1601175552) + 
  theme(plot.title = element_text(hjust = 0.45),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title.y = element_blank(),
        axis.title.x = element_blank()) +
  annotate("rect", alpha=0.2, fill="blue",
           xmin=-Inf, xmax=-0.125,
           ## this is 1048576, 1/8192th of the possible search space
           ymin=0x5F300000, ymax=0x5F400000) +
  annotate("rect", alpha=0.2, fill="blue",
           xmin=0.125, xmax=Inf,
           ymin=0x5F300000, ymax=0x5F400000) + 
  geom_hline(yintercept = 0x5F400000,
             color = "blue", alpha = 0.6, lty = 4, linewidth = 0.2) +
  geom_hline(yintercept = 0x5F300000,
             color = "blue", alpha = 0.6, lty = 4, linewidth = 0.2)

### for this plot, y ranges from 1150202431 to 1601995043
widened %>% 
  ggplot(aes(x = (initial - reference) / reference,
             y = magic,
             color = iter_rank)) +
  geom_point(shape = 16,
             size = 0.65,
             alpha = 0.95,
             show.legend = TRUE) +
  xlab("Relative error") + ylab("Restoring constant (in billions)") + 
  labs(color = "Iterations\nto converge",
       title = "Extended to only 10% of the available integer space,\nthe region where the approximation is optimal is invisible.",
       fill = "Range of\noptimal integers") +
  scale_y_continuous(labels = function(x) sprintf("%.1f", x / 1e9),
                     limits = c(1.3e9 - 1, NA)) +
  scale_color_manual(values = iter_rank_hue,
                     na.translate = F,
                     drop = FALSE) +
  guides(colour = guide_legend(override.aes = list(size=5))) +
  annotate("rect", alpha=0.2, fill="blue",
           xmin=-Inf, xmax=-0.1,
           ## this is 1048576, 1/8192th of the possible search space
           ymin=0x5F300000, ymax=0x5F400000) +
  annotate("rect", alpha=0.2, fill="blue",
           xmin=0.1, xmax=Inf,
           ymin=0x5F300000, ymax=0x5F400000) +
  annotate("rect",
           fill = NA, color = "black",
           xmin=-0.5, xmax=0.5,
           ymin=1.325e9, ymax=1.525e9) +
  annotate("segment", x = -0.15, xend = -0.5, y = 1602500000, yend = 1.525e9, 
           linetype = "dashed") +
  annotate("segment", x = 0.15, xend = 0.5, y = 1602500000, yend = 1.525e9, 
           linetype = "dashed") + 
  annotate("rect",color = "black", fill = NA, linetype = "dashed",
           xmin=-0.15, xmax=0.15,
           ymin=1592500000, ymax=1602500000) + 
  annotate("segment", x = 0.15, xend = 0.5, y = 1592500000, yend = 1.325e9, 
           linetype = "dashed") + 
  annotate("segment", x = -0.15, xend = -0.5, y = 1592500000, yend = 1.325e9, 
           linetype = "dashed") + 
  geom_point(aes(fill = "0x5F300000 to\n0x5F400000"), alpha = 0) +
  scale_fill_manual(values = c("0x5F300000 to\n0x5F400000" = "blue"),
                    name = "Optimal\ninteger values") +
  guides(fill = guide_legend(override.aes = list(color = "blue",
                                                 alpha = 0.2,
                                                 size = 5,
                                                 shape = 15))) + 
  annotation_custom(
    grob = ggplotGrob(subset_plot),
    xmin = -0.5, xmax = 0.5,
    ymin = 1.325e9, ymax = 1.525e9
  )
