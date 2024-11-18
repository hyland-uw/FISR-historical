enumerated <- read.csv("~/Desktop/FISR-historical/data/enumerated.csv")
enumerated <- enumerated[order(enumerated$input), ]
enumerated <- enumerated[!duplicated(enumerated[, "input"]), ]

ggplot(enumerated) +
  geom_point(aes(x = input, y = magic), shape = ".", alpha = 0.8) +
  guides(color = "none") + ylim(1.5965e+09, 1.5985e+09)


ggplot(enumerated[enumerated[,"input"] > 2e-08, ], aes(x = magic, y = error)) +
  geom_bin2d(bins = 80) + guides(fill = "none")
