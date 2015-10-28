; clears a VRAM background map with blank space tiles
; INPUT: h - high byte of background tile map address in VRAM
ClearBgMap:: ; 1cf0 (0:1cf0)
	ld a," "
	jr .next
	ld a,l
.next
	ld de,$400 ; size of VRAM background map
	ld l,e
.loop
	ld [hli],a
	dec e
	jr nz,.loop
	dec d
	jr nz,.loop
	ret

RedrawRowOrColumn:: ; 1d01 (0:1d01)
; This function redraws a BG row of height 2 or a BG column of width 2.
; One of its main uses is redrawing the row or column that will be exposed upon
; scrolling the BG when the player takes a step. Redrawing only the exposed
; row or column is more efficient than redrawing the entire screen.
; However, this function is also called repeatedly to redraw the whole screen
; when necessary. It is also used in trade animation and elevator code.
	ld a,[hRedrawRowOrColumnMode]
	and a
	ret z
	ld b,a
	xor a
	ld [hRedrawRowOrColumnMode],a
	dec b
	jr nz,.redrawRow
.redrawColumn
	ld hl,wRedrawRowOrColumnSrcTiles
	ld a,[hRedrawRowOrColumnDest]
	ld e,a
	ld a,[hRedrawRowOrColumnDest + 1]
	ld d,a
	ld c,SCREEN_HEIGHT
.loop1
	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	ld a,BG_MAP_WIDTH - 1
	add e
	ld e,a
	jr nc,.noCarry
	inc d
.noCarry
; the following 4 lines wrap us from bottom to top if necessary
	ld a,d
	and a,$03
	or a,$98
	ld d,a
	dec c
	jr nz,.loop1
	xor a
	ld [hRedrawRowOrColumnMode],a
	ret
.redrawRow
	ld hl,wRedrawRowOrColumnSrcTiles
	ld a,[hRedrawRowOrColumnDest]
	ld e,a
	ld a,[hRedrawRowOrColumnDest + 1]
	ld d,a
	push de
	call .DrawHalf ; draw upper half
	pop de
	ld a,BG_MAP_WIDTH ; width of VRAM background map
	add e
	ld e,a
	; fall through and draw lower half

.DrawHalf
	ld c,SCREEN_WIDTH / 2
.loop2
	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	ld a,e
	inc a
; the following 6 lines wrap us from the right edge to the left edge if necessary
	and a,$1f
	ld b,a
	ld a,e
	and a,$e0
	or b
	ld e,a
	dec c
	jr nz,.loop2
	ret

; This function automatically transfers tile number data from the tile map at
; wTileMap to VRAM during V-blank. Note that it only transfers one third of the
; background per V-blank. It cycles through which third it draws.
; This transfer is turned off when walking around the map, but is turned
; on when talking to sprites, battling, using menus, etc. This is because
; the above function, RedrawRowOrColumn, is used when walking to
; improve efficiency.
AutoBgMapTransfer:: ; 1d57 (0:1d57)
	ld a,[H_AUTOBGTRANSFERENABLED]
	and a
	ret z
	
	ld a, 2
	ld [rSVBK], a ; change wram bank to 1 to get tilemap buffer
	ld a, $d0 ; write source in wram
	ld [rHDMA1], a
	xor a
	ld [rHDMA2], a
	ld a,[H_AUTOBGTRANSFERDEST + 1] ; copy address from H_AUTOBGTRANSFERDEST to rHDMA3 and 4
	ld [rHDMA3], a					; note that hall of fame breaks because it sets H_AUTOBGTRANSFERDEST to a non-multiple of $10
	ld a,[H_AUTOBGTRANSFERDEST]		; luckily, it's the only thing that does so
	ld [rHDMA4], a
	ld a, 36 - 1					; number of multiple of $10 chunks to copy
	ld [rHDMA5], a					; writing this also doubles as starting the transfer
	xor a
	ld [rSVBK], a ; change wram bank back to normal
	ret

WriteCGBPalettes::
	ld a, [hLastBGP]
	ld b, a
	ld a, [rBGP]
	cp b ; has the BGP changed since the last check?
	ld [hLastBGP], a
	jr z, .checkOBP0 ; if not, check OBP0
	
	ld hl, wTempBGP
	lb bc, 8, rBGPI & $ff
	ld a, %10000000
	ld [$ff00+c], a
	inc c
.bgpLoop
	ld a, [hli]
	ld [$ff00+c], a
	dec b
	jr nz, .bgpLoop
