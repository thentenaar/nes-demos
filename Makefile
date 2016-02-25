# Toplevel Makefile

DEMOS = ff3-intro-screen ff3-overworld-water ff3-starfield neslife

all: bin/common.a $(DEMOS)

bin:
	@mkdir -p bin

bin/common.a: bin
	@$(MAKE) -r -C src TOPLEVEL=`pwd` all

ff3-intro-screen:
	@$(MAKE) -r -C src/$@ TOPLEVEL=`pwd` all

ff3-overworld-water:
	@$(MAKE) -r -C src/$@ TOPLEVEL=`pwd` all

ff3-starfield:
	@$(MAKE) -r -C src/$@ TOPLEVEL=`pwd` all

neslife:
	@$(MAKE) -r -C src/$@ TOPLEVEL=`pwd` all

clean: bin
	@$(MAKE) -r -C src clean
	@$(MAKE) -r -C src/neslife TOPLEVEL=`pwd` clean
	@$(RM) bin/common.a bin/*.nes src/*/*.o

.PHONY: all clean $(DEMOS)
