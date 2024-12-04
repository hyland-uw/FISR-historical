#include "util-harness.h"

// not included in normal compilation because it is very resource intensive with the below
// parameters

#define MIN_NARROW_INT 0x5F290000
#define MAX_NARROW_INT 0x5F410000
#define SAMPLES_PER_SLICE 2048

#define CYCLE_START 0.25f
#define CYCLE_END 1.0f

typedef struct {
    float min;
    float max;
    uint32_t magic;
    float avg_error;
    float max_error;
} Slice;

float calculate_errors(float min, float max, uint32_t magic, int samples, float *max_error) {
    float total_error = 0.0f;
    *max_error = 0.0f;

    #pragma omp parallel
    {
        float local_total_error = 0.0f;
        float local_max_error = 0.0f;

        #pragma omp for
        for (int i = 0; i < samples; i++) {
            float x = logStratifiedSampler(min, max);
            float approx = minimal_rsqrt(x, magic, 1);
            float actual = 1.0f / sqrtf(x);
            float rel_error = fabsf((approx - actual) / actual);
            local_total_error += rel_error;
            if (rel_error > local_max_error) {
                local_max_error = rel_error;
            }
        }

        #pragma omp critical
        {
            total_error += local_total_error;
            if (local_max_error > *max_error) {
                *max_error = local_max_error;
            }
        }
    }

    return total_error / samples;
}

void find_optimal_constants(Slice slices[], int N_BINS) {
    float log_start = log2f(CYCLE_START);
    float log_end = log2f(CYCLE_END);
    float log_step = (log_end - log_start) / N_BINS;

    #pragma omp parallel for
    for (int i = 0; i < N_BINS; i++) {
        slices[i].min = powf(2, log_start + i * log_step);
        slices[i].max = powf(2, log_start + (i + 1) * log_step);
        slices[i].magic = MIN_NARROW_INT;
        float min_max_error = FLT_MAX;

        for (uint32_t magic = MIN_NARROW_INT; magic <= MAX_NARROW_INT; magic++) {
            float max_error;
            float avg_error = calculate_errors(slices[i].min, slices[i].max, magic, SAMPLES_PER_SLICE, &max_error);
            if (max_error < min_max_error) {
                min_max_error = max_error;
                slices[i].magic = magic;
                slices[i].avg_error = avg_error;
                slices[i].max_error = max_error;
            }
        }
    }
}

void print_results(Slice slices[], int N_BINS) {
    for (int i = 0; i < N_BINS; i++) {
        printf("%d,%.3f,%.3f,0x%08X,%.9f,%.9f\n",
               N_BINS, slices[i].min, slices[i].max, slices[i].magic,
               slices[i].avg_error, slices[i].max_error);
    }
}

int main() {
    int bin_counts[] = {4, 8, 16, 32, 64};
    int num_bin_counts = sizeof(bin_counts) / sizeof(bin_counts[0]);
    printf("N,Range_Min,Range_Max,Magic,Avg_Relative_Error,Max_Relative_Error\n");
    for (int i = 0; i < num_bin_counts; i++) {
        int N_BINS = bin_counts[i];
        Slice *slices = malloc(N_BINS * sizeof(Slice));
        find_optimal_constants(slices, N_BINS);
        print_results(slices, N_BINS);
        free(slices);
    }

    return 0;
}

