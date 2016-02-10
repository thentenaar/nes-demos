;
; Final Fantasy III-like Starfield Animation Demo
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
	frame_ctr:      .res 1 ; Frame counter
	multiplier_ctr: .res 1 ; Counter for updating the multiplier index
	multiplicand:   .res 1 ; For calculating a star's next position
	temp:           .res 1 ; Temp. byte
	temp2:          .res 1 ; Temp. byte #2

.segment "BSS"

frame_counters:             .res 64 ; Frame counters for each sprite
x_multiplier_indexes:       .res 64 ; X position table offets for each sprite
y_multiplier_indexes:       .res 64 ; Y position table offets for each sprite
multiplicand_table_indexes: .res 64 ; Offets into the multiplicand table

.code

.include "../ppu.inc"

.import do_oam_dma, enable_ppu_with_sprites, nmi_spin
.export patterns, palettes

; Memory Map for utilized RAM
.define oam_shadow $0200

init:
	; Initialize the multiplicand table indexes to 1, thus forcing
	; a mutation of the arrays.
	lda #1
	ldx #63
:	sta multiplicand_table_indexes, x
	dex
	bpl :-

	; Initalize the x_multiplier_indexes
	lda #64
	tax
:	sta x_multiplier_indexes, x
	dex
	bpl :-

	; Initialize the counters
	lda #10
	sta frame_ctr
	lda #2
	sta multiplier_ctr
	jsr enable_ppu_with_sprites

.proc main
	; Do the effect
	jsr mutate_tables
	jsr update_sprites

	; Render the sprites
	jsr nmi_spin
	inc frame_ctr
	ldx #>oam_shadow
	jsr do_oam_dma
	jmp main
.endproc

;
; Generate the next state for any of the
; sprites that need updating.
;
.proc mutate_tables
	ldy #0

@mutate:
	; Increment the frame counter
	lda frame_counters, y
	clc
	adc #1
	sta frame_counters, y

	; Subtract 1 from the multiplicand table index
	lda multiplicand_table_indexes, y
	sec
	sbc #1
	and #$7f
	sta multiplicand_table_indexes, y
	bne @next

	; If the multiplicand table index was 0, regenerate
	; this sprite's indexes, and frame counter.
	lda frame_ctr
	inc frame_ctr
	and #$f
	tax
	lda multiplicand_table_initial_indexes, x
	sta multiplicand_table_indexes, y

	; Reset this sprite's frame counter to 0
	lda #0
	sta frame_counters, y

	; Regenerate this sprite's X and Y multiplier indexes
	inc multiplier_ctr
	ldx multiplier_ctr
	lda multiplier_index_table, x
	sta y_multiplier_indexes, y
	clc
	adc #64
	sta x_multiplier_indexes, y

@next:
	iny
	cpy #63
	bne @mutate
	rts
.endproc

;
; Update the local OAM data to reflect the current
; state of the sprites.
;
.proc update_sprites
	lda #0
	tay
	tax

@next:
	; Generate new Y position
	lda y_multiplier_indexes, y
	jsr calc_position
	clc
	adc #120
	sta oam_shadow, x
	inx

	; Get the next tile number
	lda frame_counters, y
	cmp #120
	bcc :+
	lda #1
	jmp @set_pattern
:	cmp #100
	bcc :+
	lda #2
	jmp @set_pattern
:	cmp #60
	bcc :+
	lda #3
	jmp @set_pattern
:	lda #4

@set_pattern:
	sta oam_shadow, x
	inx

	; Generate the attribute byte
	tya
	and #$f
	beq :+
	lda #2
:	sta oam_shadow, x
	inx

	; Generate new X position
	lda x_multiplier_indexes, y
	jsr calc_position
	clc
	adc #128
	sta oam_shadow, x
	inx
	iny
	cpy #64
	bne @next
	rts
.endproc

;
; Calculate the next position from the
; current multiplicand and byte from the
; multiplier_table.
;
; Inputs:
;    A - multiplier_table offset
;    Y - current sprite #
;
.proc calc_position
	; Save registers
	sta temp
	tya
	pha
	txa
	pha

	; Get the multiplicand
	lda multiplicand_table_indexes, y
	tay
	lda multiplicand_table, y
	lsr
	sta multiplicand

	; Get the byte from the multiplier table, and multiply.
	ldx temp
	lda multiplier_table, x
	bpl :+
	eor #$ff
	jsr mul8u
	eor #$ff
	clc
	adc #1
	beq @clear_carry
	sec
	jmp @return
