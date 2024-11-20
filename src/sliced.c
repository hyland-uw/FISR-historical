#include "sampling-harness.h"

void single_float_search(float input, uint32_t samples) {
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
        for (uint32_t i = 0; i < samples; i++) {
            uint32_t magic = sample_integer_range(MIN_INT, MAX_INT);
            approx = minimal_rsqrt(input, magic, 1);
            error = fabsf(approx - reference) / reference;

            results[i].error = error;
            results[i].magic = magic;
        }
    }

    // Print results after parallel region
    for (uint32_t i = 0; i < samples; i++) {
        printf("%e, %e, 0x%08X\n", input, results[i].error, results[i].magic);
    }

    free(results);
}

void split_float_range(float start, float end, uint32_t slices, uint32_t samples) {
    float current;
    printf("input, error, magic\n");
    for (uint32_t i = 0; i < slices; i++) {
        current = reciprocalRange(start, end);
        single_float_search(current, samples);
    }
}

int main() {
    srand(time(NULL));
    split_float_range(FLOAT_START, FLOAT_END, FLOAT_VIS_SLICES, INTEGER_SAMPLES_PER_SLICE);
    return 0;
}
