WriteDMACodeToHRAM:
; Since no other memory is available during OAM DMA,
; DMARoutine is copied to HRAM and executed there.
	ld c, $ff80 % $100
	ld b, DMARoutineEnd - DMARoutine
	ld hl, DMARoutine
.copy
	ld a, [hli]
	ld [$ff00+c], a
	inc c
	dec b
	jr nz, .copy
	ret

DMARoutine:
	; initiate DMA
	ld [$ff00+c], a
.wait
	dec b
	jr nz, .wait
	ret
DMARoutineEnd:
