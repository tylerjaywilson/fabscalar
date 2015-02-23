#ifndef _VPI_ROUTINES_H
#define _VPI_ROUTINES_H

//extern void tokenize(char *job, int& argc, char **argv);
//extern int initializeSim(char *user_data);
extern void initializeSim_register();

//extern int readOpcode_calltf(char *user_data);
extern void readOpcode_register();

//extern int readOperand_calltf(char *user_data);
extern void readOperand_register();

extern void readUnsignedByte_register();
extern void readSignedByte_register();
extern void readUnsignedHalf_register();
extern void readSignedHalf_register();
extern void readWord_register();
extern void writeByte_register();
extern void writeHalf_register();
extern void writeWord_register();
extern void getArchRegValue_register();
extern void copyMemory_register();
extern void getRetireInstPC_register();

extern void getArchPC_register();
extern void checkRetireInst_register();

extern void handleTrap_register();
extern void resumeTrap_register();

extern void getPerfectNPC_register();
extern void funcsimRunahead_register();

#endif
