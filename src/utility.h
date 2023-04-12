#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include <stddef.h>
#include <time.h>

/// utility functions for the c code

// Casting functions using pointers
// Not memory safe but used because that's how it was
// done in the examples we are following
// make sure to compile with -O0 to prevent the compiler from 
// optimizing out the pointer arithmetic
uint64_t AsIntegerDouble(double df) {
    return * ( uint64_t * ) &df;
}
double AsDouble64BitInt(int64_t i) {
    return * ( double * ) &i;
}
int AsInteger(float f) {
    return * ( int * ) &f;
}

float AsFloat(int i) {
    return * ( float * ) &i;
}

// Smooth generation of random numbers (by dividing doubles then casting)
float uniformDraw (float low, float high) {
    double x;
    float Urand;
    x = (double)rand() / (double)((unsigned)RAND_MAX + 1);
    Urand = (float) x;
    return (high - low) * Urand + low;
}

//Draw for a reciprocal distribution https://en.wikipedia.org/wiki/Reciprocal_distribution
//not used now but was investigated to clear up some plotting issues
float reciprocalDraw (float low, float high) {
    double x;
    float Urand;
    x = (double)rand() / (double)((unsigned)RAND_MAX + 1);
    Urand = (float) 1 - x;
    //Inverse CDF of the reciprocal distribution
    return powf(high/low, x) * low;
}