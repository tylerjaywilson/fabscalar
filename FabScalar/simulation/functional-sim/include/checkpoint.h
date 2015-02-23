struct a_checkpoint
{
  SS_COUNTER_TYPE num_insn;
  SS_COUNTER_TYPE num_refs;
  unsigned int arch_PC;
  bool blocked;

  SS_ADDR_TYPE ld_text_base;
  SS_ADDR_TYPE ld_text_size;
  SS_ADDR_TYPE ld_data_base;
  SS_ADDR_TYPE ld_data_size;
  SS_ADDR_TYPE ld_stack_base; 
  SS_ADDR_TYPE ld_stack_size;     
  SS_ADDR_TYPE ld_prog_entry;     
  SS_ADDR_TYPE ld_environ_base;     
  SS_ADDR_TYPE mem_brk_point;     
  SS_ADDR_TYPE mem_stack_min;     

  SS_WORD_TYPE regs_HI;     
  SS_WORD_TYPE regs_LO;     
  int regs_FCC;     
  unsigned int ShmemBase;     
  unsigned int ShmemEnd;     

  SS_ADDR_TYPE regs_PC;     
  SS_ADDR_TYPE next_PC;          

  SS_ADDR_TYPE lockaddr;     
  unsigned int n_shared_tas;           
  unsigned int n_shared_tas_succeed;     
  unsigned int n_private_tas;          
  unsigned int n_private_tas_succeed;     
  unsigned int n_shared_acc;           
  unsigned int n_shared_new;           
  unsigned int n_private_acc;          
  unsigned int n_private_new;          

  unsigned int real_upper;     
  unsigned int real_lower;     
  unsigned int store_addr;     
  unsigned long trap_inst_a;     
  unsigned long trap_inst_b;     

  SS_WORD_TYPE regs_R[SS_NUM_REGS];
  SS_WORD_TYPE regs_F_l[SS_NUM_REGS];
};
