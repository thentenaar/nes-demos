# Toplevel Makefile

DEMOS = ff3-intro-screen ff3-overworld-water

all: $(DEMOS)

ff3-intro-screen:
	@make -C src/$@ TOPLEVEL=`pwd`

ff3-overworld-water:
	@make -C src/$@ TOPLEVEL=`pwd`

clean: bin
	@rm -f bin/*.nes

.PHONY: all clean $(DEMOS)
