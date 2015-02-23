#ifndef MEMORY_H
#define MEMORY_H

#include <stdio.h>
#include "_endian.h"
#include "ss.h"

enum mem_cmd { Read, Write };

#if 0
typedef void
(*mem_access_fn)(enum mem_cmd cmd,	/* Read or Write */
		 unsigned long addr,	/* address to access */
		 void *p,		/* where to copy to/from */
		 int nbytes);		/* xfer length */
#endif

/* memory indirect table size (upper mem is not used) */
#define MEM_TABLE_SIZE		0x8000 /* was: 0x7fff */

/* memory block size, in bytes */
#define MEM_BLOCK_SIZE		0x10000

/* memory access macros */
#if 0
#define MEM_BLOCK(addr) 	(((SS_ADDR_TYPE)(addr)) >> 16)
#else
#define MEM_BLOCK(addr) 	((((SS_ADDR_TYPE)(addr)) >> 16) & 0xffff)
#endif
#if 0
#define MEM_OFFSET(addr)	((((SS_ADDR_TYPE)(addr)) << 16) >> 16)
#else
#define MEM_OFFSET(addr)	((addr) & 0xffff)
#endif


/* 12/25/99 ER: Shared memory. */
extern char *shmem_table[MEM_TABLE_SIZE];


#define __UNCHK_MEM_ACCESS(type, addr)					\
  (*((type *)(mem_table[MEM_BLOCK(addr)] + MEM_OFFSET(addr))))

#define __MEM_ACCESS(type, addr)					\
 (IsShared(addr) ?							\
  ((n_shared_acc++),							\
   (!shmem_table[MEM_BLOCK(addr)]					\
    ? (n_shared_new++, shmem_table[MEM_BLOCK(addr)] = mem_newblock())	\
    : 0),								\
   *((type *)(shmem_table[MEM_BLOCK(addr)] + MEM_OFFSET(addr)))) :	\
  ((n_private_acc++),							\
   (!mem_table[MEM_BLOCK(addr)]						\
    ? (n_private_new++, mem_table[MEM_BLOCK(addr)] = mem_newblock())	\
    : 0),								\
   *((type *)(mem_table[MEM_BLOCK(addr)] + MEM_OFFSET(addr)))))

/* fast memory access macros, these are unsafe, use lower case versions
   to enable alignment and permission checks; note, these macros may by used
   as l-value or r-values; note, all returned integer values are unsigned */
#define MEM_WORD(addr)		__MEM_ACCESS(unsigned long, addr)
#define MEM_HALF(addr)		__MEM_ACCESS(unsigned short, addr)
#define MEM_BYTE(addr)		__MEM_ACCESS(unsigned char, addr)

/* memory access functions, these are safe, swapped, and check alignment
   and permissions */
#define mem_read_word(cmd, addr, p)					\
  (mem_access(cmd, addr, p, sizeof(unsigned long)),			\
   *((unsigned long *)p) = SWAP_WORD(*((unsigned long *)p)))
#define mem_write_word(cmd, addr, p)					\
  ({ unsigned long _temp = SWAP_WORD(*((unsigned long *)p));		\
     mem_access(cmd, addr, &_temp, sizeof(unsigned long)); })

#define mem_read_half(cmd, addr, p)					\
  (mem_access(cmd, addr, p, sizeof(unsigned short)),			\
   *((unsigned short *)p) = SWAP_HALF(*((unsigned short *)p)))
#define mem_write_half(cmd, addr, p)					\
  ({ unsigned short _temp = SWAP_HALF(*((unsigned short *)p));		\
     mem_access(cmd, addr, &_temp, sizeof(unsigned short)); })

#define mem_read_byte(cmd, addr, p)					\
  mem_access(cmd, addr, p, sizeof(char))
#define mem_write_byte(cmd, addr, p)					\
  mem_access(cmd, addr, p, sizeof(char))


/* memory system-specific options */
extern char *mem_optstring;

/* parse memory system-specific options */
void mem_options(int argc, char **argv);

/* print out memory system configuration */
void mem_config(FILE *stream);

#endif /* MEMORY_H */
