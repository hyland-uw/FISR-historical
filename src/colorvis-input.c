#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include <stddef.h>
#include <time.h>


uint32_t flip_chosen_bit(uint32_t magic, uint16_t bit) {
    magic ^= 1 << (31 - bit);
    return magic;
}

void create_array32(double array[32]) {
    int i;
    for (i = 0; i < 32; i++) {
        array[i] = ldexp(1, -(32 - i));
    }
}

void create_gapped_array32(double array[32], int location) {
    int i;
    for (i = 0; i < 32; i++) {
        if (i == location) {
            array[i] = 0;
        } else {
            array[i] = ldexp(1, -(32 - i));
        }
    }
}

void compute_cumulative_sum(double arr[], double sum[]) {
    sum[0] = arr[0];
    for (int i = 1; i < 32; i++) {
        sum[i] = sum[i - 1] + arr[i];
    }
}

void multiply_array_by_scalar(double array[32], double scalar) {
    int i;
    for (i = 0; i < 32; i++) {
        array[i] *= scalar;
    }
}

void add_32_arrays(double left[32], double right[32], double output[32]) {
    int i;
    for (i = 0; i < 32; i++) {
        output[i] += left[i] + right[i];
    }
}

int choose_bit(double array[32]) {
  double cumsum[32] = { 0 };
  compute_cumulative_sum(array, cumsum);
  // https://stackoverflow.com/a/6219525
  double r = (double)rand() / (double)RAND_MAX;
  int i = 0;
  for (i = 0; i < 32; i++) {
    if (r <= cumsum[i]) {
      return i;
    }
  }
}

int mutate_and_advance(double array[32]) {
    double gapped[32];
    float chosen_prob;

    int bit = choose_bit(array);
    create_gapped_array32(gapped, bit);
    chosen_prob = array[bit];
    array[bit] = 0;
    multiply_array_by_scalar(gapped, chosen_prob);
    add_32_arrays(array, gapped, array);
    return bit;
}

typedef struct {
    int iterations_completed;
    float after_last_iter;
} Q_rsqrt_results;

Q_rsqrt_results Q_rsqrt_iter(float number, uint32_t magic, float tol, int iters) {
    union {
        float    f;
        uint32_t i;
    } conv = { .f = number };

    conv.i  = magic - (conv.i >> 1);

    int counter = 0;
    float ref = 1 / sqrtf(number);
  
    Q_rsqrt_results results = {0, 0, 0};

    while (counter < iters) {
        conv.f *= 1.5F - (number * 0.5F * conv.f * conv.f);
        results.iterations_completed = ++counter;
        results.after_last_iter = conv.f;
        if (fabsf(ref - conv.f) < tol) {
            break;
        }
    }
    return results;
}


int main() {
    uint32_t magic = 0x5f37642f;
    double array[32];
    int flipped;
    srand(time(NULL));
    float tol = 0.0005f;
    float flt_max = 2.0f;
    float flt_min = 0.25f;
    float ref, approx, input;
    int iter_limit = 100;
    int iters = 0;

    create_array32(array);

    printf("input,ref,approx,iters,flipped\n");
    while (iters < iter_limit) {
      input = flt_min + ((float)rand() / (float)RAND_MAX) * (flt_max - flt_min);
      Q_rsqrt_results results = Q_rsqrt_iter(input, magic, tol, iter_limit);
      ref = 1 / sqrtf(input);
      approx = results.after_last_iter;
      iters = results.iterations_completed;
      flipped = mutate_and_advance(array);
      magic = flip_chosen_bit(magic, flipped);
      printf("%f,%f,%f,%d,%d\n", input, ref, approx, iters, flipped);
    }
    
    return 0;
}

/* The path of one mutation.

input,ref,approx,iters,flipped
1.378260,0.851794,0.851793,2,30
1.586537,0.793916,0.793913,2,31
0.471355,1.456551,1.456550,2,28
1.395830,0.846416,0.846415,2,29
0.620060,1.269940,1.269934,2,26
1.460584,0.827440,0.827438,2,22
1.881172,0.729098,0.729097,2,23
0.306351,1.806717,1.806567,1,24
1.693480,0.768440,0.768437,2,25
1.651802,0.778074,0.778071,2,26
1.813196,0.742639,0.742637,2,19
1.877477,0.729815,0.729814,2,16
1.452443,0.829756,0.829753,2,18
1.010255,0.994911,0.994909,2,20
1.959349,0.714404,0.713989,1,15
1.061439,0.970627,0.970627,2,17
1.470807,0.824560,0.824559,2,13
1.270229,0.887276,0.887192,1,14
1.609079,0.788336,0.788335,1,11
1.320341,0.870276,0.870139,2,12
1.363609,0.856357,0.856346,2,9
0.395172,1.590768,1.590765,4,10
1.096431,0.955013,0.954945,2,6
0.845823,1.087327,1.087325,10,7
1.481340,0.821623,0.821583,13,4
0.556328,1.340708,1.340277,40,8
1.060998,0.970829,0.970821,39,2
1.386895,0.849138,inf,100,3

*/
