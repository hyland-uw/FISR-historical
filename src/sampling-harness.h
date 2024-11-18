#ifndef FISR_HARNESS_H
#define FISR_HARNESS_H

#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>


// values above or below these are usually poor sources of approximations.
#define MIN_INT 1596980000
#define MAX_INT 1598050000

// The function repeats, so passing a few binades is sufficient to see
// behavior.
#define FLOAT_START 0.0125f
#define FLOAT_END 2.0f

// For selection of magic constant over many floats
#define NUM_FLOATS 131072 // Number of floats to process (131072 is good)
#define MAGIC_CONSTANT_DRAWS 32768 // number of integer constant samples per float

// For visualizing
#define FLOAT_SLICES 512 // number of single_float_search()
#define INTEGER_SAMPLES_PER_SLICE 4096 // number of integers to sample for single float search

// Smooth generation of random floats in a range
// by dividing doubles then casting
float uniformRange (float min, float max) {
    double x;
    float Urand;
    x = (double)rand() / (double)((unsigned)RAND_MAX + 1);
    Urand = (float) x;
    return (max - min) * Urand + min;
}

// Draw for a reciprocal distribution https://en.wikipedia.org/wiki/Reciprocal_distribution
float reciprocalRange(float min, float max) {
    // Convert to double for calculation
    // to avoid potential overflow.
    double d_min = (double)min;
    double d_max = (double)max;

    // Generate a uniform random number
    double x = (double)rand() / (double)((unsigned)RAND_MAX + 1);

    // Inverse CDF using logarithmic transformation
    // old version used an exponential
    double result = exp(log(d_min) + x * (log(d_max) - log(d_min)));

    // Return as float
    return (float)result;
}

// Integer sampling methods
uint32_t sample_integer_range(uint32_t min, uint32_t max) {
    uint32_t range = max - min + 1;

    // Check if range is small enough to use rand() directly
    if (range <= RAND_MAX) {
        return min + (uint32_t)(rand() % range);
    } else {
        // For larger ranges, use a more robust method
        uint32_t x = rand();
        uint32_t y = rand();
        uint64_t r = (uint64_t)x << 32 | y;
        return min + (uint32_t)((r * (uint64_t)range) >> 32);
    }
}

uint32_t sample_integer_range_with_peak(uint32_t center, uint32_t lower, uint32_t upper) {
    if (lower > upper) {
        uint32_t temp = lower;
        lower = upper;
        upper = temp;
    }

    uint32_t range = upper - lower + 1;

    // Ensure center is within bounds
    if (center < lower) center = lower;
    if (center > upper) center = upper;

    // Calculate relative position of center within the range
    uint32_t center_offset = center - lower;

    // Generate two random numbers
    uint32_t r1 = sample_integer_range(lower, upper);
    uint32_t r2 = sample_integer_range(lower, upper);

    // Use the average of the two random numbers for triangular distribution
    uint32_t offset = (r1 + r2) / 2;

    // Adjust offset based on center position
    if (offset < center_offset) {
        return lower + offset;
    } else {
        return upper - (range - 1 - offset);
    }
}

float minimal_rsqrt(float input, uint32_t magic, int NR) {
    union { float f; uint32_t u; } y = {input};
    y.u = magic - (y.u >> 1);
    // Not all versions use the NR formula y * 1.5 -(0.5 * x * y^2) but most do.
    while (NR > 0) {
        y.f = y.f * (1.5f - 0.5f * input * y.f * y.f);
        NR--;
    }
    return y.f;
}


// Harness to capture information for visualization
typedef struct deconHarness {
    float input, reference, output, initial_approx;
    int NR_iters;
    bool invalid_float_reached;
} deconHarness;
deconHarness decon_rsqrt(float x, int NRmax, uint32_t magic, float tol);

// Sampling function prototype for draws of decon_rsqrt()
void sample_decon_rsqrt(int draws, int NRmax, uint32_t base_magic, float min, float max);

// Function prototypes for historical methods
float MagicISR(float x, int NR);
float BlinnISR(float x, int NR);
float QuakeISR(float x, int NR);
float withoutDivISR(float x, int NR);
float optimalFISR(float x, int NR);
float MorozISR(float x, int NR);

// Declare a function and struct to access the various historical methods
typedef float (*ISRFunction)(float, int);

typedef struct {
    const char *name;
    ISRFunction func;
} ISREntry;

// Declare the table as extern
extern ISREntry isr_table[];


#endif // FISR_HARNESS_H
