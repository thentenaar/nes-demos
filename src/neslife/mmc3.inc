
; MMC3 Registers
.define MMC3_BANK_SELECT  $8000
.define MMC3_BANK_DATA    $8001
.define MMC3_MIRRORING    $a000
.define MMC3_PRG_RAM_PROT $a001
.define MMC3_IRQ_LATCH    $c000
.define MMC3_IRQ_REQLOAD  $c001
.define MMC3_IRQ_DISABLE  $e000
.define MMC3_IRQ_ENABLE   $e001

;
; Values for the MMC3_PRG_RAM_PROT register.
;
; These should be OR'd together.
;
.define MMC3_PRG_RAM_ENABLE %10000000
.define MMC3_PRG_RAM_RO     %01000000

;
; Values for the MMC3_MIRRORING register.
;
.define MMC3_MIRROR_V 0
.define MMC3_MIRROR_H 1

; vi:ft=ca65:
