
enumerated <- read.csv("../data/enumerated.csv")
enumerated <- enumerated[!duplicated(enumerated[,c("input", "magic")]), ]


ggplot(enumerated,
       aes(x = magic, y = (initial - reference) / reference )) +
  geom_point(shape = ".")

ggplot(enumerated,
       aes(x = magic,
           y = (initial - reference) / reference )) +
  geom_point(shape = ".") +
  geom_density_2d(linewidth = 1.25, bins = 15) +
  xlab("Magic Constant") + 
  ylab("Relative Error") + 
  labs(title = "Distribution of error across generated constants")
ggsave("../plots/enumerated_error.png")
