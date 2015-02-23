/* make the MOD function fast (in place of %): takes advantage of
   power of 2 mod operation... */
/* NOTE: "b" must be a power of 2 !!!! */
#define MOD(a,b)        ((a) & (b-1))

/* Slower MOD function that does not require power of 2. */
/* NOTE: Assumes, however, that "a < 2*b". */
#define MOD_S(a,b)        ( (a)>=(b) ? (a)-(b) : (a) )

/* Complements of multiscalar simulator... */
#define IsPow2(a)               (((a) & ((a) - 1)) ? 0 : 1)
