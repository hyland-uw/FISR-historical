### old plotting with base R.

# q3a <- read.csv("~/Desktop/FISR-historical/data/FISR-data.csv", header=TRUE)
# ## q3a <- ### load data in to this variable
# ## Order the data frame to allow us to use
# ## base plot()'s line type without issue
# q3a <- q3a[order(q3a$Input), ]
# rownames(q3a) <- 1:nrow(q3a)
# q3Long <- pivot_longer(data = q3a, cols = 6:length(names(q3a)))


# ## Useful for comparisons
# rerange <- function(x) {
#   (x-min(x))/(max(x)-min(x))
# }

# ## Compares a lookup table method
# ## with a state of the art method that does not use lookup tables
# ## shows how accuracy can be achieved with lookup table methods
# with(q3a, {
#   par(mfrow = c(2, 3), xpd = FALSE)
#   par(cex.lab = 1.4)
#   ERRrange = c(-0.02, 0.02)

#   plot(Input, KahanNg - Reference,
#        type = "p", pch = ".", ylab = "Error",
#        main = "Kahan-Ng (1986)",
#        xlab = "", xaxt = "n",
#        xlim = c(0, 5.5), ylim = ERRrange)
#   abline(a = 0, b = 0, lty = 4, col = "grey")
#   abline(v = 2^seq(-2, 2, by = 1), lty = 3, col = "dark blue", lwd = 1.1)
#   axis(1,
#        at = c(2^seq(-2, 2, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-2, 2, 1), sep = "")))
#   title(sub = "64 entry lookup table",
#         cex.sub = 1.2, font.sub = 3)
#   plot(Input, InterState76 - Reference,
#        type = "p", col = "blue", pch = ".",
#        ylab = "", main = "Interstate 76 (1997)",
#        xlab = "", yaxt = "n", xaxt = "n",
#        xlim = c(0, 5.5), ylim = ERRrange)
#   abline(a = 0, b = 0, lty = 4, col = "grey")
#   abline(v = 2^seq(-2, 2, by = 1), lty = 3, col = "dark blue", lwd = 1.1)
#   title(sub = "256 entry",
#         cex.sub = 1.2, font.sub = 3)
#   axis(1,
#        at = c(2^seq(-2, 2, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-2, 2, 1), sep = "")))
#   plot(Input, Quake3 - Reference,
#        type = "l", col = "green",
#        ylab = "", main = "Quake 3 (1999)",
#        xlab = "", yaxt = "n", xaxt = "n",
#        xlim = c(0, 5.5), ylim = ERRrange)
#   axis(1,
#        at = c(2^seq(-2, 2, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-2, 2, 1), sep = "")))
#   abline(a = 0, b = 0, lty = 4, col = "grey")
#   abline(v = 2^seq(-2, 2, by = 1), lty = 3, col = "dark blue", lwd = 1.1)
#   axis(4)
#   title(sub = "No lookup table",
#         cex.sub = 1.2, font.sub = 3)

#   ####
#   # Bottom Row
#   ####

#   plot(Input, KahanNgNR - Reference,
#        type = "p", pch = ".", ylab = "Error",
#        xlab = "",
#        xlim = c(0, 5.5), ylim = ERRrange)
#   abline(a = 0, b = 0, lty = 4, col = "grey")

#   plot(Input, InterState76NR - Reference,
#        type = "p", col = "blue", pch = ".",
#        ylab = "",yaxt = "n",
#        xlab = "",
#        xlim = c(0, 5.5), ylim = ERRrange)
#   abline(a = 0, b = 0, lty = 4, col = "grey")
#   title(sub = "One step of Newton-Raphson\nconverges quickly",
#         cex.sub = 1.2, font.sub = 2)

#   plot(Input, Quake3NR - Reference,
#        type = "l", col = "green",
#        ylab = "",
#        xlab = "", yaxt = "n",
#        xlim = c(0, 5.5), ERRrange)
#   abline(a = 0, b = 0, lty = 4, col = "grey")
#   axis(4)
#   par(cex.lab = 1)
# })

