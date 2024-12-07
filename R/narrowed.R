# narrowed.R

source("utils.R")

narrowed <- read.csv("../data/narrowed.csv")

narrowed <- narrowed %>%
  mutate(iters = factor(iters, levels = 1:max(iters), labels = 1:max(iters)))

narrowed$magic_rank <- ntile(narrowed$magic, 8)
narrowed$input_rank <- ntile(narrowed$input, 10)


# Main plot
# Main plot
narrowed %>% 
  ggplot(aes(x = (initial - reference) / reference, y = magic, color = factor(iters))) +
  geom_point(shape = 16, alpha = 0.95) +
  xlab("Relative Error") + ylab("Magic Constant") + 
  labs(color = "Iterations\nto converge",
       title = "Zooming in on three similar constants") +
  guides(colour = guide_legend(override.aes = list(size=5))) + 
  scale_y_continuous(labels = function(x) sprintf("0x%X", as.integer(x)),
                     limits = c(0x5f37642f - 3200,
                                0x5F376D60)) +
  ### Q3A is close to Lomont's revised so we raise it up
  mc_annotate(0x5f3759df, "0x5f3759df", "blue",
              x_end = 0.04) +
  ### Lomont original
  mc_annotate(0x5f37642f, "0x5f37642f", "red",
              x_end = 0.043) +
  ## Lomont revized
  mc_annotate(0x5f375a86, "0x5f375a86", "orange") +
  ## Moroz
  mc_annotate(0x5F376908, "0x5F376908", "purple") +
  xlim(-0.035, 0.08)

narrowed %>%
  filter(iters %in% levels(iters)[1]) %>%
  ggplot(aes(x = (final - reference) / reference, y = magic)) +
  geom_point(shape = 16, alpha = 0.95, size = 0.6)
