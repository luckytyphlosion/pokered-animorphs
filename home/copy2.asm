FarCopyDataDouble::
; Expand bc bytes of 1bpp image data
; from a:hl to 2bpp data at de.
	ld [hROMBankTemp],a
	ld a,[H_LOADEDROMBANK]
	push af
	ld a,[hROMBankTemp]
	ld [H_LOADEDROMBANK],a
	ld [MBC1RomBank],a
.loop
	ld a,[hli]
	ld [de],a
	inc de
	ld [de],a
	inc de
	dec bc
	ld a,c
	or b
	jr nz,.loop
	pop af
	ld [H_LOADEDROMBANK],a
	ld [MBC1RomBank],a
	ret

CopyVideoData::
; Wait for the next VBlank, then copy c 2bpp
; tiles from b:de to hl, 8 tiles at a time.
; This takes c/8 frames.

	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a ; disable auto-transfer while copying
	ld [H_AUTOBGTRANSFERENABLED], a

	ld a, [H_LOADEDROMBANK]
	ld [hROMBankTemp], a

	ld a, b
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	ld a, e
	ld [H_VBCOPYSRC], a
	ld a, d
	ld [H_VBCOPYSRC + 1], a

	ld a, l
	ld [H_VBCOPYDEST], a
	ld a, h
	ld [H_VBCOPYDEST + 1], a

.loop
	ld a, c
	cp 8
	jr nc, .keepgoing

.done
	ld [H_VBCOPYSIZE], a
	call DelayFrame
	ld a, [hROMBankTemp]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

.keepgoing
	ld a, 8
	ld [H_VBCOPYSIZE], a
	call DelayFrame
	ld a, c
	sub 8
	ld c, a
	jr .loop

CopyVideoDataDouble::
; Wait for the next VBlank, then copy c 1bpp
; tiles from b:de to hl, 8 tiles at a time.
; This takes c/8 frames.
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a ; disable auto-transfer while copying
	ld [H_AUTOBGTRANSFERENABLED], a
	ld a, [H_LOADEDROMBANK]
	ld [hROMBankTemp], a

	ld a, b
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	ld a, e
	ld [H_VBCOPYDOUBLESRC], a
	ld a, d
	ld [H_VBCOPYDOUBLESRC + 1], a

	ld a, l
	ld [H_VBCOPYDOUBLEDEST], a
	ld a, h
	ld [H_VBCOPYDOUBLEDEST + 1], a

.loop
	ld a, c
	cp 8
	jr nc, .keepgoing

.done
	ld [H_VBCOPYDOUBLESIZE], a
	call DelayFrame
	ld a, [hROMBankTemp]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

.keepgoing
	ld a, 8
	ld [H_VBCOPYDOUBLESIZE], a
	call DelayFrame
	ld a, c
	sub 8
	ld c, a
	jr .loop

ClearScreenArea::
; Clear tilemap area cxb at hl.
	ld a, " " ; blank tile
	ld de, 20 ; screen width
.y
	push hl
	push bc
.x
	ld [hli], a
	dec c
	jr nz, .x
	pop bc
	pop hl
	add hl, de
	dec b
	jr nz, .y
	ret

CopyScreenTileBufferToVRAM::
; Copy wTileMap to the BG Map starting at b * $100.
; This is done in thirds of 6 rows, so it takes 3 frames.
	ld a, [rLY]
	cp $75
	call nc, DelayFrame ; if ly is past $80, then wait for another vblank for the tilemap to be successfully copied
						; not exactly sure if needed
	ld a, [H_AUTOBGTRANSFERDEST + 1]
	push af
	ld a, [H_AUTOBGTRANSFERDEST]
	push af
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERDEST], a
	ld a, b
	ld [H_AUTOBGTRANSFERDEST + 1], a
	ld [H_AUTOBGTRANSFERENABLED], a
	call DelayFrame
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	pop af
	ld [H_AUTOBGTRANSFERDEST], a
	pop af
	ld [H_AUTOBGTRANSFERDEST + 1], a
	ret

ClearScreen::
; Clear wTileMap, then wait
; for the bg map to update.
	ld bc, 20 * 18
	inc b
	coord hl, 0, 0
	ld a, " "
.loop
	ld [hli], a
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	jp DelayFrame