/*
Old output for N = {4, 8, 16, 32}, 2560 samples per slice

Optimal constants for 4 slices between 0.250 and 1.000:
Range 0.250 - 0.354: Magic = 0x5F38311B, Avg Relative Error = 0.000499069, Max Relative Error = 0.001352865
Range 0.354 - 0.500: Magic = 0x5F32FF5E, Avg Relative Error = 0.000102143, Max Relative Error = 0.000180310
Range 0.500 - 0.707: Magic = 0x5F33588B, Avg Relative Error = 0.000064376, Max Relative Error = 0.000121982
Range 0.707 - 1.000: Magic = 0x5F37B2FC, Avg Relative Error = 0.000821636, Max Relative Error = 0.001611145
Normalized Avg Relative error = 0.000371806 ---- Normalized Max Relative Error = 0.000816575

Optimal constants for 8 slices between 0.250 and 1.000:
Range 0.250 - 0.297: Magic = 0x5F3B3400, Avg Relative Error = 0.000175138, Max Relative Error = 0.000515375
Range 0.297 - 0.354: Magic = 0x5F343405, Avg Relative Error = 0.000066475, Max Relative Error = 0.000190212
Range 0.354 - 0.420: Magic = 0x5F314291, Avg Relative Error = 0.000004542, Max Relative Error = 0.000008437
Range 0.420 - 0.500: Magic = 0x5F331A8D, Avg Relative Error = 0.000064412, Max Relative Error = 0.000164804
Range 0.500 - 0.595: Magic = 0x5F337EF4, Avg Relative Error = 0.000038050, Max Relative Error = 0.000105233
Range 0.595 - 0.707: Magic = 0x5F3252E4, Avg Relative Error = 0.000005681, Max Relative Error = 0.000010230
Range 0.707 - 0.841: Magic = 0x5F350ED5, Avg Relative Error = 0.000127877, Max Relative Error = 0.000353157
Range 0.841 - 1.000: Magic = 0x5F3A5551, Avg Relative Error = 0.000383371, Max Relative Error = 0.000746014
Normalized Avg Relative error = 0.000108193 ---- Normalized Max Relative Error = 0.000261683

Optimal constants for 16 slices between 0.250 and 1.000:
Range 0.250 - 0.273: Magic = 0x5F3D6828, Avg Relative Error = 0.000051915, Max Relative Error = 0.000152242
Range 0.273 - 0.297: Magic = 0x5F38DBA2, Avg Relative Error = 0.000036233, Max Relative Error = 0.000107626
Range 0.297 - 0.324: Magic = 0x5F354A9C, Avg Relative Error = 0.000022347, Max Relative Error = 0.000066177
Range 0.324 - 0.354: Magic = 0x5F32C3A7, Avg Relative Error = 0.000010496, Max Relative Error = 0.000031400
Range 0.354 - 0.386: Magic = 0x5F314CFB, Avg Relative Error = 0.000002769, Max Relative Error = 0.000007372
Range 0.386 - 0.420: Magic = 0x5F30E7DA, Avg Relative Error = 0.000000325, Max Relative Error = 0.000000677
Range 0.420 - 0.459: Magic = 0x5F31BCD3, Avg Relative Error = 0.000006968, Max Relative Error = 0.000018862
Range 0.459 - 0.500: Magic = 0x5F33BC32, Avg Relative Error = 0.000024932, Max Relative Error = 0.000074169
Range 0.500 - 0.545: Magic = 0x5F340E1A, Avg Relative Error = 0.000013809, Max Relative Error = 0.000042066
Range 0.545 - 0.595: Magic = 0x5F329BE7, Avg Relative Error = 0.000004871, Max Relative Error = 0.000013821
Range 0.595 - 0.648: Magic = 0x5F32000C, Avg Relative Error = 0.000000292, Max Relative Error = 0.000000644
Range 0.648 - 0.707: Magic = 0x5F3259BB, Avg Relative Error = 0.000003596, Max Relative Error = 0.000009218
Range 0.707 - 0.771: Magic = 0x5F339CFE, Avg Relative Error = 0.000017629, Max Relative Error = 0.000050824
Range 0.771 - 0.841: Magic = 0x5F35DFC7, Avg Relative Error = 0.000046898, Max Relative Error = 0.000138829
Range 0.841 - 0.917: Magic = 0x5F392A56, Avg Relative Error = 0.000097152, Max Relative Error = 0.000292099
Range 0.917 - 1.000: Magic = 0x5F3CC044, Avg Relative Error = 0.000129407, Max Relative Error = 0.000243633
Normalized Avg Relative error = 0.000029352 ---- Normalized Max Relative Error = 0.000078104

Optimal constants for 32 slices between 0.250 and 1.000:
Range 0.250 - 0.261: Magic = 0x5F3EA97E, Avg Relative Error = 0.000013662, Max Relative Error = 0.000040929
Range 0.261 - 0.273: Magic = 0x5F3C1FD5, Avg Relative Error = 0.000011627, Max Relative Error = 0.000035105
Range 0.273 - 0.285: Magic = 0x5F39D816, Avg Relative Error = 0.000009734, Max Relative Error = 0.000029640
Range 0.285 - 0.297: Magic = 0x5F37CE5E, Avg Relative Error = 0.000008035, Max Relative Error = 0.000024173
Range 0.297 - 0.310: Magic = 0x5F3605A5, Avg Relative Error = 0.000006259, Max Relative Error = 0.000019111
Range 0.310 - 0.324: Magic = 0x5F347E26, Avg Relative Error = 0.000004735, Max Relative Error = 0.000014254
Range 0.324 - 0.339: Magic = 0x5F333862, Avg Relative Error = 0.000003264, Max Relative Error = 0.000009849
Range 0.339 - 0.354: Magic = 0x5F323699, Avg Relative Error = 0.000002000, Max Relative Error = 0.000006096
Range 0.354 - 0.369: Magic = 0x5F3179A5, Avg Relative Error = 0.000001009, Max Relative Error = 0.000003042
Range 0.369 - 0.386: Magic = 0x5F31016A, Avg Relative Error = 0.000000341, Max Relative Error = 0.000000962
Range 0.386 - 0.403: Magic = 0x5F30CC7E, Avg Relative Error = 0.000000033, Max Relative Error = 0.000000149
Range 0.403 - 0.420: Magic = 0x5F30EB63, Avg Relative Error = 0.000000211, Max Relative Error = 0.000000606
Range 0.420 - 0.439: Magic = 0x5F314E75, Avg Relative Error = 0.000000966, Max Relative Error = 0.000002844
Range 0.439 - 0.459: Magic = 0x5F31FEC4, Avg Relative Error = 0.000002460, Max Relative Error = 0.000007184
Range 0.459 - 0.479: Magic = 0x5F32FCED, Avg Relative Error = 0.000004745, Max Relative Error = 0.000014046
Range 0.479 - 0.500: Magic = 0x5F344BAF, Avg Relative Error = 0.000007978, Max Relative Error = 0.000023855
Range 0.500 - 0.522: Magic = 0x5F347D92, Avg Relative Error = 0.000004242, Max Relative Error = 0.000012729
Range 0.522 - 0.545: Magic = 0x5F338CEE, Avg Relative Error = 0.000002881, Max Relative Error = 0.000008538
Range 0.545 - 0.569: Magic = 0x5F32D271, Avg Relative Error = 0.000001654, Max Relative Error = 0.000004947
Range 0.569 - 0.595: Magic = 0x5F324E6A, Avg Relative Error = 0.000000764, Max Relative Error = 0.000002249
Range 0.595 - 0.621: Magic = 0x5F3201BB, Avg Relative Error = 0.000000182, Max Relative Error = 0.000000552
Range 0.621 - 0.648: Magic = 0x5F31ECFC, Avg Relative Error = 0.000000029, Max Relative Error = 0.000000096
Range 0.648 - 0.677: Magic = 0x5F321747, Avg Relative Error = 0.000000397, Max Relative Error = 0.000001152
Range 0.677 - 0.707: Magic = 0x5F327A1D, Avg Relative Error = 0.000001378, Max Relative Error = 0.000004022
Range 0.707 - 0.738: Magic = 0x5F331AC5, Avg Relative Error = 0.000003004, Max Relative Error = 0.000009123
Range 0.738 - 0.771: Magic = 0x5F33F910, Avg Relative Error = 0.000005593, Max Relative Error = 0.000016958
Range 0.771 - 0.805: Magic = 0x5F35183C, Avg Relative Error = 0.000009376, Max Relative Error = 0.000027920
Range 0.805 - 0.841: Magic = 0x5F3678FE, Avg Relative Error = 0.000014232, Max Relative Error = 0.000042632
Range 0.841 - 0.878: Magic = 0x5F381D39, Avg Relative Error = 0.000020691, Max Relative Error = 0.000061661
Range 0.878 - 0.917: Magic = 0x5F3A06AF, Avg Relative Error = 0.000029335, Max Relative Error = 0.000085682
Range 0.917 - 0.958: Magic = 0x5F3C37A5, Avg Relative Error = 0.000038837, Max Relative Error = 0.000116182
Range 0.958 - 1.000: Magic = 0x5F3E444F, Avg Relative Error = 0.000037218, Max Relative Error = 0.000069158
Normalized Avg Relative error = 0.000007715 ---- Normalized Max Relative Error = 0.000021733

*/
