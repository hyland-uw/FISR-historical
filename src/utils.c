#include "util-harness.h"

GeneralizedHarness generalized_rsqrt(float x, int NRmax, uint32_t magic, float tol, bool track_after_one) {
    GeneralizedHarness result;

    // Compute a reference inverse square root
    result.reference = 1.0f / sqrtf(x);

    // Track if we reach a state which won't plot well
    result.invalid_float_reached = false;

    // The input is given two simultaneous representations:
    union { float f; uint32_t u; } y = {x};

    // Manipulate the bitfield as an integer and restore the bits in the exponent
    y.u = magic - (y.u >> 1);

    // Extract the floating point representation
    result.initial_approx = y.f;
    result.after_one = NAN; // Initialize as NAN

    // Perform Newton-Raphson iterations
    int iters = 0;
    while (iters < NRmax) {
        y.f = y.f * (1.5f - 0.5f * x * y.f * y.f);
        iters++;
        if (track_after_one && iters == 1) {
            result.after_one = y.f;
        }
        if (fabs(y.f - result.reference) < tol) {
            break;
        }
    }
    result.output = y.f;
    result.NR_iters = iters;

    // Check for invalid floats
    if (!isnormal(result.initial_approx) || !isnormal(result.output) || (track_after_one && !isnormal(result.after_one))) {
        result.invalid_float_reached = true;
    }

    return result;
}

// Absolute difference of unisgned integers
// See https://stackoverflow.com/q/77337671
uint32_t abs_uint_diff(uint32_t a, uint32_t b) {
    return (a > b) ? (a - b) : (b - a);
}

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

// Extract exponent bits
uint32_t exp_extract(float input) {
    uint32_t exponent;
    // Use a union to access the bits of the float
    union {
        float f;
        uint32_t i;
    } u;
    u.f = input;

    // Extract the exponent (biased)
    exponent = ((u.i >> 23) & 0xFF) - 127;

    return exponent;
}

// Given a specific exponent, sample within the fraction range
float random_float_with_exponent(uint32_t exponent) {
    union {
        float f;
        uint32_t i;
    } u;

    // Generate a random mantissa
    uint32_t mantissa = (uint32_t)rand() & 0x7FFFFF;

    // Construct the float
    u.i = (exponent << 23) | mantissa;

    return u.f;
}

float min_max_float_with_exponent(int exponent, bool is_max) {
    exponent = exponent - 127;
    if (exponent < -126 || exponent > 127) {
        // Handle out-of-range exponents
        return 0.0f;  // or NaN, depending on your preference
    }

    union {
        float f;
        uint32_t i;
    } u;

    if (exponent == -126 && !is_max) {
        // Special case: smallest normalized number
        u.i = 0x00800000;
    } else {
        // Construct the float:
        // Sign bit: 0 (positive)
        // Exponent: biased exponent (add 127)
        // Fraction: all zeros for min, all ones for max
        u.i = (uint32_t)(exponent + 127) << 23;
        if (is_max) {
            u.i |= 0x007FFFFF;  // Set all fraction bits to 1 for max
        }
    }

    return u.f;
}
