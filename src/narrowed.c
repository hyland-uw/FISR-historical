#include "util-harness.h"

// 0x5f37642f +/- 4000
#define INT_LO 1597461647
#define INT_HI 1597469647

// This is a temporary solution to generate a plot comparing very close
// FISR approximation magic constants. It works by copying out the
// deconstructed flow with some changes for a much narrower search.
// Ideally this would be a variation within the interface provided by deconstructed.c


/*
This harness allows us to deconstruct the working and output of an idealized FISR.

The main purpose of this is to visualize the result of selecting both the
input and the magic constant at random, so the space of possible choices is seen.

Unlike in the individual methods, the FISR is allowed to converge and the
iterations required for convergence is stored.

Unions are used to avoid type punning, so this code should work at all
levels of compiler optimization.
*/

narrowHarness narrow_decon_rsqrt(float x, uint32_t magic, float tol) {
    GeneralizedHarness result = generalized_rsqrt(x, 2, magic, tol, false);

    narrowHarness harness_result;
    harness_result.input = x;
    harness_result.reference = result.reference;
    harness_result.initial_approx = result.initial_approx;
    harness_result.output = result.output;
    harness_result.NR_iters = result.NR_iters;
    harness_result.invalid_float_reached = result.invalid_float_reached;

    return harness_result;
}

typedef struct {
    float input;
    float reference;
    float initial_approx;
    float output;
    unsigned int NR_iters;
    uint32_t magic;
} SampleResult;

void total_decon_rsqrt(uint32_t int_min, uint32_t int_max, float min, float max, float tol) {
    uint32_t int_width = int_max - int_min;
    SampleResult* results = malloc(sizeof(SampleResult) * int_width);
    uint32_t valid_results = 0;
    float* inputrange = malloc(sizeof(float) * int_width);

    for (uint32_t i = 0; i < int_width; i++) {
        inputrange[i] = logStratifiedSampler(min, max);
    }

    #pragma omp parallel
    {
        // Allocate local results with sufficient size
        SampleResult* local_results = malloc(sizeof(SampleResult) * int_width);
        uint32_t local_valid_results = 0;

        #pragma omp for
        for (uint32_t i = int_min; i < int_max; i++) {
            float x = inputrange[i - int_min];  // Adjust index to match inputrange
            uint32_t magic = i;

            narrowHarness result = narrow_decon_rsqrt(x, magic, tol);

            if (!result.invalid_float_reached) {
                SampleResult sample = {
                    .input = x,
                    .reference = result.reference,
                    .initial_approx = result.initial_approx,
                    .output = result.output,
                    .NR_iters = result.NR_iters,
                    .magic = magic
                };
                local_results[local_valid_results++] = sample;
            }
        }

        // Merge local results into global results
        #pragma omp critical
        {
            for (uint32_t i = 0; i < local_valid_results && valid_results < int_width; i++) {
                results[valid_results++] = local_results[i];
            }
        }

        free(local_results);
    }

    // Print results
    printf("input,reference,initial,final,iters,magic\n");
    for (uint32_t i = 0; i < valid_results; i++) {
        printf("%f,%f,%f,%f,%u,0x%08X\n",
               results[i].input,
               results[i].reference,
               results[i].initial_approx,
               results[i].output,
               results[i].NR_iters,
               results[i].magic);
    }

    free(inputrange);
    free(results);
}

// Main function calls the sampler which
// outputs via printf for a csv
int main() {
    srand(time(NULL));
    total_decon_rsqrt(INT_LO, INT_HI, FLOAT_START, FLOAT_END, 0.00024f);
    return 0;
}