# ## FISRs without lookup tables excluding the didactic KahanNG
# ## Modification of Q3 and Moroz lines because before the
# ## NR step they are identical
# with(q3a, {
#   par(mfrow = c(1,1), xpd = FALSE)
#   plot(Input, (Blinn - Reference),
#        type = "l", col = "red", ylab = "Error",
#        ylim  = c(-0.45, 0.375), xlim = c(0.125, 2.5),
#        xaxt = "n", xlab = "Input")
#   axis(1,
#        at = c(2^seq(-4, 1, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-4, 1, 1), sep = "")))
#   title(main = "Methods without Lookup Tables", adj = 0)
#   lines(Input, (Magic - Reference), col = "orange")
#   lines(Input, (Quake3 - Reference), col = "green")
#   lines(Input, (WithoutDiv - Reference), col = "blue")
#   abline(a = 0, b = 0, lty = 4, col = "grey")
#   abline(v = 2^seq(-4, 1, by = 1), lty = 3, col = "dark gray", lwd = 0.6)
#   par(xpd = TRUE)
#   legend(x = "topright", pch = 19, ncol = 4,
#          legend = c("Blinn (1997)", "Magic SQRT\n(1980)",
#                     "Quake3\n(1999)", "Kahan\n(1999)"),
#          col = c("red", "orange",
#                  "green", "blue"),
#          cex = 0.75, pt.cex = 1.2,
#          inset = c(0, -0.16 ), yjust = 0.7)
# })

# ## Good comparison of final output for
# ## Three "modern" FISRs
# with(q3a, {
#   par(mfrow = c(1,1), xpd = FALSE)
#   plot(Input, (Quake3NR - Reference)/Reference,
#        type = "l", col = "green", ylab = "Relative Error",
#        main = "Modern methods with one Newton-Raphson step",
#        ylim  = c(-0.0023, 0.001), xlim = c(0.125, 4.2), xaxt = "n")
#   lines(Input, (KadlecNR - Reference)/Reference, col = "blue")
#   lines(Input, (MorozNR - Reference)/Reference, col = "purple")
#   abline(a = 0, b = 0, lty = 4, col = "grey")
#   axis(1,
#        at = c(2^seq(-2, 2, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-2, 2, 1), sep = "")))
#   abline(v = 2^seq(-2, 2, by = 1), lty = 3, col = "dark gray", lwd = 1.6)
#   legend(x = "bottom", pch = 19, ncol = 3,
#          legend = c("Quake3\n(1999)", "Optimal\n32-bit (2010)",
#                     "Moroz et al.\n(2018)"),
#          col = c("green", "blue",
#                  "purple"),
#          bg = "white",
#          cex = 0.75, pt.cex = 1.2)

# })

# ## Compare the naive constant to the
# ## optimized "magic" constant
# ## and the SOTA
# with(q3a, {
#   par(mfrow = c(1,1), xpd = FALSE)
#   plot(Input, Reference - Quake3NR,
#        type = "l", col = "green", lwd = 2,
#        ylab = "Absolute Error",
#        ylim = c(-0.0035, 0.008),
#        xlab = "Input x", xaxt = "n",
#        xlim = c(0.12, 2))
#   lines(Input, Reference - MagicNR , col = "blue", lwd = 2)
#   lines(Input, Reference - KahanNgNR , col = "red", lwd = 2)
#   lines(Input, MorozNR - Reference, col = "purple", lwd = 2)
#   abline(v = 2^seq(-4, 1, by = 1), lty = 3, col = "dark blue", lwd = 1.1)
#   legend(x = "topright", pch = 19,
#          legend = c("Kahan's 'Magic' Square root (1980) [1974]",
#                     "Kahan-Ng SoftSqrt (1986)",
#                     "Seen in Quake3 (1999) [2001]",
#                     "State of the art in Moroz et al. (2018)"),
#          col = c("blue", "red", "green", "purple"),
#          cex = 0.9, pt.cex = 1.5)
#   axis(1,
#        at = c(2^seq(-4, 1, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-4, 1, 1), sep = "")))
#   axis(3)
#   title(main = "Comparison after Newton-Raphson correction", line = 2.1)
# })

# ## Compare the output of the Kahan-NG FISR with and without
# ## table lookups. Show the actual value of the lookup table
# ## being substracted from the result.
# with(q3a, {
#   ## For each entry on the LUT,
#   ## scale to KahanNgNoLookup - Reference & max LUT
#   par(mfrow = c(1,1), xpd = FALSE)
#   ## if the min input is too low this max will be all the way
#   ## on the left and not the first peak
#   peakKNErr <- with(q3a[q3a$Input > 0.069, ], max(KahanNgNoLookup - Reference))
#   scaleLUT <- LUT / max(LUT)
#   plot(Input, KahanNgNoLookup - Reference,
#        type = "l", col = "orange", lwd = 1,
#        ylab = "Distance from exact 1/sqrt(x)",
#        xlab = "Input x", xaxt = "n",
#        xlim = c(0.067, 0.25),
#        main = "Kahan-Ng with and without table lookups")
#   points(Input, KahanNg - Reference, col = "blue", pch = ".")
#   points(Input,
#          ## this ONLY works within the first range
#          ## of input values (0 - 2^-2)
#          ## otherwise my scaling is off
#          scaleLUT * peakKNErr,
#          col = "dark grey", pch = ".", cex = 3)
#   abline(a = 0, b = 0, lty = 4, col = "grey", lwd = 0.7)
#   legend(x = "topright", pch = 19,
#          legend = c("Kahan-Ng with 64 entry LUT",
#                     "KahanNG with no lookup table",
#                     "Lookup table values"),
#          col = c("blue", "orange", "dark grey"),
#          cex = 0.7, pt.cex = 1.2, xjust = 0.9)
#   axis(1,
#        at = c(2^seq(-4, -2, 1)),
#        labels = parse(text = paste(2, "^", seq(-4, -2, 1), sep = "")))
#   abline(v = 2^seq(-4, -2, by = 1), lty = 3, col = "dark gray", lwd = 0.6)
# })


# ## Explanation of what the error curve looks like for a
# ## piecewise linear interpolation of a smooth function like this
# with(q3a, {
#   par(mfrow = c(2,1), xpd = FALSE)
#   xl <- c(0.0625, 1.25)
#   plot(Input, Blinn, type = "l",
#        xlim = xl,
#        xaxt = "n",
#        ylab = " y = 1 / sqrt(x)",
#        xlab = "",
#        main = "Linear interpolation along powers of 2")
#   abline(v = 2^seq(-4, 1, by = 1), lty = 3, col = "dark gray", lwd = 0.6)
#   axis(1,
#        at = c(2^seq(-4, 1, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-4, 1, 1), sep = "")))
#   lines(Input, Reference, col = "blue", lwd = 0.8, lty = 3)
#   plot(Input, Blinn - Reference,
#        type = "l",
#        xlim = xl,
#        xaxt = "n",
#        ylab = "Error",
#        main = "Error from reference 'hops' along even powers of 2",
#        xlab = "")
#   axis(1,
#        at = c(2^seq(-4, 1, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-4, 1, 1), sep = "")))
#   abline(v = 2^seq(-4, 1, by = 1), lty = 3, col = "dark gray", lwd = 0.6)
#   abline(a = 0, b = 0, col = "blue", lwd = 0.8, lty = 3)
# })

# ## Shows the approximate logarithm and the shapes of the error
# ## between it and a true logarithm
# with(q3a, {
#   par(mfrow = c(2,1), xpd = FALSE)
#   INPrange <- c(2^-4, 2^-0.25)
#   plot(Input, rerange(Integer),
#        type = "l", lwd = 1.15, col = "blue",
#        cex.lab = 1.1,
#        xaxt = "n", xlim = INPrange, xlab = "Input x",
#        ylab = parse(text = paste("log", "[2]", "(x)", sep = "")),
#        yaxt = "n",
#        main = "An approximate logarithm")
#   lines(Input, rerange(log2(1 + Input)), type = "l",
#         lwd = 0.7)
#   abline(v = 2^seq(-4, -1, by = 1), lty = 3, col = "dark gray", lwd = 0.6)
#   axis(1,
#        at = c(2^seq(-4, -1, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-4, -1, 1), sep = "")))
#   ## helps it look like it lines up w/ 1.0. Just wanted to avoid
#   ## annoying axis labels
#   plot(Input, (rerange(Integer) - rerange(log2(Input))) * 82.1, type = "l",
#        lwd = 1, col = "blue", cex.lab = 1.1,
#        xaxt = "n", ylab = "Relative Distance",
#        xlab = "", xlim = INPrange,
#        main = "Distance from the true logarithm")
#   abline(v = 2^seq(-4, -1, by = 1), lty = 3, col = "dark gray", lwd = 0.6)
#   axis(1,
#        at = c(2^seq(-4, -1, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-4, -1, 1), sep = "")))
#   browser()
# })

# with(q3a, {
#   par(mfrow = c(1,1), xpd = FALSE)
#   INPrange <- c(2^-4, 2^-0.25)
#   plot(Input, log2(Input),
#        type = "l", lwd = 1.15, col = "blue",
#        cex.lab = 1.1, xlim = c(0.125, 2.1),
#        ylim = c(-4, 1),
#        ylab = parse(text = paste("log", "[2]", "(x)", sep = "")),
#        main = "An approximate logarithm")
#   abline(v = 2^seq(-4, 4, by = 1), lty = 3, col = "dark gray", lwd = 0.6)
# })

# with(q3a, {
#   par(mfrow = c(1,1), xpd = FALSE)
#   plot(hist(Reference - BlinnNR), col = "blue")
#   lines(ecdf(Reference - WithoutDivNR), col = "red")
#   lines(ecdf(Reference - Quake3NR), col = "purple")
#   lines(ecdf(Reference - KadlecNR), col = "green")
# })


# ## Compare quake FISr w/ Blinn's example
# with(q3a[q3a$Input >= 1 & q3a$Input < 4, ], {
#   par(mfrow = c(2,1), xpd = FALSE)

#   plot(Input, Reference - Quake3NR,
#        type = "l", col = "green", lwd = 2,
#        ylab = "Error",
#        ylim = c(-0.0035, 0.004),
#        xlab = "Input x", xaxt = "n")
#   lines(Input, Reference - BlinnNR , col = "orange", lwd = 2)
#   abline(v = 2^seq(0, 2, by = 1), lty = 3, col = "dark blue", lwd = 1.1)
#   abline(a = 0, b = 0, lty = 4, col = "grey", lwd = 0.8)
#   legend(x = "bottomright", pch = 19, ncol = 2, bty = "n",
#          legend = c("Seen in Quake3 (1999) [2001]",
#                     "Blinn's baseline constant"),
#          col = c("green", "orange"),
#          cex = 0.7, pt.cex = 1.2)
#   axis(1,
#        at = c(2^seq(0, 2, by = 1)),
#        labels = parse(text = paste(2, "^", seq(0, 2, 1), sep = "")))
#   axis(3)
#   title(main = "Comparison over a common input domain", line = 2.1)
#   plot(ecdf(Reference - BlinnNR), col = "orange",
#        main = "Cumulative Distribution of Error",
#        xlab = "Error", xlim = c(-0.004, 0.004))
#   lines(ecdf(Reference - Quake3NR), col = "green")
# })


# ## Explanation of what the error curve looks like for a
# ## piecewise linear interpolation of a smooth function like this
# with(q3a, {
#   par(mfrow = c(1,1), xpd = FALSE)
#   xl <- c(0.0625, 1.25)
#   plot(Input, Blinn, type = "l",
#        xlim = c(0.125, 0.6), ylim = c(1,3),
#        xaxt = "n", lwd = 1.5,
#        ylab = " y = 1 / sqrt(x)",
#        xlab = "",
#        main = "Linear interpolation along powers of 2")
#   abline(v = 2^seq(-4, 1, by = 1), lty = 3, col = "dark gray", lwd = 0.6)
#   axis(1,
#        at = c(2^seq(-4, 1, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-4, 1, 1), sep = "")))
#   lines(Input, Reference, col = "blue", lwd = 2, lty = 3)
#   lines(Input, Quake3, col = "green", lwd = 2)
#   legend(x = "topright", pch = 19, ncol = 2,
#          legend = c("Exact 1/sqrt(x)",
#                     "Linear approximation",
#                     "Quake III's implementation"),
#          col = c("blue", "black", "green"),
#          cex = 0.7, pt.cex = 1.2)
# })

# ## Compares a lookup table method
# ## with a state of the art method that does not use lookup tables
# ## shows how accuracy can be achieved with lookup table methods
# with(q3a, {
#   par(mfrow = c(1, 3), xpd = FALSE)
#   par(cex.lab = 1.4)
#   ERRrange = c(-0.02, 0.02)

