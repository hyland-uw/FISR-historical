#include "utility.h"

// Could probably use this pattern more 
typedef struct {
    int iterations_completed;
    float after_first_iter;
} Q_rsqrt_results;


int main() {
    // Generation parameters
    uint32_t magic = 0x5f37642f;
    // It appears that for > 105 iterations,
    // the algorithm is unlikely to converge.
    int max_NR_iters = 105;
    // Need to play around with this
    // Might need to pick a power of 2
    float tol = 0.0125f;
    // More than this seems to be unhelpful
    int timelines = 7500;
    // This is (arguably) one period of the 
    // approximation--from 2^-1 to 2^1
    // Any other crossing of an even binary power of 2 will do
    float flt_min = 0.5f;
    float flt_max = 2.0f;

    generate_timelines(magic, max_NR_iters, tol, timelines, flt_min, flt_max);
    
    return 0;
}

/* The path of one timeline.

input,error,magic,iters,flipped,steps, timeline
7.845337,0.000152,0x5f37642e,1,31,1,1
6.176630,0.000617,0x5f37642c,1,30,2,1
4.926030,0.000045,0x5f376424,1,28,3,1
4.899565,0.000036,0x5f376404,1,26,4,1
7.123745,0.000480,0x5f376484,1,24,5,1
7.645338,0.000242,0x5f376494,1,27,6,1
3.673761,0.000605,0x5f3764d4,1,25,7,1
6.646753,0.000621,0x5f3765d4,1,23,8,1
0.633826,0.002222,0x5f3761d4,1,21,9,1
4.658135,0.000002,0x5f3763d4,1,22,10,1
7.695400,0.000218,0x5f3773d4,1,19,11,1
2.325683,0.000940,0x5f377bd4,1,20,12,1
7.049764,0.000526,0x5f375bd4,1,18,13,1
3.304683,0.000026,0x5f365bd4,1,15,14,1
4.711877,0.000010,0x5f361bd4,1,17,15,1
4.929669,0.000005,0x5f369bd4,1,16,16,1
4.342799,0.000247,0x5f329bd4,1,13,17,1
3.874860,0.002014,0x5f229bd4,1,11,18,1
7.963129,0.005192,0x5f629bd4,1,9,19,1
3.957974,0.061841,0x5f6a9bd4,3,12,20,1
2.166996,0.114219,0x5f4a9bd4,3,10,21,1
5.024805,0.006292,0x5f489bd4,1,14,22,1
7.318483,0.007966,0x5fc89bd4,2,8,23,1
0.985052,2.754919,0x5fc88bd4,17,19,24,1
6.480330,1.271065,0x5dc88bd4,14,6,25,1
7.099020,0.297111,0x5cc88bd4,7,7,26,1
7.818248,0.339020,0x7cc88bd4,10,2,27,1
1.464925,inf,0x74c88bd4,105,4,28,1

*/