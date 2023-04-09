library(scales)
library(ggplot2)



## Errors which converge, relative to input
## Note especially the patterns among steps which don't converge
ggplot(data = magicplot,
       aes(x = input, y = abs(ref - approx), colour = as.factor(iters))) + 
 geom_point(alpha = 0.3, shape = 20) + 
 guides(color = 'none') + ylim(0, 2)

## See here a graph of only those which no not converge
## Not very edifying as many of the input which don't converge
## are very large
ggplot(data = magicplot[magicplot[,"iters"] > 104, ],
       aes(x = input, y = abs(ref - approx), colour = as.factor(iters))) + 
  geom_point(alpha = 0.7, shape = 20) + guides(color = 'none')

## An artsy look at the same distribution
ggplot(data = magicplot,
       aes(x = iters, y = timeline, colour = as.factor(flipped))) + 
  geom_point(size=0.8) + guides(colour = 'none') + 
  xlim(0,99) + coord_flip() + theme_void()

## Follow paths for given timelines
ggplot(data = magicplot,
       aes(x = steps, y = iters, group = timeline, alpha = abs(ref - approx))) + 
  geom_line() + ylim(0,99) + scale_alpha(range = c(0.02, 0.05)) + 
  guides(alpha = 'none')
## same plot with no alpha and geom_path()
ggplot(data = magicplot,
       aes(x = steps, y = iters, group = timeline)) + 
  geom_path()


# Mutation path testing
ggplot(data = magicplot,
       aes(x = steps, fill = as.factor(flipped))) + 
  geom_bar(position = position_fill(), width = 1, color = "light grey") + 
  guides(fill = "none") + 
  theme_void() + scale_fill_hue(h = c(170, 360))

## Similar plot using iteration count and steps
ggplot(data = magicplot,
       aes(x = steps, fill = as.factor(iters))) + 
  geom_bar(position = position_fill(), width = 1, color = "white") + 
  guides(fill = "none") + theme_void() + xlim(12,31)
## More artistic
ggplot(data = magicplot,
       aes(x = steps, fill = as.factor(iters))) + 
  geom_bar(position = position_fill(), width = 1) + 
  guides(fill = "none") + 
  theme_void()

## More narrow and pretty view of some step regions
ggplot(data = magicplot,
       aes(x = steps, fill = as.factor(iters))) + 
  geom_bar(position = position_fill(), width = 1) + 
  guides(fill = "none") + 
  theme_void() + xlim(23,28)

## Similar view using colors and a white backdrop.
ggplot(data = magicplot,
       aes(x = steps, color = as.factor(iters))) + 
  geom_bar(position = position_fill(), width = 1, fill = "white") + 
  guides(color = "none") + theme_void() + xlim(12,31)

## Count of bit flips by steps
ggplot(data = magicplot,
       aes(x = steps, y = flipped, fill = as.factor(iters)), color = 'white') + 
  geom_col(width = 1, linewidth = 0.5) + 
  guides(fill = "none") + 
  theme_void() + xlim(15, 31)

## plot of bit flips by steps
plot(with(magicplot, table(steps, flipped)))

## Base R plot of range in error by iterations, excluding
## steps which don't converge.
plot(1, type="n", xlab="", ylab="", xlim=c(0, 105), ylim = c(0, 10))
lines(aggregate(abs(ref - approx)/input ~ iters, data = magicplot, min), col = "blue")
lines(aggregate(abs(ref - approx)/input ~ iters, data = magicplot, max), col = "blue")
with(magicplot[magicplot[,"iters"] < 104, ],
     points(x = iters, y = abs(ref - approx)/input,
            pch = 20, alpha = 0.3))






