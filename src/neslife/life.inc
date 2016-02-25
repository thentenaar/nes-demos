;
; neslife - Conway's Game of Life for the NES
; Copyright (C) 2016 Tim Hentenaar.
; See the LICENSE file for details.
;

; Cell states
.define CELL_OFF 0
.define CELL_ON  1

; Size contraints
.define CELLS_PER_BLOCK 6 ; Cells in a block
.define ROW_BLOCKS      5 ; Blocks per row
.define BOARD_HEIGHT   20 ; Rows on the board

; Configuration values for the 'neighborhood' variable
.define NEIGHBORHOODS            2
.define NEIGHBORHOOD_MOORE       0
.define NEIGHBORHOOD_VAN_NEUMANN 1

; Configuration values for the board topology
.define TOPOLOGY_SQUARE 0
.define TOPOLOGY_TOROID 1

; Entry in life_damage_list
.struct life_damage
	row   .byte ; Damaged row number
	block .byte ; Damaged block number
	state .byte ; State for each cell in the block
.endstruct

; vi:set ft=ca65:
