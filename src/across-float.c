#include "sampling-harness.h"
#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <float.h>
#include <omp.h>

#define FLOAT_SLICES 512 // number of single_float_search()
#define INTEGER_SAMPLES 4096 // number of integers to sample for single float search

// values above or below these are usually poor sources of approximations.
#define MIN_INT 1568000000
#define MAX_INT 1612000000

void single_float_search(float input, int samples) {
    float reference = 1.0f / sqrtf(input);

    float error, approx;
    struct Result {
        float error;
        uint32_t magic;
    };
    struct Result *results = malloc(samples * sizeof(struct Result));
    if (results == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        return;
    }

    #pragma omp parallel
    {
        #pragma omp for
        for (int i = 0; i < samples; i++) {
            uint32_t magic = sample_integer_range(MIN_INT, MAX_INT);
            approx = minimal_rsqrt(input, magic);
            error = fabsf(approx - reference) / reference;

            results[i].error = error;
            results[i].magic = magic;
        }
    }

    // Print results after parallel region
    for (int i = 0; i < samples; i++) {
        printf("%e, %e, 0x%08X\n", input, results[i].error, results[i].magic);
    }

    free(results);
}

int main() {
    float current;
    printf("float, error, magic\n");
    for (int i = 0; i < FLOAT_SLICES; i++) {
        current = reciprocalRange(FLOAT_START, FLOAT_END);
        single_float_search(current, INTEGER_SAMPLES);
    }
    return 0;
}
