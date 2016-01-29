RedsHouse1FScript: ; 48168 (12:4168)
	jp EnableAutoTextBoxDrawing

RedsHouse1FTextPointers: ; 4816b (12:416b)
	dw RedsHouse1FText1
	dw RedsHouse1FText2

RedsHouse1FText1: ; 4816f (12:416f) Mom
	TX_ASM
	ld a, [wd72e]
	bit 3, a
	ld hl, MomDontPushYourselfText
	jr nz, .printAltText ; if player has received a Pokémon from Oak, heal team
	ld hl, MomWakeUpText
.printAltText
	call PrintText
	jp TextScriptEnd

MomDontPushYourselfText:
	TX_FAR _MomDontPushYourselfText
	db "@"

MomWakeUpText: ; 48185 (12:4185)
	TX_FAR _MomWakeUpText
	db "@"

MomHealPokemon: ; 4818a (12:418a)
	ld hl, MomDontPushYourselfText
	call PrintText
	call GBFadeOutToWhite
	call ReloadMapData
	predef HealParty
	ld a, MUSIC_PKMN_HEALED
	ld [wNewSoundID], a
	call PlaySound
.next
	ld a, [wChannelSoundIDs]
	cp MUSIC_PKMN_HEALED
	jr z, .next
	ld a, [wMapMusicSoundID]
	ld [wNewSoundID], a
	call PlaySound
	call GBFadeInFromWhite
	ld hl, MomDontPushYourselfText
	jp PrintText

SECTION "fixed addresses redshouse1f", ROMX[$41c6], BANK[$12]
RedsHouse1FText2: ; 0x481c6 TV
	TX_ASM
	ld a,[wSpriteStateData1 + 9]
	cp SPRITE_FACING_UP
	ld hl,TVWrongSideText
	jr nz,.notUp
	ld hl,StandByMeText
.notUp
	call PrintText
	jp TextScriptEnd

StandByMeText: ; 481da (12:41da)
	TX_FAR _StandByMeText
	db "@"

TVWrongSideText: ; 481df (12:41df)
	TX_FAR _TVWrongSideText
	db "@"
