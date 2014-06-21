;
; Final Fantasy III-like Intro Screen Demo
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

; iNES Header
.byte "NES", $1a
.byte $01          ; 1x 16k bank of PRG-ROM
.byte $00          ; 0x 8k  bank of CHR-ROM (1x 8k bank of CHR-RAM)
.byte $01          ; Vertical Mirroring / Mapper Lo: 0
.byte $00          ; Mapper Hi: 0 (NROM)
.word $0000, $0000
.word $0000, $0000

; PPU Registers
.alias PPUCTRL $2000
.alias PPUMASK $2001
.alias PPUSTAT $2002
.alias PPUSCRL $2005
.alias PPUADDR $2006
.alias PPUDATA $2007

; Data markers
.alias data_end $ae ; End of Data

; Text markers
.alias text_eol $aa ; End of Line
.alias text_eop $ac ; End of Page
.alias text_eot $ae ; End of Text

; Delay by the time it would take the effect to
; be done over this number of lines before going
; to the next page (for readability.)
.alias ln_delay 2

; Memory Map for utilized RAM
.alias zero_page    $0000
.alias stack        $0100
.alias ram_palettes $0200

; Zero Page Variables
.alias longptr      $00 ; Temporary 16-bit pointer
.alias textptr      $02 ; Pointer to the current pos. in the text
.alias lineptr      $04 ; Pointer to the current pos. in the nametable
.alias line_offset  $06 ; Position within the current line of text
.alias num_lines    $07 ; Number of lines rendered for the current page
.alias is_attr_addr $08 ; Current attribute table address
.alias is_attr_byte $09 ; Current attribute byte
.alias is_color     $0a ; Current color
.alias frame_ctr    $0b ; Frame counter for the fade effect
.alias nmi          $0c ; Dynamic NMI Handler

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
	sta ram_palettes,x
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
	jsr copy_palettes_to_ram
	jsr copy_palettes_to_ppu
	jsr clear_nametables

	; Initialize the pointer to our patterns
	ldx #<patterns
	stx longptr
	ldx #>patterns
	stx longptr+1

	; Load our patterns into the pattern table
	ldy #0
	sty PPUADDR
	sty PPUADDR
*	lda (longptr),y
	cmp #data_end
	beq +
	sta PPUDATA
	inc longptr
	bne -
	inc longptr+1
	bne -

	; Initialize our pointer to the page text
*	lda #<intro_pages
	sta textptr
	lda #>intro_pages
	sta textptr+1

;
; Main loop
;
main:
	; Disable the PPU
	jsr disable_ppu

	; Clear the screen
	jsr clear_nametables

	; Render the next page
	jsr render_page
	pha

	; Enable the PPU
	jsr enable_ppu

	; Do the fade-in effect
	jsr fade_in

	; Did we finish the last page?
	pla
	cmp #text_eot
	bne main

	; If so, we're done
	brk

;
; Do the fade-in effect
;
; It's really simple, actually. We're simply rotating
; colors in the palette we're using to give the
; impression that the text is fading-in. We then
; use the PPU attribute table to effect changes
; in palette.
;
; Keep in mind that each attribute byte affects
; a 16x16 area on the screen. Each two bits
; contains the palette number used for one tile.
;
; The bits are assigned in the following order:
;
;  -------------
; |  0   |  1   |
; | ---- | ---- |
; |  2   |  3   |
;  -------------
;
; So, the value %11100100 is used like:
;
;  -------------
; |  00  |  01  |
; | ---- | ---- |
; |  10  |  11  |
;  -------------
;
; What does this have to do with our lines of text?
;
; Simply put, we drew the text on odd-numbered rows.
; Thus, only the lower half of the attribute row is
; used for our line of text.
;
fade_in:
	; Set our attribute table address to point to the
	; beginning of the attribute table.
	lda #$c0
	sta is_attr_addr

	; Palette #1 / #2
*	lda #%01011010
	sta is_attr_byte
	jsr rotate_color

	; Are we at the last row of text?
	dec num_lines
	bmi +

	; Palette #2 / #3
	lda #%10101111
	sta is_attr_byte
	jsr rotate_color

	; Finally, use palette #3
*	lda #%11111111
	sta is_attr_byte
	jsr render_intro_screen

	; Go to the next attribute table row
	lda is_attr_addr
	clc
	adc #8
	sta is_attr_addr

	; Loop until we've completed the last row
	dec num_lines
	bpl --
	rts

;
; Rotate color #3 of palette #2
;
; This is where the real magic happens.
;
; Keep in mind that the NES palette goes from $00 - $3f,
; with 16 basic color entries. Thus, adding $10 lightens
; the color by one shade, while subtracting $10 makes it
; one shade darker.
;
rotate_color:
	; Start with the darkest grey
	lda #0
	sta is_color
*	lda is_color
	sta ram_palettes+$0b

	; Update the PPU and increment our frame counter
*	jsr render_intro_screen
	inc frame_ctr
	lda frame_ctr
	and #$0f
	bne +

	; Make the color one shade lighter (each 16th frame)
	lda is_color
	clc
	adc #$10
	sta is_color

	; When we finally reach $40, we're done.
	cmp #$40
	bcc --
	rts

	; For frames 2 - 15, we make the color darker
	; for each odd-numbered frame.
*	lsr
	bcc ---

	; Make the color one shade darker
	lda ram_palettes+$0b
	sec
	sbc #$10
	bpl +

	; If our subtraction went negative, reset
	; our color to one shade above the darkest
	; grey.
	lda #1

	; Store the new color and loop
*	sta ram_palettes+$0b
	jmp ---

;
; Here's where we finally send our updated
; palette and attribute data to the PPU.
;
render_intro_screen:
	jsr nmi_spin
	jsr copy_palettes_to_ppu

	; Reset PPU address/scroll latches to avoid
	; possibly generating multiple NMIs.
	lda PPUSTAT

	; Set PPUADDR to point to the current row's attributes
	lda #$23
	sta PPUADDR
	lda is_attr_addr
	sta PPUADDR

	; Write one full row of attribute info
	ldx #8
	lda is_attr_byte
*	sta PPUDATA
	dex
	bne -

	; Reset the PPU scrolling registers
	jmp reset_ppu_scroll

;
; Layout a page of text on the screen
;
; Text is rendered every 2 rows from (2, 3) to (29, 27)
;
; Output:
;
;   A - Contains the text marker byte, if a End-of-Page or
;       End-of-Text marker are found.
;
; Clobbers:
;
;   Y
;
render_page:
	; Initalize the line pointer
	lda #$62
	sta lineptr
	lda #$20
	sta lineptr+1

	; Zero the line offset
	lda #0
	sta line_offset
	tay

	; Initialize the line counter
	lda #ln_delay
	sta num_lines

	; Load the next byte and update our pointer
*	lda (textptr),y
	inc textptr
	bne +
	inc textptr+1

	; Check for space
*	cmp #$00
	beq +

	; Check for text markers
	cmp #text_eol
	beq ++
	cmp #text_eop
	beq +++
	cmp #text_eot
	beq +++

	; Set the PPU Address
	tay
	lda lineptr+1
	sta PPUADDR
	lda lineptr
	clc
	adc line_offset
	sta PPUADDR

	; Draw the char
	tya
	ldy #0
	sta PPUDATA

	; Advance to the next cell
*	inc line_offset
	lda line_offset
	cmp #28 ; Chars per line
	bcc ---

	; Skip any leading newlines
*	lda #62
	cmp lineptr
	beq ----

	; Advance to the next line
	sty line_offset
	lda num_lines
	cmp #12 + ln_delay ; Lines per page
	bcs +
	inc num_lines
	lda lineptr
	clc
	adc #$40
	sta lineptr
	bcc ----

	; Are we at the end of the screen?
	inc lineptr+1
	lda lineptr+1
	cmp #28 ; Rows per page
	bne ----
*	rts

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
*	txa
	sta PPUADDR
	tya
	sta PPUADDR
*	lda #0
	sta PPUDATA
	iny
	bne -
	inx
	cpx #$28
	bne --
	rts

;
; Copy palettes to RAM (so we can manipulate them)
;
copy_palettes_to_ram:
	ldx #0
*	lda palettes,x
	sta ram_palettes,x
	inx
	cpx #32
	bmi -
	rts

;
; Copy our palettes from RAM to the PPU
;
copy_palettes_to_ppu:
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	tax
*	lda ram_palettes,x
	sta PPUDATA
	inx
	cpx #32
	bmi -
	rts

palettes:
	.byte $02, $02, $02, $02 ; Background Palette 0
	.byte $02, $02, $02, $02 ; Background Palette 1
	.byte $0f, $0f, $02, $02 ; Background Palette 2
	.byte $0f, $00, $02, $10 ; Background Palette 3
	.byte $02, $0f, $0f, $0f ; Sprite Palette 0
	.byte $0f, $0f, $0f, $0f ; Sprite Palette 1
	.byte $0f, $0f, $0f, $0f ; Sprite Palette 2
	.byte $0f, $0f, $0f, $0f ; Sprite Palette 3

patterns:
	; Transparent tile
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.include "font.asm"

intro_pages:
	.incbin "text.bin"
	.byte text_eot

; Interrupt vector table
.checkpc $bffa
.advance $bffa
.org $fffa
	.word nmi         ; NMI Vector
	.word reset       ; Reset Vector
	.word reset       ; IRQ / BRK Vector

; vi:set ft=ophis:
