;
; NES init routine
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

; Memory Map for utilized RAM
.alias zero_page    $0000
.alias stack        $0100

.org $8000

;
; Reset / Initialization Vector
;
reset:
	sei ; Ensure IRQs are disabled
	cld ; Clear D flag (since the NES doesn't support decimal mode.)

	; Initialize the memory that we'll be using
	lda #0
	ldx #$ff
*	sta zero_page,x
	sta stack,x
	sta $200,x
	dex
	bne -

	; Setup some stack space ($0100 - $01FF)
	dex
	txs

	; Initialize the NMI handler
	lda #$40 ; RTI opcode
	sta nmi

	; Disable the display
	jsr disable_ppu

	; Give the PPU 2 frames to warm up
	ldx #2
*	bit PPUSTAT
	bpl -
	dex
	bne -

	; Prepare palettes and clear the screen
	jsr copy_palettes_to_ppu
	jsr clear_nametables

	; Load the patterns
	jsr load_patterns

; vi:set ft=ophis:
