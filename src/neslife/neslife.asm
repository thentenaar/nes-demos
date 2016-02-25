;
; neslife - Conway's Game of Life for the NES
; Copyright (C) 2016 Tim Hentenaar.
; See the LICENSE file for details.
;

.segment "HEADER"

; iNES Header
.byte "NES", $1a
.byte $08          ; 8x 16k bank of PRG-ROM
.byte $00          ; 0x 8k  bank of CHR-ROM (1x 8k bank of CHR-RAM)
.byte $41          ; Vertical Mirroring / Mapper Lo: 4
.byte $00          ; Mapper Hi: 0 (TxROM)

.zeropage

	; Cell editor positions
	row_number:        .res 1
	block_number:      .res 1
	cell_number:       .res 1

.code

.include "mmc3.inc"
.include "rules.inc"
.include "life.inc"
.include "patterns.inc"
.include "../ppu.inc"

.import halt, draw_pattern
.import life_init, life_toggle_cell, life_calculate_next_generation
.import life_set_topology, life_damage_list
.import drawing_init, nmi_spin
.export patterns, palettes

.exportzp block_number, row_number, cell_number
.importzp speed, delay, life_damage_ctr

init:
	; Disable MMC3 IRQ and enable PRG-RAM
	lda #MMC3_PRG_RAM_ENABLE
	sta MMC3_IRQ_DISABLE
	sta MMC3_PRG_RAM_PROT

	; Set vertical mirroring
	lda #MMC3_MIRROR_V
	sta MMC3_MIRRORING

	; Set the bank in $8000 to the default rule (B3S23)
	lda #6
	sta MMC3_BANK_SELECT
	lda #BANK_B3S23
	sta MMC3_BANK_DATA

	; Set the bank in $A000 (unused)
	lda #7
	sta MMC3_BANK_SELECT
	lda #BANK_B3S23
	sta MMC3_BANK_DATA

	; Set the default speed (0 = stopped, 6 = maximum)
	lda #3
	sta speed

	; Initialize the life engine
	jsr life_init

	; Initialize the main drawing code
	jsr drawing_init

	ldy #5 ; Row 5
	ldx #1 ; Block 1
	lda #PATTERN_PENTADECATHLON
	jsr draw_pattern

; Main loop
@gitrdone:
	jsr life_calculate_next_generation
:	lda life_damage_ctr
	bne :-
:	lda delay
	bpl :-
	jmp @gitrdone
	jmp halt

.rodata

.align 32
patterns:
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

	; Live cell
	.byte $00, $1c, $22, $22, $22, $1c, $00, $00
	.byte $00, $00, $1c, $1c, $1c, $00, $00, $00
	.byte data_end

.align 32
palettes:
	.byte $20, $0f, $19, $20 ; Background Palette 0 [ Green / White ]
	.byte data_end

; vi:ft=ca65:
