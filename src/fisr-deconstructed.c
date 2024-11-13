#include "sampling-harness.h"

/*
This harness allows us to deconstruct the working and output of an idealized FISR.

The main parameters used to tune the approximation are magic, halfthree, and halfone.

The number of Newton-Raphson iterations are selected by parameter NR. High values
of NR can show where a set of parameters causes the approximation to fail to converge

Unions are used to avoid type punning, so this code should work at all
levels of compiler optimization.
*/

Harness fast_rsqrt(float x, uint32_t NR, uint32_t magic, float halfthree, float halfone) {
    Harness result;

    // Capture the inputs to the function so we can get at them
    // later without trickery
    result.input = x;
    result.NR_iterations = NR;
    result.magic = magic;

    // In NR steps, halfthree is usually 1.5 and halfone 0.5,
    // but not always.
    result.halfthree = halfthree;
    result.halfone = halfone;

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

    // All of the FISRs we see in this library use at least
    // one iteration of Newton-Raphson.
    // Because different approximations choose differing
    // values for halfthree and halfone, we can select them
    while (NR > 0) {
        // not all methods use y * (3x - 1/2 * x^2 * y^2)
        // but most do
        y.f = y.f * (halfthree - halfone * x * y.f * y.f);
        NR--;
    }

    result.output = y.f;

    // We may reach an invalid float through a
    // poor choice of restoring constant or
    // overflow with (very) poor choices of
    // three or half
    if (isnan(y.f)) {
        result.invalid_float_reached = true;
    } else {
        result.invalid_float_reached = false;
    }

    return result;
}

// Main function calls the sampler which
// outputs via printf for a csv
int main() {
    int draws = 20000;
    uint32_t NR = 2;
    uint32_t base_magic = 0x5f3759df;
    int scale = 1000000;
    float min = 0.25f;
    float max = 1.0f;
    sample_fast_rsqrt(draws, NR, scale, base_magic, min, max);
    return 0;
}
