approximated <- read.csv("../data/approximated.csv")

ggplot(approximated,
       aes(x = input,
           y = NR_0 - reference,
           color = ISR_function)) +
  geom_point(shape = ".")