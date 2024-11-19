#include "sampling-harness.h"

typedef struct {
    float input;
    float halfthree;
    float halfone;
    float error;
} Result;

void test_half_values(uint32_t slices, uint32_t magic) {
    Result results[MAX_RESULTS];
    int result_count = 0;

    #pragma omp parallel
    {
        Result local_results[MAX_RESULTS / omp_get_max_threads()];
        int local_count = 0;

        #pragma omp for
        for (uint32_t i = 0; i < slices; i++) {
            float input = reciprocalRange(FLOAT_START, FLOAT_END);
            union { float f; uint32_t u; } y = {input};
            y.u = magic - (y.u >> 1);
            float system = 1.0f / sqrtf(input);

            for (float halfthree = 1.3f; halfthree <= 1.65f; halfthree += 0.05f) {
                for (float halfone = 0.3f; halfone <= 0.7f; halfone += 0.05f) {
                    float yf_temp = y.f * (halfthree - halfone * input * y.f * y.f);
                    float error = fabsf((yf_temp - system) / system); // Changed to relative error

                    if (local_count < MAX_RESULTS / omp_get_max_threads()) {
                        local_results[local_count].input = input;
                        local_results[local_count].halfthree = halfthree;
                        local_results[local_count].halfone = halfone;
                        local_results[local_count].error = error;
                        local_count++;
                    }
                }
            }
        }

        #pragma omp critical
        {
            for (int i = 0; i < local_count && result_count < MAX_RESULTS; i++) {
                results[result_count++] = local_results[i];
            }
        }
    }

    // Print results
    printf("input,halfthree,halfone,error\n");
    for (int i = 0; i < result_count; i++) {
        printf("%e,%.2f,%.2f,%e\n", results[i].input, results[i].halfthree, results[i].halfone, results[i].error);
    }
}


int main() {
    srand(time(NULL));
    test_half_values(FLOAT_SLICES/2, 0x5f3759df);
    return 0;
}
