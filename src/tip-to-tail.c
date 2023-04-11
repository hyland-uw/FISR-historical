#include "utility.h"

/// These here help us draw a tail to tip path for mutations

// Map a float to radians based in subdividing a range
float map_to_radians(float input, float min, float max) {
    float scale;
    float output_range_start = 0.0;
    float output_range_end = 2 * M_PI;

    scale = (output_range_end - output_range_start) / (max - min);
    return (input - min) * scale + output_range_start;
}

// Define the coordinate struct
typedef struct {
    float x;
    float y;
} Cartesian;

// Function to convert polar coordinates to Cartesian coordinates
Cartesian polar_to_cartesian(float theta, float r) {
    Cartesian coords = {0, 0};
    coords.x = r * cos(theta);
    coords.y = r * sin(theta);

    return coords;
}