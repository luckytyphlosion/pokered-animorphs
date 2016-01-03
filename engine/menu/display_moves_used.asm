_DisplayMovesUsed:
	ld hl, wd730
	set 6, [hl]
	ld a, MOVE_NAME
	ld [wNameListType], a
	call SaveScreenTilesToBuffer1
	xor a
	ld [wBagSavedMenuItem], a
	ld [wParentMenuItem], a
	ld a, [wFlags_0xcd60]
	bit 3, a ; accessing player's PC through another PC?
	jr nz, _DisplayMovesUsedMenu
; accessing it directly
	ld a, SFX_TURN_ON_PC
	call PlaySound
	ld hl, TurnedOnPC3Text
	call PrintText

_DisplayMovesUsedMenu: ; 790c (1:790c)
	call UpdateSprites
	xor a
	ld [wMovesUsedWhichPointer], a
.bigloop
	xor a
	ld [wCurrentMenuItem], a
	ld [wListScrollOffset], a
	;inc a
	;ld [wMenuWrappingEnabled], a
.loop
	ld hl, DisplayMovesUsedMenu_WhichMoveText
	call PrintText
	ld a, [wMovesUsedWhichPointer]
	and a
	ld hl, MovesAsIndexesListOne
	jr z, .foundPointer
	ld hl, MovesAsIndexesListTwo
.foundPointer
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a
	xor a
	ld [wPrintItemPrices], a
	ld a, MOVESLISTMENU
	ld [wListMenuID], a
	call DisplayListMenuID
	jp c, ExitDisplayMovesUsedMenu
	ld a, [wcf91]
	cp NUM_ATTACKS + 2
	jr nz, .notNext
	ld a, $1
	ld [wMovesUsedWhichPointer], a
	jr .bigloop
.notNext
	cp NUM_ATTACKS + 3
	jr nz, .notBack
	xor a
	ld [wMovesUsedWhichPointer], a
	jr .bigloop
.notBack
	dec a
	ld e, a
	ld d, 0
	ld hl, sMoveUseRecord
	add hl, de
	add hl, de
	ld a, SRAM_ENABLE
	ld [wSRAMEnabled], a
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [wSRAMBank], a
	ld [MBC1SRamBank], a
	ld a, [hli]
	ld [wBuffer], a
	ld a, [hl]
	ld [wBuffer + 1], a
	xor a
	ld [wSRAMEnabled], a
	ld [MBC1SRamEnable], a
	ld [wSRAMBank], a
	ld [MBC1SRamBank], a
	
	ld hl, UsedXTimesText
	call PrintText
	jr .loop

ExitDisplayMovesUsedMenu: ; 796d (1:796d)
	ld a, [wFlags_0xcd60]
	bit 3, a ; accessing player's PC through another PC?
	jr nz, .next
; accessing it directly
	ld a, SFX_TURN_OFF_PC
	call PlaySound
	call WaitForSoundToFinish
.next
	call LoadScreenTilesFromBuffer2
	xor a
	ld [wListScrollOffset], a
	ld [wBagSavedMenuItem], a
	ld hl, wd730
	res 6, [hl]
	xor a
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ld [wMenuWrappingEnabled], a
	ret

UsedXTimesText:
	TX_RAM wcf4b
	text ":"
	line "@"
	TX_NUM wBuffer, 2, 5
	TX_ASM
	ld a, $ee
	Coorda 18, 16
	call WaitForTextScrollButtonPress
	jp TextScriptEnd

DisplayMovesUsedMenu_WhichMoveText:
	text "Which move?"
	done
	
MovesAsIndexesListOne:
CUR_MOVE EQU 1
	db $7e
	rept $7d
	db CUR_MOVE
CUR_MOVE = CUR_MOVE + 1
	endr
	db NUM_ATTACKS + 2
	db $ff
	
MovesAsIndexesListTwo:
	db NUM_ATTACKS - $7d + 1
	
	rept 39 ; NUM_ATTACKS - $7e
	db CUR_MOVE
CUR_MOVE = CUR_MOVE + 1
	endr
	db NUM_ATTACKS + 3
	db $ff
	
TurnedOnPC3Text:
	TX_FAR _TurnedOnPC1Text
	db "@"