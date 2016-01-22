# Toplevel Makefile

DEMOS = ff3-intro-screen ff3-overworld-water

all: bin $(DEMOS)

bin:
	@mkdir -p bin

ff3-intro-screen:
	@make -r -C src/$@ TOPLEVEL=`pwd`

ff3-overworld-water:
	@make -r -C src/$@ TOPLEVEL=`pwd`

clean: bin
	@rm -f bin/*.nes src/*/*.o src/*.o

.PHONY: all clean $(DEMOS)
