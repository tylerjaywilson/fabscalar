#include <stdio.h>
#include "veri_memory_macros.h"
#include "veri_memory.h"
#include <stdlib.h>

void veri_memory::fetch(unsigned int pc, SS_INST_TYPE& inst) {
  // Fetch instruction from the binary.
  if ((pc < ld_text_base) || (pc > ld_text_base + ld_text_size)) {
    inst.a = 0;
    inst.b = 0;
  }
  else {
    inst = __UNCHK_TEXT_MEMORY_ACCESS(SS_INST_TYPE, (pc & ~7));
  }
} // fetch()


void veri_memory::copy_mem(char **master_mem_table) {
  for (unsigned int i = 0; i < MEMORY_TABLE_SIZE; i++) {
    if (master_mem_table[i]) {
      if (!mem_table[i])
	mem_table[i] = mem_newblock();
      for (unsigned int j = 0; j < MEMORY_BLOCK_SIZE; j++)
	mem_table[i][j] = master_mem_table[i][j];
    }
    else {
      if (mem_table[i]) {
	free(mem_table[i]);
	mem_table[i] = (char *)NULL;
      }
    }
  }
} // copy_mem()

// Copies into the text memory. Don't mess with this.
void veri_memory::copy_text_mem(char **master_mem_table) {
  for (unsigned int i = 0; i < MEMORY_TABLE_SIZE; i++) {
    if (master_mem_table[i]) {
      if (!text_mem_table[i])
	text_mem_table[i] = mem_newblock();
      for (unsigned int j = 0; j < MEMORY_BLOCK_SIZE; j++)
	text_mem_table[i][j] = master_mem_table[i][j];
    }
    else {
      if (text_mem_table[i]) {
	free(text_mem_table[i]);
	text_mem_table[i] = (char *)NULL;
      }
    }
  }
} // copy_text_mem()


// STATS
void veri_memory::stats(FILE *fp) {
  fprintf(fp, "----memory system results----\n");

  fprintf(fp, "LOADS (retired)\n");
  fprintf(fp, "  loads            = %d\n", n_load);

  fprintf(fp, "STORES (retired)\n");

  fprintf(fp, "----memory system results----\n");

//   fprintf(fp, "----DC results----\n");
//   DC->stats(fp);
//   fprintf(fp, "----DC results----\n");
}


  
///////////////////////////////////////////////////////////////////////////

char *veri_memory::mem_newblock(void) {
  char *p = new char[MEMORY_BLOCK_SIZE];

  for (unsigned int i = 0; i < MEMORY_BLOCK_SIZE; i++) {
    p[i] = (char)0;
  }
  return(p);
  //return(new char[MEMORY_BLOCK_SIZE]);
  //return((char *) getcore(MEMORY_BLOCK_SIZE));
}

///////////////////////////////////////////////////////////////////////////
