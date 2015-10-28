CopyScreenTilesToWRAMBuffer::
	ld a, [H_AUTOBGTRANSFERENABLED]
	and a ; do we need to transfer the BG Map?
	jr z, ConvertDMGPaletteIndexesToCGB ; if not, skip to palette conversion
	ld a, 2
; change to wram bank 1
	ld [rSVBK], a
; load hl with tilemap buffer
	ld hl, $d000
; do stack copy similar to AutoBGMapTransfer
	ld [H_SPTEMP], sp
	coord sp, 0, 0
	ld bc, 32 - (20 - 1)
	ld a, 18
	
TransferBgRows:
	rept 20 / 2 - 1
	pop de
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	endr

	pop de
	ld [hl], e
	inc l
	ld [hl], d

	add hl, bc
	dec a
	jr nz, TransferBgRows

	ld a, [H_SPTEMP]
	ld l, a
	ld a, [H_SPTEMP + 1]
	ld h, a
	ld sp, hl
	xor a
	ld [rSVBK], a
; while we're here, handle palettes
ConvertDMGPaletteIndexesToCGB:
	ld hl, wOAMBuffer + 3
	ld bc, 4
	ld e, 40
.palIndexConversionLoop
	ld a, [hl]
	and %11111000
	bit 4, a
	ld [hl], a
	jr z, .continue
	set 0, [hl]
.continue
	add hl, bc
	dec e
	jr nz, .palIndexConversionLoop

	ld a, [hLastBGP]
	ld b, a
	ld a, [rBGP]
	cp b ; has the BGP changed since the last check?
	jr z, .checkOBP0 ; if not, check OBP0
	ld hl, CGBPalettes_BGP ; store hl and de with palettes and buffer respectively
	ld de, wTempBGP
	call HandleDMGPalettes
.checkOBP0
	ld a, [hLastOBP0]
	ld b, a
	ld a, [rOBP0]
	cp b ; has the OBP0 changed?
	jr z, .checkOBP1 ; if not, check OBP1
	ld hl, CGBPalettes_OBP0
	ld de, wTempOBP0
	call HandleDMGPalettes
.checkOBP1
	ld a, [hLastOBP1]
	ld b, a
	ld a, [rOBP1]
	cp b ; has the OBP1 changed?
	ret z ; if not, we're done here
	ld hl, CGBPalettes_OBP1
	ld de, wTempOBP1

; fallthrough
HandleDMGPalettes:
	ld c, 4
.loop
	push hl
	push bc
	push af
	
	and %11 ; get individual shade
	add a
	;add a
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	inc de
	pop af
	srl a ; get next shade
	srl a
	pop bc
	pop hl
	dec c
	jr nz, .loop
	ret
	
CGBPalettes_BGP:
IF DEF(_RED)
	RGB 31, 31, 31
	RGB 29, 16, 18
	RGB 15, 7, 9
	RGB 0, 0, 0
ENDC

IF DEF(_BLUE)
	RGB 31, 31, 31
	RGB 14, 22, 27
	RGB 1, 7, 21
	RGB 0, 0, 0
ENDC

CGBPalettes_OBP0:
IF DEF(_RED)
	RGB 31, 31, 31
	RGB 16, 25, 10
	RGB 2, 12, 2
	RGB 0, 0, 0
ENDC

IF DEF(_BLUE)
	RGB 31, 31, 31
	RGB 29, 16, 18
	RGB 15, 7, 9
	RGB 0, 0, 0
ENDC

CGBPalettes_OBP1:
IF DEF(_RED)
	RGB 31, 31, 31
	RGB 16, 25, 10
	RGB 2, 12, 2
	RGB 0, 0, 0
ENDC

IF DEF(_BLUE)
	RGB 31, 31, 31
	RGB 29, 16, 18
	RGB 15, 7, 9
	RGB 0, 0, 0
ENDC