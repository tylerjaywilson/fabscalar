#ifndef _VERI_MEMORY_H
#define _VERI_MEMORY_H

#include "ss.h"

class veri_memory {

private:

SS_ADDR_TYPE ld_text_base;
SS_ADDR_TYPE ld_text_size;
SS_ADDR_TYPE ld_data_base;
SS_ADDR_TYPE ld_data_size;
SS_ADDR_TYPE ld_stack_base;
SS_ADDR_TYPE ld_stack_size;
SS_ADDR_TYPE ld_prog_entry;
SS_ADDR_TYPE ld_environ_base;

  //////////////////////////
  //  Memory
  ////////////////////////// 
  char *text_mem_table[MEMORY_TABLE_SIZE];
  char *mem_table[MEMORY_TABLE_SIZE];

  //////////////////////////
  //  Data Cache
  ////////////////////////// 
  // ER 11/16/02
  //CacheClass DC;
  //CacheClass *DC;

  // ER 11/16/02
  unsigned int Tid;

  //////////////////////////
  // Number of loads and stores.
  unsigned int n_load;
  unsigned int n_store;

  //////////////////////////
  //  Private functions
  //////////////////////////

  // Allocate a chunk of memory.
  char *mem_newblock(void);


public:

  veri_memory(/*CacheClass *DC,*/unsigned int Tid,
	      SS_ADDR_TYPE ld_text_base,
	      SS_ADDR_TYPE ld_text_size) {

    unsigned int i,j;


    this->Tid = Tid;
    this->ld_text_base = ld_text_base;
    this->ld_text_size = ld_text_size;

    for (unsigned int i = 0; i < MEMORY_TABLE_SIZE; i++)
      mem_table[i] = (char *)NULL;

    // STATS
    n_load = 0;
    n_store = 0;

  } // Constructor

  void fetch(unsigned int pc, SS_INST_TYPE& inst);

  
  void copy_mem(char **master_mem_table);
  void copy_text_mem(char **master_mem_table);

  // STATS
  void stats(FILE *fp);


  // Wrapper function to read from/write to memory

  unsigned char read_unsigned_byte(unsigned int addr) {
    return (MEM_READ_UNSIGNED_BYTE(addr));
  }    
      
  signed char read_signed_byte(unsigned int addr) {
    return (MEM_READ_SIGNED_BYTE(addr));
  }

  unsigned short read_unsigned_half(unsigned int addr) {
    return (MEM_READ_UNSIGNED_HALF(addr));
  }

  signed short read_signed_half(unsigned int addr) {
    return (MEM_READ_SIGNED_HALF(addr));
  }

  SS_WORD_TYPE read_word(unsigned int addr) {
    return (MEM_READ_WORD(addr));
  }

  void write_word(SS_WORD_TYPE src, unsigned int addr) {
    MEM_WRITE_WORD(src, addr);
  }

  void write_half(unsigned short src, unsigned int addr) {
    MEM_WRITE_HALF(src, addr);
  }

  void write_byte(unsigned char src, unsigned int addr) {
    MEM_WRITE_BYTE(src, addr);
  }

}; 


#endif
