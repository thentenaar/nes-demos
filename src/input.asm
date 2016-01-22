;
; NES input routines
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

.export read_input1
.exportzp input1_stat

.zeropage
	; Controller 1 state
	input1_stat: .res 1

.segment "COMMON"
.include "input.inc"

;
; Read the state of the 1st controller into
; the input1_stat bitfield which uses the
; corresponding bits to represent currently
; pressed buttons.
;
; 7 6   5     4    3   2    1     0
; -----------------------------------
; A B Select Start Up Down Left Right
;
read_input1:
	; Save X
	txa
	pha

	; Strobe the input pins for INPUT1.
	ldx #1
	stx INPUT1

	; Stop strobing the pins in and latch
	; the bits in the shift register.
	dex
	stx INPUT1

	;
	; Read the state of each button,
	; shifting it into input1_stat.
	;
	; The bit is read into A, and placed
	; into the carry flag (C) by cmp,
	; and shifted into input1_stat by way
	; of rol.
	;
	ldx #8
:	lda INPUT1
	and #3
	cmp #1
	rol input1_stat
	dex
	bne :-

	; Restore X
	pla
	tax
	rts

; vi:set ft=ca65:
