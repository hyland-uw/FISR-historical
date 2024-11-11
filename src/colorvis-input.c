#include <stdint.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <float.h>
#include "timelines.h"
#include "utility.h"

// these will eventually be stored for display
// the invalid_float field is used to indicate that the
// initial approximation was not a valid float and is
// not displayed but makes it easy for the below
// function to return it
typedef struct FISR_Result {
    float inverse_sqrt;
    float initial_approx;
    int iteration_count;
    int invalid_float;
} FISR_Result;

FISR_Result fast_inverse_sqrt(float input, int32_t magic, float tolerance, int max_NR_iters) {
    FISR_Result result;
    int step_count = 0;
    // set reference float for comparison
    float target_value = 1.0f / sqrt(input);

    union {
        float    f;
        uint32_t i;
    } conv = { .f = input };
    // First approximation
    conv.i  = magic - (conv.i >> 1);
    
    // Newton-Raphson iteration with tolerance and maximum steps
    do {
        conv.f *= (1.5F - (input * 0.5F * conv.f * conv.f));
        if (step_count < 1) {
            result.initial_approx = conv.f;
        }
        step_count++;
    } while (fabs(conv.f - target_value) > tolerance && step_count < max_NR_iters);
 
    result.inverse_sqrt = conv.f;
    result.iteration_count = step_count;

    return result;
}


void generate_timelines(uint32_t magic, int max_NR_iters, float tolerance, int timelines, float flt_min, float flt_max) {
    float ref, input, final_error, prior_error, initial_error;
    int iters, steps, flipped;
    uint32_t stored_magic = magic;
    int current_timeline = 1;


    
    double init_probabilities[FLOATSLICE] = {0};
    create_prob_array(init_probabilities);
    // define these now. They will be updated later
    double probabilities[FLOATSLICE] = {0};
    double prob_cache[FLOATSLICE] = {0};


    srand(time(NULL));
    printf("input, initial_error, final_error, prior_error, magic, iters, flipped, steps, current_timeline\n");
    while (current_timeline <= timelines) {
        // starts with the baseline distribution
        copy_array(probabilities, init_probabilities);
        iters = 0;
        steps = 0;
        prior_error = 0;

        while (iters < max_NR_iters) {
            input = uniformDraw(flt_min, flt_max);
            FISR_Result results = fast_inverse_sqrt(input, magic, tolerance, max_NR_iters);


            // compute errors
            ref = 1 / sqrtf(input);
            final_error = fabs(ref - results.inverse_sqrt);
            initial_error = fabs(ref - results.initial_approx);
            iters = results.iteration_count;

            // we don't have a prior error for the first step
            // so we skip printing it 
            // We need to assign final error and steps twice which
            // is awkward
            if (steps == 0) {
                prior_error = final_error;
                steps++;
                continue;
            }
            printf("%f,%f,%f,%f,0x%08x,%d,%d,%d,%d\n", input, initial_error, final_error, prior_error, magic, iters, flipped, steps, current_timeline);
            prior_error = final_error;

            // mutate the magic number
            flipped = choose_mutation_index(probabilities);
            magic ^= (1 << flipped);
            redistribute_probabilities(probabilities, flipped, init_probabilities);

            steps++;
        }
        current_timeline++;
        magic = stored_magic;
    }
}

int main() {
    // Common generation parameters
    uint32_t magic = 0x5f37642f;
    // It appears that for > 105 iterations,
    // the algorithm is unlikely to converge.
    int max_NR_iters = 10;
    // Need to play around with this
    // Might need to pick a power of 2
    float tolerance = 0.0024f;
    // More than this seems to be unhelpful
    int timelines = 55;
    // This is (arguably) one period of the 
    // approximation--from 2^-1 to 2^1
    // Any other crossing of an even binary power of 2 will do
    float flt_min = 0.5f;
    float flt_max = 2.0f;

    generate_timelines(magic, max_NR_iters, tolerance, timelines, flt_min, flt_max);

    return 0;
}