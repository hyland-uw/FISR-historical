// Functions to create probability arrays
void create_prob_array(double array[32]) {
    int i;
    for (i = 0; i < 32; i++) {
        array[i] = ldexp(1, -(32 - i));
    }
}
// Create a gapped one without a fuss. You could 
// use a location > 31 to create a full array.
void create_gapped_prob_array(double array[32], int location) {
    int i;
    for (i = 0; i < 32; i++) {
        if (i == location) {
            array[i] = 0;
        } else {
            array[i] = ldexp(1, -(32 - i));
        }
    }
}

// We have individual probabilities in the array
// but to select them we want an array of the
// cumulative sum of the probabilities.
void compute_cumulative_sum(double arr[], double sum[]) {
  for (int i = 0; i < 32; i++) {
    sum[i + 1] = sum[i] + arr[i];
  }  
}

// Who knew you need to just use a for loop?
// https://stackoverflow.com/a/16734848/1188479
void multiply_array_by_scalar(double array[32], double scalar) {
    int i;
    for (i = 0; i < 32; i++) {
        array[i] *= scalar;
    }
}

// Same deal.
void add_32_arrays(double left[32], double right[32], double output[32]) {
    int i;
    for (i = 0; i < 32; i++) {
        output[i] += left[i] + right[i];
    }
}



// Select a bit based on our probability array.
int choose_bit(double array[32]) {
  double cumsum[33] = { 0 };
  compute_cumulative_sum(array, cumsum);
  // https://stackoverflow.com/a/6219525
  double r = (double)rand() / (double)((unsigned)RAND_MAX);
  for (int i = 0; i < 32; i++) {
    if (cumsum[i] <= r && r < cumsum[i + 1]) {
      return i;
    }
  }
}

// Mutate the probability array and return the bit that was flipped.
int mutate_and_advance(double array[32]) {
    double gapped[32];
    float chosen_prob;

    // Choose a bit to flip
    int bit = choose_bit(array);
    // Create a gapped array
    create_gapped_prob_array(gapped, bit);
    // Multiply the gapped array by the chosen probability
    chosen_prob = array[bit];
    array[bit] = 0;
    multiply_array_by_scalar(gapped, chosen_prob);
    // Add to the existing array, which has the 
    // chosen bit set to zero.
    add_32_arrays(array, gapped, array);
    return bit;
}

// Could probably use this pattern more 
typedef struct {
    int iterations_completed;
    float after_first_iter;
} Q_rsqrt_results;

Q_rsqrt_results Q_rsqrt_iter(float number, uint32_t magic, float tol, int iters) {
    union {
        float    f;
        uint32_t i;
    } conv = { .f = number };

    conv.i  = magic - (conv.i >> 1);

    int counter = 0;
    float ref = 1 / sqrtf(number);
  
    Q_rsqrt_results results = {0, 0};

    while (counter < iters) {
        conv.f *= 1.5F - (number * 0.5F * conv.f * conv.f);
        results.iterations_completed = ++counter;
        if (counter == 1) {
          results.after_first_iter = conv.f;
        }  
        if (fabsf(ref - conv.f) < tol) {
            break;
        }
    }
    return results;
}

void generate_timelines(uint32_t magic, int max_NR_iters, float tol, int timelines, float flt_min, float flt_max) {
    double probabilities[32];
    float ref, error, input;
    int iters, steps, flipped;
    float curr_x, curr_y;
    uint32_t stored_magic = magic;
    int current_timeline = 1;

    srand(time(NULL));
    printf("input,error,magic,iters,flipped,steps, timeline\n");
    while (current_timeline <= timelines) {
        create_prob_array(probabilities);
        iters = 0;
        steps = 0;
        curr_x = 0;
        curr_y = 0;


        while (iters < max_NR_iters) {
            input = uniformDraw(flt_min, flt_max);
            Q_rsqrt_results results = Q_rsqrt_iter(input, magic, tol, max_NR_iters);
            steps++;
            ref = 1 / sqrtf(input);
            error = fabs(ref - results.after_first_iter);
            iters = results.iterations_completed;
            flipped = mutate_and_advance(probabilities);
            magic ^= 1 << (31 - flipped);
            printf("%f,%f,0x%08x,%d,%d,%d,%d\n", input, error, magic, iters, flipped, steps, current_timeline);
        }
        current_timeline++;
        magic = stored_magic;
    }
}