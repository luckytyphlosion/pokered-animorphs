SoftReset::
	call StopAllSounds
	call GBPalWhiteOut
	ld a, [wOptions3]
	bit 6, a
	jr z, .noConsideringSaveScumMode
	callab CheckForPlayerNameInSRAM
	jr nc, .noConsideringSaveScumMode
	ld a, $1
	call EnableSRAMAndSwitchSRAMBank
	ld a, [sMainData + (wOptions3 - wMainDataStart)]
	bit 6, a ; is save scum mode set in player save as well?
	ld c, 1
	call DisableSRAMAndSwitchSRAMBank0 ; flags preserved
	jr nz, .saveScumMode	
.noConsideringSaveScumMode
	ld c, 32
.saveScumMode
	call DelayFrames
	; fallthrough

Init::
;  Program init.

rLCDC_DEFAULT EQU %11100011
; * LCD enabled
; * Window tile map at $9C00
; * Window display enabled
; * BG and window tile data at $8800
; * BG tile map at $9800
; * 8x8 OBJ size
; * OBJ display enabled
; * BG display enabled

	di

	xor a
	ld [rIF], a
	ld [rIE], a
	ld [rSCX], a
	ld [rSCY], a
	ld [rSB], a
	ld [rSC], a
	ld [rWX], a
	ld [rWY], a
	ld [rTMA], a
	ld [rTAC], a
	ld [rBGP], a
	ld [rOBP0], a
	ld [rOBP1], a

	ld a, rLCDC_ENABLE_MASK
	ld [rLCDC], a
	call DisableLCD
	
	lb bc, $3f, rBGPI & $ff
	ld a, %10000000
	ld [$ff00+c], a
	inc c
	ld a, $ff
.bgpClearLoop
	ld [$ff00+c], a
	dec b
	jr nz, .bgpClearLoop
	lb bc, $3f, rOBPI & $ff
	ld a, %10000000
	ld [$ff00+c], a
	inc c
	ld a, $ff
.obpClearLoop
	ld [$ff00+c], a
	dec b
	jr nz, .obpClearLoop
	ld a, [rKEY1]
	bit 7, a
	jr nz, .skipSpeedSwitch
	ld a, 1
	ld [rKEY1], a
	dec a
	ld [rJOYP], a
	stop
	ld a, $30
	ld [rJOYP], a
.skipSpeedSwitch
	ld sp, wStack
	ld hl, $c000 ; start of WRAM
	ld bc, $2000 ; size of WRAM
	xor a
.clearwram1
	ld [hli], a
	dec c
	jr nz, .clearwram1
	dec b
	jr nz, .clearwram1
	
	ld hl, $d000
	ld bc, $1000
	lb de, $d0, $10
	
	ld a, 2
	ld [rSVBK], a
	xor a
.clearwram2
	ld [hli], a
	dec c
	jr nz, .clearwram2
	dec b
	jr nz, .clearwram2
	
	ld h, d
	ld b, e
	
	ld a, 3
	ld [rSVBK], a
	xor a
.clearwram3
	ld [hli], a
	dec c
	jr nz, .clearwram3
	dec b
	jr nz, .clearwram3
	
	ld [rSVBK], a
	
	call ClearVram
	ld a, 1
	ld [rVBK], a
	call ClearVram
	xor a
	ld [rVBK], a

	ld hl, $ff80
	ld bc, $ffff - $ff80
	call FillMemory

	call ClearSprites

	ld a, Bank(WriteDMACodeToHRAM)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call WriteDMACodeToHRAM

	ld a, %1000000
	ld [rSTAT], a
	xor a
	ld [hTilesetType], a
	ld [hSCX], a
	ld [hSCY], a
	ld [rIF], a
	ld a, 1 << LCD_STAT + 1 << VBLANK + 1 << TIMER + 1 << SERIAL
	ld [rIE], a
	
	ld a, $81
	ld [rLYC], a
	ld a, 144 ; move the window off-screen
	ld [hWY], a
	ld [rWY], a
	ld a, 7
	ld [rWX], a

	ld a, CONNECTION_NOT_ESTABLISHED
	ld [hSerialConnectionStatus], a

	ld h, vBGMap0 / $100
	call ClearBgMap
	ld h, vBGMap1 / $100
	call ClearBgMap
	
	ld e, $0
	callab CopyOffscreenTilesToWRAMBuffer
	ld a, rLCDC_DEFAULT
	ld [rLCDC], a
	ld a, 16
	ld [hSoftReset], a
	call StopAllSounds

	ei
	
	ld a, BANK(SFX_Shooting_Star)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, $9c
	ld [H_AUTOBGTRANSFERDEST + 1], a
	xor a
	ld [H_AUTOBGTRANSFERDEST], a
	dec a
	ld [wUpdateSpritesEnabled], a
	
	call AfterInitSRAMChecks
	
	jr c, .skipIntroAndMainMenu
	
	;predef LoadSGB
	
	predef PlayIntro

	call DisableLCD
	call ClearVram
	call GBPalNormal
	call ClearSprites
	ld a, rLCDC_DEFAULT
	ld [rLCDC], a

	jp SetDefaultNamesBeforeTitlescreen
.skipIntroAndMainMenu
	jp MainMenu
	
ClearVram:
	ld hl, $8000
	ld bc, $2000
	xor a
	jp FillMemory

StopAllSounds::
	ld a, BANK(Audio1_UpdateMusic)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	xor a
	ld [wAudioFadeOutControl], a
	ld [wNewSoundID], a
	ld [wLastMusicSoundID], a
	dec a
	jp PlaySound

AfterInitSRAMChecks:
	call CheckForPlayerNameInSRAM
	ret nc
	ld hl, wd732
	set 0, [hl]
	ld a, $1
	call EnableSRAMAndSwitchSRAMBank
	and a ; clear carry
	ld a, [sMainData + (wOptions3 - wMainDataStart)]
	bit 6, a
	call DisableSRAMAndSwitchSRAMBank0
	ret z
	ld a, $1
	ld [wIsSaveScumMode], a
	scf
	ret