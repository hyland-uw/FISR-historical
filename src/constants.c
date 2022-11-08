#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <inttypes.h>
#include <time.h>
#include <math.h>

int32_t AsInteger(float f) {
    return * ( int32_t * ) &f;
}
float AsFloat(int32_t i) {
    return * ( float * ) &i;
}

// 0x5f3759df = Q3, 0x5F400000 = Blinn
float FISR(float f, int32_t i) {
    int32_t i0;
    i0 = i - (AsInteger(f) >> 1);
    return AsFloat(i0);
}

// ~~ 1597463007 to 1598029824
const int32_t FISRWalk {
    1597480720,1597498433,1597516146,1597533859,1597551572,
    1597569285,1597586998,1597604711,1597622424,1597640137,
    1597657850,1597675563,1597693276,1597710989,1597728702,
    1597746415,1597764128,1597781841,1597799554,1597817267,
    1597834980,1597852693,1597870406,1597888119,1597905832,
    1597923545,1597941258,1597958971,1597976684,1597994397,
    1598012110,1598029823
};

const int32_t iters = 600000;


int main() {
    unsigned long int i = 0;
    int32_t magic;
    // use  %" PRId32 " for printing int32_t
    // new seed each time 
    srand(time(NULL));
    // print column names to convert this to csv later
    printf("Input, Reference, SteppedConstant, Blinn, \n");
    while (i < 600000) {
        inputFloat =  0.06f + (rand() / (RAND_MAX + 1.0)) * 1.25f;
        Blinn = BlinnISR(inputFloat);
        KNG = KahanNgISR(inputFloat);
        invSqrtLib = 1 / sqrt(inputFloat);
        q3a = QuakeISR(inputFloat);
        steppedFISR = FISR(inputFloat, FISRWalk[i % 32]);
        magic = FISRWalk[i % 32];
        printf("%.9lf,  %.9lf, %.9lf, %.9lf, %.9lf\n",
                  inputFloat ,invSqrtLib, Blinn, q3a, KNG);
        i++;
    }
	return 0;
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