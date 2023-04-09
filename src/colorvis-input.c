#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include <stddef.h>
#include <time.h>

// convenience function for a float in range.
float rand_range(float min, float max) {
  float upper;
  upper = ((double)rand() / (double)RAND_MAX) * (max - min);
  return min + upper;
}

// Functions to create probability arrays
void create_prob_array(double array[32]) {
    int i;
    for (i = 0; i < 32; i++) {
        array[i] = ldexp(1, -(32 - i));
    }
}
// Create a gapped one without a fuss. You could 
// use a location > 31 to create a full array.
void create_gapped_prob_array(double array[32], int location) {
    int i;
    for (i = 0; i < 32; i++) {
        if (i == location) {
            array[i] = 0;
        } else {
            array[i] = ldexp(1, -(32 - i));
        }
    }
}

// We have individual probabilities in the array
// but to select them we want an array of the
// cumulative sum of the probabilities.
void compute_cumulative_sum(double arr[], double sum[]) {
  for (int i = 0; i < 32; i++) {
    sum[i + 1] = sum[i] + arr[i];
  }  
}

// Who knew you need to just use a for loop?
// https://stackoverflow.com/a/16734848/1188479
void multiply_array_by_scalar(double array[32], double scalar) {
    int i;
    for (i = 0; i < 32; i++) {
        array[i] *= scalar;
    }
}

// Same deal.
void add_32_arrays(double left[32], double right[32], double output[32]) {
    int i;
    for (i = 0; i < 32; i++) {
        output[i] += left[i] + right[i];
    }
}

// Select a bit based on our probability array.
int choose_bit(double array[32]) {
  double cumsum[33] = { 0 };
  compute_cumulative_sum(array, cumsum);
  // https://stackoverflow.com/a/6219525
  double r = (double)rand() / (double)((unsigned)RAND_MAX);
  for (int i = 0; i < 32; i++) {
    if (cumsum[i] <= r && r < cumsum[i + 1]) {
      return i;
    }
  }
}

// Mutate the probability array and return the bit that was flipped.
int mutate_and_advance(double array[32]) {
    double gapped[32];
    float chosen_prob;

    // Choose a bit to flip
    int bit = choose_bit(array);
    // Create a gapped array
    create_gapped_prob_array(gapped, bit);
    // Multiply the gapped array by the chosen probability
    chosen_prob = array[bit];
    array[bit] = 0;
    multiply_array_by_scalar(gapped, chosen_prob);
    // Add to the existing array, which has the 
    // chosen bit set to zero.
    add_32_arrays(array, gapped, array);
    return bit;
}

// Could probably use this pattern more 
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
  
    Q_rsqrt_results results = {0, 0};

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
    float ref, error, input;
    int iters, steps, flipped;
  
    float flt_max = 8.0f;
    float flt_min = 0.25f;
    uint32_t stored_magic = magic;
    int current_timeline = 1;

    srand(time(NULL));
    printf("input,error,magic,iters,flipped,steps, timeline\n");
    while (current_timeline <= timelines) {
        create_prob_array(probabilities);
        iters = 0;
        steps = 0;

        while (iters < max_NR_iters) {
            input = rand_range(flt_min, flt_max);
            Q_rsqrt_results results = Q_rsqrt_iter(input, magic, tol, max_NR_iters);
            steps++;
            ref = 1 / sqrtf(input);
            error = fabs(ref - results.after_first_iter);
            iters = results.iterations_completed;
            flipped = mutate_and_advance(probabilities);
            magic ^= 1 << (31 - flipped);
            printf("%f,%f,0x%08x,%d,%d,%d,%d\n", input, error, magic, iters, flipped, steps, current_timeline);
        }
        current_timeline++;
        magic = stored_magic;
    }
}

int main() {
    uint32_t magic = 0x5f37642f;
    int max_NR_iters = 105;
    float tol = 0.0075f;
    int timelines = 4500;

    generate_timelines(magic, max_NR_iters, tol, timelines);
    
    return 0;
}

/* The path of one timeline.

input,ref,approx,magic,iters,flipped,steps, timeline
1.822221,0.740797,0.739979,0x5f37642e,1,31,1,1
1.860121,0.733212,0.732534,0x5f37642c,1,30,2,1
0.678317,1.214182,1.212159,0x5f376428,1,29,3,1
0.382197,1.617545,1.615127,0x5f376420,1,28,4,1
1.852858,0.734647,0.733942,0x5f376460,1,25,5,1
1.496734,0.817387,0.816246,0x5f376440,1,26,6,1
0.289847,1.857445,1.857429,0x5f376640,1,22,7,1
0.270309,1.923399,1.922643,0x5f376740,1,23,8,1
0.316764,1.776774,1.776343,0x5f372740,1,17,9,1
1.150908,0.932137,0.932105,0x5f372340,1,21,10,1
0.448202,1.493699,1.492024,0x5f370340,1,18,11,1
1.805549,0.744210,0.743453,0x5f371340,1,19,12,1
1.281693,0.883299,0.883077,0x5f371b40,1,20,13,1
0.549303,1.349255,1.348111,0x5f371bc0,1,24,14,1
1.196545,0.914188,0.914182,0x5f379bc0,1,16,15,1
1.042972,0.979183,0.978399,0x5f369bc0,1,15,16,1
1.539086,0.806062,0.805113,0x5f329bc0,1,13,17,1
0.905405,1.050942,1.046552,0x5f309bc0,1,14,18,1
0.865219,1.075070,1.070053,0x5f389bc0,2,12,19,1
1.966911,0.713030,0.712462,0x5f189bc0,1,10,20,1
1.701090,0.766719,0.749489,0x5f089bc0,2,11,21,1
0.287600,1.864687,1.760429,0x5f08dbc0,3,17,22,1
1.676161,0.772400,0.727864,0x5708dbc0,2,4,23,1
0.555509,1.341697,0.000023,0x5788dbc0,31,8,24,1
0.341032,1.712389,0.000063,0x5688dbc0,29,7,25,1
1.129044,0.941119,0.000009,0x4688dbc0,32,3,26,1
1.636066,0.781807,0.000000,0x4288dbc0,87,5,27,1
0.885638,1.062605,0.000000,0x4088dbc0,100,6,28,1
0.590039,1.301846,0.004328,0x58c89bc0,18,6,26
0.957868,1.021756,0.000203,0x50c89bc0,25,4,27
1.598911,0.790839,0.000000,0x40c89bc0,52,3,28
1.901019,0.725282,0.000000,0x40c8bbc0,100,18,29

*/