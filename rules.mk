# Common Makefile rules
BIN=$(TOPLEVEL)/bin
LDCFG=$(TOPLEVEL)/cfg
OBJS=${SRC:.asm=.o}

all: $(BIN)/$(DEMO).nes

$(BIN)/$(DEMO).nes: $(OBJS)
	@echo "Linking $(basename $(notdir $<))..."
	@ld65 -C $(LDCFG)/$(CFG).cfg -o $@ $<

%.o: %.asm
	@echo "Assembling $(basename $(notdir $<))..."
	@ca65 -o $@ $<

