FarCopyData::
FarCopyData2::
; Copy bc bytes from a:hl to de.
	ld [hROMBankTemp], a
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, [hROMBankTemp]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call CopyData
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

CopyData::
; Copy bc bytes from hl to de.
	ld a,b
	and a
	jr z, .copybytes
	ld a,c
	and a ; is lower byte 0
	jr z, .loop
	inc b ; if not, increment b as there are <$100 bytes to copy
.loop
	call .copybytes
	dec b
	jr nz,.loop
	ret
	
.copybytes
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copybytes
	ret