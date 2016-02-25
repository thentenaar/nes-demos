;
; neslife - Conway's Game of Life for the NES
; Copyright (C) 2016 Tim Hentenaar.
; See the LICENSE file for details.
;

.segment "BANK1"

.align 256
table_16_all_dead:
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $40, $40, $40, $42, $42, $40, $40, $40
	.byte $40, $00, $00, $00, $00, $00, $00, $00
	.byte $40, $40, $40, $42, $42, $40, $40, $40
	.byte $40, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_16_both_alive:
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $40, $40, $40, $42, $42, $40, $40, $40
	.byte $40, $00, $00, $00, $00, $00, $00, $00
	.byte $40, $40, $40, $42, $42, $40, $40, $40
	.byte $40, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_16_left_only:
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $40, $40, $40, $42, $42, $40, $40, $40
	.byte $40, $00, $00, $00, $00, $00, $00, $00
	.byte $40, $40, $40, $42, $42, $40, $40, $40
	.byte $40, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_16_right_only:
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $40, $40, $40, $42, $42, $40, $40, $40
	.byte $40, $00, $00, $00, $00, $00, $00, $00
	.byte $40, $40, $40, $42, $42, $40, $40, $40
	.byte $40, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $02, $02, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_25_all_dead:
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $20, $20, $20, $24, $24, $20, $20, $20
	.byte $20, $00, $00, $00, $00, $00, $00, $00
	.byte $20, $20, $20, $24, $24, $20, $20, $20
	.byte $20, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_25_both_alive:
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $20, $20, $20, $24, $24, $20, $20, $20
	.byte $20, $00, $00, $00, $00, $00, $00, $00
	.byte $20, $20, $20, $24, $24, $20, $20, $20
	.byte $20, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_25_left_only:
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $20, $20, $20, $24, $24, $20, $20, $20
	.byte $20, $00, $00, $00, $00, $00, $00, $00
	.byte $20, $20, $20, $24, $24, $20, $20, $20
	.byte $20, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_25_right_only:
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $20, $20, $20, $24, $24, $20, $20, $20
	.byte $20, $00, $00, $00, $00, $00, $00, $00
	.byte $20, $20, $20, $24, $24, $20, $20, $20
	.byte $20, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $04, $04, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_34_all_dead:
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $10, $10, $10, $18, $18, $10, $10, $10
	.byte $10, $00, $00, $00, $00, $00, $00, $00
	.byte $10, $10, $10, $18, $18, $10, $10, $10
	.byte $10, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_34_both_alive:
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $10, $10, $10, $18, $18, $10, $10, $10
	.byte $10, $00, $00, $00, $00, $00, $00, $00
	.byte $10, $10, $10, $18, $18, $10, $10, $10
	.byte $10, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_34_left_only:
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $10, $10, $10, $18, $18, $10, $10, $10
	.byte $10, $00, $00, $00, $00, $00, $00, $00
	.byte $10, $10, $10, $18, $18, $10, $10, $10
	.byte $10, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

.align 256
table_34_right_only:
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $10, $10, $10, $18, $18, $10, $10, $10
	.byte $10, $00, $00, $00, $00, $00, $00, $00
	.byte $10, $10, $10, $18, $18, $10, $10, $10
	.byte $10, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $08, $08, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00

; vi:set ft=ca65: