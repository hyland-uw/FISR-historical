# Testing and instrumenting versions of the fast inverse square root

![An artistic deconstruction](/plots/pastelerror.png)

This project is a work in progress.

The code and data here are components of a larger investigation into the history and re-use of the Fast Inverse Square Root, including [the most famous implementation found in Quake III Arena](https://en.wikipedia.org/wiki/Fast_inverse_square_root). The larger project website is here, at [0x5f37642f.com](https://0x5f37642f.com/).

## Mode of operation

The project right now works in batches. The c code is compiled and run to produce the desired output, then the output is loaded into R manually and the plot functions provided should generate the plots you see. The project will eventually move to C++ code which is called from functions in an R package to generate these numbers on the fly for plotting (or interact with a dataset of them).

C code is in "/src", R code "/R" and data in "/data". Example plots are in "/plots". Note plots are illustrative and are not mapped securely to a specific version of the code, so your results may vary.

### Specific files

C code:
* deconstructed-fisr.c replaces the usual iteration limit of 1-2 Newton-Raphson iterations with iteration to a tolerance, which supports plotting the space for random inputs and magic constants (which produce better or worse approximations).
* minimal-fisr.c performs 1 iterations of Newton-raphson with user supplied values for the magic constant and NR parameters. Returns the initial approximation and the final result.
* float-methods.c and double-methods.c contain specific approximations in order to graph their performance.
* sampling-harness.h contains utility methods for sampling floats and integers as well as headers for some functions we use to sample.

R code:
* Currently the R code in the repository works with old datasets where I used an elaborate method to change the magic constant for artsy purposes. It is being re-written to use the new sampling methods.

### Note for compilation

Compile C code with -O0 to disable optimization (otherwise some elements are optimized out and the output is wrong).

## Future directions

Ideally the end point for this is an R package containing data as well as functions to call the underlying C code at will. What needs to happen for that is:

1. [Convert the existing C code to C++](https://legalizeadulthood.wordpress.com/2007/05/18/refactoring-convert-c-to-c/) to allow the use of [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) which has a much better interface than between  R and C.
2. Refactor the existing R and C code from the current mode of batch process to CSV to to an R function like generate_timelines() which would call the underlying C++ code with passed parameters.
3. Generate exemplary datasets and store them in .Rdata format.
4. Convert the whole project into a package with named exported functions and data.

Future needs for the project apart from that:
* Actual documentation
* Once packaging is finished, potentialy moving the project to CRAN

## License
I have not yet chosen a blanket license for these but each of the individual versions are licensed under a variety of terms. Quake III's source code is licensed under the GPL, while fdlibm (which is where the Kahan-Ng softsqrt was published in fixed form) is under a license which may [loosely be described](https://lists.fedoraproject.org/archives/list/legal@lists.fedoraproject.org/thread/2T6RANNIF652RMGG725LNRKT63ALAPN4/) as "MIT". Before borrowing please check the individual example licenses.
