#include <stdint.h>
#include <math.h>

// See https://gist.github.com/Protonk/f3c5bb91f228ffec4d4c5e2eb16e489d
// and https://www.netlib.org/fdlibm/e_sqrt.c "sqrt(x) by Reciproot Iteration"
// 1986
float KahanNgISR(double x, int NR) {
    double y;
    int magic = 0x5fe80000;
    static int lookup[64]= {
        0x1500, 0x2ef8, 0x4d67, 0x6b02, 0x87be, 0xa395, 0xbe7a, 0xd866,
        0xf14a, 0x1091b,0x11fcd,0x13552,0x14999,0x15c98,0x16e34,0x17e5f,
        0x18d03,0x19a01,0x1a545,0x1ae8a,0x1b5c4,0x1bb01,0x1bfde,0x1c28d,
        0x1c2de,0x1c0db,0x1ba73,0x1b11c,0x1a4b5,0x1953d,0x18266,0x16be0,
        0x1683e,0x179d8,0x18a4d,0x19992,0x1a789,0x1b445,0x1bf61,0x1c989,
        0x1d16d,0x1d77b,0x1dddf,0x1e2ad,0x1e5bf,0x1e6e8,0x1e654,0x1e3cd,
        0x1df2a,0x1d635,0x1cb16,0x1be2c,0x1ae4e,0x19bde,0x1868e,0x16e2e,
        0x1527f,0x1334a,0x11051,0xe951, 0xbe01, 0x8e0d, 0x5924, 0x1edd
    };
    uint32_t xUPPER, yUPPER, k;
    uint64_t xINT, yINT;
    xINT = *( uint64_t *) &x;
    xUPPER = (xINT & 0xffffffff00000000) >> 32;
    k = magic - (xUPPER >> 1);
    yUPPER = k - lookup[63 & (k >> 14)];
    yINT = ((uint64_t) yUPPER << 32);
    y = *( double* ) &yINT;
    y = (float) y;
    while (NR > 0) {
        // from fdlibm comments:
        // The constant 1.5-2^-30 is chosen to bias the error so that
        //    (a) the term z*y in the final iteration is always less than 1;
	    //    (b) the error in the final result is biased upward so that
		//    -1 ulp < sqrt(x) - z < 1.0625 ulp instead of |sqrt(x)-z|<1.03125ulp.
        y = y * (1.5f - powf(2, -30) - (0.5f * x * y * y));
        NR--;
    }
    return y;
}

// accepts a double and splits it, like KahanNg
// See https://inbetweennames.net/blog/2021-05-06-i76rsqrt/
// for more details and the original recovered code (in C++)
// It is different from KahanNg as it splits the double into
// exponent and mantissa, whereas KahanNg splits it into
// high 32 and low 32 bits
double i76ISR(double x, int NR) {
    // Interstate76's lookup table generator
    // uint8_t LUT[256];
    // void generateLUT(){
    //     for (uint32_t i = 0; i < 256; ++i)
    //     {
    //         uint64_t float64bits = ((uint64_t) i | UINT64_C(0x1ff00)) << 0x2d;
    //         double d = AsDouble64BitInt(float64bits);
    //         double rsqrt = 1.0 / sqrt(d);

    //         uint64_t u64rsqrt = AsIntegerDouble(rsqrt);
    //         uint32_t high32bits = (uint32_t) (u64rsqrt >> 0x20);
    //         uint32_t high32bits_rounded_up = high32bits + 0x800;
    //         uint8_t mantissa_high8bits_only = (high32bits_rounded_up >> 0xc) & UINT32_C(0xFF);

    //         //store the 8 bits of mantissa remaining
    //         LUT[i] = mantissa_high8bits_only;
    //     }
    //     LUT[0x80] = 0xFF;
    // }
    // Just generate once and store since we don't need it to be dynamic
    static uint8_t I76LUT[256] = {
        106, 105, 103, 102, 101, 99, 98, 97, 95, 94, 93, 91,
        90, 89, 88, 87, 85, 84, 83, 82, 81, 80, 78, 77, 76,
        75, 74, 73, 72, 71, 70, 69, 68, 67, 66, 65, 64, 63,
        62, 61, 60, 59, 58, 57, 56, 55, 55, 54, 53, 52, 51,
        50, 49, 48, 48, 47, 46, 45, 44, 44, 43, 42, 41, 40,
        40, 39, 38, 37, 37, 36, 35, 34, 34, 33, 32, 31, 31,
        30, 29, 29, 28, 27, 27, 26, 25, 25, 24, 23, 23, 22,
        21, 21, 20, 20, 19, 18, 18, 17, 16, 16, 15, 15, 14,
        13, 13, 12, 12, 11, 11, 10, 10, 9, 8, 8, 7, 7, 6, 6,
        5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 255, 254, 252, 250, 248,
        246, 244, 243, 241, 239, 237, 235, 234, 232, 230, 228,
        227, 225, 223, 222, 220, 219, 217, 215, 214, 212, 211,
        209, 208, 206, 205, 203, 202, 201, 199, 198, 196, 195,
        194, 192, 191, 190, 188, 187, 186, 184, 183, 182, 181,
        179, 178, 177, 176, 175, 173, 172, 171, 170, 169, 168,
        166, 165, 164, 163, 162, 161, 160, 159, 158, 157, 156,
        155, 154, 153, 152, 151, 150, 149, 148, 147, 146, 145,
        144, 143, 142, 141, 140, 139, 138, 137, 136, 135, 135,
        134, 133, 132, 131, 130, 129, 128, 128, 127, 126, 125,
        124, 123, 123, 122, 121, 120, 119, 119, 118, 117, 116,
        116, 115, 114, 113, 113, 112, 111, 110, 110, 109, 108,
        107, 107
    };
    uint64_t x_bits = *( uint64_t *) &x;

    uint8_t const index = (x_bits >> 0x2d) & 0xff;
    // Shane Peelar's comments:
    // "LUT[index] contains the 8 most significant bits of the mantissa, rounded up.
    // Treat all lower 44 bits as zeroed out"
    uint64_t const mantissa_bits = ((uint64_t) I76LUT[index]) << 0x2c;

    // From Shane Peelar's comments:
    // "Exponent bits are calculated based on the formula in the article"
    // https://inbetweennames.net/blog/2021-05-06-i76rsqrt/
    uint64_t const exponent_bits = ((0xbfcUL - (x_bits >> 0x34)) >> 1) << 0x34;

    // From Shane Peelar's comments:
    // "exponent_bits have form 0xYYY00000 00000000
    // "mantissa_bits have form 0x000ZZ000 00000000
    // "so combined, we have    0xYYYZZ000 00000000 -- a complete float64 for the guess"
    uint64_t const combined_bits = exponent_bits | mantissa_bits;
    double y = *( double* ) &combined_bits;

    while (NR > 0) {
        y = y * (1.5f - (0.5f * x * y * y));
        // Interstate76 used a correction factor of 1.00001 here
        y = y * 1.00001;
        NR--;
    }

    return y;
}
