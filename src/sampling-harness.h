#ifndef FISR_HARNESS_H
#define FISR_HARNESS_H

#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>

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
uint32_t generate_sample(uint32_t input, int scale) {
    double t = random_student_t();

    // Scale the t-distribution value
    // Adjust this scaling factor to control the spread
    // 1000000 is a good value for scale
    int32_t offset = (int32_t)(t * scale);

    // Add the offset to the input, wrapping around if necessary
    return (uint32_t)((int64_t)input + offset);
}

// Harness Function prototype
typedef struct Harness {
    float input, reference, output, initial_approx;
    int NR_iters;
    bool invalid_float_reached;
} Harness;

Harness fast_rsqrt(float x, int NRmax, uint32_t magic, float halfthree, float halfone);

// Sampling function prototype
void sample_fast_rsqrt(int draws, int NRmax, int scale, uint32_t base_magic, float min, float max);

#endif // FISR_HARNESS_H
