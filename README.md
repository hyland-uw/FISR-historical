# Testing and instrumenting versions of the fast inverse square root

![An artistic deconstruction](/plots/pastelerror.png)

This project is a work in progress.

The code and data here are components of a larger investigation into the history and re-use of the Fast Inverse Square Root, including [the most famous implementation found in Quake III Arena](https://en.wikipedia.org/wiki/Fast_inverse_square_root). The larger project website is here, at [0x5f37642f.com](https://0x5f37642f.com/).

## Mode of operation

Run `make` in the base directory to generate csvs in the data directory. Sampling parameters are set in the sampling-harness.h file.

### Specific files

C code:
* approximated.c plots performance of historical FRSR style approximations over a range of floats.
* deconstructed.c replaces the usual iteration limit of 1-2 Newton-Raphson iterations with iteration to a tolerance, which supports plotting the space for random inputs and magic constants (which produce better or worse approximations).
* enumerated.c does the unusual job of enumerating a "best" magic constant for a given float. Imagine the world's least efficient lookup table.
* sliced.c maps the performance of a range of magic constants across sets of floats to visualize slices of the output.
* sampling-harness.h contains utility methods for sampling floats and integers as well as headers for some functions we use to sample.

R code:
* Currently the R code in the repository works with old datasets where I used an elaborate method to change the magic constant for artsy purposes. It is being re-written to use the new sampling methods.

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
