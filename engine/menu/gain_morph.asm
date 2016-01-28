DisplayGainMorphMenu:
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	call UpdateSprites
	callba LoadMonPartySpriteGfxWithLCDDisabled ; load pokemon icon graphics

	callab ErasePartyMenuCursors
	callab HealEnemyParty
	
	ld hl, wEnemyMonNicks
	ld de, wEnemyPartyMons
	push de
.writeNicknameLoop
	ld a, [de]
	cp $ff
	jr z, .writeNicknameLoopDone
	inc de
	ld [wd11e], a
	push de
	call GetMonName
	ld de, wcd6d
	ld c, NAME_LENGTH
.copyIndivNickLoop
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .copyIndivNickLoop
	pop de
	jr .writeNicknameLoop
.writeNicknameLoopDone
	pop de
	coord hl, 3, 0
	xor a
	ld c,a
	ld [hPartyMonIndex],a
	ld [wWhichPartyMenuHPBar],a
	inc a
	ld [wMonDataLocation], a
.loop
	ld a,[de]
	cp a,$FF ; reached the terminator?
	jp z,.printMessage
	push bc
	push de
	push hl
	ld a,c
	push hl
	ld hl,wEnemyMonNicks
	call GetPartyMonName
	pop hl
	call PlaceString ; print the pokemon's name
	callba WriteMonPartySpriteOAMByPartyIndex ; place the appropriate pokemon icon
	ld a,[hPartyMonIndex]
	ld [wWhichPokemon],a
	inc a
	ld [hPartyMonIndex],a
	call LoadMonData
	pop hl
	push hl
	ld a,[wMenuItemToSwap]
	and a ; is the player swapping pokemon positions?
	jr z,.skipUnfilledRightArrow
; if the player is swapping pokemon positions
	dec a
	ld b,a
	ld a,[wWhichPokemon]
	cp b ; is the player swapping the current pokemon in the list?
	jr nz,.skipUnfilledRightArrow
; the player is swapping the current pokemon in the list
	dec hl
	dec hl
	dec hl
	ld a,$EC ; unfilled right arrow menu cursor
	ld [hli],a ; place the cursor
	inc hl
	inc hl
.skipUnfilledRightArrow
	push hl
	ld bc,14 ; 14 columns to the right
	add hl,bc
	pop hl
	
	push hl
	ld bc,20 + 1 ; down 1 row and right 1 column
	ld a,[hFlags_0xFFF6]
	set 0,a
	ld [hFlags_0xFFF6],a
	add hl,bc
	predef DrawHP2 ; draw HP bar and prints current / max HP
	ld a,[hFlags_0xFFF6]
	res 0,a
	ld [hFlags_0xFFF6],a
	pop hl
	
	ld bc,10 ; move 10 columns to the right
	add hl,bc
	call PrintLevel
	pop hl
	pop de
	inc de
	ld bc,2 * 20
	add hl,bc
	pop bc
	inc c
	jp .loop
.printMessage
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	ld hl, wd730
	set 6, [hl] ; turn off letter printing delay
	push hl
	call .handleMorphMenu
	pop hl
	res 6, [hl]
	ret

.handleMorphMenu
	ld hl, ChooseMorphText
	call PrintText
	xor a
	ld [wMenuWatchMovingOutOfBounds], a
	ld hl, wTopMenuItemY
	inc a
	ld [hli], a ; top menu item Y
	xor a
	ld [hli], a ; top menu item X
	ld [hli], a ; current menu item ID
	inc hl
	ld a, [wEnemyPartyCount]
	and a ; are there more than 0 pokemon in the party?
	jr z, .storeMaxMenuItemID
	dec a
; if party is not empty, the max menu item ID is ([wPartyCount] - 1)
; otherwise, it is 0
.storeMaxMenuItemID
	ld [hli], a
	ld [hl], A_BUTTON
	ld a,1
	ld [wMenuWrappingEnabled],a
	ld [wForcePlayerToChooseMon], a
	ld a,$40
	ld [wPartyMenuAnimMonEnabled],a
	call HandleMenuInput_
	xor a
	ld [wPartyMenuAnimMonEnabled], a
	ld a, [wCurrentMenuItem]
	ld [wWhichPokemon], a
	
	ld hl, wEnemyMon1
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	ld a, [hl]
	ld [wcf91], a

	ld bc, wEnemyMon1Level - wEnemyMon1
	add hl, bc
	ld a, [hl]
	ld [wCurEnemyLVL], a
	call LoadEnemyMonFromParty
	ld a, [wPartyCount]
	cp PARTY_LENGTH
	jr c, .addToParty
	ld a, [wNumInBox]
	cp MONS_PER_BOX
	jr nc, .boxFull
; box not full
	jpab _GivePokemon_Common
.addToParty
	xor a
	ld [wMonDataLocation], a
	call AddPartyMon
	ld hl, GotMorphText
	call PrintText
	scf
	ret
.boxFull
	jpab _GivePokemon_BoxFull

GotMorphText:
	TX_FAR _GotMorphText
	db "@"

ChooseMorphText:
	TX_FAR _ChooseMorphText
	db "@"