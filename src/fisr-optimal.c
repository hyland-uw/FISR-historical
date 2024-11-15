#include <stdint.h>

/*
Proposed Universally Optimal values are:
* magic: 0x5F376908
* halfthree: 1.5008789f
* halfone: 0.5f
*/
float fast_rsqrt(float input, uint32_t magic, float halfthree, float halfone) {
    float approx, output;
    // The input is given two simultaneous representations:
    // a 32 bit float y.f and a 32 bit unsigned integer y.u,
    // both from the same bitfield associated with x
    // For an integer, the position of the bit does not have
    // special meaning save that the more significant bits
    // represent larger numbers. By contrast, bit position
    // in floats is significant,with bit 0 being the sign,
    // 1-8 being exponents, and the remaining 23 the fraction.
    union { float f; uint32_t u; } y = {input};

    // The unisgned integer representation y.u is right shifted
    // dividing it by two. It is then subtracted from a
    // magic constant. The constant's main purpose is to restore
    // the exponents lost in that bit shift.
    // A choice of "0x5F400000" is exactly will
    // only restore the exponents in high 8 bits where
    // the float exponents are stored.
    y.u = magic - (y.u >> 1);
    // Assign the floating point values associated with the
    // bitfield for y.u to approx. This will be the
    // input into NR iteration.
    approx = y.f;
    // All of the FISRs we see in this library use at least
    // one iteration of Newton-Raphson.
    // Because different approximations choose differing
    // values for halfthree and halfone, we can select them
    output = approx * (halfthree - halfone * input * approx * approx);
    return output;
}
