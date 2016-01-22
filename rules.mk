# Common Makefile rules
BIN=$(TOPLEVEL)/bin
LDCFG=$(TOPLEVEL)/cfg
OBJ=${SRC:.asm=.o}

all: $(BIN)/$(DEMO).nes

$(BIN)/$(DEMO).nes: $(OBJ)
	@echo "  LD $(basename $(notdir $@)).nes"
	@ld65 -C $(LDCFG)/$(CFG).cfg -o $@ $^ --lib $(BIN)/common.a

%.o: %.asm
	@echo "  AS $(basename $(notdir $<)).asm"
	@ca65 -o $@ $<

