#ifndef FISR_HARNESS_H
#define FISR_HARNESS_H

#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>

#define FLOAT_START FLT_MIN
#define FLOAT_END 0.75f


// Smooth generation of random floats in a range
// by dividing doubles then casting
float uniformRange (float min, float max) {
    double x;
    float Urand;
    x = (double)rand() / (double)((unsigned)RAND_MAX + 1);
    Urand = (float) x;
    return (max - min) * Urand + min;
}

//Draw for a reciprocal distribution https://en.wikipedia.org/wiki/Reciprocal_distribution
float reciprocalRange (float min, float max) {
    double x;
    float Urand;
    x = (double)rand() / (double)((unsigned)RAND_MAX + 1);
    Urand = (float) 1 - x;
    //Inverse CDF of the reciprocal distribution
    return powf(max/min, x) * min;
}


//// The below random_normal() and random_students_t() serve our
//// integer sampler, generate_sample

// Box-Muller transform to generate normally distributed numbers
// Used to generate a student's t.
double random_normal() {
    double u1 = (double)rand() / RAND_MAX;
    double u2 = (double)rand() / RAND_MAX;
    return sqrt(-2 * log(u1)) * cos(2 * M_PI * u2);
}

// Generate a number from Student's t-distribution with 3 degrees of freedom
// We choose this for a simple "wide tailed" distribution
double random_student_t() {
    double x = random_normal();
    double y = random_normal();
    double z = random_normal();
    return x / sqrt((y*y + z*z) / 3);
}

// Generate a sample based on the input number
// We are sampling integers, not floats.
uint32_t generate_integer_sample(uint32_t input) {
    double t = random_student_t();
    uint32_t scale = 1000000;
    // Scale the t-distribution value
    // Adjust this scaling factor to control the spread
    // 1000000 is a good value for scale
    int32_t offset = (int32_t)(t * scale);

    // Add the offset to the input, wrapping around if necessary
    return (uint32_t)((int64_t)input + offset);
}

uint32_t sample_integer_range(uint32_t min, uint32_t max) {
    double t = random_student_t();
    uint32_t scale = 1000000;
    // Calculate the range
    uint32_t range = max - min + 1;

    // Scale the t-distribution value
    int64_t offset = (int64_t)(t * scale);

    // Add the offset to the middle of the range, then wrap around
    int64_t sample = min + range / 2 + offset;

    // Wrap around if necessary
    while (sample < (int64_t)min) {
        sample += range;
    }
    while (sample > (int64_t)max) {
        sample -= range;
    }

    return (uint32_t)sample;
}

// minimal float which accepts an input magic and returns only a float
float minimal_rsqrt(float input, uint32_t magic) {
    union { float f; uint32_t u; } y = {input};
    y.u = magic - (y.u >> 1);
    // Not all versions use the NR formula y * 1.5 -(0.5 * x * y^2) but most do.
    return y.f * (1.5f - 0.5f * input * y.f * y.f);
}


// Harness to capture information for visualization
typedef struct deconHarness {
    float input, reference, output, initial_approx;
    int NR_iters;
    bool invalid_float_reached;
} deconHarness;
deconHarness decon_rsqrt(float x, int NRmax, uint32_t magic, float tol);

// Sampling function prototype
void sample_fast_rsqrt(int draws, int NRmax, uint32_t base_magic, float min, float max);

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
