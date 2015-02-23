# Pick your favorite compiler
CC = g++

# Choose your optimization level here
OPT  = -g -O3 -finline-functions -funroll-loops
OPT2 = -ggdb -fno-inline

# INC = -I../include -I../../include
INC = -I../../include

CFLAGS  = $(OPT)  $(INC) -DSIM_LINUX -DBYTES_LITTLE_ENDIAN -DWORDS_LITTLE_ENDIAN
CFLAGS2 = $(OPT2) $(INC) -DSIM_LINUX -DBYTES_LITTLE_ENDIAN -DWORDS_LITTLE_ENDIAN


SIM_OBJ = main_misc.o syscall.o memory.o regs.o loader.o ss.o endian.o misc.o \
	  arch.o func_sim.o info.o sim_main.o 

#global_vars.o


all: libSS_VPI.a
	touch ../lib/libSS_VPI.a
	mv ../lib/libSS_VPI.a ../lib/libSS_VPI.a.bak
	cp libSS_VPI.a ../lib/libSS_VPI.a
	@echo "my work is done here..."

libSS_VPI.a:	$(SIM_OBJ)
	ar r libSS_VPI.a $(SIM_OBJ)

func_sim.o:  func_sim.cc
	$(CC) $(CFLAGS2) -c $*.cc

endian.o:  endian.cc
	$(CC) $(CFLAGS2) -c $*.cc

.cc.o:
	$(CC) $(CFLAGS2) -c $*.cc



clean:
	rm -f *.o libSS_VPI.a core

