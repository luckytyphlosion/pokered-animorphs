LoadMapSpriteMovementBytes:
; for spinner hell option
	ld a, [wCurMap]
	call SwitchToMapRomBank
	ld a, [wCurMap]
	ld e, a
	ld d, $0
	ld hl, MapHeaderPointers
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a ; hl = map header pointer
	ld bc, 9
	add hl, bc ; skip to connection data
	ld a, [hli]
	and a
	jr z, .noConnections
	ld b, a
	ld de, 11
	ld c, 4
.skipConnectionDataLoop
	srl b
	jr nc, .noConnection
	add hl, de
.noConnection
	dec c
	jr nz, .skipConnectionDataLoop
.noConnections
	ld a, [hli]
	ld h, [hl]
	ld l, a ; hl = object pointer
	inc hl ; skip border block
	ld a, [hli]
	and a
	jr z, .noWarps
	push hl
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl ; use 16-bit because of sabrina's gym
	ld c, l
	ld b, h
	pop hl
	add hl, bc
.noWarps
	ld a, [hli]
	and a
	jr z, .noSigns
	ld c, a
	add a
	add c ; triple it
	ld c, a
	ld b, 0
	add hl, bc
.noSigns
	ld a, [hli]
	and a
	ret z ; return if no map sprites
	ld [hLoadSpriteTemp1], a ; num sprites
	ld de, wMapSpriteData
	ld bc, $5 ; offset to skip to flags byte
.rewriteSpriteMovementByteLoop
	add hl, bc
	ld a, [hl]
	bit 6, a
	jr nz, .trainerSprite
	bit 7, a
	jr z, .notTrainerOrItemSprite
; handle item sprite
	jr .itemSprite
.trainerSprite
	ld a, [wOptions2]
	bit 0, a ; spinner hell mode?
	ld a, NONE
	jr nz, .spinnerHellMode
; load regular movement byte
	dec hl
	ld a, [hli] ; a = movement byte
.spinnerHellMode
	ld [de], a
	inc hl
.itemSprite
	inc hl ; hl = one less than next sprite entry
.notTrainerOrItemSprite
	inc hl
	inc de
	inc de
	ld a, [hLoadSpriteTemp1]
	dec a
	ld [hLoadSpriteTemp1], a
	jr nz, .rewriteSpriteMovementByteLoop
	ret