#include "util-harness.h"

typedef struct {
    float input;
    float error;
    float NR0;
    uint32_t exponent;
    uint32_t magic;
    const char* type; // Added to store type (min, median, max)
} Extraction;

void initialize_extraction(Extraction *result, int exponent, const char *type) {
    result->exponent = exponent;
    result->error = FLT_MAX;
    result->type = type; // Set the type
}

void exponent_search(int exponent, uint32_t samples, Extraction results[3]) {
    // Initialize results for min, median, max
    initialize_extraction(&results[0], exponent, "min");
    initialize_extraction(&results[1], exponent, "median");
    initialize_extraction(&results[2], exponent, "max");

    uint32_t baseline_magic = 0x5f3759df;

    // Promote min and max to handle median without overflow
    double min_float = (double)min_max_float_with_exponent(exponent, false);
    double max_float = (double)min_max_float_with_exponent(exponent, true);
    // Calculate the median using double precision
    double median_float = (min_float + max_float) * 0.5;

    // Return to float for our routine, which relies on the structure in memory of a float (not a double)
    float test_floats[3] = {(float)min_float, (float)median_float, (float)max_float};

    for (int i = 0; i < 3; i++) {
        float input = test_floats[i];
        float baseline_result = minimal_rsqrt(input, baseline_magic, 1);

        for (uint32_t k = 0; k < samples; k++) {
            uint32_t magic = sample_integer_range(MIN_INT, MAX_INT);

            union { float f; uint32_t u; } y = {input};
            y.u = magic - (y.u >> 1);
            float approx = y.f;
            float error = fabsf(approx - baseline_result) / baseline_result;

            if (error < results[i].error) {
                results[i].input = input;
                results[i].NR0 = approx;
                results[i].error = error;
                results[i].magic = abs_uint_diff(baseline_magic, magic);
            }
        }
    }
}

void sample_and_test_exponents(uint32_t slices) {
    // Print CSV header
    printf("input,exponent,type,magic_vs_fixed,approx,error_vs_fixed\n");

    // Loop through all possible exponent values (1 to 254)
    for (int exp = 1; exp <= 254; exp++) {
        Extraction results[3];
        exponent_search(exp, slices, results); // Get results

        // Print results in CSV format for all three types
        for (int i = 0; i < 3; i++) {
            printf("%.9e,%d,%s,0x%08X,%.9e,%.9e\n",
                   results[i].input,
                   results[i].exponent,
                   results[i].type,
                   results[i].magic,
                   results[i].NR0,
                   results[i].error);
        }
    }
}

int main() {
    srand(time(NULL));
    sample_and_test_exponents(FLOAT_SLICES);
    return 0;
}
