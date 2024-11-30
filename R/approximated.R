approximated <- read.csv("../data/approximated.csv")
## reference is generated here and not in C
approximated$reference <- with(approximated, 1/sqrt(input))


### Useful to compare Blinn with three tuned algorithms
### The shape of the error function of the other two are different becuase
### the impact of the constant is non-linear
### but the impact of a specifically good guess over Blinn's result is
### limited because of his specific NR parameter choice.
ggplot(approximated,
       aes(x = input,
           y = (after_one - reference) / reference,
           color = method,
           linetype = method)) +
  geom_line(linewidth = 1.25) +
  ylab("Relative Error") +
  xlab("Input") +
  labs(color = "Algorithm", linetype = "Algorithm",
       title = "Performance of four Fast Inverse Square Root algorithms") +
  scale_color_manual(
    values = c(
      "Blinn" = "blue",
      "QuakeIII" = "green",
      "Moroz" = "red",
      "Kahan" = "orange"),
    labels =c(
      "Blinn" = "Blinn\n(1997)",
      "QuakeIII" = "Quake III\n(1999)",
      "Moroz" = "Moroz\n(2016)",
      "Kahan" = "Kahan\n(1999)")) +
  scale_linetype_manual(
    values = c("Blinn" = "dashed", "QuakeIII" = "solid", "Moroz" = "solid", "Kahan" = "solid"),
    labels = custom_labels
  ) +
  guides(color = guide_legend(override.aes = list(linewidth = 1.5))) +
  theme(
    legend.key.size = unit(1.5, 'cm'),
    legend.text = element_text(margin = margin(l = 10, unit = "pt"))
  ) +
  scale_x_continuous(trans = 'log2',
                     breaks = scales::trans_breaks("log2", function(x) 2^x, n = 4),
                     labels = function(x) round(x, 4),
                     limits = c(2^-4, 2^-1))