.checkOBP0
	ld a, [hLastOBP0]
	ld b, a
	ld a, [rOBP0]
	cp b ; has the OBP0 changed?
	ld [hLastOBP0], a
	jr z, .checkOBP1
	
	ld hl, wTempOBP0
	ld d, h ; save address to copy non-sequentially to palettes 2 and 3 (see below)
	ld e, l
	lb bc, 8, rOBPI & $ff
	ld a, %10000000
	ld [$ff00+c], a
	inc c
.obp0Loop1
	ld a, [hli]
	ld [$ff00+c], a
	dec b
	jr nz, .obp0Loop1
; the oam code writes 02 and 03 to the flags byte for the bottom half of sprites for some reason
; the hblank function clears these useless writes, but sprite flickering still occurs
; therefore, we write to palettes 2 and 3 to hide the sprite flickering
	ld a, %10000000 | 16
	ld [rOBPI], a
	ld b, 8
	ld h, d ; saves cycles over push/pop
	ld l, e
.obp0Loop2
	ld a, [hli]
	ld [$ff00+c], a
	dec b
	jr nz, .obp0Loop2
	ld b, 8
	ld h, d
	ld l, e
.obp0Loop3
	ld a, [hli]
	ld [$ff00+c], a
	dec b
	jr nz, .obp0Loop3
.checkOBP1
	ld a, [hLastOBP1]
	ld b, a
	ld a, [rOBP1]
	cp b ; has the OBP1 changed?
	ld [hLastOBP1], a
	ret z
	ld hl, wTempOBP1
	lb bc, 8, rOBPI & $ff
	ld a, %10000000 | 8
	ld [$ff00+c], a
	inc c
.obp1Loop
	ld a, [hli]
	ld [$ff00+c], a
	dec b
	jr nz, .obp1Loop
	ret

VBlankCopyCommon::
; Copy [H_VBCOPYSIZE] 2bpp tiles (or 16 * [H_VBCOPYSIZE] tile map entries)
; from H_VBCOPYSRC to H_VBCOPYDEST.

; Source and destination addresses are updated,
; so transfer can continue in subsequent calls.

	ld a, [H_VBCOPYSIZE]
	and a
	ret z
	
	ld a, $3
	ld [rSVBK], a
	
	ld a, [H_VBCOPYSRC + 1]
	ld [rHDMA1], a
	ld a, [H_VBCOPYSRC]
	ld [rHDMA2], a

	ld a, [H_VBCOPYDEST + 1]
	ld [rHDMA3], a
	ld a, [H_VBCOPYDEST]
	ld [rHDMA4], a
	
	ld a, [H_VBCOPYSIZE]
	dec a
	ld [rHDMA5], a

	xor a ; transferred
	ld [H_VBCOPYSIZE], a
	ld [rSVBK], a
	
	ret

UpdateMovingBgTiles::
; Animate water and flower
; tiles in the overworld.

	ld a, [hTilesetType]
	and a
	ret z ; no animations if indoors (or if a menu set this to 0)
	
	ld a, [rLY]
	cp $90
	ret c
	
	ld a, [hMovingBGTilesCounter1]
	inc a
	ld [hMovingBGTilesCounter1], a
	cp 20
	ret c
	cp 21
	jr z, .flower

; water

	ld hl, vTileset + $14 * $10
	ld c, $10

	ld a, [wMovingBGTilesCounter2]
	inc a
	and 7
	ld [wMovingBGTilesCounter2], a

	and 4
	jr nz, .left
.right
	ld a, [hl]
	rrca
	ld [hli], a
	dec c
	jr nz, .right
	jr .done
.left
	ld a, [hl]
	rlca
	ld [hli], a
	dec c
	jr nz, .left
.done
	ld a, [hTilesetType]
	rrca
	ret nc
; if in a cave, no flower animations
	xor a
	ld [hMovingBGTilesCounter1], a
	ret

.flower
	xor a
	ld [hMovingBGTilesCounter1], a

	ld a, [wMovingBGTilesCounter2]
	and 3
	cp 2
	ld hl, FlowerTile1
	jr c, .copy
	ld hl, FlowerTile2
	jr z, .copy
	ld hl, FlowerTile3
.copy
	ld de, vTileset + $3 * $10
	ld c, $10
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	ret

FlowerTile1: INCBIN "gfx/tilesets/flower/flower1.2bpp"
FlowerTile2: INCBIN "gfx/tilesets/flower/flower2.2bpp"
FlowerTile3: INCBIN "gfx/tilesets/flower/flower3.2bpp"
