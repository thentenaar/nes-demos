
.code

.include "life.inc"

.import drawing_set_cell
.export draw_pattern

.importzp row_number, block_number, cell_number, longptr

;
; Draw a pattern on the screen.
;
; Inputs:
;    X - Block number
;    Y - Row number
;    A - Pattern number
;
.proc draw_pattern
	pha
	tya
	sta row_number
	txa
	sta block_number

	; Get the address of the pattern description
	lda #<pattern_table
	sta longptr
	lda #>pattern_table
	sta longptr+1
	pla
	asl
	tay
	lda (longptr), y
	tax
	iny
	lda (longptr), y
	sta longptr+1
	txa
	sta longptr

	; Get the pattern size
	ldy #0
	lda (longptr), y
	tax

@draw:
	; Get the cell index, and determine which block we're in
	iny
	lda (longptr), y
:	cmp #CELLS_PER_BLOCK
	bcc :+
	sbc #CELLS_PER_BLOCK
	inc block_number
	bne :-
:	sta cell_number

	; Ensure we don't go past the end of the row
	lda block_number
:	cmp #ROW_BLOCKS
	bcc :+
	sbc #ROW_BLOCKS
	inc row_number
	bne :-
:	sta block_number

	; Draw the cell
	lda #CELL_ON
	jsr drawing_set_cell
	dex
	bne @draw
	rts
.endproc

.rodata

.align 64
pattern_table:
	; Stills

	; Oscillators
	.word blinker
	.word toad
	.word beacon
	.word pulsar
	.word pentadecathlon
	.word cross

blinker: ; Period 2
	.byte 3        ; Size (in cells)
	.byte 0, 1, 2  ; Cell offsets to set within the block

toad: ; Period 2
	.byte 6        ; Size (in cells)
	.byte 0, 1, 2  ; A value of 29 means: Advance 5 blocks, and set
	               ; cell #5.
	.byte 29, 6, 1 ; 6 means: Advance one block, and set cell #0.

beacon: ; Period 2
	.byte 8
	.byte 0, 1, 30, 1
	.byte 33, 2, 32, 3

pulsar: ; Period 3
	.byte 48
	.byte 3, 4, 5, 9, 4, 5
	.byte 55, 6, 2, 7
	.byte 19, 6, 2, 7
	.byte 19, 6, 2, 7
	.byte 21, 4, 5, 9, 4, 5
	.byte 57, 4, 5, 9, 4, 5
	.byte 25, 6, 2, 7
	.byte 19, 6, 2, 7
	.byte 19, 6, 2, 7
	.byte 51, 4, 5, 9, 4, 5

pentadecathlon: ; Period 15
	.byte 12
	.byte 3, 8
	.byte 25, 2, 4, 5, 6, 1, 3, 4
	.byte 27, 8

cross: ; Period 3
	.byte 28
	.byte 3, 4, 5, 6
	.byte 27, 6
	.byte 25, 2, 3, 6, 1, 2
	.byte 25, 8
	.byte 25, 8
	.byte 25, 2, 3, 6, 1, 2
	.byte 27, 6
	.byte 27, 4, 5, 6

; vi:set ft=ca65:
