approximated <- read.csv("../data/approximated.csv")

## reference is generated here and not in C
approximated$reference <- with(approximated, 1/sqrt(input))

## if we are using scale_color_manual
## we need to set these
custom_labels <- c(
  "Blinn" = "Blinn\n(1997)",
  "QuakeIII" = "Quake III\n(1999)",
  "Moroz" = "Moroz\n(2016)",
  "Kahan" = "Kahan\n(1999)"
)
custom_colors <- c(
  "Blinn" = "blue",
  "QuakeIII" = "green",
  "Moroz" = "red",
  "Kahan" = "orange"
)

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
    values = custom_colors,
    labels = custom_labels
  ) +
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

ggplot(approximated[approximated[, "method"] %in% c("QuakeIII", "Moroz"),],
       aes(x = input,
           y = (guess - reference) / reference,
           color = method)) +
  geom_line() + 
  ylab("Relative Error") + 
  xlab("Input") +
  labs(color = "Algorithm",
       title = "Performance of three Fast Inverse Square Root Algorithms") +
  theme(
    legend.key.size = unit(1.5, 'cm'),    # Increase the size of the color box
    legend.text = element_text(margin = margin(l = 10, unit = "pt"))
  )

approximated %>%
  filter(method %in% c("QuakeIII", "Kahan", "Blinn"),
         iters %in% c(1:7)) %>%
  ggplot(aes(x = method, y = iters, fill = failure)) +
  geom_col()

approximated %>%
  filter(iters < 95) %>%
  ggplot(aes(x = iters, fill = method)) + geom_bar(position = "dodge")







