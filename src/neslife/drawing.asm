;
; neslife - Conway's Game of Life for the NES
; Copyright (C) 2016 Tim Hentenaar.
; See the LICENSE file for details.
;

.zeropage
	; Temporary values
	tmp:               .res 1
	tmp2:              .res 1

	; State tracking for damage rendering
	damage_rendered:   .res 1 ; Number of entries rendered
	damage_list_ptr:   .res 2 ; Current location in the damage list
	damage_row_offset: .res 1 ; Current row / block offset
	speed:             .res 1 ; Rate at which damage is drawn
	delay:             .res 1 ; Number of frames to delay when drawing

.code

.include "life.inc"
.include "../ppu.inc"

.import life_damage_list, life_toggle_cell
.import enable_ppu, disable_ppu, reset_ppu_scroll
.export drawing_init, drawing_set_cell

.importzp longptr, nmi, life_damage_ctr, device_type
.importzp row_number, block_number, cell_number
.exportzp speed, delay

.proc drawing_init
	; Initialize the damage tracking vars
	lda #<life_damage_list
	sta damage_list_ptr
	lda #>life_damage_list
	sta damage_list_ptr+1
	lda #0
	sta damage_rendered
	sta life_damage_ctr
	sta delay

	; Install the NMI handler
	lda #<handle_nmi
	sta nmi+1
	lda #>handle_nmi
	sta nmi+2
	lda #$4c ; JMP opcode
	sta nmi

	; Set the table offset to get the delay values from.
	lda device_type
	asl
	asl
	adc device_type
	sta device_type
	jsr enable_ppu
	rts
.endproc

;
; Set the state of one cell on the screen.
;
; Input;
;    A            - Cell state (CELL_ON / CELL_OFF)
;    row_number   - Row containing the specified block
;    block_number - Block containing the cell
;    cell_number  - Cell to set
;
.proc drawing_set_cell
	pha
	txa
	pha
	tya
	pha

	; Update the cell state
	ldx cell_number
	ldy row_number
	lda block_number
	jsr life_toggle_cell

	; Draw the cell on the screen
	ldx row_number
	lda row_to_ppu_hi, x
	sta PPUADDR
	lda row_to_ppu_lo, x
	sta tmp
	ldx block_number
	lda block_to_row_offset, x
	clc
	adc tmp
	adc cell_number
	sta PPUADDR

	pla
	tay
	pla
	tax
	pla
	sta PPUDATA
	rts
.endproc

.proc handle_nmi
	pha
	tya
	pha
	txa
	pha

	; Ensure we're in VBLANK, and reset the PPU's latch
	bit PPUSTAT
	bpl @return

	; Ensure there's something to do
	lda life_damage_ctr
	beq @delay

	; Get the index for the speed table
	lsr
	lsr
	lsr
	lsr
	clc
	adc device_type
	tay

	; Just return if the simulation is stopped
	lda speed
	beq @return
	tax

	; Load the delay from the speed table
	lda speed_table, y
	sta delay

@draw:
	; Draw damage
	jsr draw_one_damage
	inc damage_rendered
	lda damage_rendered
	cmp life_damage_ctr
	beq @done

	; Go to the next entry in the list
	ldy #.sizeof(life_damage)
:	inc damage_list_ptr
	bcc :+
	inc damage_list_ptr+1
:	dey
	bne :--
	dex
	bne @draw
	beq @delay

@done:
	; Re-initialize the tracking vars
	lda #<life_damage_list
	sta damage_list_ptr
	lda #>life_damage_list
	sta damage_list_ptr+1
	lda #0
	sta damage_rendered
	sta life_damage_ctr

@delay:
	dec delay

@return:
	jsr reset_ppu_scroll
	pla
	tax
	pla
	tay
	pla
	rti
.endproc

;
; Draw one block of damage.
;
; Input:
;    Y - Current position within the damage list
;
; Clobbers:
;    X
;
.proc draw_one_damage
	txa
	pha

	; Compute the PPU address of the beginning of the row
	ldy #life_damage::row
	lda (damage_list_ptr), y
	sta tmp
	tax
	lda row_to_ppu_hi, x
	sta longptr+1
	lda row_to_ppu_lo, x
	sta damage_row_offset
	sta longptr

	; Get the block offset
	ldy #life_damage::block
	lda (damage_list_ptr), y
	tax
	lda block_to_row_offset, x
	clc
	adc damage_row_offset
	sta longptr

	; Now, load the new state
	ldy #life_damage::state
	lda (damage_list_ptr), y
	ldx #5
	asl
	pha
	lda longptr
	tay

@cell:
	; Draw one cell in the block
	pla
	asl
	pha
	lda longptr+1
	sta PPUADDR
	sty PPUADDR
	lda #0
	rol
	sta PPUDATA
	iny
	dex
	bpl @cell

@return:
	pla
	pla
	tax
	rts
.endproc

.rodata

;
; How many frames to delay in between generations.
;
; This is derived from the amount of blocks to be
; updated, where a maximum of 100 blocks exist.
;
.align 16
speed_table:
	.byte 30, 24, 18, 12, 6 ; NTSC
	.byte 25, 20, 15, 10, 5 ; PAL
	.byte 25, 20, 15, 10, 5 ; Dendy
	.byte 30, 24, 18, 12, 6 ; Unknown (assume NTSC compatible)

; Mapping between row and hi-byte of PPU address
.align 16
row_to_ppu_hi:
	.byte $21, $21, $21, $21, $21, $21, $21
	.byte $21, $22, $22, $22, $22, $22, $22
	.byte $22, $22, $23, $23, $23, $23

; Mapping between row nad lo-byte of PPU address
.align 16
row_to_ppu_lo:
	.byte $00, $20, $40, $60, $80, $a0, $c0
	.byte $e0, $00, $20, $40, $60, $80, $a0
	.byte $c0, $e0, $00, $20, $40, $60

; PPU address offsets of blocks within a row
.align 8
block_to_row_offset:
	.byte $01, $07, $0D, $13, $19

; vi:set ft=ca65:
