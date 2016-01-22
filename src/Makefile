BIN=$(TOPLEVEL)/bin
SRC=$(wildcard *.asm)
OBJ=${SRC:.asm=.o}

all: $(BIN)/common.a

clean:
	@$(RM) *.o $(BIN)/common.a

$(BIN)/common.a: $(OBJ)
	@echo "  AR $(basename $(notdir $@)).a"
	@ar65 a $@ $^

%.o: %.asm
	@echo "  AS $(basename $(notdir $<)).asm"
	@ca65 -o $@ $<

.PHONY: all clean
