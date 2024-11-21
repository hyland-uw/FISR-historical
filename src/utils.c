#include <math.h>
#include <stdint.h>
#include <stdlib.h>

// Smooth generation of random floats in a range
// by dividing doubles then casting
// Uniform sampling is fast, but floats aren't uniformly
// distributed over the number line.
float uniformRange (float min, float max) {
    double x;
    float Urand;
    x = (double)rand() / (double)((unsigned)RAND_MAX + 1);
    Urand = (float) x;
    return (max - min) * Urand + min;
}

// Draw for a reciprocal distribution
// https://en.wikipedia.org/wiki/Reciprocal_distribution
// this implementation is a bit dodgy, but it gives
// a better approximation than uniform for float distribution

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

// Function to sample floats in a logarithmic distribution
// Floats are uniform-logarithmically distributed, in a manner of speaking
// Within an exponent range, the distribution of numbers is uniform
// Smaller values pack more in.
float logStratifiedSampler(float min, float max) {
    // Convert to double for precision
    double d_min = (double)min;
    double d_max = (double)max;

    // Generate a random value in [0, 1)
    double x = (double)rand() / ((double)RAND_MAX + 1);

    // Map the random value to the logarithmic scale
    double log_min = log(d_min);
    double log_max = log(d_max);
    double log_sample = log_min + x * (log_max - log_min);

    // Convert back to linear scale
    return (float)exp(log_sample);
}

// Integer sampling
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
