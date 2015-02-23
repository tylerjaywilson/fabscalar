#define RSRC(n,v)     DB->push_operand_actual(n, RSRC_OPERAND, v, regs_PC)
#define RSRC_A(n,v)   DB->push_operand_actual(n, RSRC_A_OPERAND, v, regs_PC)
 
#define RDST(n,v)     DB->push_operand_actual(n, RDST_OPERAND, v, regs_PC)
 
#define MSRC_B(addr)  (get_arch_mem_value(addr, &real_upper, &real_lower), \
		       DB->push_address_actual(addr,			   \
					       MSRC_OPERAND,		   \
					       regs_PC,			   \
					       real_upper,		   \
					       real_lower))
#define MSRC_H(addr)  MSRC_B(addr)
#define MSRC_W(addr)  MSRC_B(addr)
#define MSRC_WL(addr) MSRC_B(addr)
#define MSRC_WR(addr) MSRC_B(addr)

#define MDST_B(addr)  (store_addr = addr,				   \
		       get_arch_mem_value(addr, &real_upper, &real_lower), \
		       DB->push_address_actual(addr,			   \
					       MDST_OPERAND,		   \
					       regs_PC,			   \
					       real_upper,		   \
					       real_lower))
#define MDST_H(addr)  MDST_B(addr)
#define MDST_W(addr)  MDST_B(addr)
#define MDST_WL(addr) MDST_B(addr)
#define MDST_WR(addr) MDST_B(addr)
