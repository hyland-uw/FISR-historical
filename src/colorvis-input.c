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

/// These here help us draw a tail to tip path for mutations

// Map a float to radians.
float map_to_radians(float input, float min, float max) {
    float scale;
    float output_range_start = 0.0;
    float output_range_end = 2 * M_PI;

    scale = (output_range_end - output_range_start) / (max - min);
    return (input - min) * scale + output_range_start;
}

// Define the coordinate struct
typedef struct {
    float x;
    float y;
} Cartesian;

// Function to convert polar coordinates to Cartesian coordinates
Cartesian polar_to_cartesian(float theta, float r) {
    Cartesian coords = {0, 0};
    coords.x = r * cos(theta);
    coords.y = r * sin(theta);

    return coords;
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

void generate_timelines(uint32_t magic, int max_NR_iters, float tol, int timelines, float flt_min, float flt_max) {
    double probabilities[32];
    float ref, error, input;
    int iters, steps, flipped;
  
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
    // Generation parameters
    uint32_t magic = 0x5f37642f;
    // It appears that for > 105 iterations,
    // the algorithm is unlikely to converge.
    int max_NR_iters = 105;
    // Need to play around with this
    // Might need to pick a power of 2
    float tol = 0.0075f;
    // More than this seems to be unhelpful
    int timelines = 4500;
    // This is (arguably) one period of the 
    // approximation--from 2^-1 to 2^1
    // Any other crossing of an even binary power of 2 will do
    float flt_min = 0.5f;
    float flt_max = 2.0f;

    generate_timelines(magic, max_NR_iters, tol, timelines, flt_min, flt_max);
    
    return 0;
}

/* The path of one timeline.

input,error,magic,iters,flipped,steps, timeline
7.845337,0.000152,0x5f37642e,1,31,1,1
6.176630,0.000617,0x5f37642c,1,30,2,1
4.926030,0.000045,0x5f376424,1,28,3,1
4.899565,0.000036,0x5f376404,1,26,4,1
7.123745,0.000480,0x5f376484,1,24,5,1
7.645338,0.000242,0x5f376494,1,27,6,1
3.673761,0.000605,0x5f3764d4,1,25,7,1
6.646753,0.000621,0x5f3765d4,1,23,8,1
0.633826,0.002222,0x5f3761d4,1,21,9,1
4.658135,0.000002,0x5f3763d4,1,22,10,1
7.695400,0.000218,0x5f3773d4,1,19,11,1
2.325683,0.000940,0x5f377bd4,1,20,12,1
7.049764,0.000526,0x5f375bd4,1,18,13,1
3.304683,0.000026,0x5f365bd4,1,15,14,1
4.711877,0.000010,0x5f361bd4,1,17,15,1
4.929669,0.000005,0x5f369bd4,1,16,16,1
4.342799,0.000247,0x5f329bd4,1,13,17,1
3.874860,0.002014,0x5f229bd4,1,11,18,1
7.963129,0.005192,0x5f629bd4,1,9,19,1
3.957974,0.061841,0x5f6a9bd4,3,12,20,1
2.166996,0.114219,0x5f4a9bd4,3,10,21,1
5.024805,0.006292,0x5f489bd4,1,14,22,1
7.318483,0.007966,0x5fc89bd4,2,8,23,1
0.985052,2.754919,0x5fc88bd4,17,19,24,1
6.480330,1.271065,0x5dc88bd4,14,6,25,1
7.099020,0.297111,0x5cc88bd4,7,7,26,1
7.818248,0.339020,0x7cc88bd4,10,2,27,1
1.464925,inf,0x74c88bd4,105,4,28,1

*/