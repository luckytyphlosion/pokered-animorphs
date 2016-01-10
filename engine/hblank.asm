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
	lb de, %11111000, 40
.palIndexConversionLoop
	ld a, [hl]
	and d
	bit 4, a
	ld [hl], a
	jr z, .continue
	set 0, [hl]
.continue
	add hl, bc
	dec e
	jr nz, .palIndexConversionLoop
	
	ld a, [wCurPalette]	
	ld e, a
	ld hl, CGBPalettes
	and a
	jr z, .regularPalette
	ld bc, $8 * 3
.addNTimesLoop
	add hl, bc
	dec e
	jr nz, .addNTimesLoop
.regularPalette
	ld a, [wLastPalette]
	ld b, a
	ld a, [wCurPalette]
	cp b
	ld [wLastPalette], a
	jr z, .paletteHasNotChanged
	ld de, wTempBGP
	ld a, [rBGP]
	call HandleDMGPalettes
	ld bc, $8
	add hl, bc
	ld de, wTempOBP0
	ld a, [rOBP0]
	call HandleDMGPalettes
	ld bc, $8
	add hl, bc
	ld de, wTempOBP1
	ld a, [rOBP1]
	call HandleDMGPalettes
	ld hl, hLastBGP
; trick the game into transferring palettes by faking a palette change
	ld a, [rBGP]
	inc a
	ld [hli], a
	ld a, [rOBP0]
	inc a
	ld [hli], a
	ld a, [rOBP1]
	inc a
	ld [hl], a
	ret
	
.paletteHasNotChanged
	ld a, [hLastBGP]
	ld b, a
	ld a, [rBGP]
	cp b ; has the BGP changed since the last check?
	jr z, .checkOBP0 ; if not, check OBP0
	; store de with buffer
	ld de, wTempBGP
	call HandleDMGPalettes
.checkOBP0
	ld bc, $8
	add hl, bc
	ld a, [hLastOBP0]
	ld b, a
	ld a, [rOBP0]
	cp b ; has the OBP0 changed?
	jr z, .checkOBP1 ; if not, check OBP1
	ld de, wTempOBP0
	call HandleDMGPalettes
.checkOBP1
	ld a, [hLastOBP1]
	ld b, a
	ld a, [rOBP1]
	cp b ; has the OBP1 changed?
	ret z ; if not, we're done here
	ld de, wTempOBP1
	ld bc, $8
	add hl, bc

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
	
CGBPalettes:

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

InvertedPalettes_BGP:
	dw $0000, $4200, $037f, $7fff
	
InvertedPalettes_OBP0:
	dw $0000, $4200, $037f, $7fff
	
InvertedPalettes_OBP1:
	dw $0000, $4200, $037f, $7fff
	
CheaterPalettes_BGP:
	dw $639f, $4279, $15b0, $04cb
	
CheaterPalettes_OBP0:
	dw $7fff, $32bf, $00d0, $0000

CheaterPalettes_OBP1:
	dw $7fff, $32bf, $00d0, $0000