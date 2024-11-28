approximated <- read.csv("../data/approximated.csv")

## reference is generated here and not in C
approximated$reference <- with(approximated, 1/sqrt(input))

### 95 seems to catch most that will likely never converge
approximated$failure <- FALSE
approximated[approximated[, "iters"] == 95, "failure"] <- TRUE

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

ggplot(approximated[approximated[, "method"] %in% big_three,],
       aes(x = input,
           y = (after_one - reference) / reference,
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
  filter(method %in% c("Naive_1_over_x", "Naive_x", "Blinn")) %>%
  ggplot(aes(x = iters, fill = method)) +
  geom_bar()

approximated %>%
  filter(iters %in% c(0,1,95)) %>%
  ggplot(aes(x = iters, fill = method)) + geom_bar(position = "dodge")


