#include "util-harness.h"

#define NUM_FLOATS 131072 // Number of floats to process (131072 is good)
#define MAGIC_CONSTANT_DRAWS 32768 // number of integer constant samples per float

typedef struct {
    float input;
    float system;
    float NR0;
    float final;
    uint32_t magic;
} Result;

void full_float_search(int float_slices, int int_samples) {
    Result* results = malloc(float_slices * sizeof(Result));
    float inputrange[float_slices];
    for (int i = 0; i < float_slices; i++) {
        inputrange[i] = logStratifiedSampler(FLOAT_START, FLOAT_END);
    }

    #pragma omp parallel
    {
        #pragma omp for
        for (int i = 0; i < float_slices; i++) {
            float approx, error, best_error;
            float best_NR0, system, final, best_final;
            uint32_t magic;
            float input = inputrange[i];

            system = 1.0f / sqrtf(input);

            best_error = INFINITY;
            uint32_t best_magic = 0x5F400000;

            for (int k = 0; k < int_samples; k++) {
                magic = sample_integer_range(MIN_INT, MAX_INT);
                union { float f; uint32_t u; } y = {input};
                y.u = magic - (y.u >> 1);
                approx = y.f;
                final = y.f * (1.5f - 0.5f * input * y.f * y.f);
                error = fabsf(final - system) / system;
                if (error < best_error) {
                    best_NR0 = approx;
                    best_final = final;
                    best_error = error;
                    best_magic = magic;
                }
            }

            results[i] = (Result){
                .input = input,
                .system = system,
                .NR0 = best_NR0,
                .final = best_final,
                .magic = best_magic
            };
        }
    }

    printf("input,reference,initial,final,magic\n");
    for (int i = 0; i < float_slices; i++) {
        printf("%e,%e,%e,%e,0x%08X\n",
               results[i].input,
               results[i].system,
               results[i].NR0,
               results[i].final,
               results[i].magic);
    }

    free(results);
}

int main() {
    srand(time(NULL));
    full_float_search(NUM_FLOATS, MAGIC_CONSTANT_DRAWS);
    return 0;
}
