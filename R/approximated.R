approximated <- read.csv("../data/approximated.csv")


### plot the "big three"
big_three <- c("Blinn", "QuakeIII", "Moroz")

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

ggplot(approximated[approximated[, "ISR_function"] %in% big_three,],
       aes(x = input,
           y = (final - reference) / reference,
           color = ISR_function)) +
  geom_line() + 
  ylab("Relative Error") + 
  xlab("Input") +
  labs(color = "Approximation",
       title = "Performance of Three FISR Approximations") +
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
