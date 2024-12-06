#include "util-harness.h"

// Structure to hold the error and magic number for each approximation
struct Result {
    float error;
    uint32_t magic;
};

// Structure to hold an array of Results and its length
struct SearchResult {
    struct Result *results;
    uint32_t length;
};

// Comparison function for qsort to sort Results by error
int compare_results(const void *a, const void *b) {
    const struct Result *ra = (const struct Result *)a;
    const struct Result *rb = (const struct Result *)b;
    if (ra->error < rb->error) return -1;
    if (ra->error > rb->error) return 1;
    return 0;
}

// Function to search for the best magic numbers for a single float input
struct SearchResult single_float_search(float input, uint32_t samples, uint32_t select) {
    float reference = 1.0f / sqrtf(input);
    float error, approx;
    struct Result *results = malloc(samples * sizeof(struct Result));
    if (results == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        return (struct SearchResult){NULL, 0};
    }

    // Parallel computation of errors for different magic numbers
    #pragma omp parallel
    #pragma omp for
    for (uint32_t i = 0; i < samples; i++) {
        uint32_t magic = sample_integer_range(MIN_INT, MAX_INT);
        approx = minimal_rsqrt(input, magic, 1);
        error = fabsf(approx - reference) / reference;
        results[i].error = error;
        results[i].magic = magic;
    }

    // Sort the results by lowest error
    qsort(results, samples, sizeof(struct Result), compare_results);

    // Select the top 'select' results
    uint32_t length = (select < samples) ? select : samples;
    struct Result *selected_results = malloc(length * sizeof(struct Result));
    if (selected_results == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        free(results);
        return (struct SearchResult){NULL, 0};
    }

    for (uint32_t i = 0; i < length; i++) {
        selected_results[i] = results[i];
    }

    free(results);
    return (struct SearchResult){selected_results, length};
}

// Function to sample a range of float inputs and find best magic numbers for each
void sample_float_range(float start, float end, uint32_t slices, uint32_t samples, uint32_t select) {
    #pragma omp parallel
    #pragma omp for schedule(dynamic, CHUNK_SIZE)
    for (uint32_t i = 0; i < slices; i++) {
        float input = logStratifiedSampler(start, end);
        struct SearchResult result = single_float_search(input, samples, select);

        // Critical section to ensure thread-safe printing of results
        #pragma omp critical
        for (uint32_t j = 0; j < result.length; j++) {
            printf("%.9e,%.9e,%u\n", input, result.results[j].error, result.results[j].magic);
        }

        free(result.results);
    }
}

int main() {
    srand(time(NULL));
    printf("input, error, magic\n");
    sample_float_range(FLOAT_START, FLOAT_END, FLOAT_VIS_SLICES, INTEGER_SAMPLES_PER_SLICE, INTEGER_SELECTIONS);
    return 0;
}
