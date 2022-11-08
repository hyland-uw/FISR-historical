This is work in progress.

Code for testing and instrumenting version of the fast inverse square root.

Compile FISR-instrumentation.c with -O0 to disable optimization (otherwise some elements are optimized out and the output is wrong). The executable will produce a csv and code for plots I have so far are in FISR-plotting.R

C code is in "/src", R code "/R" and data in "/data". Example plots are in "/plots". Note these illustrative and are not versioned or mapped securely to a specific version of the code, so your results may vary.

I have not yet chosen a blanket license for these but each of the individual versions are licensed under a variety of terms. Quake III's source code is licensed under the GPL, while fdlibm (which is where the Kahan-Ng softsqrt was published in fixed form) is under a license which may [loosely be described](https://lists.fedoraproject.org/archives/list/legal@lists.fedoraproject.org/thread/2T6RANNIF652RMGG725LNRKT63ALAPN4/) as "MIT". Before borrowing please check the individual example licenses. 