DisplayPokemonCenterDialogue_: ; 6fe6 (1:6fe6)
	call SaveScreenTilesToBuffer1 ; save screen
	ld a,MONEY_BOX
	ld [wTextBoxID],a
	call DisplayTextBoxID ; draw money text box
	ld hl, wObtainedBadges
	ld b, $1
	call CountSetBits
	ld hl, hItemPrice
	ld de, hMoney
	xor a
	ld [hli], a
	ld [de], a
	inc de
	ld a, $4
	ld [hli], a
	ld [de], a
	inc de
	ld a, $20
	ld [hl], a
	ld [de], a
	ld a, [wNumSetBits]
	and a
	jr z, .noBadges
.multiplyBCDLoop
	push af
	push hl
	push de
	ld c, $3
	predef AddBCDPredef
	pop de
	pop hl
	pop af
	dec a
	jr nz, .multiplyBCDLoop
.noBadges
	ld hl, PokemonCenterWelcomeText
	call PrintText
	ld hl, wd72e
	bit 2, [hl]
	set 1, [hl]
	set 2, [hl]
	jr nz, .skipShallWeHealYourPokemon
	ld hl, ShallWeHealYourPokemonText
	call PrintText
.skipShallWeHealYourPokemon
	call YesNoChoicePokeCenter ; yes/no menu
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .declinedHealing ; if the player chose No
	ld a, [wPartyCount]
	and a
	ld hl, NoPokemonWithYouText
	jr z, .noPokemonInParty
	call SubtractAmountPaidFromMoney
	jr c, .notEnoughMoney
; if the player had enough money
	ld a,SFX_PURCHASE
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	call SetLastBlackoutMap
	call LoadScreenTilesFromBuffer1 ; restore screen
	ld hl, NeedYourPokemonText
	call PrintText
	ld a, $18
	ld [wSpriteStateData1 + $12], a ; make the nurse turn to face the machine
	call Delay3
	predef HealParty
	callba AnimateHealingMachine ; do the healing machine animation
	xor a
	ld [wAudioFadeOutControl], a
	ld a, [wAudioSavedROMBank]
	ld [wAudioROMBank], a
	ld a, [wMapMusicSoundID]
	ld [wLastMusicSoundID], a
	ld [wNewSoundID], a
	call PlaySound
	ld hl, PokemonFightingFitText
	call PrintText
	ld a, $14
	ld [wSpriteStateData1 + $12], a ; make the nurse bow
	ld c, a
	call DelayFrames
	jr .done
.notEnoughMoney
	ld hl, PokemonCenterNotEnoughMoneyText
.noPokemonInParty
	call PrintText
.declinedHealing
	call LoadScreenTilesFromBuffer1 ; restore screen
.done
	ld hl, PokemonCenterFarewellText
	call PrintText
	jp UpdateSprites

PokemonCenterWelcomeText: ; 705d (1:705d)
	TX_FAR _PokemonCenterWelcomeText
	db "@"

ShallWeHealYourPokemonText: ; 7062 (1:7062)
	db $a
	TX_FAR _ShallWeHealYourPokemonText
	db "@"

NoPokemonWithYouText:
	TX_FAR _NoPokemonWithYouText
	db "@"

PokemonCenterNotEnoughMoneyText:
	TX_FAR _PokemonCenterNotEnoughMoneyText
	db "@"
	
NeedYourPokemonText: ; 7068 (1:7068)
	TX_FAR _NeedYourPokemonText
	db "@"

PokemonFightingFitText: ; 706d (1:706d)
	TX_FAR _PokemonFightingFitText
	db "@"

PokemonCenterFarewellText: ; 7072 (1:7072)
	TX_FAR _PokemonCenterFarewellText
	db "@"