:	jsr mul8u

@clear_carry:
	clc

@return:
	sta temp
	pla
	tax
	pla
	tay
	lda temp
	rts
.endproc

;
; Using the multiplicand from the table,
; and the multiplier in A, perform 8-bit
; unsigned multiplication. This method is
; also known as "Ancient Egyptian Multiplication."
;
; The lo-byte is discarded.
;
; Inputs:
;    A - multiplier
;
; Output:
;    A - Hi-byte of the result << 1.
;
.proc mul8u
	sta temp2
	ldx #7
	lda #0

@loop:
	lsr temp2
	bcc :+
	clc
	adc multiplicand
:	ror
	dex
	bne @loop
	rts
.endproc

palettes:
	.byte $0f, $0f, $0f, $0f ; Background Palette 0
	.byte $0f, $0f, $0f, $0f ; Background Palette 1
	.byte $0f, $0f, $0f, $0f ; Background Palette 2
	.byte $0f, $0f, $0f, $0f ; Background Palette 3

	.byte $0f, $11, $21, $30 ; Sprite Palette 0
	.byte $0f, $01, $11, $21 ; Sprite Palette 1
	.byte $0f, $1c, $2c, $3c ; Sprite Palette 2
	.byte $0f, $21, $31, $30 ; Sprite Palette 3
	.byte data_end

patterns:
	; Transparent tile
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

	; Largest Star
	.byte $00, $1c, $22, $22, $22, $1c, $00, $00
	.byte $00, $00, $1c, $1c, $1c, $00, $00, $00

	; 2nd-largest Star
	.byte $00, $00, $18, $24, $24, $18, $00, $00
	.byte $00, $00, $00, $18, $18, $00, $00, $00

	; 2nd-smallest Star
	.byte $00, $00, $00, $00, $18, $18, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

	; Smallest Star
	.byte $00, $00, $00, $00, $00, $10, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte data_end

multiplicand_table_initial_indexes:
	.byte $02, $03, $04, $05, $06, $07, $08, $0a
	.byte $14, $19, $1e, $2d, $3c, $4d, $5c, $7f

multiplicand_table:
	.byte $ff, $e3, $cd, $ba, $ab, $9e, $93, $89
	.byte $80, $79, $72, $6c, $67, $62, $5e, $5a
	.byte $56, $52, $4f, $4c, $4a, $47, $45, $43
	.byte $40, $3f, $3d, $3b, $39, $38, $36, $35
	.byte $34, $32, $31, $30, $2f, $2e, $2d, $2c
	.byte $2b, $2a, $29, $29, $28, $27, $26, $26
	.byte $25, $24, $24, $23, $22, $22, $21, $21
	.byte $20, $20, $1f, $1f, $1e, $1e, $1e, $1d
	.byte $1d, $1c, $1c, $1c, $1b, $1b, $1b, $1a
	.byte $1a, $1a, $19, $19, $19, $19, $18, $18
	.byte $18, $17, $17, $17, $16, $16, $16, $16
	.byte $16, $15, $15, $15, $15, $14, $14, $14
	.byte $14, $14, $14, $13, $13, $13, $13, $13
	.byte $12, $12, $12, $12, $12, $12, $12, $11
	.byte $11, $11, $11, $11, $11, $11, $10, $10
	.byte $10, $10, $10, $10, $48, $a9, $01, $20

multiplier_index_table:
	.byte $01, $04, $0d, $28, $79, $93, $45, $d0
	.byte $71, $ab, $02, $07, $16, $43, $ca, $5f
	.byte $e1, $a4, $12, $37, $a6, $0c, $25, $70
	.byte $ae, $0b, $22, $67, $c9, $5c, $ea, $bf
	.byte $3e, $bb, $32, $97, $39, $ac, $05, $10
	.byte $31, $94, $42, $c7, $56, $fc, $f5, $e0
	.byte $a1, $1b, $52, $f7, $e6, $b3, $1a, $4f
	.byte $ee, $cb, $62, $d8, $89, $63, $d5, $80
	.byte $7e, $84, $72, $a8, $06, $13, $3a, $af
	.byte $0e, $2b, $82, $78, $96, $3c, $b5, $20
	.byte $61, $db, $92, $48, $d9, $8c, $5a, $f0
	.byte $d1, $74, $a2, $18, $49, $dc, $95, $3f
	.byte $be, $3b, $b2, $17, $46, $d3, $7a, $90
	.byte $4e, $eb, $c2, $47, $d6, $83, $75, $9f
	.byte $21, $64, $d2, $77, $99, $33, $9a, $30
	.byte $91, $4b, $e2, $a7, $09, $1c, $55, $ff
	.byte $fe, $fb, $f2, $d7, $86, $6c, $ba, $2f
	.byte $8e, $54, $fd, $f8, $e9, $bc, $35, $a0
	.byte $1e, $5b, $ed, $c8, $59, $f3, $da, $6f
	.byte $51, $f4, $dd, $98, $36, $a3, $15, $40
	.byte $c1, $44, $cd, $68, $c6, $53, $fa, $ef
	.byte $ce, $6b, $bd, $38, $a9, $03, $0a, $1f
	.byte $5e, $e4, $ad, $08, $19, $4c, $e5, $b0
	.byte $11, $34, $9d, $27, $26, $9c, $2a, $7f
	.byte $81, $7b, $8d, $57, $f9, $ec, $c5, $50
	.byte $f1, $d4, $7d, $87, $69, $c3, $4a, $df
	.byte $9e, $24, $6d, $b7, $26, $73, $a5, $0f
	.byte $2e, $8b, $5d, $e7, $b6, $23, $6a, $c0
	.byte $41, $c4, $4d, $e8, $b9, $2c, $85, $6f
	.byte $b1, $14, $3d, $b8, $29, $7c, $8a, $60
	.byte $de, $9b, $2d, $88, $66, $cc, $65, $cf
	.byte $6e, $b4, $1d, $58, $f6, $e3, $aa, $00

multiplier_table:
	.byte $00, $03, $06, $09, $0c, $10, $13, $16
	.byte $19, $1c, $1f, $22, $25, $28, $2b, $2e
	.byte $31, $33, $36, $39, $3c, $3f, $41, $44
	.byte $47, $49, $4c, $4e, $51, $53, $55, $58
	.byte $5a, $5c, $5e, $60, $62, $64, $66, $68
	.byte $6a, $6b, $6d, $6f, $70, $71, $73, $74
	.byte $75, $76, $78, $79, $7a, $7a, $7b, $7c
	.byte $7d, $7d, $7e, $7e, $7e, $7f, $7f, $7f
	.byte $7f, $7f, $7f, $7f, $7e, $7e, $7e, $7d
	.byte $7d, $7c, $7b, $7a, $7a, $79, $78, $76
	.byte $75, $74, $73, $71, $70, $6f, $6d, $6b
	.byte $6a, $68, $66, $64, $62, $60, $5e, $5c
	.byte $5a, $58, $55, $53, $51, $4e, $4c, $49
	.byte $47, $44, $41, $3f, $3c, $39, $36, $33
	.byte $31, $2e, $2b, $28, $25, $22, $1f, $1c
	.byte $19, $16, $13, $10, $0c, $09, $06, $03
	.byte $00, $fd, $fa, $f7, $f4, $f0, $ed, $ea
	.byte $e7, $e4, $e1, $de, $db, $db, $d5, $d2
	.byte $cf, $cd, $ca, $c7, $c4, $c1, $bf, $bc
	.byte $b9, $b7, $b4, $b2, $af, $ad, $ab, $a8
	.byte $a6, $a4, $a2, $a0, $9e, $9c, $9a, $98
	.byte $96, $95, $93, $91, $90, $8f, $8d, $8c
	.byte $8b, $8a, $88, $87, $86, $86, $85, $84
	.byte $83, $83, $82, $82, $82, $81, $81, $81
	.byte $81, $81, $81, $81, $82, $82, $82, $83
	.byte $83, $84, $85, $86, $86, $87, $88, $8a
	.byte $8b, $8c, $8d, $8f, $90, $91, $93, $95
	.byte $96, $98, $9a, $9c, $9e, $a0, $a2, $a4
	.byte $a6, $a8, $ab, $ad, $af, $b2, $b4, $b7
	.byte $b9, $bc, $bf, $c1, $c4, $c7, $ca, $cd
	.byte $cf, $d2, $d5, $d8, $db, $de, $e1, $e4
	.byte $e7, $ea, $ed, $f0, $f4, $f7, $fa, $fd

; vi:set ft=ca65:
