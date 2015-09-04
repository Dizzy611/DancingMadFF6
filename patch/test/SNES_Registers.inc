 ; Registers
 
 .define DISPLAY_CONTROL  $2100
 .define PALETTE_SELECT   $2121
 .define PALETTE_WRITE    $2122
 .define INT_ENABLE       $4200
 .define JOY_STATUS       $4212 ; This is apparently technically "PPU Status".
 .define JOY1_LOW         $4218 ; #%axlr0000
 .define JOY1_HIGH        $4219 ; #%byetudlr
 .define JOY2_LOW         $421A
 .define JOY2_HIGH        $421B
 .define JOY3_LOW         $421C
 .define JOY3_HIGH        $421D
 .define JOY4_LOW         $421E
 .define JOY4_HIGH        $421F
 
 
  ; Values
 
 ; INT_ENABLE
 .define INT_JOY %00000001
 ; DISPLAY_CONTROL
.define DCTL_SCREEN_OFF %10000000
.define DCTL_SCREEN_ON %00001111
 ; JOY_STATUS
.define JOY_READY %00000001
 ; JOY#_HIGH
.define JOY_B %10000000
JOY_B: 
.define JOY_Y %01000000
.define JOY_SELECT %00100000
.define JOY_START %00010000
.define JOY_UP %00001000
.define JOY_DOWN %00000100
.define JOY_LEFT %00000010
.define JOY_RIGHT %00000001
 ; JOY#_LOW
.define JOY_A %10000000
.define JOY_X %01000000
.define JOY_L %00100000
.define JOY_R %00010000
  