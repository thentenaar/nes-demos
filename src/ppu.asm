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
.export enable_ppu_with_sprites, do_oam_dma, detect_device_type
.export halt

.importzp longptr
.exportzp nmi, device_type

.zeropage
	nmi:         .res 3 ; NMI Handler Routine
	device_type: .res 1 ; Device type

.segment "COMMON"
.include "ppu.inc"

;
; NMI Handler
;
; This simply returns to the original calling routine,
; disregarding the context placed on the stack by the
; CPU.
;
.proc nmi_return
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
.endproc

;
; NMI Spin
;
; This function sets our custom NMI handler up
; as "jmp nmi_return" and spins until a NMI
; occurs.
;
.proc nmi_spin
	lda #<nmi_return
	sta nmi+1
	lda #>nmi_return
	sta nmi+2
	lda #$4c ; JMP opcode
	sta nmi
.endproc

;
; Halt the CPU
;
.proc halt
	jmp halt
.endproc

;
; Disable PPU
;
.proc disable_ppu
	lda #0
	sta PPUCTRL
	sta PPUMASK
	rts
.endproc

;
; Enable PPU (BG only / NMI Enabled)
;
.proc enable_ppu
	lda #%10000000
	sta PPUCTRL
	lda #%00001010
	sta PPUMASK
.endproc

;
; Reset PPU scrolling registers
;
.proc reset_ppu_scroll
	lda #0
	sta PPUSCRL
	sta PPUSCRL
	rts
.endproc

;
; Enable Sprites
;
.proc enable_ppu_with_sprites
	lda #%10000000
	sta PPUCTRL
	lda #%00011110
	sta PPUMASK
	jmp reset_ppu_scroll
.endproc

;
; Performa DMA transfer to the PPU's OAM.
;
; Inputs:
;    X - Hi byte of the RAM page to copy from
;
.proc do_oam_dma
	lda #0
	sta OAMADDR
	txa
	sta OAMDMA
	rts
.endproc

;
; Clear the nametables ($2000 - $27FF)
;
.proc clear_nametables
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
.endproc

;
; Copy our palettes to the PPU
;
.proc copy_palettes_to_ppu
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	tax
:	lda palettes,x
	cmp #data_end
	beq :+
	sta PPUDATA
	inx
	cpx #32
	bmi :-
:	rts
.endproc

.proc load_patterns
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
.endproc

; Detect the type of device we're using based on
; how long it takes to render one frame on various
; PPU types.
;
; The VBLANK will occur during the
;
;     inc device_type
;
; instruction, if it didn't just occur during the
; loop.
;
; After this routine, the zeropage variable
; device_type will be set as follows:
;
; 0 - NTSC
; 1 - PAL
; 2 - Dendy
; 3 - Unknown
;
.proc detect_device_type
:	bit PPUSTAT
	bpl :-

	; 29,464 cycles
	ldy #23
:	ldx #$ff
:	dex
	bne :-
	dey
	bne :--

	; 316 cycles
	ldx #63
:	dex
	bne :-

	; NTSC
	inc device_type
	bit PPUSTAT
	bmi @done

	; 2,563 cycles
	ldy #2
:	ldx #$ff
:	dex
	bne :-
	dey
	bne :--

	; 891 cycles
	ldx #178
:	dex
	bne :-

	; PAL
	inc device_type
	bit PPUSTAT
	bmi @done

	; 1,282 cycles
	ldy #1
:	ldx #$ff
:	dex
	bne :-
	dey
	bne :--

	; 921 cycles
	ldx #184
:	dex
	bne :-

	; Dendy
	inc device_type
	bit PPUSTAT
	bmi @done
	inc device_type

@done:
	dec device_type
	rts
.endproc

; vi:ft=ca65:
