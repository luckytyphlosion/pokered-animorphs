_AnimatePlayerMonMorph:
	ld a, $31
	ld [hStartTileID], a
	coord hl, 1, 5
	predef CopyUncompressedPicToTilemap
	call RearrangeMonPicInLines
	call CopyLeftPortionOfTileMap
; now copy each line to vram
; save H_AUTOBGTRANSFERENABLED
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
; get sprite width
	xor a
	ld [hSavedLYAddressValue], a
	ld [hSCX], a
	ld a, 40
	ld [hWhichOverride], a
	ld a, 40 + 8 * 7 - 1
	ld [hMaxLY], a
	
; get base address of enemy pic and vram address
	ld de, sSpriteBuffer3
	ld hl, vBackPic
; offset to next column
	ld bc, 7 * $10
; reset ly
	call DelayFrame
; number of lines
	ld a, (7 * 8) / 2
.loop
	push af
	call GetLYOffsetsForMorphAnim
	push hl
	push bc
	lb bc, $8, rSCX & $ff
	ld a, [hWhichOverride]
	ld l, a
	ld h, $c9
	dec l
.writeNewSCXLoop
	ld a, [rLY]
	cp l
	jr nz, .writeNewSCXLoop
	inc l
.waitForHBlankLoop
	ld a, [rSTAT]
	and %10
	jr nz, .waitForHBlankLoop
	ld a, [hli]
	ld [$ff00+c], a
.waitForNonHBlankLoop
	ld a, [rSTAT]
	and %10
	jr z, .waitForNonHBlankLoop
	dec b
	jr nz, .waitForHBlankLoop
	ld hl, hWhichOverride
	inc [hl]
	inc [hl]
	ld a, [hSavedLYAddressValue]
	ld [$ff00+c], a
	pop bc
	pop hl


; first, wait for ly $38 (past player pic)
.waitForSafeLY
	ld a, [rLY]
	cp 12 * 8
	jr c, .waitForSafeLY
; copy during hblank
	call CopyOneLineOfPic
	call CopyOneLineOfPic
	call DelayFrame
	pop af
	dec a
	jr nz, .loop
MorphMonDone:
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ld hl, rLCDC
	res 3, [hl]
	set 6, [hl]
	ld a, $7
	ld [rWX], a
	ret

_AnimateEnemyMorphMon:
; animate the enemy trainer morphing
; by drawing each line of the mon sprite every frame

; first, re-order the first sprite buffer in the order of each tile line
	xor a
	ld [hStartTileID], a
	coord hl, 12, 0
	predef CopyUncompressedPicToTilemap
	call RearrangeMonPicInLines
	call CopyLeftPortionOfTileMap

; now copy each line to vram
; save H_AUTOBGTRANSFERENABLED
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld [hWhichOverride], a
	ld [hSCX], a
	ld a, 7 * 8 - 1
	ld [hMaxLY], a
	ld a, [rWX]
	ld [hSavedLYAddressValue], a
; get base address of enemy pic and vram address
	ld de, sSpriteBuffer3
	ld hl, vFrontPic
; offset to next column
	ld bc, 7 * $10
	call DelayFrame
	ld a, $ff
	ld [hSpecialVBlankFunction], a
; number of lines
	ld a, (7 * 8) / 2
.loop
	push af
	call GetLYOffsetsForMorphAnim
; first, wait for ly $38 (past enemy pic)
.waitForSafeLY
	ld a, [rLY]
	cp $90 ; don't copy if in vblank period
	jr nc, .waitForSafeLY
	cp $38
	jr c, .waitForSafeLY
; copy during hblank
	call CopyOneLineOfPic
	call CopyOneLineOfPic
	call DelayFrame
	pop af
	dec a
	jr nz, .loop
	xor a
	ld [hSpecialVBlankFunction], a
	jp MorphMonDone

DoEnemyMonSCXManipulation:
; called in vblank to ensure we aren't too late with LY
	lb bc, $8, rWX & $ff
	ld a, [hWhichOverride]
	ld l, a
	ld h, $c9
.writeNewSCXLoop
	ld a, [rLY]
	cp l
	jr nz, .writeNewSCXLoop
.waitForHBlankLoop
	ld a, [rSTAT]
	and %10
	jr nz, .waitForHBlankLoop
	ld a, [hli]
	ld [$ff00+c], a
.waitForNonHBlankLoop
	ld a, [rSTAT]
	and %10
	jr z, .waitForNonHBlankLoop
	dec b
	jr nz, .waitForHBlankLoop
	ld hl, hWhichOverride
	inc [hl]
	inc [hl]
	ld a, [hSavedLYAddressValue]
	ld [$ff00+c], a
	ret

RearrangeMonPicInLines:
	ld hl, sSpriteBuffer1
	ld de, sSpriteBuffer3
	ld b, 7 * 8
.outerLoop
	push hl
	ld c, $7
.innerLoop
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hld]
	ld [de], a
	inc de
	ld a, 7 * $10
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	dec c
	jr nz, .innerLoop
	pop hl
	inc hl
	inc hl
	dec b
	jr nz, .outerLoop
	ret

CopyOneLineOfTile:
	ld a, [rSTAT]
	and %10
	jr z, CopyOneLineOfTile ; wait until we're not in hblank for full effect
.waitForHBlank
	ld a, [rSTAT]
	and %10
	jr nz, .waitForHBlank ; now wait for the beginning of hblank
; copy one tile line
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hld], a
	inc de
	add hl, bc
	ret
	
CopyOneLineOfPic:
	ld a, $7
	push hl
.copyOneLineLoop
	push af
	call CopyOneLineOfTile
	pop af
	dec a
	jr nz, .copyOneLineLoop
	pop hl
	inc hl
	inc hl
	ret
	
GetLYOffsetsForMorphAnim:
	push hl
	push bc
	ld h, $c9
	ld a, [hWhichOverride]
	ld l, a
	ld c, $8
.loop
	ld a, [hMaxLY]
	cp l
	ld b, $0
	jr c, .noLYManip
	ld b, 3 * 8
.rejectionSampleLoop
	call Random
	and $3f
	cp b
	jr nc, .rejectionSampleLoop
	srl b
	sub b
	ld b, a
.noLYManip
	ld a, [hSavedLYAddressValue]
	sub b
	ld [hli], a
	dec c
	jr nz, .loop
	pop bc
	pop hl
	ret
	
CopyLeftPortionOfTileMap:
	call SaveScreenTilesToBuffer1
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
; copy the right part of the tilemap to vBGMap0
	coord hl, 8, 0
	coord de, 0, 0
	ld b, SCREEN_HEIGHT
.copyTileMapLoop_outer
	push de
	push hl
	ld c, SCREEN_WIDTH - $8
.copyTileMapLoop_inner
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copyTileMapLoop_inner
	pop hl
	ld de, SCREEN_WIDTH
	add hl, de
	pop de
	ld a, SCREEN_WIDTH
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	dec b
	jr nz, .copyTileMapLoop_outer
	ld b, vBGMap0 / $100
	call CopyScreenTileBufferToVRAM
	call LoadScreenTilesFromBuffer1
	ld a, (8 * 8) + 7
	ld [rWX], a
	ld hl, rLCDC
	set 3, [hl] ; switch to bg map 1
	res 6, [hl] ; window to bg map 0
	ret