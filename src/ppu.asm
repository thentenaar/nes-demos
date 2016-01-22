;
; NES PPU / NMI routines
;
; Copyright (c) 2014, Tim Hentenaar
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

.import patterns, palettes
.export nmi_spin, disable_ppu, enable_ppu, reset_ppu_scroll
.export clear_nametables, copy_palettes_to_ppu, load_patterns

.importzp longptr
.exportzp nmi

.zeropage
	; NMI Handler Routine
	nmi: .res 3

.segment "COMMON"
.include "ppu.inc"

;
; NMI Handler
;
; This simply returns to the original calling routine,
; disregarding the context placed on the stack by the
; CPU.
;
nmi_return:
	; Reset the PPU address latches
	lda PPUSTAT

	; Rewrite our NMI handler to simply return
	lda #$40 ; RTI opcode
	sta nmi

	; Pop the provided context and return to the original
	; caller.
	pla ; CPU Status
	pla ; IRQ Return Address (Hi)
	pla ; IRQ Return Address (Lo)
	rts

;
; NMI Spin
;
; This function sets our custom NMI handler up
; as "jmp nmi_return" and spins until a NMI
; occurs.
;
nmi_spin:
	lda #$4c ; JMP opcode
	sta nmi
	lda #<nmi_return
	sta nmi+1
	lda #>nmi_return
	sta nmi+2

;
; Halt the CPU
;
halt:
	jmp halt

;
; Disable PPU
;
disable_ppu:
	lda #0
	sta PPUCTRL
	sta PPUMASK
	rts

;
; Enable PPU (BG only / NMI Enabled)
;
enable_ppu:
	lda #%10001000
	sta PPUCTRL
	lda #%00001010
	sta PPUMASK

;
; Reset PPU scrolling registers
;
reset_ppu_scroll:
	lda #0
	sta PPUSCRL
	sta PPUSCRL
	rts

;
; Clear the nametables ($2000 - $27FF)
;
clear_nametables:
	ldx #$20
	ldy #0
:	txa
	sta PPUADDR
	tya
	sta PPUADDR
:	lda #0
	sta PPUDATA
	iny
	bne :-
	inx
	cpx #$28
	bne :--
	rts

;
; Copy our palettes to the PPU
;
copy_palettes_to_ppu:
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	tax
:	lda palettes,x
	sta PPUDATA
	inx
	cpx #16
	bmi :-
	rts

load_patterns:
	; Initialize our pointer to the patterns
	ldx #<patterns
	stx longptr
	ldx #>patterns
	stx longptr+1

	; Load our patterns into the pattern table
	ldy #0
	sty PPUADDR
	sty PPUADDR
:	lda (longptr),y
	cmp #data_end
	beq :+
	sta PPUDATA
	inc longptr
	bne :-
	inc longptr+1
	bne :-
:	rts

; vi:ft=ca65:
