library(scales)
library(ggplot2)


magicplot <- read.csv("~/Desktop/FISR-historical/data/magicplot.csv")
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

## Histogram of number of steps taken in mutation timelines
## all have more than 10 steps, none more than 30
hist(aggregate(steps ~ timeline,
               data = magicplot[magicplot[, "iters"] < 100, ],
               max)[, 2])

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

## a very cooorful region plot
ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = input, y = log1p(steps), colour = sort(as.factor(iters), decreasing = TRUE))) + 
  geom_path(alpha = 0.2, linewidth = 0.25) + 
  guides(color = 'none') + scale_color_viridis_d(option = "turbo") +
  coord_polar(theta = 'x') + theme_void()

## cool color/line width combo
ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = input^2, y = log1p(steps), colour = as.factor(iters - flipped))) + 
  geom_path(alpha = 0.01, linewidth = 2.5) + 
  guides(color = 'none') + scale_color_viridis_d(option = "H") +
  coord_polar(theta = 'x') + theme_void()

## well now
ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = input^2, y = steps / flipped, colour = as.factor(iters))) + 
  geom_path(alpha = 0.1, linewidth = 0.5) + 
  guides(color = 'none') + scale_color_viridis_d(option = "H") +
  coord_polar(theta = 'x') + theme_void()

## technical difficulties

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = input^2 - error, y = steps / flipped, colour = as.factor(iters))) + 
  geom_step(linewidth = 1, direction = "mid", alpha = 0.6) + 
  guides(color = 'none') + scale_color_viridis_d(option = "H", direction = -1) +
  coord_polar(theta = 'x') + theme_void()

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = input^2, y = steps / flipped, colour = as.factor(iters))) + 
  geom_step(linewidth = 0.7, alpha = 0.2) + 
  guides(color = 'none') + scale_color_viridis_d(option = "H", direction = -1) +
  coord_polar(theta = 'y') + theme_void()

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = log(abs(error)) - input , y = steps / (iters + steps), colour = as.factor(iters))) + 
  geom_step() + 
  guides(color = 'none') + scale_color_viridis_d(option = "H") +
  coord_polar(theta = 'x') + theme_void()

ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[, "error"] < 1.8, ],
       aes(x = (iters - steps) / iters, y = error^(1 - input), fill = as.factor(steps))) + 
  scale_fill_viridis_d(option = "D") + geom_area(alpha = 0.85) + 
  guides(fill = 'none', color = 'none') + 
  theme_void() + coord_polar(theta = 'y')


ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[, "error"] < 1.8, ],
       aes(x = iters, y = error-input, color = as.factor(steps))) + 
  scale_color_viridis_d(option = "H", direction = -1) + 
  geom_step(direction = "mid") + guides(fill = 'none', color = 'none') + theme_void() + coord_polar(theta = 'x')

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = input^2 - log(abs(error)), y = steps %/% (flipped + steps), colour = as.factor(iters))) + 
  geom_path(linewidth = 0.35, alpha = 0.7) + 
  guides(color = 'none') + scale_color_viridis_d(option = "H") +
  coord_polar(theta = 'y', start = pi * 1.0765) + theme_void()

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = input^2 - log(abs(error)), y = steps / (flipped + steps), colour = as.factor(iters))) + 
  geom_path(linewidth = 0.5, alpha = 0.07) + 
  guides(color = 'none') + scale_color_viridis_d(option = "H") +
  coord_polar(theta = 'y') + theme_void()

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = input - log(abs(error)), y = iters / (iters + steps), colour = as.factor(iters %/% error))) + 
  geom_step(linewidth = 0.5, alpha = 0.3) + 
  guides(color = 'none') + scale_color_viridis_d(option = "C") +
  coord_polar(theta = 'x') + theme_void()

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = input^2 - log(abs(error)), y = iters / (iters + error), colour = as.factor(steps %/% iters))) + 
  geom_path(linewidth = 0.25, alpha = 0.75) + 
  guides(color = 'none') + scale_color_viridis_d(option = "H") +
  coord_polar(theta = 'y', start = 3*pi) + theme_void()

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = input / (input + error), y = (iters + steps), colour = as.factor(iters %/% steps))) + 
  geom_step(linewidth = 0.25, direction = "mid") + 
  guides(color = 'none') + scale_color_viridis_d(option = "H", direction = -1) +
  coord_polar(theta = 'y', start = pi - 1.5) + theme_void()

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = iters, y = steps , colour = as.factor( iters %/% steps))) + 
  geom_path(linewidth = 0.25, alpha = 0.2) + 
  guides(color = 'none') +
  coord_polar(theta = 'x') + theme_void()

## fat point chart
ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = iters, y = steps , color = as.factor( steps %/% iters))) + 
  geom_point() + 
  guides(color = 'none', fill = 'none') + theme_void() + coord_polar(theta = 'x')

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

## this fuckin rips

ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[, "error"] < 1.8, ],
       aes(x = iters, y = error, fill = as.factor(steps))) + scale_fill_viridis_d(option = "H") +
  geom_area() + guides(fill = 'none') + theme_void() + coord_polar(theta = 'y')

##takes forever to run but wild
ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[, "error"] < 1.8, ],
       aes(x = iters, y = error, fill = as.factor(steps))) + scale_fill_viridis_d(option = "H") +
  geom_area(orientation = 'y') + guides(fill = 'none') + theme_void() + coord_polar(theta = 'y')

##?? 
ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[, "error"] < 1.8, ],
       aes(x = iters^-input, y = error, fill = as.factor(steps))) + scale_fill_viridis_d(option = "H") +
  geom_area() + guides(fill = 'none') + theme_void() + coord_polar(theta = 'y')

ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[, "error"] < 1.8, ],
       aes(x = iters^input, y = error^-input, fill = as.factor(steps))) + 
  scale_color_viridis_d(option = "H", direction = -1) + 
  geom_area() + guides(fill = 'none') + theme_void()

### takes forever to run
ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[, "error"] < 1.8, ],
       aes(x = iters^input, y = error^input, fill = as.factor(steps))) + 
  scale_color_viridis_d(option = "H", direction = -1) + 
  geom_area() + guides(fill = 'none') + 
  theme_void()

## the region

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = sqrt(iters/steps),
           y = sqrt(error/steps),
           group = timeline,
           colour = as.factor(steps))) + 
  geom_step(alpha = 0.2) + coord_polar(theta = 'y',start = pi) +
  guides(colour = 'none') +
  theme_void() 

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = iters / (32 - flipped),
           y = error^2,
           group = timeline)) + 
  geom_col(alpha = 0.25) +   
  guides(colour = 'none') + coord_polar(theta = 'x',start = pi) +
  theme_void()



## Something that looks like a parallel coordinates plot
ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = iters,
           y = error^2,
           group = timeline,
           colour = as.factor(steps))) + 
  geom_line(alpha = 0.25) +   
  guides(colour = 'none') + ylim(0, 3) + xlim(15, 30) + 
  theme_void() + theme(plot.background = element_rect(fill = "gainsboro"))

## similar to the above, but a shaded area chart.
ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = log1p(iters),
           y = error^2,
           fill = as.factor(iters - steps))) + 
  geom_area(alpha = 0.06) +   
  guides(colour = 'none', fill = 'none') + ylim(0, 3)  + 
  theme_void() + coord_polar(theta = 'y')

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = iters/steps,
           y = error^2,
           group = timeline,
           colour = as.factor(steps))) + 
  geom_line(alpha = 0.25) +   
  guides(colour = 'none') + ylim(0, 3) + 
  theme_void()

## really interesting plot

ggplot(data = magicplot[magicplot[,"iters"] < 100, ],
       aes(x = iters,
           y = error^2,
           colour = input)) + 
  geom_point(alpha = 0.35, shape = 20) +   
  guides(colour = 'none') + ylim(0, 2) + xlim(1, 90)

### the region

ggplot(data = magicplot,
       aes(x = input, y = steps, colour = iters)) + 
  geom_path(alpha = 0.9, size = 0.05) + 
  guides(color = 'none') + 
  coord_polar(theta = 'x') + theme_void()


ggplot(data = magicplot[magicplot[,"timeline"] < 500, ],
       aes(x = input, y = steps, colour = iters)) + 
  geom_area(alpha = 0.9, size = 0.05) + 
  guides(color = 'none') + 
  coord_polar(theta = 'x') + theme_void()

## column plot (if it works)
ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[,"timeline"] < 500, ],
       aes(x = steps %/% iters,
           y = sqrt(error) - input, group = timeline, fill = iters)) + 
  geom_col() + coord_polar(theta = 'y',start = pi) +
  guides(colour = 'none', fill = 'none') + 
  theme_void() 


ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[,"timeline"] < 1500, ],
       aes(x = iters - steps, y = error^2/input, fill = as.factor(steps %/% iters) )) + 
  geom_polygon(alpha = 0.8, rule = 'winding') +
  coord_polar(theta = 'y',start = 1.242*pi) +
  guides(colour = 'none', fill = 'none') +
  scale_fill_brewer(palette = "Set1", direction = -1) +
  theme_void()


## https://stackoverflow.com/a/25449256/1188479 for the NA fill trick
## the region 2.0
ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[,"iters"] > 1, ],
       aes(x = iters - steps, y = error^2/input, color = as.factor(timeline), group = as.factor(steps %/% iters))) + 
  geom_col(fill= 'black', linewidth = 1) + scale_color_viridis(discrete = TRUE, option = "H") +
  guides(colour = 'none', fill = 'none') +
  theme_void() + xlim(-25, 0) + coord_polar(theta = 'y')


ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[,"iters"] > 1 & magicplot[,"timeline"] < 3500, ],
       aes(x = iters - steps, y = error^2/input, fill = as.factor(steps %/% iters) )) + 
  geom_polygon(alpha = 0.8, rule = 'winding') +
  coord_polar(theta = 'y',start = 4.65) + scale_fill_viridis(discrete = TRUE) +
  guides(colour = 'none', fill = 'none') +
  theme_void()

ggplot(data = magicplot[magicplot[,"iters"] < 100 & magicplot[,"iters"] > 1 & magicplot[,"timeline"] < 100, ],
       aes(x = error, y = input, fill = as.factor(iters %/% steps))) + 
  geom_polygon(alpha = 0.3) + 
  guides(colour = 'none', fill = 'none') +
  theme_void() 


