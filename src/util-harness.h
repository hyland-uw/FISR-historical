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
#define FLOAT_END 1.0f

// For selection of magic constant over many floats
#define NUM_FLOATS 131072 // Number of floats to process (131072 is good)
#define MAGIC_CONSTANT_DRAWS 32768 // number of integer constant samples per float

// For visualizing
#define FLOAT_SLICES 12288 // number for optimized/approximated/extracted
#define FLOAT_VIS_SLICES 2048 // Smaller slices for sliced.c to keep file size down
#define INTEGER_SAMPLES_PER_SLICE 2048 // number of integers to sample for single float search
#define INTEGER_SELECTIONS 256 // winnow best performers
#define CHUNK_SIZE 1000

// for sampling halfone/halfthree
//
#define GRID_SIZE 10
#define GRID_STEP 0.001f

// Utility function prototpes which we want to define elsewhere
// These should (should!) all be un utils.c
float uniformRange (float min, float max);
float reciprocalRange(float min, float max);
float logStratifiedSampler(float min, float max);
uint32_t sample_integer_range(uint32_t min, uint32_t max);
float minimal_rsqrt(float input, uint32_t magic, int NR);
float random_float_with_exponent(uint32_t exponent);
uint32_t exp_extract(float input);
uint32_t abs_uint_diff(uint32_t a, uint32_t b);
float min_max_float_with_exponent(int exponent, bool is_max);
uint32_t extract_top10_fraction(float input);

// Harness to capture information for visualization
// Placing the definition here seems to allow me to return an object struct
// though I am not sure why
typedef struct deconHarness {
    float input, reference, after_one, initial_approx;
    int NR_iters;
    bool invalid_float_reached;
} deconHarness;
deconHarness decon_rsqrt(float x, int NRmax, uint32_t magic, float tol);


typedef struct narrowHarness {
    float input, reference, output, initial_approx;
    int NR_iters;
    bool invalid_float_reached;
} narrowHarness;
narrowHarness narrow_decon_rsqrt(float x, uint32_t magic, float tol);

// Sampling function prototype for draws of decon_rsqrt()
void sample_decon_rsqrt(int draws, int NRmax, float min, float max, float tol);

// Function prototypes for historical methods
float BlinnISR(float x, int NR);
float QuakeISR(float x, int NR);
float withoutDivISR(float x, int NR);
float optimalFISR(float x, int NR);
float MorozISR(float x, int NR);

// Declare a function and struct to access the various historical methods
typedef float (*ISRFunction)(float, int);

typedef struct {
    const char *name;
    float (*func)(float, int);
} ISREntry;

// Declare the table as extern
extern ISREntry isr_table[];

#endif // FISR_HARNESS_H
