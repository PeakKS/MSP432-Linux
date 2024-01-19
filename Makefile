# Makefile for the Texas Instruments MSP432P401R LaunchPad Development Kit (MSP-EXP432P401R).
# Supports compilation, flashing, and debugging.
#
# Depends on msp432-gcc-support-files available at:
# 	https://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSP432GCC/latest/index_FDS.html
#
# Depends on
# 	GCC
# 	OpenOCD
# 	GDB
# 
# Blake Batson - 1/18/2024
.SILENT:

USRSRC = src/blinker.c

###############################################################################
# MSP432 GCC Support Files
###############################################################################
MSPDIR   = msp432-gcc-support-files
MSPINC   = $(MSPDIR)/include
CMSISINC = $(MSPDIR)/include/CMSIS
STARTUP  = $(MSPDIR)/src/startup_msp432p401r_gcc.c
SYSTEM   = $(MSPDIR)/src/system_msp432p401r.c
LINKERSCRIPT = $(MSPINC)/msp432p401r.lds

DEVICE = MSP432P401R

###############################################################################
# Compilation
###############################################################################
SRC = $(STARTUP) $(SYSTEM) $(USRSRC)
OBJ = $(SRC:.c=.o)
ELF = firmware.elf
HEX = $(ELF:.elf=.hex)
MAPFILE = firmware.map

GCC_INSTALL_PATH = /usr/bin
GCC_TRIPLET = arm-none-eabi

CC = $(GCC_INSTALL_PATH)/$(GCC_TRIPLET)-gcc
CFLAGS  += -mcpu=cortex-m4 -march=armv7e-m -mfloat-abi=hard -mfpu=fpv4-sp-d16 -mthumb -D__$(DEVICE)__ -DTARGET_IS_MSP432P4XX -Dgcc -g -gstrict-dwarf -Wall -ffunction-sections -fdata-sections -MD -std=c99 -g -O0 -I$(MSPINC) -I$(CMSISINC) -Wa,-adhlns="$@.lst"
LDFLAGS += -mcpu=cortex-m4 -march=armv7e-m -mfloat-abi=hard -mfpu=fpv4-sp-d16 -mthumb -D__$(DEVICE)__ -DTARGET_IS_MSP432P4XX -Dgcc -g -gstrict-dwarf -Wall -T$(LINKERSCRIPT) -l'c' -l'gcc' -l'nosys' -Wl,-Map=$(MAPFILE)
OBJCPY = $(GCC_INSTALL_PATH)/$(GCC_TRIPLET)-objcopy

# GDB may or may not be prefixed with the triplet
GDB = $(GCC_INSTALL_PATH)/$(GCC_TRIPLET)-gdb
#GDB = $(GCC_INSTALL_PATH)/gdb

all: $(HEX)

$(HEX): $(ELF)
	@echo "Generating: $@ ..."
	$(OBJCPY) -O ihex $< $@

# Link the firmware
$(ELF): $(OBJ)
	@echo "Linking: $@ ..."
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

# Compile C files
.c.o:
	@echo "Compiling: $< ..."
	$(CC) $(CFLAGS) -c $< -o $@

###############################################################################
# Programming/Debugging
###############################################################################
OPENOCD = openocd
OCDSCRIPTS = /usr/share/openocd/scripts/board
OCDCFG = $(OCDSCRIPTS)/ti_msp432_launchpad.cfg

flash: $(HEX)
	openocd -f $(OCDCFG) -c "program $(HEX) verify reset exit"

debugserver: $(HEX)
	openocd -f $(OCDCFG) -c ""

debug: $(ELF)
	$(GDB) -tui -ex "target extended-remote localhost:3333" $(ELF)

###############################################################################
# Clean
###############################################################################

clean:
	-rm -f $(HEX) $(ELF) $(OBJ) $(OBJ:.o=.d) $(addsuffix .lst,$(OBJ)) $(addsuffix .lst,$(ELF)) $(MAPFILE)
