DEMO = neslife
CFG  = tnrom-128
RULES = B3S23 B34S34 B1S12 B36S23 B38S23 B38S238
RULES_SRC = rules/B3S23.asm rules/B34S34.asm rules/B1S12.asm\
            rules/B36S23.asm rules/B38S23.asm rules/B38S238.asm
SRC = neslife.asm drawing.asm life.asm patterns.asm $(RULES_SRC)

neslife.asm: rules.inc

$(RULES_SRC): rules.inc

rules.inc: scripts/rulegen.rb
	@echo "  GEN rules"
	@mkdir -p rules
	@scripts/rulegen.rb $(RULES)

clean:
	@rm -rf *.o

include $(TOPLEVEL)/rules.mk

