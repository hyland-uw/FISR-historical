#include "utility.h"

// Main function mostly sets the parameters and prints output
int main() {
	float inputFloat, invSqrtLib;
    uint8_t KNGInd;
    uint32_t AsInt;
    int LUT;
    float Quake3, Blinn, InterState76, Kadlec, Moroz;
    float Magic, KahanNg, WithoutDiv, KahanNgNoLookup;
    float KahanNgNR, MagicNR, WithoutDivNR;
    float Quake3NR, BlinnNR, InterState76NR, KadlecNR, MorozNR;

    // new seed each time
    srand(time(NULL));
    // print column names to convert this to csv later

    // ITERATION CONTROL
    // High and low for range of distribution
    // Much lower and the approximation fails spectacularly
    const float lowerBound = 0.025f;
    // Much higher and the error becomes too small to see
    const float upperBound = 6.0f;
    // 70000 is a good number for the plots
    const unsigned long long int iters = 80000;
    unsigned long long int i = 0;
    // Reference points
    printf("Input, Reference, Integer, ");
    // Uncorrected
    printf("Magic, KahanNg, KahanNgNoLookup, WithoutDiv, ");
    printf("Blinn, Quake3, InterState76, Kadlec, Moroz, ");
    // Newton-Raphson corrected
    printf("BlinnNR, WithoutDivNR, KahanNgNR, Quake3NR, MagicNR, InterState76NR, KadlecNR, MorozNR\n");

    while (i < iters) {
        // the "x" in y = 1/sqrt(x)
        inputFloat = uniformDraw(lowerBound, upperBound);

        // A reference point using the system sqrt
        // which is accurate as if performed in infinite precision
        // and rounded to the number of digits available.
        invSqrtLib = 1.0f / sqrt(inputFloat);

        // Easy access to the integer representation
        AsInt = AsInteger(inputFloat);

        //Uncorrected

        // LUT methods
        KahanNg = KahanNgISR(inputFloat, 0);
        InterState76 = i76ISR(inputFloat, 0);

        //Older methods
        Magic = MagicISR(inputFloat, 0);
        Blinn = BlinnISR(inputFloat, 0);
        KahanNgNoLookup = KahanNgNoLookupISR(inputFloat, 0);
        WithoutDiv = withoutDivISR(inputFloat, 0);

        // Modern FISRs
        Quake3 = QuakeISR(inputFloat, 0);
        Kadlec = optimalFISR(inputFloat, 0);
        Moroz = MorozISR(inputFloat, 0);

        // Newton-Raphson outputs of most of the above
        BlinnNR = BlinnISR(inputFloat, 1);
        KahanNgNR = KahanNgISR(inputFloat, 1);
        Quake3NR = QuakeISR(inputFloat, 1);
        MagicNR = MagicISR(inputFloat, 1);
        InterState76NR = i76ISR(inputFloat, 1);
        KadlecNR = optimalFISR(inputFloat, 1);
        MorozNR = MorozISR(inputFloat, 1);
        WithoutDivNR = withoutDivISR(inputFloat, 1);

        // Breaking these up by lines makes it easier to read and update
        printf("%.9lf, %.9lf, %u, ",
                inputFloat, invSqrtLib, AsInt);
        printf("%.9lf, %.9lf, %.9lf, %.9lf, ",
                Magic, KahanNg, KahanNgNoLookup, WithoutDiv);
        printf("%.9lf, %.9lf, %.9lf, %.9lf, %.9lf, ",
                Blinn, Quake3, InterState76, Kadlec, Moroz);
        printf("%.9lf, %.9lf, %.9lf, %.9lf, %.9lf, %.9lf, %.9lf, %.9lf\n",
                BlinnNR, WithoutDivNR, KahanNgNR, Quake3NR, MagicNR, InterState76NR, KadlecNR, MorozNR);
        i++;
    }
	return 0;
}
