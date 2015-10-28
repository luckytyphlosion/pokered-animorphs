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
	jr nz, .ok
	ld a, [hWY]
	ld [rWY], a
.ok

	call AutoBgMapTransfer
	call WriteCGBPalettes
	call RedrawRowOrColumn
	call VBlankCopyCommon
	call UpdateMovingBgTiles
	call $ff80 ; hOAMDMA

	; VBlank-sensitive operations end.

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
	push bc
	push de
	push hl
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, Bank(PrepareOAMData)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call PrepareOAMData
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	pop hl
	pop de
	pop bc
	ld a, NOT_VBLANKED
	ld [H_VBLANKOCCURRED], a
.halt
	halt
	ld a, [H_VBLANKOCCURRED]
	and a
	jr nz, .halt
	ret
