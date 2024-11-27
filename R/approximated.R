approximated <- read.csv("../data/approximated.csv")
approximated$reference <- with(approximated, 1/sqrt(input))

### plot the "big three"
big_three <- c("Blinn", "QuakeIII", "Moroz")

## if we are using scale_color_manual
## we need to set these
custom_labels <- c(
  "Blinn" = "Blinn\n(1997)",
  "QuakeIII" = "Quake III\n(1999)",
  "Moroz" = "Moroz\n(2018)"
)
custom_colors <- c(
  "Blinn" = "blue",
  "QuakeIII" = "green",
  "Moroz" = "red"
)

bt_plot <- ggplot(approximated[approximated[, "method"] %in% big_three,],
       aes(x = input,
           y = (one_iteration - reference) / reference,
           color = method)) +
  geom_line() + 
  ylab("Relative Error") + 
  xlab("Input") +
  labs(color = "Algorithm",
       title = "Performance of three Fast Inverse Square Root Algorithms") +
  scale_color_manual(
    values = custom_colors,
    labels = custom_labels,
    guide = guide_legend(override.aes = list(linewidth = 1.5)),
  ) +
  theme(
    legend.key.size = unit(1.5, 'cm'),    # Increase the size of the color box
    legend.text = element_text(margin = margin(l = 10, unit = "pt"))
  )
print(bt_plot)

## save to plots

ggsave(filename = "../plots/big_three_compared.png", bt_plot)
