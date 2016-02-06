VBlank::

	ld [hSavedAReg], a
	
	ld a, [rSVBK]
	ld [hSavedWRAMBankVBlank], a
	
	ld a, $0
	ld [rSVBK], a
	
	ld a, [hSavedAReg]
	
	push af
	push bc
	push de
	push hl
	
	ld a, [H_LOADEDROMBANK]
	ld [wVBlankSavedROMBank], a

	ld a, [hSCX]
	ld [rSCX], a
	ld a, [hSCY]
	ld [rSCY], a

	ld a, [wDisableVBlankWYUpdate]
	and a
	jr nz, DontUpdateWY
	ld a, [hWY]
ItemUse8_8:
	ld [rWY], a
DontUpdateWY:

	call AutoBgMapTransfer
	call WriteCGBPalettes
	call RedrawRowOrColumn
	call VBlankCopyCommon
	call UpdateMovingBgTiles
	ld a, [wDoOAMUpdate]
	and a
	ld a, wOAMBuffer / $100
	lb bc, $29, rDMA & $ff
	call z, $ff80 ; hOAMDMA

	; VBlank-sensitive operations end.
	ld a, [wUpdateSpritesEnabled]
	cp $ff ; simulate red/blue dsum
	call Random

	xor a
	ld [H_VBLANKOCCURRED], a
	
	ld a, [H_FRAMECOUNTER]
	and a
	jr z, .skipDec
	dec a
	ld [H_FRAMECOUNTER], a

.skipDec
	call FadeOutAudio
	
	ld a, [wAudioROMBank] ; music ROM bank
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	cp BANK(Audio1_UpdateMusic)
	jr nz, .checkForAudio2
.audio1
	call Audio1_UpdateMusic
	jr .afterMusic
.checkForAudio2
	cp BANK(Audio2_UpdateMusic)
	jr nz, .audio3
.audio2
	call Music_DoLowHealthAlarm
	call Audio2_UpdateMusic
	jr .afterMusic
.audio3
	call Audio3_UpdateMusic
.afterMusic
	ld a, [hDoBattleTransition]
	and a ; do battle transition?
	jr z, .noBattleTransition
	ld a, BANK(BattleTransition)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call BattleTransitionPreparation
	
.noBattleTransition
	ld a, [wOptions3]
	bit 6, a
	jr z, .noSoftReset
	ld hl, wSRAMBank
	ld a, [hli] ; go to enable status
	cp $1
	jr c, .allowSoftReset ; bank 0 is scratch, HoF doesn't really matter that much
	ld a, [hl]
	cp SRAM_ENABLE
	jr z, .noSoftReset ; if sram is enabled and we're in a save-data bank, prevent soft reset
.allowSoftReset
	ld a, [hJoyInput]
	and $f
	cp $f
	jr nz, .noSoftReset
	ld a, [hSoftReset]
	and a
	jr z, .doSoftReset
	dec a
	ld [hSoftReset], a
	jr .noSoftReset
.doSoftReset
	ld hl, [sp+$8] ; swag pinball strats
	ld [hl], SoftReset & $ff
	inc hl
	ld [hl], SoftReset / $100
.noSoftReset
	callba TrackPlayTime ; keep track of time played

	ld a, [hDisableJoypadPolling]
	and a
	call z, ReadJoypad

	ld a, [wVBlankSavedROMBank]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	
	pop hl
	pop de
	pop bc
	pop af
	ld [hSavedAReg], a
	
	ld a, [hSavedWRAMBankVBlank]
	ld [rSVBK], a
	
	ld a, [hSavedAReg]
	reti
	
DelayFrame::
; Wait for the next vblank interrupt.
; As a bonus, this saves battery.

NOT_VBLANKED EQU 1
	ld a, [rLY]
	cp $81
	jr c, .regularDelayFrame
	cp $90
	jr nc, .regularDelayFrame
	call .delayFrame
; if we're too close to vblank, do the OAM update after
; to prevent sprite flickering
.prepareOAMData
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, Bank(PrepareOAMData)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call PrepareOAMData
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

.regularDelayFrame
	call .prepareOAMData
.delayFrame
	ld a, NOT_VBLANKED
	ld [H_VBLANKOCCURRED], a
.halt
	halt
	ld a, [H_VBLANKOCCURRED]
	and a
	jr nz, .halt
	ret

