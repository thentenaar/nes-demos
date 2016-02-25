;
; neslife - Conway's Game of Life for the NES
; Copyright (C) 2016 Tim Hentenaar.
; See the LICENSE file for details.
;

.include "life.inc"

.import table_16_all_dead, table_16_both_alive
.import table_16_left_only, table_16_right_only
.import table_25_all_dead, table_25_both_alive
.import table_25_left_only, table_25_right_only
.import table_34_all_dead, table_34_both_alive
.import table_34_left_only, table_34_right_only

.export life_init, life_set_neighborhood, life_set_topology
.export life_calculate_next_generation, life_toggle_cell
.export life_damage_list
.exportzp life_damage_ctr

.zeropage

	; State table pointers
	state:             .res 2
	new_state:         .res 2

	; Block state bytes for the current, next, and previous rows
	byte0:             .res 1
	byte1:             .res 1
	byte2:             .res 1
	prev_byte1:        .res 1

	; Mask bytes
	mask_16_top:       .res 1
	mask_16_bottom:    .res 1
	mask_25_top:       .res 1
	mask_25_bottom:    .res 1

	; Temporary byte and counters
	tmp:               .res 1
	tmp2:              .res 1
	tmp3:              .res 1
	state_row_ctr:     .res 1
	state_block_ctr:   .res 1
	state_selector:    .res 1

	; Damage list tracking
	damage_list:       .res 2
	life_damage_ctr:   .res 1 ; Number of items in the damage list

	; Configuration values
	topology:          .res 1 ; 1 if toroidal, 0 if square
	neighborhood:      .res 1 ; 0 if Moore, 1 if van Neumann

.segment "BSS"

	.align 256
	state1: .res (BOARD_HEIGHT + 2) * ROW_BLOCKS

	.align 8
	row_buffer: .res ROW_BLOCKS

	.align 256
	state2: .res (BOARD_HEIGHT + 2) * ROW_BLOCKS

.segment "PRGRAM"

	.align 128
	life_damage_list: .res .sizeof(life_damage) * ROW_BLOCKS * BOARD_HEIGHT

.code

;
; Initialize the Life engine.
;
; Clobbers:
;    X
;
.proc life_init
	lda #0
	sta state_selector
	lda #TOPOLOGY_TOROID
	sta topology
	jsr set_state_table_pointers
	lda #NEIGHBORHOOD_MOORE
.endproc

;
; Set the neighborhood type to be used.
;
; Inputs:
;    A - Neighborhood type
;
; Clobbers:
;    X
;
.proc life_set_neighborhood
	and #((NEIGHBORHOODS - 1) | 1)
	tax
	sta neighborhood
	lda mask_table, x
	sta mask_16_top
	lda mask_table+NEIGHBORHOODS, x
	sta mask_16_bottom
	lda mask_table+NEIGHBORHOODS * 2, x
	sta mask_25_top
	lda mask_table+NEIGHBORHOODS * 3, x
	sta mask_25_bottom
	rts
.endproc

;
; Toggle the state of one specific cell.
;
; Inputs:
;    X - Cell number (0..5)
;    Y - Row Number (0..BOARD_HEIGHT-1)
;    A - Block Number
;
; Clobbers:
;    X, Y
;
.proc life_toggle_cell
	cpx #6
	bcs @return
	sta tmp3

	cpy #BOARD_HEIGHT - 1
	bcs @return

	; Get the offset of the row in the state array
	sty tmp
	lda #ROW_BLOCKS
	cpy #0
	beq @get_block_pos
	clc
:	adc #ROW_BLOCKS
	dey
	bne :-

@get_block_pos:
	; Now figure in the block position
	sta tmp2
	clc
	adc tmp3
	tay

	; Store the offset of the last block on the row in tmp2
	lda tmp2
	clc
	adc #ROW_BLOCKS - 1
	sta tmp2

	; Get the position of the bit within the block
	; for the specified cell, and toggle it
	lda cell_positions, x
	eor (state), y
	sta (state), y

	; Rectify the remaining blocks in the row, if
	; this isn't the first block
	lda tmp3
	bne :+
	iny
