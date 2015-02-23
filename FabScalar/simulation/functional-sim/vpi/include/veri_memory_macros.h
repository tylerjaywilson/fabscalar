#ifndef _VERI_MEMORY_MACROS_H
#define _VERI_MEMORY_MACROS_H

/* memory indirect table size (upper mem is not used) */
#define MEMORY_TABLE_SIZE		0x8000 /* was: 0x7fff */

/* memory block size, in bytes */
#define MEMORY_BLOCK_SIZE		0x10000

/* memory access macros */
#if 0
#define MEMORY_BLOCK(addr) 	(((SS_ADDR_TYPE)(addr)) >> 16)
#else
#define MEMORY_BLOCK(addr) 	((((SS_ADDR_TYPE)(addr)) >> 16) & 0xffff)
#endif
#if 0
#define MEMORY_OFFSET(addr)	((((SS_ADDR_TYPE)(addr)) << 16) >> 16)
#else
#define MEMORY_OFFSET(addr)	((addr) & 0xffff)
#endif


/* ER 9/29/02: Bounds check. */
#define MEMORY_IN_BOUNDS(addr)	(MEMORY_BLOCK(addr) < MEMORY_TABLE_SIZE)


#define __UNCHK_MEMORY_ACCESS(type, addr)				\
  (*((type *)(mem_table[MEMORY_BLOCK(addr)] + MEMORY_OFFSET(addr))))

#define __UNCHK_TEXT_MEMORY_ACCESS(type, addr)				\
  (*((type *)(text_mem_table[MEMORY_BLOCK(addr)] + MEMORY_OFFSET(addr))))

#define __MEMORY_ACCESS(type, addr)					\
   ((!mem_table[MEMORY_BLOCK(addr)]					\
    ? (mem_table[MEMORY_BLOCK(addr)] = mem_newblock())			\
    : 0),								\
   *((type *)(mem_table[MEMORY_BLOCK(addr)] + MEMORY_OFFSET(addr))))

/* fast memory access macros, these are unsafe, use lower case versions
   to enable alignment and permission checks; note, these macros may by used
   as l-value or r-values; note, all returned integer values are unsigned */
#define MEMORY_WORD(addr)		__MEMORY_ACCESS(unsigned long, addr)
#define MEMORY_HALF(addr)		__MEMORY_ACCESS(unsigned short, addr)
#define MEMORY_BYTE(addr)		__MEMORY_ACCESS(unsigned char, addr)


#define MEM_READ_WORD(SRC)						\
  (/* num_refs++, */MEMORY_WORD(SRC))
#define MEM_READ_UNSIGNED_HALF(SRC)					\
  (/* num_refs++, */(unsigned long)((unsigned short)MEMORY_HALF(SRC)))
#define MEM_READ_SIGNED_HALF(SRC)					\
  (/* num_refs++, */(signed long)((signed short)MEMORY_HALF(SRC)))
#define MEM_READ_UNSIGNED_BYTE(SRC)					\
  (/* num_refs++, */(unsigned long)((unsigned char)MEMORY_BYTE(SRC)))
#define MEM_READ_SIGNED_BYTE(SRC)					\
  (/* num_refs++, */(unsigned long)((signed long)((signed char)MEMORY_BYTE(SRC))))

#define MEM_WRITE_WORD(SRC, DST)					\
  (/* num_refs++, */MEMORY_WORD(DST) = (unsigned long)(SRC))
#define MEM_WRITE_HALF(SRC, DST)					\
  (/* num_refs++, */MEMORY_HALF(DST) = (unsigned short)((unsigned long)(SRC)))
#define MEM_WRITE_BYTE(SRC, DST)					\
  (/* num_refs++, */MEMORY_BYTE(DST) = (unsigned char)((unsigned long)(SRC)))



#endif // _VERI_MEMORY_MACROS_H
