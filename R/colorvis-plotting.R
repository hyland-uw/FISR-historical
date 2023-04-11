library(scales)
library(ggplot2)

## assumes that we have:
## magicplot and itercount

## Errors which converge, relative to input
## Note especially the patterns among steps which don't converge
ggplot(data = magicplot,
       aes(x = input, y = error, colour = as.factor(iters))) + 
 geom_point(alpha = 0.3, shape = 20) + 
 guides(color = 'none') + ylim(0, 2)

## See here a graph of only those which no not converge
## Not very edifying as many of the input which don't converge
## are very large
ggplot(data = magicplot[magicplot[,"iters"] > 104, ],
       aes(x = input, y = error, colour = as.factor(iters))) + 
  geom_point(alpha = 0.7, shape = 20) + guides(color = 'none')

## An artsy look at the same distribution
ggplot(data = magicplot,
       aes(x = iters, y = timeline, colour = as.factor(flipped))) + 
  geom_point(size=0.8) + guides(colour = 'none') + 
  xlim(0,99) + coord_flip() + theme_void()

## Follow paths for given timelines
ggplot(data = magicplot,
       aes(x = steps, y = iters, group = timeline, alpha =error)) + 
  geom_line() + ylim(0,99) + scale_alpha(range = c(0.02, 0.05)) + 
  guides(alpha = 'none')
## same plot with no alpha and geom_path()
ggplot(data = magicplot,
       aes(x = steps, y = iters, group = timeline)) + 
  geom_path()
## Same plot but placed on a polar coordinate system for fun
ggplot(data = magicplot, aes(x = steps, y = iters, group = timeline)) + 
  geom_path(alpha = 0.25) + 
  theme_void() +
  coord_polar()

# Mutation path testing
ggplot(data = magicplot,
       aes(x = steps, fill = as.factor(flipped))) + 
  geom_bar(position = position_fill(), width = 1, color = "light grey") + 
  guides(fill = "none") + 
  theme_void() + scale_fill_hue(h = c(170, 360))

## testing using base plot
plot(with(magicplot, table(steps, flipped)))

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
lines(aggregate(error/input ~ iters, data = magicplot, min), col = "blue")
with(magicplot[magicplot[,"iters"] < 104, ],
     points(x = iters, y = error/input,
            pch = 20))

## another look, based on input. Not sure if the ones above the pink 
## line are bugs or not. 
ggplot(data = magicplot[magicplot[,"iters"] > 1 & magicplot[,"iters"] < 12, ],
       aes(x = input, y = error, colour = as.factor(iters))) + 
  geom_point(shape = 20) + ylim(0,2.1) + 
  guides(color = 'none')

## input and error with hexbin

ggplot(data = itercount,
       aes(x = input, y = error)) + 
  geom_hex(bins = 700) + ylim(0.6,8) + 
  guides(fill = 'none') + 
  ggtitle("Points which converged only after > 20 iterations")

# These are chosent to capture most of the variation in high
# iteration convergence
ggplot(data = itercount, aes(x = error, fill = as.factor(iters))) + 
  geom_histogram(bins = 60) + 
  xlim(0.71, 1.25) + guides(fill = 'none')


## artistic version of the above
wideplot <- ggplot(data = magicplot[(magicplot[, "input"] < 0.99 | magicplot[, "error"] < 0.99) & magicplot[,"iters"] > 1 & magicplot[,"iters"] < 12, ],
                   aes(x = input, y = error, colour = as.factor(iters))) + 
  geom_line(aes(group = timeline), alpha = 0.1) + coord_polar() +
  guides(color = 'none') + theme_void()
## see https://stackoverflow.com/a/53160799 for why
## cartesian coord plots can just use internal limits
widebuild <- ggplot_build(wideplot)
widebuild[["layout"]][["panel_params"]][[1]][["r.range"]][2] <- 0.33
wideplot <- ggplot_gtable(widebuild)
plot(wideplot)
rm(widebuild, wideplot)

## Another look, this time at just steps which require many
## iterations to converge but do so 
ggplot(data = magicplot[magicplot[,"iters"] > 60 & magicplot[,"iters"] < 104, ],
       aes(x = input, y = error, colour = as.factor(iters))) + 
  geom_point(shape = 20) + guides(color = 'none') + 
  coord_polar(theta = 'x')

## Here we have steps to convergence as plotted from the origin
ggplot(data = magicplot,
       aes(x = iters, y = timeline, colour = as.factor(steps))) + 
  geom_point(alpha = 0.25, shape = 20) + guides(colour = 'none') + 
  xlim(2, 103) + theme_void() + coord_polar(theta = 'y')


## Here looking at only those which do not converge

ggplot(data = magicplot[magicplot[,"iters"] > 104, ],
       aes(x = input, y = error, colour = as.factor(iters))) + 
  geom_point(alpha = 0.7, shape = 20) + ylim(0,2.1) + 
  guides(color = 'none') + 
  coord_polar(theta = 'x')

## A flower
ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = steps, y = error, group = timeline, colour = input)) + 
  geom_line(alpha = 0.25) +  
  coord_polar(theta = 'x',start = 2.15*pi/3) + 
  guides(colour = 'none') + ylim(0, 3) + xlim(15, 30) + theme_void()

## A colored flower

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = steps,
           y = error^2,
           group = timeline,
           colour = as.factor(iters))) + 
  geom_line(alpha = 0.05) +  
  coord_polar(theta = 'x',start = 2.15*pi/3) + 
  guides(colour = 'none') + ylim(0, 3) + xlim(15, 30) + 
  theme_void() + theme(plot.background = element_rect(fill = "gainsboro"))

## Something that looks like a parallel coordinates plot
ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = iters,
           y = error^2,
           group = timeline,
           colour = as.factor(steps))) + 
  geom_line(alpha = 0.25) +   
  guides(colour = 'none') + ylim(0, 3) + xlim(15, 30) + 
  theme_void() + theme(plot.background = element_rect(fill = "gainsboro"))
