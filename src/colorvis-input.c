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
    float after_first_iter;
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
        if (counter == 1) {
          results.after_first_iter = conv.f;
        }  
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
    int steps = 0;

    create_array32(array);

    printf("input,ref,approx,iters,flipped,steps\n");
    while (iters < iter_limit) {
      input = flt_min + ((float)rand() / (float)RAND_MAX) * (flt_max - flt_min);
      Q_rsqrt_results results = Q_rsqrt_iter(input, magic, tol, iter_limit);
      steps++;
      ref = 1 / sqrtf(input);
      approx = results.after_first_iter;
      iters = results.iterations_completed;
      flipped = mutate_and_advance(array);
      magic = flip_chosen_bit(magic, flipped);
      printf("%f,%f,%f,%d,%d,%d\n", input, ref, approx, iters, flipped, steps);
    }
    
    return 0;
}

/* The path of one mutation.

input,ref,approx,iters,flipped,steps
1.154656,0.930623,0.930609,1,30,1
1.995487,0.707906,0.707710,1,31,2
1.561315,0.800303,0.799048,2,28,3
1.823150,0.740609,0.739793,2,27,4
1.561520,0.800251,0.798996,2,26,5
1.310742,0.873457,0.873056,1,25,6
1.802190,0.744903,0.744013,2,23,7
0.485837,1.434678,1.433944,2,24,8
0.768270,1.140888,1.140149,2,21,9
0.651364,1.239048,1.236861,2,22,10
0.586281,1.306012,1.304114,2,19,11
1.700844,0.766775,0.765576,2,18,12
0.553746,1.343832,1.342478,2,17,13
1.718543,0.762816,0.761793,2,13,14
0.892975,1.058231,1.054437,2,14,15
1.190156,0.916638,0.915819,2,16,16
0.992382,1.003831,0.999173,2,15,17
1.478703,0.822355,0.822346,1,11,18
0.419416,1.544107,1.528528,2,20,19
1.514834,0.812489,0.805166,2,12,20
0.411700,1.558509,1.554541,2,9,21
1.147631,0.933467,0.761979,4,10,22
1.328983,0.867442,0.854865,2,8,23
1.627713,0.783811,-1.757129,100,18,24

*/
