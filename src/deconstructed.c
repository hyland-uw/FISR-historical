#include "sampling-harness.h"

/*
This harness allows us to deconstruct the working and output of an idealized FISR.

The main purpose of this is to visualize the result of selecting both the
input and the magic constant at random, so the space of possible choices is seen.

Unlike in the individual methods, the FISR is allowed to converge and the
iterations required for convergence is stored.

Unions are used to avoid type punning, so this code should work at all
levels of compiler optimization.
*/

deconHarness decon_rsqrt(float x, int NRmax, uint32_t magic, float tol) {
    deconHarness result;

    // Compute a reference inverse square root
    // Used to compute error
    result.reference = 1.0f / sqrtf(x);

    // float tol should be somewhere around or above 0.000125f


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
    // floating point representation. Treating the value
    // has the effect of removing us from the logarithmic domain
    result.initial_approx = y.f;

    // All of the FISRs we see in this library use at least
    // one iteration of Newton-Raphson.
    // Because different approximations choose differing
    // values for halfthree and halfone, we can select them
    int iters = 0;
    while (iters < NRmax) {
        // Hardcode 1.5 and 0.5 for this version
        y.f = y.f * (1.5f - 0.5f * x * y.f * y.f);
        iters++;
        // terminate NR iteration when we are close
        // rather than after 1 or 2 to better show
        // the possibility space
        if (fabs(y.f - result.reference) < tol) {
            break;
        }
    }
    // Record output after the while loop, then check
    // validity
    result.output = y.f;
    result.NR_iters = iters;

    if (!isnormal(result.initial_approx)) {
        result.invalid_float_reached = true;
    }

    // We set the max elsewhere. If we reach it,
    // it is likely the output will not converge
    if (result.NR_iters == NRmax) {
        result.invalid_float_reached = true;
    }

    // A poor choice of restoring constant can make the
    // resulting float invalid. isnormal() is chosen to
    // exclude subnormal numbers, which won't work with
    // the trick
    // c.f. https://stackoverflow.com/q/75772363/1188479
    //
    // We may also reach an invalid float through
    // overflow with (very) poor choices of
    // three or half
    if (!isnormal(result.output) || !isnormal(result.initial_approx)) {
        result.invalid_float_reached = true;
    }

    return result;
}

typedef struct {
    float input;
    float reference;
    float initial_approx;
    float output;
    unsigned int NR_iters;
    uint32_t magic;
} SampleResult;

void sample_decon_rsqrt(int draws, int NRmax, float min, float max, float tol) {
    SampleResult* results = malloc(sizeof(SampleResult) * draws);
    int valid_results = 0;

    #pragma omp parallel
    {
        // Thread-local storage for results
        SampleResult* local_results = malloc(sizeof(SampleResult) * draws / omp_get_num_threads());
        int local_valid_results = 0;

        #pragma omp for
        for (int i = 0; i < draws; i++) {
            float x = uniformRange(min, max);
            // Wider integer sample range than the others. we are looking for
            // poor fits
            uint32_t magic = sample_integer_range(1578000000, 1602000000);

            deconHarness result = decon_rsqrt(x, NRmax, magic, tol);

            if (!result.invalid_float_reached) {
                SampleResult sample = {
                    .input = x,
                    .reference = result.reference,
                    .initial_approx = result.initial_approx,
                    .output = result.output,
                    .NR_iters = result.NR_iters,
                    .magic = magic
                };
                local_results[local_valid_results++] = sample;
            }
        }

        // Merge local results into global results
        #pragma omp critical
        {
            for (int i = 0; i < local_valid_results && valid_results < draws; i++) {
                results[valid_results++] = local_results[i];
            }
        }

        free(local_results);
    }

    // Print results
    printf("input,reference,initial,final,iters,magic\n");
    for (int i = 0; i < valid_results; i++) {
        printf("%f,%f,%f,%f,%u,0x%08X\n",
               results[i].input,
               results[i].reference,
               results[i].initial_approx,
               results[i].output,
               results[i].NR_iters,
               results[i].magic);
    }

    free(results);
}

// Main function calls the sampler which
// outputs via printf for a csv
int main() {
    srand(time(NULL));
    sample_decon_rsqrt(PAIR_DRAWS, NRMAX, FLOAT_START, FLOAT_END, FLOAT_TOL);
    return 0;
}
