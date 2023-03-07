#include <math.h>

/*
A HIGH SPEED, LOW PRECISION SQUARE ROOT, Lalonde & Dawson 1990
Graphics Gems (1990) pp. 424-426,756-757
*/


/* SPARC floating point format is as follows
BIT 31   30    23 22     0
    sign exponent mantissa
*/
static short sqrttab[0x100];
void build_table() {
    unsigned short i;
    float f;
    unsigned int *fi=&f;
    for (i = 0; i <= 0x7f; i++) {
        *fi = 0;
        /* Build a float with the bit pattern i as mantissa
         * and an exponent of 0, stored as 127 */
        */
       *fi = (i << 16) | (127 << 23);
       f = sqrt(f);
       /* Take the square root then strip the first 7 bits of
        * the mantissa into the table
        */
       sqrttab[i] = (*fi & 0x7fffff) >> 16;
       /* Repeat the process, this time with an exponent of
        * 1, stored as 128
        */
       *fi = 0;
       *fi = (i << 16) | (128 << 23);
       f = sqrt(f);
       sqrttab[i + 0x80] = (*fi & 0x7fffff) >> 16;
    }
}

/*
* fsqrt - fast square root by table lookup
*/

float fsqrt(float n) {
    unsigned int *num = &n;  /* to access the bits of a float in C
                              * we must misuse pointers*/
    short e;                 /* the exponent */
    if (n == 0) return (0);  /* check for square root of 0 */
    e = (*num >> 23) - 127   /* get the exponent - on a SPARC the 
                              * exponent is stored with 127 added*/
                              /* leave only the mantissa */
    if (e & 0x01) *num | = 0x800000;
                              /* the exponent is odd so we have to
                               look it up in the second half of
                               the lookup table, so we set the 
                               high bit */
    e >>= 1;                 /* divide the exponent by 2 */ 
                             /* note that in C the shift */                        
                             /* operators are sign preserving */   
                             /* for signed operands */
/* Do the table lookup, based on the quartenary mantissa,
   then reconstruct the result back into a float
*/
    *num = (sqrttab[*num >> 16] << 16) | ((e + 127) << 23);
    return (n);
}