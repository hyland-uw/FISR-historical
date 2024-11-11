// We won't flip the sign bit and I 
// don't want to write "31" a lot
#define FLOATSLICE 32

// use a geometric series to sum to 1 over a finite number of terms
void create_prob_array(double array[FLOATSLICE]) {
    int n = FLOATSLICE;
    double a = 0.5;   // First term of the geometric series
    double r = 0.5;   // Common ratio of the geometric series

    // Calculating the sum of the first n terms of the geometric series
    double S_n = a * (1 - ldexp(r, n)) / (1 - r);

    // Normalizing the distribution to sum to 1
    // Start from the end of the array to bias
    // mutation toward LS bits
    for (int i = n - 1; i >= 0; --i) {
        array[i] = a * ldexp(r, i) / S_n;
    }
}

// distribute probability of 
// a flip.

void redistribute_probabilities(double array[FLOATSLICE], int position, double probabilities[FLOATSLICE]) {
    double chosen_prob = array[position];
    array[position] = 0;

    // Redistributing the probability
    for (int i = 0; i < FLOATSLICE; ++i) {
        if (i != position) {
            array[i] += chosen_prob * probabilities[i];
        }
    }
}

void copy_array(double source[FLOATSLICE], double destination[FLOATSLICE]) {
    for (int i = 0; i < FLOATSLICE; i++) {
        destination[i] = source[i];
    }
}

// Selects based on our distributed probabilities
int choose_mutation_index(double array[FLOATSLICE]) {
    double rand_val = (double)rand() / (double)RAND_MAX;
    double cum_prob = 0;
    int chosen_index = 0;
    for (int j = 0; j < FLOATSLICE; j++) {
        cum_prob += array[j];
        if (rand_val <= cum_prob) {
            chosen_index = j;
            break;
        }
    }

    return chosen_index;
}