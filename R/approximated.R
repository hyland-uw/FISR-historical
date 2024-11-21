approximated <- read.csv("../data/approximated.csv")





x_intercepts <- c(2^seq(-6, 1, by = 0.5))
x_intercepts <- x_intercepts[x_intercepts <= 1 & x_intercepts >= 0.03125]
ggplot(approximated, aes(x = input,
                         y = (final - reference) / reference,
                         color = ISR_function)) +
  geom_line() + 
  geom_vline(xintercept = x_intercepts,
             color = "gray",
             linetype = "dashed") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  xlim(c(0.25, 1))


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

bt_plot <- ggplot(approximated[approximated[, "ISR_function"] %in% big_three,],
       aes(x = input,
           y = (final - reference) / reference,
           color = ISR_function)) +
  geom_line() + 
  ylab("Relative Error") + 
  xlab("Input") +
  labs(color = "Algorithm",
       title = "Performance of three Fast Inverse Square Root Algorithms") +
  xlim(0.2, 1.25) +
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
