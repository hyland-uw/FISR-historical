#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include <stddef.h>
#include <time.h>

/// utility functions for the c code

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