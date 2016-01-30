CGBOnlyMessage:
	ld hl, $fe00
	ld bc, $a0
	xor a
	call FillMemory
	
	ld hl, vBGMap0
	
	push hl
	ld a, "┌"
	ld [hli], a
	call DMG_DrawTextBoxHorizontalLine
	ld [hl], "┐"
	ld bc, BG_MAP_WIDTH
	add hl, bc
	call DMG_DrawTextBoxVerticalLine
	ld [hl], "┘"
	pop hl
	
	ld bc, BG_MAP_WIDTH
	add hl, bc
	call DMG_DrawTextBoxVerticalLine
	ld a, "└"
	ld [hli], a
	call DMG_DrawTextBoxHorizontalLine
	
	ld hl, vBGMap0 + BG_MAP_WIDTH * 2 + $2
	ld de, CGBOnlyText
	ld bc, BG_MAP_WIDTH
	push hl
.printTextLoop
	ld a, [de]
	inc de
	cp $4e
	jr nz, .notNewline
	pop hl
	add hl, bc
	push hl
	jr .printTextLoop
.notNewline
	cp "@"
	jr z, .done
	ld [hli], a
	jr .printTextLoop
.done
	call LoadFontTilePatterns
	call LoadTextBoxTilePatterns
	call GBPalNormal
	ld a, rLCDC_DEFAULT
	ld [rLCDC], a
	call StopAllSounds
	
	jr @
	
CGBOnlyText:
	db   "This game is"
	next "meant for CGB"
	next "use only."
	next $4e
	next "(And no, DMG"
	next "mode would not"
	next "make the game"
	next "slightly faster)@"

	
DMG_DrawTextBoxHorizontalLine:
	ld a, "─"
	ld d, SCREEN_WIDTH - 2
.drawHorizontalTextBoxLineLoop
	ld [hli], a
	dec d
	jr nz, .drawHorizontalTextBoxLineLoop
	ret
	
DMG_DrawTextBoxVerticalLine:
	ld a, "│"
	ld d, SCREEN_HEIGHT - 2
	ld bc, BG_MAP_WIDTH
.drawVerticalTextBoxLineLoop
	ld [hl], a
	add hl, bc
	dec d
	jr nz, .drawVerticalTextBoxLineLoop
	ret