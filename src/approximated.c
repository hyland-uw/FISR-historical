#include "util-harness.h"

// 2^-8 seems generous, let's try 2^-9
#define FLOAT_TOL 0.001953125
#define MAX_NR 95

#define LOCAL_FLOAT_START 0.0078125f
#define LOCAL_FLOAT_END 0.25f

//// Implementations of various inverse square roots.
//// all should accept:
////     an input float x, assumed to be positive and normal
////     an input int NR, assumed to be > 0
//// all should return:
////     a float which is an approximation of 1/sqrt(x)

// FISR demonstrating the logaritmic nature of the floating-point numbers
// The constant chosen is not "magic" but that which replaces the lost
// exponents from the shift of the number as an integer.
// 1997
float BlinnISR(float x, int NR) {
    int magic = 0x5F400000;
    union { float f; uint32_t u; } y = {x};
    // 0x5F400000 = 1598029824
    y.u = magic - (y.u >> 1);
    while (NR > 0) {
        // See https://doi.org/10.1109/38.595279
        y.f = y.f * (1.47f - 0.47f * x * y.f * y.f);
        NR--;
    }
    return y.f;
}

// See https://en.wikipedia.org/wiki/Fast_inverse_square_root
// Published ~1999
float QuakeISR(float x, int NR) {
    int magic = 0x5f3759df;
    union { float f; uint32_t u; } y = {x};
    y.u = magic - (y.u >> 1);

    while (NR > 0) {
        y.f = y.f * (1.5f - (0.5f * x * y.f * y.f));
        NR--;
    }
    return  y.f;
}

// "Square root without division" From Kahan 1999
// See http://www.arithmazium.org/library/lib/wk_square_root_without_division_feb99.pdf
float withoutDivISR(float x, int NR) {
    // 0x5f39d015 is the hex value for
    // the float which has an exponent of 190
    // and a fraction of ~.451
    int magic = 0x5f39d015;
    union { float f; uint32_t u; } y = {x};
    y.u = magic - (y.u >> 1);
    while (NR > 0) {
        y.f = y.f * (1.5f - (0.5f * x * y.f * y.f));
        NR--;
    }
    return y.f;
}


// See https://web.archive.org/web/20220826232306/http://rrrola.wz.cz/inv_sqrt.html
// Optimal Newton-Raphson / magic constant combination
// found viabrute force search of the 32-bit integer space
// for magic constant and coefficients in Newton-Raphson step
// post 2010
float optimalFISR(float x, int NR) {
    int magic = 0x5F1FFFF9;
    union { float f; uint32_t u; } y = {x};
    y.u = magic - (y.u >> 1);
    while (NR > 0) {
        y.f = 0.703952253f * y.f * (2.38924456f - x * y.f * y.f);
        NR--;
    }
    return y.f;
}

// Constant choice from Moroz et al (2016)
// https://doi.org/10.48550/arXiv.1603.04483
// See page 14 for InvSqrt2 constants
float MorozISR(float x, int NR) {
    int magic = 0x5F37ADD5;
    union { float f; uint32_t u; } y = {x};
    y.u = magic - (y.u >> 1);
    while (NR > 0) {
        y.f = y.f * (1.5 - 0.5f * x * y.f * y.f);
        NR--;
    }
    return y.f;
}

// This construction allows easy dispatch for each of the FISR methods
// we are testing.

ISREntry isr_table[] = {
    {"Blinn", BlinnISR},
    {"QuakeIII", QuakeISR},
    {"withoutDiv", withoutDivISR},
    {"optimal_grid", optimalFISR},
    {"Moroz", MorozISR},
    {NULL, NULL} // Sentinel to mark the end of the array
};

float FISR(const char *name, float x, int NR) {
    for (int i = 0; isr_table[i].name != NULL; i++) {
        if (strcmp(name, isr_table[i].name) == 0) {
            return isr_table[i].func(x, NR);
        }
    }
    fprintf(stderr, "Error: ISR function '%s' not found\n", name);
    return NAN;
}

void compare_isr_methods(float input) {
    float reference = 1.0f / sqrtf(input);

    for (int i = 0; isr_table[i].name != NULL; i++) {
        float initial_guess = FISR(isr_table[i].name, input, 0);
        float one_iteration = FISR(isr_table[i].name, input, 1);

        int iterations = 0;
        float result = initial_guess;

        while (iterations < MAX_NR) {
            // Compare first because we record the initial guess
            if (fabsf(result - reference) <= FLOAT_TOL) {
                break;
            }
            // if it doesn't meet tolerance, do one loop of NR iteration
            // and guess again
            iterations++;
            result = FISR(isr_table[i].name, input, iterations);
        }

        printf("%e,%s,%e,%e,%e,%d\n",
               input, isr_table[i].name, initial_guess, one_iteration, result, iterations);
    }
}

int main() {
    srand(time(NULL));

    printf("input, method, guess, after_one, final, iters\n");

    for (int draw = 0; draw < FLOAT_SLICES; draw++) {
        float input = logStratifiedSampler(LOCAL_FLOAT_START, LOCAL_FLOAT_END);
        compare_isr_methods(input);
    }

    return 0;
}
