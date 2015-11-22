FarCopyDataDouble::
; Expand bc bytes of 1bpp image data
; from a:hl to 2bpp data at de.
	ld [hROMBankTemp],a
	ld a,[H_LOADEDROMBANK]
	push af
	ld a,[hROMBankTemp]
	ld [H_LOADEDROMBANK], a
	ld [$2000], a
	push hl ; swap hl and de
	ld h,d
	ld l,e
	pop de
	
	ld a,b
	and a
	jr z,.eightbitcopyamount
	ld a,c
	and a ; multiple of $100
	jr z, .expandloop ; if so, do not increment b because the first instance of dec c results in underflow
.eightbitcopyamount
	inc b
.expandloop
	ld a,[de]
	inc de
	ld [hli],a
	ld [hli],a
	dec c
	jr nz, .expandloop
	dec b
	jr nz, .expandloop
	pop af
	ld [H_LOADEDROMBANK], a
	ld [$2000], a
	ret

;CopyDataInChunksOf16::
;	ld [hROMBankTemp], a
;	ld a, [H_LOADEDROMBANK]
;	push af
;	ld a, [hROMBankTemp]
;	call BankswitchCommon
;	xor a
;	ld [hDidWRAMBankswitchFlag], a
;	call CopyVideoTilesInChunksOf16Common
;	pop af
;	jp BankswitchCommon
	
;CopyDataInChunksOf16_WRAMBankswitch::
;	ld [hROMBankTemp], a
;	ld a, [rSVBK]
;	ld [hSavedWRAMBank], a
;	ld a, [hROMBankTemp]
;	ld [rSVBK], a
;	ld a, $1
;	ld [hDidWRAMBankswitchFlag], a
;CopyDataInChunksOf16Common::
; copy data in chunks of 16
; INPUT:
; hl = source
; de = dest
; c = number of loops
; assumes e = 0
	
;	rept 15
;	ld a, [hli]
;	ld [de], a
;	inc e
;	endr
;	
;	ld a, [hli]
;	ld [de], a
;	inc de
;	dec c
;	jr nz, CopyDataInChunksOf16Common
;	ld a, [hDidWRAMBankswitchFlag]
;	and a
;	ld a, $0
;	ld [hDidWRAMBankswitchFlag], a
;	ret z
;	ld a, [hSavedWRAMBank]
;	ld [rSVBK], a
;	ret
	
CopyVideoData::
; Wait for the next VBlank, then copy c 2bpp
; tiles from b:de to hl, 8 tiles at a time.
; This takes c/8 frames.

	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a ; disable auto-transfer while copying
	ld [H_AUTOBGTRANSFERENABLED], a
	
	ld a, l
	ld [H_VBCOPYDEST], a
	ld a, h
	ld [H_VBCOPYDEST + 1], a
	
	ld a, c
	ld [hSavedVBCopySize], a
	
	ld h,d 
	ld l,e
	
	ld de, $d000 ; set de to 3:d000
	
	ld a, [H_LOADEDROMBANK]
	push af ; save bank
	
	ld a,b
	ld [H_LOADEDROMBANK], a
	ld [$2000], a
	
	swap c
	ld a,$f
	and c
	ld b,a
	ld a,$f0
	and c
	ld c,a
	
	ld a, [rSVBK]
	ld [hSavedWRAMBank], a
	
	ld a, $3
	ld [rSVBK], a
	
	ld a, l
	and $f
	jr nz, .alignTiles
	ld a, h
	ld [rHDMA1], a
	ld a, l
	jp SkipAligningTiles
.alignTiles
	bit 7, h
	jr z, .notCopyingFromVRAM
	ld a, h ; sSpriteBuffer0 / $100
	cp $a0
	jr nc, .notCopyingFromVRAM
; custom function incase we're copying from vram
	inc b
	inc c
	dec c
	jr nz, .waitForNonHBlank
	dec b
.waitForNonHBlank
	ld a, [rSTAT]
	bit 0, a ; in hblank/oam period?
	jr z, .waitForNonHBlank ; wait until we've passed that to get the full effect