#   plot(Input, KahanNg - Reference,
#        type = "p", pch = ".", ylab = "Error",
#        main = "Kahan-Ng (1986)",
#        xlab = "", xaxt = "n", col = "blue",
#        xlim = c(0.25, 5.5), ylim = ERRrange)
#   abline(a = 0, b = 0, lty = 4, col = "grey")
#   abline(v = 2^seq(-2, 2, by = 1), lty = 3, col = "dark blue", lwd = 1.1)
#   axis(1,
#        at = c(2^seq(-2, 2, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-2, 2, 1), sep = "")))
#   title(sub = "64 entry lookup table",
#         cex.sub = 1.2, font.sub = 3)
#   plot(Input, KahanNgNoLookup - Reference,
#        type = "l", col = "purple", lwd = 2,
#        ylab = "", main = "Kahan-Ng modified\nto remove lookup",
#        xlab = "", yaxt = "n", xaxt = "n",
#        xlim = c(0.25, 5.5), ylim = c(-0.15, 0.15))
#   axis(1,
#        at = c(2^seq(-2, 2, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-2, 2, 1), sep = "")))
#   abline(v = 2^seq(-2, 2, by = 1), lty = 3, col = "dark blue", lwd = 1.1)
#   points(Input, KahanNg - Reference, pch = ".", cex = 0.6, col = "blue")
#   axis(4)
#   plot(Input, Quake3 - Reference,
#        type = "l", col = "green", lwd = 2,
#        ylab = "", main = "Quake 3 (1999)",
#        xlab = "", yaxt = "n", xaxt = "n",
#        xlim = c(0.25, 5.5), ylim = c(-0.15, 0.15))
#   axis(1,
#        at = c(2^seq(-2, 2, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-2, 2, 1), sep = "")))
#   points(Input, KahanNg - Reference, pch = ".", cex = 0.6, col = "blue")
#   abline(v = 2^seq(-2, 2, by = 1), lty = 3, col = "dark blue", lwd = 1.1)
#   axis(4)
#   title(sub = "No lookup table",
#         cex.sub = 1.2, font.sub = 3)
#   par(cex.lab = 1)
# })

# ## FISRs without lookup tables excluding the didactic KahanNG
# ## Modification of Q3 and Moroz lines because before the
# ## NR step they are identical
# with(q3a, {
#   par(mfrow = c(1,1), xpd = FALSE)
#   plot(Input, (Blinn - Reference),
#        type = "l", col = "red", ylab = "Error",
#        ylim  = c(-0.45, 0.375), xlim = c(0.125, 2.5),
#        xaxt = "n", xlab = "Input")
#   axis(1,
#        at = c(2^seq(-4, 1, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-4, 1, 1), sep = "")))
#   title(main = "Methods without Lookup Tables", adj = 0)
#   lines(Input, (Magic - Reference), col = "orange")
#   lines(Input, (Quake3 - Reference), col = "green")
#   lines(Input, (WithoutDiv - Reference), col = "blue")
#   abline(a = 0, b = 0, lty = 4, col = "grey")
#   abline(v = 2^seq(-4, 1, by = 1), lty = 3, col = "dark gray", lwd = 0.6)
#   par(xpd = TRUE)
#   legend(x = "topright", pch = 19, ncol = 4,
#          legend = c("Blinn (1997)", "Magic SQRT\n(1980)",
#                     "Quake3\n(1999)", "Kahan\n(1999)"),
#          col = c("red", "orange",
#                  "green", "blue"),
#          cex = 0.75, pt.cex = 1.2,
#          inset = c(0, -0.16 ), yjust = 0.7)
# })


# ## Explanation of what the error curve looks like for a
# ## piecewise linear interpolation of a smooth function like this
# with(q3a, {
#   par(mfrow = c(1,1), xpd = FALSE)
#   xl <- c(0.0625, 1.25)
#   plot(Input, Blinn - Reference,
#        type = "l",
#        xlim = xl,
#        xaxt = "n", lwd = 2,
#        ylab = "Error", ylim = c(-0.1, 0.4),
#        main = "Error from reference 'hops' along even powers of 2",
#        xlab = "")
#   axis(1,
#        at = c(2^seq(-4, 1, by = 1)),
#        labels = parse(text = paste(2, "^", seq(-4, 1, 1), sep = "")))
#   abline(v = 2^seq(-4, 1, by = 1), lty = 3, col = "dark gray", lwd = 0.6)
#   abline(a = 0, b = 0, col = "blue", lwd = 1.5, lty = 3)
#   lines(Input, Quake3 - Reference, col = "green", lwd = 2)
#   legend(x = "topright", pch = 19, ncol = 2,
#          legend = c("Exact 1/sqrt(x)",
#                     "Linear approximation",
#                     "Quake III's implementation"),
#          col = c("blue", "black", "green"),
#          cex = 0.7, pt.cex = 1.2)
# })
