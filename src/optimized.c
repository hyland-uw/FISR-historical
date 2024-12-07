#include "util-harness.h"

#define MAGIC_CONSTANT 0x5F400000

typedef struct {
    float A;        // First coefficient
    float B;        // Second coefficient
} NRParams;

typedef struct {
    float input;
    NRParams params;
    float error;
} Result;

typedef struct {
    float input;
    Result results[GRID_SIZE*GRID_SIZE];
} ResultBlock;

float A_grid[GRID_SIZE];
float B_grid[GRID_SIZE];

float computeNR(float input, NRParams params) {
    union { float f; uint32_t u; } y = {input};
    y.u = MAGIC_CONSTANT - (y.u >> 1);
    y.f = y.f * (params.A - params.B * input * y.f * y.f);
    return y.f;
}

void compute_result_block(float input, ResultBlock* block) {
    float approx, error, system;
    int results_counter = 0;
    system = 1.0f / sqrtf(input);

    for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
            NRParams params = {.A = A_grid[i], .B = B_grid[j]};
            approx = computeNR(input, params);
            error = fabsf((approx - system) / system);

            block->results[results_counter++] = (Result){
                .input = input,
                .params = params,
                .error = error
            };
        }
    }
}

void print_result_block(const ResultBlock* block) {
    for (int i = 0; i < GRID_SIZE*GRID_SIZE; i++) {
        float constraint_deviation = block->results[i].params.A * (block->results[i].params.B - 1.0f) - 1.0f;
        printf("%e,%e,%e,%e,%e\n",
               block->results[i].input,
               block->results[i].params.A,
               block->results[i].params.B,
               block->results[i].error,
               constraint_deviation);
    }
    printf("\n");
}

void initialize_grids(float A_center, float B_center, float half_extent) {
    for (int i = 0; i < GRID_SIZE; i++) {
        A_grid[i] = A_center + ((float)rand() / (float)RAND_MAX - 0.5f) * half_extent;
        B_grid[i] = B_center + ((float)rand() / (float)RAND_MAX - 0.5f) * half_extent;
    }
}

void generate_input_samples(float* inputs, int count) {
    for (int i = 0; i < count; i++) {
        inputs[i] = logStratifiedSampler(FLOAT_START, FLOAT_END);
    }
}

void compute_all_result_blocks(float* inputs, ResultBlock* result_blocks, int count) {
    #pragma omp parallel for
    for (int j = 0; j < count; j++) {
        compute_result_block(inputs[j], &result_blocks[j]);
    }
}

void print_all_result_blocks(ResultBlock* result_blocks, int count) {
    printf("input,A,B,error,constraint_deviation\n");
    for (int j = 0; j < count; j++) {
        print_result_block(&result_blocks[j]);
    }
}

int main() {
    srand(time(NULL));

    const float A_center = 1.5f;
    const float B_center = 0.5f;
    const float half_extent = (GRID_SIZE * GRID_STEP) / 2;
    const int samples = FLOAT_SLICES  / 2;
    initialize_grids(A_center, B_center, half_extent);

    float inputs[samples];
    generate_input_samples(inputs, samples);

    ResultBlock* result_blocks = malloc(samples * sizeof(ResultBlock));
    compute_all_result_blocks(inputs, result_blocks, samples);

    print_all_result_blocks(result_blocks, samples);

    free(result_blocks);
    return 0;
}
