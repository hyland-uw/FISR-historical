#include "sampling-harness.h"

void full_float_search(int float_slices, int int_samples) {
    printf("input, system, NR0, magic\n");
    #pragma omp parallel
    {
        #pragma omp for
        for (int i = 0; i < float_slices; i++) {
            float approx, error, best_error;
            float best_NR0, system;
            uint32_t magic;
            float input = uniformRange(FLOAT_START, FLOAT_END);

            system = 1.0f / sqrtf(input);

            best_error = INFINITY;
            // Choose the naive restoring constant first
            uint32_t best_magic = 0x5F400000;
            for (int k = 0; k < int_samples; k++) {
                magic = sample_integer_range(MIN_INT, MAX_INT);
                // Inlined minimal_rsqrt
                union { float f; uint32_t u; } y = {input};
                y.u = magic - (y.u >> 1);
                approx = y.f;
                error = fabsf(approx - system) / system;
                if (error < best_error) {
                    best_NR0 = approx;
                    best_error = error;
                    best_magic = magic;
                }
            }
            // Print results directly, without a critical section
            // The order lines are printed doesn't matter directly.
            printf("%e,%e,%e,0x%08X\n", input, system, best_NR0, best_magic);
        }
    }
}

int main() {
    srand(time(NULL));
    full_float_search(NUM_FLOATS, MAGIC_CONSTANT_DRAWS);
    return 0;
}
