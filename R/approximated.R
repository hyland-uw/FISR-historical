library(tidyr)

approximated <- read.csv("../data/approximated.csv")
## reference is generated here and not in C
approximated$reference <- with(approximated, 1/sqrt(input))


### Useful to compare Blinn with three tuned algorithms
### The shape of the error function of the other two are different becuase
### the impact of the constant is non-linear
### but the impact of a specifically good guess over Blinn's result is
### limited because of his specific NR parameter choice.
blinncomp_labels <- c(
  "Blinn" = "Blinn\n(1997)",
  "QuakeIII" = "Quake III\n(1999)",
  "Moroz" = "Moroz\n(2016)",
  "Kahan" = "Kahan\n(1999)")

approximated %>%
  filter(method %in% c("Blinn", "QuakeIII", "Kahan", "Moroz")) %>%
  ggplot(aes(x = input,
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
      labels = blinncomp_labels) +
    scale_linetype_manual(
      values = c("Blinn" = "dashed", "QuakeIII" = "solid", "Moroz" = "solid", "Kahan" = "solid"),
      labels = blinncomp_labels
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


### Good plot showing NR and naive choices
### this is a rather fragile plot, with (relative to others in this repo)
### not much DRYing out
approximated %>%
  filter(method %in% c("Naive_1_over_x", "Naive_x")) %>%
  ggplot() + 
  geom_ribbon(aes(x = input,
                  ymin = pmin((guess - reference) / reference, (after_one - reference) / reference),
                  ymax = pmax((guess - reference) / reference, (after_one - reference) / reference),
                  fill = method),
              alpha = 0.3) +
  geom_line(aes(x = input,
                y = (guess - reference) / reference,
                color = method,
                linetype = "Initial guess"),
            linewidth = 1.4) +
  geom_line(aes(x = input,
                y = (after_one - reference) / reference,
                color = method,
                linetype = "After one iteration"),
            linewidth = 1.2) +
  scale_color_discrete(labels = c("1 / x", "x"), name = "Method for\nfirst guess") +
  scale_linetype_manual(name = "Newton-Raphson",
                        values = c("Initial guess" = "solid", 
                                   "After one iteration" = "dotted")) +
  guides(color = guide_legend(override.aes = list(linewidth = 1.5)),
         fill = "none") +
  geom_segment(data = . %>% 
                 filter(case_when(
                   method == "Naive_1_over_x" ~ round(input - 0.125, 3) %% 0.125 == 0,
                   method == "Naive_x" ~ round(input - 0.0625, 3) %% 0.125 == 0
                 ),
                 round(input, 3) != 1,
                 round(input, 3) != 0.25),
               aes(x = input, 
                   xend = input,
                   y = (guess - reference) / reference, 
                   yend = (after_one - reference) / reference,
                   color = method),
               linewidth = 0.5,
               arrow = arrow(length = unit(0.2, "cm"), type = "closed"),
               show.legend = FALSE) +
  geom_vline(xintercept = 1, color = "black") + 
  annotate("text", 
           x = 1.05, 
           y = -1, 
           hjust = 0,
           label = "At x = 1:\n1/x = x = 1/√x",
           size = 6) +
  ylim(-2, 1) + 
  scale_x_continuous(limits = c(0.25, 1.5), breaks = c(0.5, 1, 1.5)) + 
  labs(y = "Relative error",
       title = "Poor guesses and the result of one Newton-Raphson step")

## simple bar plot of iterations
approximated %>%
  filter(method %in% c("Blinn", "QuakeIII", "Kahan", "Moroz")) %>%
  ggplot() + geom_bar(aes(x = iterations, fill = method), position = "dodge") +
  labs(title = "All four approximations converge to a tight tolerance in two iterations",
       y = "Count of samples",
       x = "Iterations",
       fill = "Approximation\nmethod")


approximated %>%
  filter(method %in% c("QuakeIII")) %>%
  mutate(relErrGuess = (guess - reference) / reference,
         relErrNR = (after_one - reference) / reference) %>% 
  ggplot(aes(x = input)) + 
  geom_ribbon(aes(ymin = pmin(relErrGuess, relErrNR),
                  ymax = pmax(relErrGuess, relErrNR),
                  fill = method),
              alpha = 0.3) +
  geom_line(aes(y = relErrGuess,
                linetype = "Initial guess"),
            linewidth = 1.1) +
  geom_line(aes(y = relErrNR,
                linetype = "After one iteration")) +
  scale_linetype_manual(name = "Newton-Raphson",
                        values = c("Initial guess" = "solid", 
                                   "After one iteration" = "dotted")) +
  guides(fill = "none") +
  xlim(0.25, 2) + 
  labs(y = "Relative error") + 
  facet_wrap(~ method)




nrplot <- function(df = approximated, approx = "QuakeIII") {
  # First create the desired regularly spaced x values
  target_xs <- seq(0.25, 2, by = 0.125)
  temp <- df %>%
    filter(method == approx)
  # Then find the closest actual input values in the dataset
  segment_data <- temp %>%
    mutate(closest_target = target_xs[sapply(input, function(x) 
      which.min(abs(target_xs - x)))]) %>%
    group_by(closest_target) %>%
    slice_min(abs(input - closest_target), n = 1) %>%
    ungroup()
  temp %>%
    mutate(relErrGuess = (guess - reference) / reference,
           relErrNR = (after_one - reference) / reference) %>% 
    ggplot(aes(x = input)) + 
    geom_ribbon(aes(ymin = pmin(relErrGuess, relErrNR),
                    ymax = pmax(relErrGuess, relErrNR),
                    fill = method),
                alpha = 0.3) +
    geom_line(aes(y = relErrGuess,
                  linetype = "Initial guess"),
              linewidth = 1.1) +
    geom_line(aes(y = relErrNR,
                  linetype = "After one iteration")) +
    scale_linetype_manual(name = "Newton-Raphson",
                          values = c("Initial guess" = "solid", 
                                     "After one iteration" = "dotted")) +
    guides(fill = "none") +
    geom_segment(data = segment_data,
                 aes(x = input, 
                     xend = input,
                     y = (guess - reference) / reference, 
                     yend = (after_one - reference) / reference),
                 linewidth = 0.5,
                 arrow = arrow(length = unit(0.2, "cm"), type = "closed"),
                 show.legend = FALSE) +
    xlim(0.25, 2) + 
    labs(y = "Relative error") -> output
  return(output)
}
nrplot()
