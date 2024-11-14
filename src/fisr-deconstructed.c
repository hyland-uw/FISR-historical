#include "sampling-harness.h"

/*
This harness allows us to deconstruct the working and output of an idealized FISR.

The main parameters used to tune the approximation are magic, halfthree, and halfone.

The number of Newton-Raphson iterations are selected by parameter NR. High values
of NR can show where a set of parameters causes the approximation to fail to converge

Unions are used to avoid type punning, so this code should work at all
levels of compiler optimization.
*/

Harness fast_rsqrt(float x, int NRmax, uint32_t magic, float halfthree, float halfone) {
    Harness result;

    // Compute a reference inverse square root
    // Used to compute error
    result.reference = 1.0f / sqrtf(x);

    int iters = 0;

    // Track if we reach a state which won't plot well
    result.invalid_float_reached = false;
    // The input is given two simultaneous representations:
    // a 32 bit float y.f and a 32 bit unsigned integer y.u,
    // both from the same bitfield associated with x
    // For an integer, the position of the bit does not have
    // special meaning save that the more significant bits
    // represent larger numbers. By contrast, bit position
    // in floats is significant,with bit 0 being the sign,
    // 1-8 being exponents, and the remaining 23 the fraction.
    union { float f; uint32_t u; } y = {x};

    // The unisgned integer representation y.u is right shifted
    // dividing it by two. It is then subtracted from a
    // magic constant. The constant's main purpose is to restore
    // the exponents lost in that bit shift.
    // A choice of "0x5F400000" is exactly will
    // only restore the exponents in high 8 bits where
    // the float exponents are stored.
    y.u = magic - (y.u >> 1);

    // Now that we have manipulated the bitfield as an integer
    // and restored the bits in the exponent, we extract the
    // floating point representation.
    result.initial_approx = y.f;
    if (!isnormal(result.initial_approx)) {
        result.invalid_float_reached = true;
    }

    // All of the FISRs we see in this library use at least
    // one iteration of Newton-Raphson.
    // Because different approximations choose differing
    // values for halfthree and halfone, we can select them
    while (iters < NRmax) {
        y.f = y.f * (halfthree - halfone * x * y.f * y.f);
        // terminate NR iteration when we are close
        if (fabs(y.f - result.reference) < 0.0025f) {
            break;
        }
        iters++;
    }
    result.output = y.f;
    result.NR_iters = iters;

    // We may reach an invalid float through a
    // poor choice of restoring constant or
    // overflow with (very) poor choices of
    // three or half
    if (!isnormal(result.output)) {
        result.invalid_float_reached = true;
    }

    //WIP. If we are too far off, discard for visual clarity
    if (fabs(result.output - result.reference) > 5 * fabs(result.reference)) {
        result.invalid_float_reached = true;
    }

    return result;
}

void sample_fast_rsqrt(int draws, int NRmax, int scale, uint32_t base_magic, float min, float max) {
    // These are not user defined for now.
    // In NR steps, halfthree is usually 1.5 and halfone 0.5,
    // but not always.
    float halfthree = 1.5f;
    float halfone = 0.5f;

    // Define our x here, which will change for each draw.
    float x;

    printf("input,reference,initial_approx,output,NR_iters,magic_number,invalid\n");

    for (int i = 0; i < draws; i++) {
        // we also have a smooth uniform distribution
        // with uniformRange()
        x = reciprocalRange(min, max);
        // Select a magic random number
        uint32_t magic = generate_sample(base_magic, scale);
        // run the harness with above parameters
        Harness result = fast_rsqrt(x, NRmax, magic, halfthree, halfone);

        // because we used the result struct, this is reasonably tidy
        printf("%f,%f,%f,%f,%u,0x%08X,%d\n",
               x,
               result.reference,
               result.initial_approx,
               result.output,
               result.NR_iters,
               magic,
               result.invalid_float_reached);
    }
}

// Main function calls the sampler which
// outputs via printf for a csv
int main() {
    int draws = 40000;
    int NRmax = 8;
    uint32_t base_magic = 0x5f3759df;
    int scale = 1000000;
    float min = 0.25f;
    float max = 1.0f;
    sample_fast_rsqrt(draws, NRmax, scale, base_magic, min, max);
    return 0;
}
