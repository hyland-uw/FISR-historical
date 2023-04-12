#include "utility.h"
#include "timelines.h"

int main() {
    // Generation parameters
    uint32_t magic = 0x5f37642f;
    // It appears that for > 105 iterations,
    // the algorithm is unlikely to converge.
    int max_NR_iters = 110;
    // Need to play around with this
    // Might need to pick a power of 2
    float tol = 0.0125f;
    // need a lot to capture the tail (copilot suggested that name)
    int timelines = 800000;
    // This is (arguably) one period of the 
    // approximation--from 2^-1 to 2^1
    // Any other crossing of an even binary power of 2 will do
    float flt_min = 0.5f;
    float flt_max = 2.0f;

    generate_timelines(magic, max_NR_iters, tol, timelines, flt_min, flt_max);
    
    return 0;
}
