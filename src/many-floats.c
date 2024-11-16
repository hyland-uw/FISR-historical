#include "sampling-harness.h"
#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <float.h>
#include <time.h>
#include <omp.h>

#define NUM_FLOATS 131072 // Number of floats to process for full float search
#define INTEGER_SAMPLES 8192 // number of samples per float


// values above or below these are usually poor sources of approximations.
#define MIN_INT 1560000000
#define MAX_INT 1610000000

void full_float_search(int floats, int samples) {

    // Struct to store results
    struct Result {
        float input;
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
        for (int i = 0; i < floats; i++) {

            float approx, error, best_error;
            uint32_t magic;
            uint32_t best_magic = 0x5f3759df;

            float input = reciprocalRange(FLOAT_START, FLOAT_END);

            float reference = 1.0f / sqrtf(input);
            best_error = fabsf(minimal_rsqrt(input, best_magic) - reference) / reference;

            for (int k = 0; k <= samples; k++) {
                magic = sample_integer_range(MIN_INT, MAX_INT);
                approx = minimal_rsqrt(input, magic);
                error = fabsf(approx - reference) / reference;
                if (error <= best_error) {
                    best_error = error;
                    best_magic = magic;
                }
            }

            // Store results in the array
            results[i].input = input;
            results[i].magic = best_magic;
        }
    }

    // Print results after parallel region
    for (int i = 0; i < floats; i++) {
        printf("%e, 0x%08X\n", results[i].input, results[i].magic);
    }
    free(results);
}

int main() {
    srand(time(NULL));

    printf("input, magic\n");
    full_float_search(NUM_FLOATS, INTEGER_SAMPLES);

    return 0;
}
