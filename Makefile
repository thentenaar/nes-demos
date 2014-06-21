# Toplevel Makefile

DEMOS= src/ff3-intro-screen

all: $(DEMOS)
	@make -C $< TOPLEVEL=`pwd`

clean: bin
	@rm -f bin/*.nes

