#include "util-harness.h"

typedef struct {
    float input;
    float y_naught;
    float halfthree;
    float halfone;
    float error;
} Result;

typedef struct {
    float input;
    Result results[GRID_SIZE*GRID_SIZE];
} ResultBlock;


float x_grid[GRID_SIZE];
float y_grid[GRID_SIZE];

void compute_result_block(float input, uint32_t magic, ResultBlock* block) {
    float halfthree, halfone, approx, error, system, y_naught;
    int results_counter = 0;
    // Calculate system and y_naught once for this input
    system = 1.0f / sqrtf(input);
    union { float f; uint32_t u; } y = {input};
    y.u = magic - (y.u >> 1);
    y_naught = y.f;

    for (int i = 0; i < GRID_SIZE; i++) {
        halfthree = x_grid[i];
        for (int j = 0; j < GRID_SIZE; j++) {
            halfone = y_grid[j];
            approx = y.f * (halfthree - halfone * input * y.f * y.f);
            error = fabsf((approx - system) / system);
            block->results[results_counter] = (Result){input, y_naught, halfthree, halfone, error};
            results_counter++;
        }
    }
}

void print_result_block(const ResultBlock* block) {
    for (int i = 0; i < GRID_SIZE*GRID_SIZE; i++) {
        printf("%e,%e,%e,%e,%e\n",
               block->results[i].input,
               block->results[i].y_naught,
               block->results[i].halfthree,
               block->results[i].halfone,
               block->results[i].error);
    }
    printf("\n");
}

int main() {
    srand(time(NULL));

    // Generate fixed grid
    const float half_extent = (GRID_SIZE * GRID_STEP) / 2;
    for (int i = 0; i < GRID_SIZE; i++) {
        x_grid[i] = (1.5 - half_extent) + i * GRID_STEP;
        y_grid[i] = (0.5 - half_extent) + i * GRID_STEP;
    }

    // Generate range of inputs
    float inputs[FLOAT_SLICES];
    for (int i = 0; i < FLOAT_SLICES; i++) {
        inputs[i] = logStratifiedSampler(FLOAT_START, FLOAT_END);
    }

    // Compute results in parallel and store in an object
    ResultBlock* result_blocks = malloc(FLOAT_SLICES * sizeof(ResultBlock));
    #pragma omp parallel for
    for (int j = 0; j < FLOAT_SLICES; j++) {
        compute_result_block(inputs[j], 0x5f3759df, &result_blocks[j]);
    }

    // Print results as they come in
    printf("input,initial,halfthree,halfone,error\n");
    for (int j = 0; j < FLOAT_SLICES; j++) {
        print_result_block(&result_blocks[j]);
    }

    free(result_blocks);
    return 0;
}
