;
; Final Fantasy III-like Overworld Water Animation Demo
;
; Copyright (c) 2016, Tim Hentenaar
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are
; met:
;
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
; PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;

.segment "HEADER"

; iNES Header
.byte "NES", $1a
.byte $01          ; 1x 16k bank of PRG-ROM
.byte $00          ; 0x 8k  bank of CHR-ROM (1x 8k bank of CHR-RAM)
.byte $01          ; Vertical Mirroring / Mapper Lo: 0
.byte $00          ; Mapper Hi: 0 (NROM)

.zeropage
	; Frame counter for the water animation
	water_ctr: .res 1

	; Water rotation direction
	water_dir: .res 1

.code

.include "../ppu.inc"
.include "../input.inc"

.importzp input1_stat
.import enable_ppu, reset_ppu_scroll, nmi_spin, read_input1
.export patterns, palettes

; Memory Map for utilized RAM
.define tiles $0200

init:
	; Fill the screen
	jsr copy_water_patterns_to_ram
	jsr flood_fill
	jsr enable_ppu

;
; Main loop
;
.proc main
	; Update the patterns in PPU memory, then
	; delay for a couple of frames.
	jsr update_water_tiles
	jsr nmi_spin
	jsr nmi_spin

	; Allow changing the rotation direaction via
	; Left and Right on the 1st controller.
	jsr read_input1
	lda input1_stat
	and #BUTTON_LEFT
	beq :+
	sta water_dir
:	lda input1_stat
	and #BUTTON_RIGHT
	beq :+
	sta water_dir

	;
	; Update the water animation counter.
	;
	; The animation consists of 16 frames
	; across four different tiles. On the
	; 0th frame, the pattern will be rotated
	; in the current direction of movement.
	;
:	inc water_ctr
	lda water_ctr
	cmp #17
	bcc main
	lda #0
	sta water_ctr

	; Rotate the water patterns in RAM.
	lda water_dir
	cmp #2
	beq @water_rol
	bne @water_ror

;
; Rotate the water tiles to the right.
;
@water_ror:
	ldx #0
:	lda tiles+1, x
	lsr
	ror tiles, x
	ror tiles+1, x
	inx
	inx
	cpx #32
	bcc :-
	bcs main

;
; Rotate the water tiles to the left.
;
@water_rol:
	ldx #0
:	lda tiles, x
	asl
	rol tiles+1, x
	rol tiles, x
	inx
	inx
	cpx #32
	bcc :-
	bcs main
.endproc

;
; Update the water tiles in the pattern table.
;
.proc update_water_tiles
	bit PPUADDR
	lda water_ctr
	asl
	tax
	ldy water_tile_index, x
	lda #0
	sta PPUADDR
	lda water_anim_table, x
	sta PPUADDR
	lda tiles, y
	sta PPUDATA
	inx
	ldy water_tile_index, x
	lda #0
	sta PPUADDR
	lda water_anim_table, x
	sta PPUADDR
	lda tiles, y
	sta PPUDATA
	jsr reset_ppu_scroll
	rts
.endproc

;
; These are the addresses in the pattern table in
; the order we'll update the tiles. Each two
; addresses repesent one frame.
;
; The addresses will be $00xx in PPU memory, where
; xx is a byte from this table.
;
water_anim_table:
	.byte $10, $20, $13, $23, $16, $26, $31, $41
	.byte $34, $44, $37, $47, $12, $22, $15, $25
	.byte $30, $40, $33, $43, $36, $46, $11, $21
	.byte $14, $24, $17, $27, $32, $42, $35, $45

;
; These are offsets into the tile data which
; represent the specific bytes placed into the
; above places in PPU memory.
;
water_tile_index:
	.byte $00, $01, $06, $07, $0c, $0d, $12, $13
	.byte $18, $19, $1e, $1f, $04, $05, $0a, $0b
	.byte $10, $11, $16, $17, $1c, $1d, $02, $03
	.byte $08, $09, $0e, $0f, $14, $15, $1a, $1b

;
; Copy the first plane of water patterns to RAM so we can
; manuipulate them.
;
; The lines from the pattern are stored in an interleaved fasion
; as follows:
;
; tile1[0] tile2[1] tile1[1] tile2[1] ...
;
.proc copy_water_patterns_to_ram
	ldx #0
	ldy #0
:	lda patterns+16, x
	sta tiles, y
	iny
	lda patterns+32, x
	sta tiles, y
	iny
	inx
	cpx #8
	bcc :-
	ldx #0
	ldy #0
:	lda patterns+48, x
	sta tiles+16, y
	iny
	lda patterns+64, x
	sta tiles+16, y
	iny
	inx
	cpx #8
	bcc :-
	rts
.endproc

;
; Fill the nametable with water
;
; The water pattern is based around 4 tiles, two for each row.
; These tiles alternate for the entire row, and swap between rows.
;
; The rows will look like:
;
; 1 2 1 2 1 2 ...
; 3 4 3 4 3 4 ...
;
.proc flood_fill
	bit PPUSTAT
	ldy #$20
	ldx #0
	lda #0
	sty PPUADDR
	stx PPUADDR
	ldy #1

@fill:
	sty PPUDATA
	iny
	sty PPUDATA
	dey
	inx
	cpx #16  ; 32 columns
	bcc @fill
	clc
	adc #1
	cmp #30  ; 30 rows
	bcs @return

	; Transition from 1/2 to 3/4
	iny
	cpy #4
	bpl :+
	ldy #3
	ldx #0
	jmp @fill

	; Transition from 3/4 to 1/2
:	ldy #1
	ldx #0
	jmp @fill

@return:
	rts
.endproc

palettes:
	.byte $22, $22, $22, $31 ; Background Palette 0
	.byte $0f, $0f, $0f, $0f ; Background Palette 1
	.byte $0f, $0f, $0f, $0f ; Background Palette 2
	.byte $0f, $0f, $0f, $0f ; Background Palette 3
	.byte data_end

patterns:
	; Transparent tile
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

	; Water tile #1
	.byte $83, $01, $33, $ce, $01, $cf, $7c, $c0
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

	; Water tile #2
	.byte $01, $8e, $f8, $0d, $07, $f8, $60, $13
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

	; Water tile #3
	.byte $80, $e0, $9e, $01, $00, $00, $8f, $fc
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

	; Water tile #4
	.byte $0c, $10, $7f, $c6, $7c, $ce, $03, $00
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	.byte data_end

; vi:set ft=ca65:
