
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; tank bomb panic
; written by ville helin <vhelin@cc.hut.fi> in 2000
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.INCDIR  "include/"
.INCLUDE "gb_memory.i"
.INCLUDE "gb_banks.i"
.INCLUDE "cgb_hardware.i"

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; project definitions
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.NAME "TANKBOMBPANIC!"
.RAMSIZE 0
.EMPTYFILL $00
.CARTRIDGETYPE 1
.LICENSEECODENEW ";)"
.COMPUTECHECKSUM
.COMPUTECOMPLEMENTCHECK
.ROMGBC

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; memory map
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

; $C000-$C09F   sprites
; $C0A0-        global variables

; $FF80-FF8B    sprite dma loader

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; global variables
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.ENUM $C0A0

irq_vbi DS 3
irq_lcd DS 3
irq_tim DS 3
irq_ser DS 3
irq_htl DS 3

vbi_counter DB

work_main DB
work_vbi  DB

main_bank_rom  DB
main_bank_dram DB

player_x  DB
player_x8 DB
player_y  DB
player_y8 DB
screen_x  DB
screen_y  DB

screen_origo DW

level_bank_tiles DB
level_bank_map   DB
level_bank_attr  DB

level_dx_x18 DW
level_dx     DB
level_dy     DB

.ENDE
