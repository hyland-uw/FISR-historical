#include "util-harness.h"

#define MAGIC_CONSTANT 0x5F400000
#define GRID_SIZE 8
#define GRID_STEP 0.0075f
#define MAX_NR_ITERS 10

typedef struct {
    float A;        // First coefficient
    float B;        // Second coefficient
} NRParams;

typedef struct {
    float error;
    int iter;
} IterationResult;

typedef struct {
    float input;
    NRParams params;
    IterationResult iterations[MAX_NR_ITERS];
} Result;

typedef struct {
    float input;
    Result results[GRID_SIZE*GRID_SIZE];
} ResultBlock;

float A_grid[GRID_SIZE];
float B_grid[GRID_SIZE];

void initialize_grids(float A_center, float B_center, float half_extent) {
    for (int i = 0; i < GRID_SIZE; i++) {
        A_grid[i] = A_center + ((float)rand() / (float)RAND_MAX - 0.5f) * half_extent;
        B_grid[i] = B_center + ((float)rand() / (float)RAND_MAX - 0.5f) * half_extent;
    }
}

float computeNR(float x, float y, NRParams params, IterationResult* results) {
    for (int i = 0; i < MAX_NR_ITERS; i++) {
        y = y * (params.A - params.B * x * y * y);
        results[i].error = fabsf(y - 1.0f / sqrtf(x)) / (1.0f / sqrtf(x));
        results[i].iter = i + 1;
    }
    return y;
}

void compute_result_block(float input, ResultBlock* block) {
    int results_counter = 0;
    union { float f; uint32_t u; } y = {input};
    y.u = MAGIC_CONSTANT - (y.u >> 1);

    for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
            NRParams params = {.A = A_grid[i], .B = B_grid[j]};
            Result* result = &block->results[results_counter++];
            result->input = input;
            result->params = params;
            computeNR(input, y.f, params, result->iterations);
        }
    }
}

void print_result_block(const ResultBlock* block) {
    for (int i = 0; i < GRID_SIZE*GRID_SIZE; i++) {
        const Result* result = &block->results[i];
        for (int j = 0; j < MAX_NR_ITERS; j++) {
            printf("%e,%e,%e,%e,%d\n",
                   result->input,
                   result->params.A,
                   result->params.B,
                   result->iterations[j].error,
                   result->iterations[j].iter);
        }
    }
    printf("\n");
}

int main() {
    srand(time(NULL));
    // set up search params
    const float A_center = 1.5f;
    const float B_center = 0.5f;
    const float half_extent = (GRID_SIZE * GRID_STEP) / 2;
    initialize_grids(A_center, B_center, half_extent);
    // determine the size of the search
    const int samples = 1024;
    float inputs[samples];

    printf("input,A,B,error,iter\n");
    ResultBlock* result_blocks = malloc(samples * sizeof(ResultBlock));
    #pragma omp parallel for
    for (int j = 0; j < samples; j++) {
        inputs[j] = logStratifiedSampler(FLOAT_START, FLOAT_END);
        compute_result_block(inputs[j], &result_blocks[j]);
        print_result_block(&result_blocks[j]);
    }

    free(result_blocks);
    return 0;
}
