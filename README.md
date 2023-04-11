# Testing and instrumenting versions of the fast inverse square root

This is work in progress.

## Mode of operation

The project right now works in batches. The c code is compiled and run to produce the desired output, then the output is loaded into R manually and the plot functions provided should generate the plots you see. The project will eventually move to C++ code which is called from functions in an R package to generate these numbers on the fly for plotting (or interact with a dataset of them). 

C code is in "/src", R code "/R" and data in "/data". Example plots are in "/plots". Note plots are illustrative and are not mapped securely to a specific version of the code, so your results may vary.

### Note for compilation

Compile C code with -O0 to disable optimization (otherwise some elements are optimized out and the output is wrong).

## License 
I have not yet chosen a blanket license for these but each of the individual versions are licensed under a variety of terms. Quake III's source code is licensed under the GPL, while fdlibm (which is where the Kahan-Ng softsqrt was published in fixed form) is under a license which may [loosely be described](https://lists.fedoraproject.org/archives/list/legal@lists.fedoraproject.org/thread/2T6RANNIF652RMGG725LNRKT63ALAPN4/) as "MIT". Before borrowing please check the individual example licenses. 
