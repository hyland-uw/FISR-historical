#include "sampling-harness.h"
#include <stdint.h>



// this hardness does not return parameters, just the initial approx
// and one iteration of Newton-Raphson.
// /*
// Globally Optimal values from Moroz et al 2016 and 2018
// * magic: 0x5F376908
// * halfthree: 1.5008789f
// * halfone: 0.5f
//
minimalHarness minimal_rsqrt(float input, uint32_t magic, float halfthree, float halfone) {
    minimalHarness result;
    float approx, output;

    union { float f; uint32_t u; } y = {input};
    y.u = magic - (y.u >> 1);
    result.approx = y.f;

    // Because different approximations choose differing
    // values for halfthree and halfone, we can select them
    // Not all versions use the NR formula y * 1.5 -(0.5 * x * y^2)
    // but most do.
    result.final = approx * (halfthree - halfone * input * approx * approx);
    return result;
}