:	jsr set_state_table_pointers
:	jsr rectify_block
	iny
	cpy tmp2
	bne :-
	jsr rectify_row_edges

	; Re-copy the board's edge rows if we changed them
	ldy tmp
	beq :+
	cpy #BOARD_HEIGHT - 1
	bne :+

	ldy #ROW_BLOCKS + (ROW_BLOCKS * BOARD_HEIGHT) - 1
	jsr shadow_edge_rows
:	jsr set_state_table_pointers

@return:
	rts
.endproc

;
; Set the topology of the board, which
; can be either toroidal, or square.
;
; Inputs:
;    A - Board topology
;
.proc life_set_topology
	and #1
	sta topology
	rts
.endproc

;
; Compute the next generation, and update
; the damage_list with the state of all
; modified blocks.
;
; Output:
;    life_damage_ctr - Count of damage list entries.
;
; Clobbers:
;    X, Y
;
.proc life_calculate_next_generation
	lda #<life_damage_list
	sta damage_list
	lda #>life_damage_list
	sta damage_list+1
	lda #0
	sta life_damage_ctr
	sta state_row_ctr

	; Skip the first physical row
	lda #ROW_BLOCKS
	tay

@row:
	lda #0
	sta state_block_ctr
	sta prev_byte1

@block:
	lda #0
	sta (new_state), y
	jsr prepare_state

	; Skip empty blocks of cells
	lda byte0
	ora byte1
	ora byte2
	bne :+

	; Ensure that we rectify forward if the previous cell
	; was non-zero.
	lda prev_byte1
	and #$7e
	bne @rectify
	beq @next_block

	; Calculate the next state for this block
:	jsr mutate_state

	; See which cells changed in this block (if any)
	eor byte1
	and #$7e
	beq @rectify

	; Save the state index
	pha
	tya
	tax
	pla

	; Set the damaged block state
	ldy #.sizeof(life_damage) - 1
	lda prev_byte1
	sta (damage_list), y

	; Set the damaged block number
	lda state_block_ctr
	dey
	sta (damage_list), y

	; Set the damaged row number
	lda state_row_ctr
	dey
	sta (damage_list), y

	; Increment the damage_list counter and pointer
	inc life_damage_ctr
	ldy #.sizeof(life_damage)
:	inc damage_list
	bne :+
	inc damage_list+1
:	dey
	bne :--
	txa
	tay

@rectify:
	; Edges are rectified when the row is finished
	lda state_block_ctr
	beq @next_block
	cmp #ROW_BLOCKS - 1
	beq @next_block

	; Rectify and Rotate the block
	jsr rectify_block

@next_block:
	iny
	inc state_block_ctr
	lda #ROW_BLOCKS
	cmp state_block_ctr
	bne @block

	; Rectify the row edges if the board is toroidal.
	lda topology
	beq :+
	jsr rectify_row_edges

	; Loop through all rows
:	inc state_row_ctr
	lda #BOARD_HEIGHT
	cmp state_row_ctr
	bne @row

	; Make shadow copies of first and last row (if toroidal)
	lda topology
	beq @done
	jsr shadow_edge_rows

@done:
	; Swap state and new_state
	jsr set_state_table_pointers
	rts
.endproc

;
; Make a shadow copy of the rows at the top and bottom
; edges of the board.
;
; Inputs:
;    Y - Index of the last block of the last row
;
; Clobbers:
;    X
;
.proc shadow_edge_rows
	; Y should correspond to the last block of the last row here
	; so, copy the last row into the row buffer.
	ldx #ROW_BLOCKS - 1
:	lda (new_state), y
	sta row_buffer, x
	dey
	dex
	bpl :-

	; Now, get the offset of the shadow row at the end
	tya
	clc
	adc #ROW_BLOCKS
	pha

	; Set Y to point to the first shadow row, and copy
	; the row buffer into place.
	ldy #0
:	lda row_buffer, x
	sta (new_state), y
	inx
	iny
	cpy #ROW_BLOCKS
	bne :-

	; Now, copy the first row into the row buffer, since
	; Y should be at the start of the first row.
	ldx #0
:	lda (new_state), y
	sta row_buffer, x
	inx
	iny
	cpx #ROW_BLOCKS
	bne :-

	; Copy the row buffer into the shadow row at the end
	pla
	tay
	ldx #0
:	lda row_buffer, x
	sta (new_state), y
	iny
	inx
	cpx #ROW_BLOCKS
	bne :-
	rts
.endproc

;
; Fetch the previous row, current row, and next row's bytes
; from the state array in preparation for generating the next
; state.
;
.proc prepare_state
	tya
	pha
	lda (state), y            ; Current Row
	sta byte1
	tya
	sec
	sbc #ROW_BLOCKS
	tay
	lda (state), y            ; Previous Row
	sta byte0
	tya
	clc
	adc #(2 * ROW_BLOCKS)
	tay
	lda (state), y            ; Next Row
	sta byte2
	pla
	tay
	rts
.endproc

;
; Determine the next state for the current block of 6 cells,
; using tables to acheive 2-way parallelism.
;
; This takes around 303 clock cycles for all 6 cells,
; which is 50.5 clock cycles per cell.
;
; Returns: new cell state in A.
;
.proc mutate_state
	lda byte0
	and mask_16_top
	tax
	lda nibble_pop, x
	sta tmp
	lda byte1
	and #$a5
	tax
	lda nibble_pop, x
	clc
	adc tmp
	sta tmp
	lda neighborhood
	tax
	lda byte2
	and mask_16_bottom
	tax
	lda nibble_pop, x
	clc
	adc tmp
	tax

	; Figure out which table to pull from based on
	; the state of cells 1 and 6.
	lda byte1
	and #$42
	beq @all_dead_16
	cmp #$40
	beq @left_only_16
	bcc @right_only_16
	lda table_16_both_alive, x
	bpl @do_25

@all_dead_16:
	lda table_16_all_dead, x
	bpl @do_25

@left_only_16:
	lda table_16_left_only, x
	bpl @do_25

@right_only_16:
	lda table_16_right_only, x

@do_25:
	ora (new_state), y
	sta (new_state), y
	lda byte0
	and mask_25_top
	tax
	lda nibble_pop, x
	sta tmp
	lda byte1
	and #$5a
	tax
	lda nibble_pop, x
	clc
	adc tmp
	sta tmp
	lda byte2
	and mask_25_bottom
	tax
	lda nibble_pop, x
	clc
	adc tmp
	tax

	; Figure out which table to pull from based on
	; the state of cells 2 and 5.
	lda byte1
	and #$24
	beq @all_dead_25
	cmp #$20
	beq @left_only_25
	bcc @right_only_25
	lda table_25_both_alive, x
	bpl @do_34

@all_dead_25:
	lda table_25_all_dead, x
	bpl @do_34

@left_only_25:
	lda table_25_left_only, x
	bpl @do_34

@right_only_25:
	lda table_25_right_only, x

@do_34:
	ora (new_state), y
	sta (new_state), y
	lda byte0
	asl
	and #$70
	sta tmp2
	lda byte0
	lsr
	and #$0e
	ora tmp2
	and mask_25_top
	tax
	lda nibble_pop, x
	sta tmp
	lda byte1
	asl
	and #$50
	sta tmp2
	lda byte1
	lsr
	and #$0a
	ora tmp2
	tax
	lda nibble_pop, x
	clc
	adc tmp
	sta tmp
	lda byte2
	asl
	and #$70
	sta tmp2
	lda byte2
	lsr
	and #$0e
	ora tmp2
	and mask_25_bottom
	tax
	lda nibble_pop, x
	clc
	adc tmp
	tax

	; Figure out which table to pull from based on
	; the state of cells 3 and 4.
	lda byte1
	and #$18
	beq @all_dead_34
	cmp #$10
	beq @left_only_34
	bcc @right_only_34
	lda table_34_both_alive, x
	bpl @done

@all_dead_34:
	lda table_34_all_dead, x
	bpl @done

@left_only_34:
	lda table_34_left_only, x
	bpl @done

@right_only_34:
	lda table_34_right_only, x

@done:
	ora (new_state), y
	sta (new_state), y
	sta prev_byte1
	rts
.endproc

;
; Copy the first and last bits of the
; specified block into the next / previous
; blocks to simplify neighbor counting.
;
; Input:
;    Y - Current block
;
.proc rectify_block
	lda (new_state), y
	and #$40
	beq :+
	asl
	asl
	rol
:	dey
	ora (new_state), y
	sta (new_state), y

	and #$02
	beq :+
	lsr
	lsr
	ror
:	iny
	ora (new_state), y
	sta (new_state), y
	rts
.endproc

;
; Copy the state of the last cell of the row into
; the first block, and the first cell into the last
; block to simplify neighbor counting.
;
; Assumes:
;    Y points to cell at the end of the row.
;
.proc rectify_row_edges
	lda (new_state), y
	and #$20
	beq :+
	lsr
	clc
	ror
:	dey
	dey
	dey
	dey
	ora (new_state), y
	sta (new_state), y

	and #$40
	beq :+
	asl
	clc
	rol
:	iny
	iny
	iny
	iny
	ora (new_state), y
	sta (new_state), y
	rts
.endproc

;
; Set the state table pointers in the zero page
; to point to the correct tables.
;
.proc set_state_table_pointers
	lda state_selector
	bne @state_1

	; Initial configuration
	lda #<state1
	sta state
	lda #>state1
	sta state+1
	lda #<state2
	sta new_state
	lda #>state2
	sta new_state+1
	bpl @done

@state_1:
	; Second configuration
	lda #<state2
	sta state
	lda #>state2
	sta state+1
	lda #<state1
	sta new_state
	lda #>state1
	sta new_state+1

@done:
	lda #1
	eor state_selector
	sta state_selector
	rts
.endproc

.rodata

; Positions of a particular cell within a block.
.align 16
cell_positions:
	.byte %01000000 ; 1
	.byte %00100000 ; 2
	.byte %00010000 ; 3
	.byte %00001000 ; 4
	.byte %00000100 ; 5
	.byte %00000010 ; 6

; Masks for excluding cells outside of the
; neighborhood boundaries.
mask_table:
	; Moore / van Neumann
	.byte $e7, $42 ; 1/6: top
	.byte $e7, $42 ; 1/6: bottom
	.byte $7e, $24 ; 2/5: top
	.byte $7e, $24 ; 2/5: bottom

;
; Bit population counts per nibble.
;
.align 256
nibble_pop:
	.byte $00, $01, $01, $02, $01, $02, $02, $03
	.byte $01, $02, $02, $03, $02, $03, $03, $04
	.byte $10, $11, $11, $12, $11, $12, $12, $13
	.byte $11, $12, $12, $13, $12, $13, $13, $14
	.byte $10, $11, $11, $12, $11, $12, $12, $13
	.byte $11, $12, $12, $13, $12, $13, $13, $14
	.byte $20, $21, $21, $22, $21, $22, $22, $23
	.byte $21, $22, $22, $23, $22, $23, $23, $24
	.byte $10, $11, $11, $12, $11, $12, $12, $13
	.byte $11, $12, $12, $13, $12, $13, $13, $14
	.byte $20, $21, $21, $22, $21, $22, $22, $23
	.byte $21, $22, $22, $23, $22, $23, $23, $24
	.byte $20, $21, $21, $22, $21, $22, $22, $23
	.byte $21, $22, $22, $23, $22, $23, $23, $24
	.byte $30, $31, $31, $32, $31, $32, $32, $33
	.byte $31, $32, $32, $33, $32, $33, $33, $34
	.byte $10, $11, $11, $12, $11, $12, $12, $13
	.byte $11, $12, $12, $13, $12, $13, $13, $14
	.byte $20, $21, $21, $22, $21, $22, $22, $23
	.byte $21, $22, $22, $23, $22, $23, $23, $24
	.byte $20, $21, $21, $22, $21, $22, $22, $23
	.byte $21, $22, $22, $23, $22, $23, $23, $24
	.byte $30, $31, $31, $32, $31, $32, $32, $33
	.byte $31, $32, $32, $33, $32, $33, $33, $34
	.byte $20, $21, $21, $22, $21, $22, $22, $23
	.byte $21, $22, $22, $23, $22, $23, $23, $24
	.byte $30, $31, $31, $32, $31, $32, $32, $33
	.byte $31, $32, $32, $33, $32, $33, $33, $34
	.byte $30, $31, $31, $32, $31, $32, $32, $33
	.byte $31, $32, $32, $33, $32, $33, $33, $34
	.byte $40, $41, $41, $42, $41, $42, $42, $43
	.byte $41, $42, $42, $43, $42, $43, $43, $44

; vi:set ft=ca65:
