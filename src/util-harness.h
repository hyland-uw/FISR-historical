#ifndef FISR_HARNESS_H
#define FISR_HARNESS_H

// Localized calls to libraries
#include <float.h>
#include <math.h>
#include <omp.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// values above or below these are usually poor sources of approximations.
#define MIN_INT 1596980000
#define MAX_INT 1598050000

// The function repeats, so passing a few binades is sufficient to see
// behavior.
#define FLOAT_START 0.03125f
#define FLOAT_END 2.5f

// For approximated.c and other files which iterate to a tolerance,
// we can use 2^-11
#define FLOAT_TOL 0.0004882812f
// most guesses which converge do so before 95 iterations
#define MAX_NR 95

// For visualizing
#define FLOAT_SLICES 18432 // number for optimized/approximated/extracted
#define FLOAT_VIS_SLICES 2048 // Smaller slices for sliced.c to keep file size down
#define CHUNK_SIZE 1000

#endif // FISR_HARNESS_H
