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

float rand_range(float min, float max) {
  float upper;
  upper = ((float)rand() / (float)RAND_MAX) * (max - min);
  return min + upper;
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

void generate_timelines(uint32_t magic, int max_NR_iters, float tol, int timelines) {
    double probabilities[32];
    float ref, approx, input;
    int iters, steps, flipped;
  
    float flt_max = 2.0f;
    float flt_min = 0.25f;
    uint32_t stored_magic = magic;
    int current_timeline = 0;

    srand(time(NULL));
    printf("input,ref,approx,magic,iters,flipped,steps\n");
    while (current_timeline < timelines) {
        create_array32(probabilities);
        iters = 0;
        steps = 0;

        while (iters < max_NR_iters) {
            input = rand_range(flt_min, flt_max);
            Q_rsqrt_results results = Q_rsqrt_iter(input, magic, tol, max_NR_iters);
            steps++;
            ref = 1 / sqrtf(input);
            approx = results.after_first_iter;
            iters = results.iterations_completed;
            flipped = mutate_and_advance(probabilities);
            magic = flip_chosen_bit(magic, flipped);
            printf("%f,%f,%f,0x%08x,%d,%d,%d\n", input, ref, approx, magic, iters, flipped, steps);
        }
        current_timeline++;
        magic = stored_magic;
    }
}

int main() {
    uint32_t magic = 0x5f37642f;
    int max_NR_iters = 100;
    float tol = 0.0005f;
    int timelines = 3;

    generate_timelines(magic, max_NR_iters, tol, timelines);
    
    return 0;
}

/* The path of one mutation.

input,ref,approx,magic,iters,flipped,steps
1.413207,0.841196,0.840335,0x5f37642d,2,30,1
0.300952,1.822852,1.822799,0x5f376429,1,29,2
0.294844,1.841637,1.841635,0x5f376428,1,31,3
1.957728,0.714700,0.714384,0x5f376420,1,28,4
1.621368,0.785343,0.784069,0x5f376460,2,25,5
1.013768,0.993186,0.991818,0x5f376440,2,26,6
1.383140,0.850290,0.849557,0x5f374440,2,18,7
1.449231,0.830675,0.829719,0x5f374040,2,21,8
0.642930,1.247148,1.245047,0x5f374140,2,23,9
1.582590,0.794906,0.793687,0x5f374940,2,20,10
0.553910,1.343633,1.342302,0x5f374b40,2,22,11
0.663844,1.227346,1.225289,0x5f375b40,2,19,12
0.322370,1.761258,1.760658,0x5f375bc0,2,24,13
0.583367,1.309270,1.307432,0x5f371bc0,2,17,14
1.946364,0.716783,0.716486,0x5f331bc0,1,13,15
1.037373,0.981822,0.979225,0x5f321bc0,2,15,16
0.794343,1.122008,1.121187,0x5f301bc0,2,14,17
0.473448,1.453328,1.452718,0x5f381bc0,2,12,18
0.724341,1.174974,1.173008,0x5f181bc0,2,10,19
0.656227,1.234448,1.187423,0x5f981bc0,3,8,20
0.945643,1.028339,0.111591,0x5f881bc0,10,11,21
1.496862,0.817352,0.270820,0x5b881bc0,7,5,22
1.439251,0.833550,0.007873,0x5bc81bc0,16,9,23
0.506685,1.404853,0.018242,0x5bc89bc0,15,16,24
0.706834,1.189436,0.015942,0x5ac89bc0,15,7,25
0.590039,1.301846,0.004328,0x58c89bc0,18,6,26
0.957868,1.021756,0.000203,0x50c89bc0,25,4,27
1.598911,0.790839,0.000000,0x40c89bc0,52,3,28
1.901019,0.725282,0.000000,0x40c8bbc0,100,18,29

*/