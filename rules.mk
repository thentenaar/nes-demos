# Top-level Makefile rules
OPHIS=$(TOPLEVEL)/ophis/bin/ophis
BIN=$(TOPLEVEL)/bin

all: $(BIN) $(OBJS)

%.nes: %.asm
	@echo "Assembling $(basename $(notdir $<))..."
	@$(OPHIS) -o $(BIN)/$@ $<