.waitForHBlank
	ld a, [rSTAT]
	bit 0, a
	jr nz, .waitForHBlank
	ld a, [hli]
	ld [de], a
	inc e
	ld a, [hli]
	ld [de], a
	inc e
	ld a, [hli]
	ld [de], a
	inc e
	ld a, [hli]
	ld [de], a
	inc de
	
	dec c
	jr nz, .waitForNonHBlank
	dec b
	jr nz, .waitForNonHBlank
	jr CopyVideoDataCommon

; input is now:
; hl = source
; de = destination
; bc = raw bytes to copy
; a = bank
.notCopyingFromVRAM
	inc b  ; we bail the moment b hits 0, so include the last run
	inc c  ; same thing; include last byte
	jr .HandleLoop
.CopyByte
	ld a, [hli]
	ld [de], a
	inc de
.HandleLoop
	dec c
	jr nz, .CopyByte
	dec b
	jr nz, .CopyByte
	jr CopyVideoDataCommon

CopyVideoDataDouble::
; Wait for the next VBlank, then copy c 1bpp
; tiles from b:de to hl, 8 tiles at a time.
; This takes 2 frames at most.
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a ; disable auto-transfer while copying
	ld [H_AUTOBGTRANSFERENABLED], a
	; save destination for later
	ld a, l
	ld [H_VBCOPYDOUBLEDEST], a
	ld a, h
	ld [H_VBCOPYDOUBLEDEST + 1], a
	
	ld a, c
	ld [hSavedVBCopySize], a

	ld hl, $d000 ; set hl to 3:d000 (scratch space)
	
	ld a,[H_LOADEDROMBANK]
	push af
	
	ld a, b ; get bank
	ld [H_LOADEDROMBANK], a
	ld [$2000], a
	
	push hl
	ld h,$0
	ld l,c
	add hl,hl ; get raw length of bytes to copy
	add hl,hl
	add hl,hl
	ld b,h
	ld c,l
	pop hl
	
	ld a, [rSVBK]
	ld [hSavedWRAMBank], a
	
	ld a, $3
	ld [rSVBK], a
	
; input is now:
; hl = source
; de = fixed destination
; bc = raw number of bytes to copy
; a = bank
	ld a,b
	and a
	jr z,.eightbitcopyamount
	ld a,c
	and a ; multiple of $100
	jr z, .expandloop ; if so, do not increment b because the first instance of dec c results in underflow
.eightbitcopyamount
	inc b
.expandloop
	ld a,[de]
	inc de
	ld [hli],a
	ld [hli],a
	dec c
	jr nz, .expandloop
	dec b
	jr nz, .expandloop

CopyVideoDataCommon:
	ld a, $d0
	ld [rHDMA1], a ; write source
	xor a
SkipAligningTiles:
	ld [rHDMA2], a
	ld a, [H_VBCOPYDEST + 1]
	ld [rHDMA3], a
	ld a, [H_VBCOPYDEST]
	ld [rHDMA4], a
	
	ld a, [rIE] ; disable H-Blank interrupt for now
	res LCD_STAT, a
	ld [rIE], a
	
	ld a, [hSavedVBCopySize]
	dec a
	set 7, a
	ld hl, rHDMA5
	lb bc, $ff, (rSTAT & $ff)
	ld d, a
.waitForNonHBlankLoop
	ld a, [$ff00+c]
	and %11
	jr nz, .waitForNonHBlankLoop
	
	ld [hl], d
	ld a, d
	ld [H_VBCOPYSIZE], a
	ld a, b
	
.waitForHDMALoop
	cp [hl]
	jr nz, .waitForHDMALoop
	
	xor a
	ld [H_VBCOPYSIZE], a

	ld a, [hSavedWRAMBank]
	ld [rSVBK], a

	ld a, [rIE]
	set LCD_STAT, a
	ld [rIE], a
	pop af
	ld [H_LOADEDROMBANK], a
	ld [$2000], a
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

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
	cp $81
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
