enumerated <- read.csv("~/Desktop/FISR-historical/data/enumerated.csv")
enumerated <- enumerated[order(enumerated$input), ]

ggplot(enumerated) +
  geom_point(aes(x = input, y = magic), shape = ".", alpha = 0.8) +
  guides(color = "none") + ylim(1.5985e+09, 1.5965e+09)

