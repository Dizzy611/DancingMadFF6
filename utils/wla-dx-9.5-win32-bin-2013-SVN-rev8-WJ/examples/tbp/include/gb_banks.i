;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; game boy ROM bank map. two ways to define the ROM bank mapping.
; if the banks are all equal in size, use .BANKSIZE and .ROMBANKS,
; otherwise you'll have to define all the banks one by one.
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

/*
.ROMBANKMAP
BANK 0 $4000
BANK 1 $4000
BANK 2 $4000
BANK 3 $4000
.ENDRO
*/

.ROMBANKSIZE $4000
.ROMBANKS 4
