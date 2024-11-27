#include "util-harness.h"

// 2^-8 seems generous
#define FLOAT_TOL 0.00390625
#define MAX_NR 95


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
    // the float which has an eponent of 190
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
float optimalFISR (float x, int NR) {
    union { float f; uint32_t u; } y = {x};
    int magic = 0x5F1FFFF9;
    y.u = magic - (y.u >> 1);
    while (NR > 0) {
        y.f = 0.703952253f * y.f * (2.38924456f - x * y.f * y.f);
        NR--;
    }
    return y.f;
}

// Constant choice from Moroz et al (2018)
// https://doi.org/10.48550/arXiv.1603.04483 is original 2016 paper
// NR values and different constant chosen from 2018 paper
// https://doi.org/10.48550/arXiv.1802.06302
// See page 15 for InvSqrt2 constants
float MorozISR(float x, int NR) {
    int magic = 0x5F376908;
    union { float f; uint32_t u; } y = {x};
    y.u = magic - (y.u >> 1);
    while (NR > 0) {
        y.f = y.f * (1.5008789f - 0.5f * x * y.f * y.f);
        NR--;
    }
    return y.f;
}

// Naive guesses are used to help show the virtue of a good guess
// We can track number of iterations for convergence, which
// for naive guesses is meaningful, where most of the
// optimized guesses will converge to tight tolerances after 1 or 2
// iterations.
float NaiveISR_1_over_x(float x, int NR) {
    union { float f; uint32_t u; } y = {x};
    y.f = 1.0f / x;
    while (NR > 0) {
        y.f = y.f * (1.5f - 0.5f * x * y.f * y.f);
        NR--;
    }
    return y.f;
}

// x is a particularly bad guess!
float NaiveISR_x(float x, int NR) {
    union { float f; uint32_t u; } y = {x};
    y.f = x;
    while (NR > 0) {
        y.f = y.f * (1.5f - 0.5f * x * y.f * y.f);
        NR--;
    }
    return y.f;
}

// Using the system square root is numerically a very good guess
// In terms of use of computing resources it is
// ironically profligate for NR > 0 ;)
float SqrtISR(float x, int NR) {
    union { float f; uint32_t u; } y = {x};
    y.f = 1.0f / sqrtf(x);
    while (NR > 0) {
        y.f = y.f * (1.5f - 0.5f * x * y.f * y.f);
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
    {"Naive_1_over_x", NaiveISR_1_over_x},
    {"Naive_x", NaiveISR_x},
    {"Sqrt", SqrtISR},
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
            result = FISR(isr_table[i].name, input, iterations);
            if (fabsf(result - reference) <= FLOAT_TOL || isnan(result)) {
                break;
            }
            iterations++;
        }

        printf("%e,%s,%e,%e,%e,%d\n",
               input, isr_table[i].name, initial_guess, one_iteration, result, iterations);
    }
}

int main() {
    srand(time(NULL));

    printf("input, method, initial_guess, one_iteration, final, iterations_to_converge\n");

    for (int draw = 0; draw < FLOAT_SLICES; draw++) {
        float input = logStratifiedSampler(FLOAT_START, FLOAT_END);
        compare_isr_methods(input);
    }

    return 0;
}
