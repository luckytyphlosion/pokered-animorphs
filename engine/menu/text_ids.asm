; function that performs initialization for DisplayTextID
DisplayTextIDInit: ; 7096 (1:7096)
	xor a
	ld [wListMenuID],a
	ld a,[wAutoTextBoxDrawingControl]
	bit 0,a
	jr nz,.skipDrawingTextBoxBorder
	ld a,[hSpriteIndexOrTextID] ; text ID (or sprite ID)
	and a
	jr nz,.notStartMenu
; if text ID is 0 (i.e. the start menu)
; Note that the start menu text border is also drawn in the function directly
; below this, so this seems unnecessary.
	CheckEvent EVENT_GOT_POKEDEX
; start menu with pokedex
	coord hl, 10, 0
	ld b,$0e
	ld c,$08
	jr nz,.drawTextBoxBorder
; start menu without pokedex
	coord hl, 10, 0
	ld b,$0c
	ld c,$08
	jr .drawTextBoxBorder
; if text ID is not 0 (i.e. not the start menu) then do a standard dialogue text box
.notStartMenu
	coord hl, 0, 12
	ld b,$04
	ld c,$12
.drawTextBoxBorder
	call TextBoxBorder
.skipDrawingTextBoxBorder
	ld hl,wFontLoaded
	set 0,[hl]
	ld hl,wFlags_0xcd60
	bit 4,[hl]
	res 4,[hl]
	jr nz,.skipMovingSprites
	call UpdateSprites
.skipMovingSprites
; loop to copy C1X9 (direction the sprite is facing) to C2X9 for each sprite
; this is done because when you talk to an NPC, they turn to look your way
; the original direction they were facing must be restored after the dialogue is over
	ld hl,wSpriteStateData1 + $19
	ld c,$0f
	ld de,$0010
.spriteFacingDirectionCopyLoop
	ld a,[hl]
	inc h
	ld [hl],a
	dec h
	add hl,de
	dec c
	jr nz,.spriteFacingDirectionCopyLoop
; loop to force all the sprites in the middle of animation to stand still
; (so that they don't like they're frozen mid-step during the dialogue)
	ld hl,wSpriteStateData1 + 2
	ld de,$0010
	ld c,e
.spriteStandStillLoop
	ld a,[hl]
	cp a,$ff ; is the sprite visible?
	jr z,.nextSprite
; if it is visible
	and a,$fc
	ld [hl],a
.nextSprite
	add hl,de
	dec c
	jr nz,.spriteStandStillLoop
	ld b,$9c ; window background address
	call CopyScreenTileBufferToVRAM ; transfer background in WRAM to VRAM
	xor a
	ld [hWY],a ; put the window on the screen
	call LoadFontTilePatterns
	ld a,$01
	ld [H_AUTOBGTRANSFERENABLED],a ; enable continuous WRAM to VRAM transfer each V-blank
	ret

; function that displays the start menu
DrawStartMenu: ; 710b (1:710b)
	CheckEvent EVENT_GOT_POKEDEX
; menu with pokedex
	coord hl, 10, 0
	ld b,$0e
	ld c,$08
	jr nz,.drawTextBoxBorder
; shorter menu if the player doesn't have the pokedex
	coord hl, 10, 0
	ld b,$0c
	ld c,$08
.drawTextBoxBorder
	call TextBoxBorder
	ld a,D_DOWN | D_UP | START | B_BUTTON | A_BUTTON
	ld [wMenuWatchedKeys],a
	ld a,$02
	ld [wTopMenuItemY],a ; Y position of first menu choice
	ld a,$0b
	ld [wTopMenuItemX],a ; X position of first menu choice
	ld a,[wBattleAndStartSavedMenuItem] ; remembered menu selection from last time
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	xor a
	ld [wMenuWatchMovingOutOfBounds],a
	ld hl,wd730
	set 6,[hl] ; no pauses between printing each letter
	coord hl, 12, 2
	CheckEvent EVENT_GOT_POKEDEX
; case for not having pokdex
	ld a,$06
	jr z,.storeMenuItemCount
; case for having pokedex
	ld de,StartMenuPokedexText
	call PrintStartMenuItem
	ld a,$07
.storeMenuItemCount
	ld [wMaxMenuItem],a ; number of menu items
	ld de,StartMenuPokemonText
	call PrintStartMenuItem
	ld de,StartMenuItemText
	call PrintStartMenuItem
	ld de,wPlayerName ; player's name
	call PrintStartMenuItem
	ld a,[wd72e]
	bit 6,a ; is the player using the link feature?
; case for not using link feature
	ld de,StartMenuSaveText
	jr z,.printSaveOrResetText
; case for using link feature
	ld de,StartMenuResetText
.printSaveOrResetText
	call PrintStartMenuItem
	ld de,StartMenuOptionText
	call PrintStartMenuItem
	ld de,StartMenuExitText
	call PlaceString
	ld hl,wd730
	res 6,[hl] ; turn pauses between printing letters back on
	ret

StartMenuPokedexText: ; 718f (1:718f)
	db "POKéDEX@"

StartMenuPokemonText: ; 7197 (1:7197)
	db "POKéMON@"

StartMenuItemText: ; 719f (1:719f)
	db "ITEM@"

StartMenuSaveText: ; 71a4 (1:71a4)
	db "SAVE@"

StartMenuResetText: ; 71a9 (1:71a9)
	db "RESET@"

StartMenuExitText: ; 71af (1:71af)
	db "EXIT@"

StartMenuOptionText: ; 71b4 (1:71b4)
	db "OPTION@"

PrintStartMenuItem: ; 71bb (1:71bb)
	push hl
	call PlaceString
	pop hl
	ld de,SCREEN_WIDTH * 2
	add hl,de
	ret

INCLUDE "engine/overworld/cable_club_npc.asm"

; function to draw various text boxes
DisplayTextBoxID_: ; 72ea (1:72ea)
	ld a,[wTextBoxID]
	cp a,TWO_OPTION_MENU
	jp z,DisplayTwoOptionMenu
	ld c,a
	ld hl,TextBoxFunctionTable
	ld de,3
	call SearchTextBoxTable
	jr c,.functionTableMatch
	ld hl,TextBoxCoordTable
	ld de,5
	call SearchTextBoxTable
	jr c,.coordTableMatch
	ld hl,TextBoxTextAndCoordTable
	ld de,9
	call SearchTextBoxTable
	jr c,.textAndCoordTableMatch
.done
	ret
.functionTableMatch
	ld a,[hli]
	ld h,[hl]
	ld l,a ; hl = address of function
	ld de,.done
	push de
	jp [hl] ; jump to the function
.coordTableMatch
	call GetTextBoxIDCoords
	call GetAddressOfScreenCoords
	call TextBoxBorder
	ret
.textAndCoordTableMatch
	call GetTextBoxIDCoords
	push hl
	call GetAddressOfScreenCoords
	call TextBoxBorder
	pop hl
	call GetTextBoxIDText
	ld a,[wd730]
	push af
	ld a,[wd730]
	set 6,a ; no pauses between printing each letter
	ld [wd730],a
	call PlaceString
	pop af
	ld [wd730],a
	call UpdateSprites
	ret

; function to search a table terminated with $ff for a byte matching c in increments of de
; sets carry flag if a match is found and clears carry flag if not
SearchTextBoxTable: ; 734c (1:734c)
	dec de
.loop
	ld a,[hli]
	cp a,$ff
	jr z,.notFound
	cp c
	jr z,.found
	add hl,de
	jr .loop
.found
	scf
.notFound
	ret

; function to load coordinates from the TextBoxCoordTable or the TextBoxTextAndCoordTable
; INPUT:
; hl = address of coordinates
; OUTPUT:
; b = height
; c = width
; d = row of upper left corner
; e = column of upper left corner
GetTextBoxIDCoords: ; 735a (1:735a)
	ld a,[hli] ; column of upper left corner
	ld e,a
	ld a,[hli] ; row of upper left corner
	ld d,a
	ld a,[hli] ; column of lower right corner
	sub e
	dec a
	ld c,a     ; c = width
	ld a,[hli] ; row of lower right corner
	sub d
	dec a
	ld b,a     ; b = height
	ret

; function to load a text address and text coordinates from the TextBoxTextAndCoordTable
GetTextBoxIDText: ; 7367 (1:7367)
	ld a,[hli]
	ld e,a
	ld a,[hli]
	ld d,a ; de = address of text
	push de ; save text address
	ld a,[hli]
	ld e,a ; column of upper left corner of text
	ld a,[hl]
	ld d,a ; row of upper left corner of text
	call GetAddressOfScreenCoords
	pop de ; restore text address
	ret

; function to point hl to the screen coordinates
; INPUT:
; d = row
; e = column
; OUTPUT:
; hl = address of upper left corner of text box
GetAddressOfScreenCoords: ; 7375 (1:7375)
	push bc
	coord hl, 0, 0
	ld bc,20
.loop ; loop to add d rows to the base address
	ld a,d
	and a
	jr z,.addedRows
	add hl,bc
	dec d
	jr .loop
.addedRows
	pop bc
	add hl,de
	ret

; Format:
; 00: text box ID
; 01-02: function address
TextBoxFunctionTable: ; 7387 (1:7387)
	dbw MONEY_BOX, DisplayMoneyBox
	dbw BUY_SELL_QUIT_MENU, DoBuySellQuitMenu
	dbw FIELD_MOVE_MON_MENU, DisplayFieldMoveMonMenu
	db $ff ; terminator

; Format:
; 00: text box ID
; 01: column of upper left corner
; 02: row of upper left corner
; 03: column of lower right corner
; 04: row of lower right corner
TextBoxCoordTable: ; 7391 (1:7391)
	db MESSAGE_BOX,       0, 12, 19, 17
	db $03,               0,  0, 19, 14
	db $07,               0,  0, 11,  6
	db LIST_MENU_BOX,     4,  2, 19, 12
	db $10,               7,  0, 19, 17
	db MON_SPRITE_POPUP,  6,  4, 14, 13
	db $ff ; terminator

; Format:
; 00: text box ID
; 01: column of upper left corner
; 02: row of upper left corner
; 03: column of lower right corner
; 04: row of lower right corner
; 05-06: address of text
; 07: column of beginning of text
; 08: row of beginning of text
; table of window positions and corresponding text [key, start column, start row, end column, end row, text pointer [2 bytes], text column, text row]
TextBoxTextAndCoordTable: ; 73b0 (1:73b0)
	db JP_MOCHIMONO_MENU_TEMPLATE
	db 0,0,14,17   ; text box coordinates
	dw JapaneseMochimonoText
	db 3,0   ; text coordinates

	db USE_TOSS_MENU_TEMPLATE
	db 13,10,19,14 ; text box coordinates
	dw UseTossText
	db 15,11 ; text coordinates

	db JP_SAVE_MESSAGE_MENU_TEMPLATE
	db 0,0,7,5     ; text box coordinates
	dw JapaneseSaveMessageText
	db 2,2   ; text coordinates

	db JP_SPEED_OPTIONS_MENU_TEMPLATE
	db 0,6,5,10    ; text box coordinates
	dw JapaneseSpeedOptionsText
	db 2,7   ; text coordinates

	db BATTLE_MENU_TEMPLATE
	db 8,12,19,17  ; text box coordinates
	dw BattleMenuText
	db 10,14 ; text coordinates

	db SAFARI_BATTLE_MENU_TEMPLATE
	db 0,12,19,17  ; text box coordinates
	dw SafariZoneBattleMenuText
	db 2,14  ; text coordinates

	db SWITCH_STATS_CANCEL_MENU_TEMPLATE
	db 11,11,19,17 ; text box coordinates
	dw SwitchStatsCancelText
	db 13,12 ; text coordinates

	db BUY_SELL_QUIT_MENU_TEMPLATE
	db 0,0,10,6    ; text box coordinates
	dw BuySellQuitText
	db 2,1   ; text coordinates

	db MONEY_BOX_TEMPLATE
	db 11,0,19,2   ; text box coordinates
	dw MoneyText
	db 13,0  ; text coordinates

	db JP_AH_MENU_TEMPLATE
	db 7,6,11,10   ; text box coordinates
	dw JapaneseAhText
	db 8,8   ; text coordinates

	db JP_POKEDEX_MENU_TEMPLATE
	db 11,8,19,17  ; text box coordinates
	dw JapanesePokedexMenu
	db 12,10 ; text coordinates

; note that there is no terminator

BuySellQuitText: ; 7413 (1:7413)
	db   "BUY"
	next "SELL"
	next "QUIT@@"

UseTossText: ; 7422 (1:7422)
	db   "USE"
	next "TOSS@"

JapaneseSaveMessageText: ; 742b (1:742b)
	db   "きろく"
	next "メッセージ@"

JapaneseSpeedOptionsText: ; 7435 (1:7435)
	db   "はやい"
	next "おそい@"

MoneyText: ; 743d (1:743d)
	db "MONEY@"

JapaneseMochimonoText: ; 7443 (1:7443)
	db "もちもの@"

JapaneseMainMenuText: ; 7448 (1:7448)
	db   "つづきから"
	next "さいしょから@"

BattleMenuText: ; 7455 (1:7455)
	db   "FIGHT ",$E1,$E2
	next "ITEM  RUN@"

SafariZoneBattleMenuText: ; 7468 (1:7468)
	db   "BOMB×       BAIT"
	next "THROW ROCK  RUN@"

SwitchStatsCancelText: ; 7489 (1:7489)
	db   "SWITCH"
	next "STATS"
	next "CANCEL@"

JapaneseAhText: ; 749d (1:749d)
	db "アッ!@"

JapanesePokedexMenu: ; 74a1 (1:74a1)
	db   "データをみる"
	next "なきごえ"
	next "ぶんぷをみる"
	next "キャンセル@"

DisplayMoneyBox: ; 74ba (1:74ba)
	ld hl, wd730
	set 6, [hl]
	ld a, MONEY_BOX_TEMPLATE
	ld [wTextBoxID], a
	call DisplayTextBoxID
	coord hl, 13, 1
	ld b, 1
	ld c, 6
	call ClearScreenArea
	coord hl, 12, 1
	ld de, wPlayerMoney
	ld c, $a3
	call PrintBCDNumber
	ld hl, wd730
	res 6, [hl]
	ret

CurrencyString: ; 74e2 (1:74e2)
	db "      ¥@"

DoBuySellQuitMenu: ; 74ea (1:74ea)
	ld a, [wd730]
	set 6, a ; no printing delay
	ld [wd730], a
	xor a
	ld [wChosenMenuItem], a
	ld a, BUY_SELL_QUIT_MENU_TEMPLATE
	ld [wTextBoxID], a
	call DisplayTextBoxID
	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a
	ld a, $2
	ld [wMaxMenuItem], a
	ld a, $1
	ld [wTopMenuItemY], a
	ld a, $1
	ld [wTopMenuItemX], a
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld [wMenuWatchMovingOutOfBounds], a
	ld a, [wd730]
	res 6, a ; turn on the printing delay
	ld [wd730], a
	call HandleMenuInput
	call PlaceUnfilledArrowMenuCursor
	bit 0, a ; was A pressed?
	jr nz, .pressedA
	bit 1, a ; was B pressed? (always true since only A/B are watched)
	jr z, .pressedA
	ld a, CANCELLED_MENU
	ld [wMenuExitMethod], a
	jr .quit
.pressedA
	ld a, CHOSE_MENU_ITEM
	ld [wMenuExitMethod], a
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	ld b, a
	ld a, [wMaxMenuItem]
	cp b
	jr z, .quit
	ret
.quit
	ld a, CANCELLED_MENU
	ld [wMenuExitMethod], a
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	scf
	ret

; displays a menu with two options to choose from
; b = Y of upper left corner of text region
; c = X of upper left corner of text region
; hl = address where the text box border should be drawn
DisplayTwoOptionMenu: ; 7559 (1:7559)
	push hl
	ld a, [wd730]
	set 6, a ; no printing delay
	ld [wd730], a

; pointless because both values are overwritten before they are read
	xor a
	ld [wChosenMenuItem], a
	ld [wMenuExitMethod], a

	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a
	ld a, $1
	ld [wMaxMenuItem], a
	ld a, b
	ld [wTopMenuItemY], a
	ld a, c
	ld [wTopMenuItemX], a
	xor a
	ld [wLastMenuItem], a
	ld [wMenuWatchMovingOutOfBounds], a
	push hl
	ld hl, wTwoOptionMenuID
	bit 7, [hl] ; select second menu item by default?
	res 7, [hl]
	jr z, .storeCurrentMenuItem
	inc a
.storeCurrentMenuItem
	ld [wCurrentMenuItem], a
	pop hl
	push hl
	push hl
	call TwoOptionMenu_SaveScreenTiles
	ld a, [wTwoOptionMenuID]
	ld hl, TwoOptionMenuStrings
	ld e, a
	ld d, $0
	ld a, $5
.menuStringLoop
	add hl, de
	dec a
	jr nz, .menuStringLoop
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld e, l
	ld d, h
	pop hl
	push de
	ld a, [wTwoOptionMenuID]
	cp TRADE_CANCEL_MENU
	jr nz, .notTradeCancelMenu
	call CableClub_TextBoxBorder
	jr .afterTextBoxBorder
.notTradeCancelMenu
	call TextBoxBorder
.afterTextBoxBorder
	call UpdateSprites
	pop hl
	ld a, [hli]
	and a ; put blank line before first menu item?
	ld bc, 20 + 2
	jr z, .noBlankLine
	ld bc, 2 * 20 + 2
.noBlankLine
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	pop hl
	add hl, bc
	call PlaceString
	ld hl, wd730
	res 6, [hl] ; turn on the printing delay
	ld a, [wTwoOptionMenuID]
	cp NO_YES_MENU
	jr nz, .notNoYesMenu
; No/Yes menu
; this menu type ignores the B button
; it only seems to be used when confirming the deletion of a save file
	xor a
	ld [wTwoOptionMenuID], a
	ld a, [wFlags_0xcd60]
	push af
	push hl
	ld hl, wFlags_0xcd60
	bit 5, [hl]
	set 5, [hl] ; don't play sound when A or B is pressed in menu
	pop hl
.noYesMenuInputLoop
	call HandleMenuInput
	bit 1, a ; A button pressed?
	jr nz, .noYesMenuInputLoop ; try again if A was not pressed
	pop af
	pop hl
	ld [wFlags_0xcd60], a
	ld a, SFX_PRESS_AB
	call PlaySound
	jr .pressedAButton
.notNoYesMenu
	xor a
	ld [wTwoOptionMenuID], a
	call HandleMenuInput
	pop hl
	bit 1, a ; A button pressed?
	jr nz, .choseSecondMenuItem ; automatically choose the second option if B is pressed
.pressedAButton
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	and a
	jr nz, .choseSecondMenuItem
; chose first menu item
	ld a, CHOSE_FIRST_ITEM
	ld [wMenuExitMethod], a
	ld c, 15
	call DelayFrames
	call TwoOptionMenu_RestoreScreenTiles
	and a
	ret
.choseSecondMenuItem
	ld a, 1
	ld [wCurrentMenuItem], a
	ld [wChosenMenuItem], a
	ld a, CHOSE_SECOND_ITEM
	ld [wMenuExitMethod], a
	ld c, 15
	call DelayFrames
	call TwoOptionMenu_RestoreScreenTiles
	scf
	ret

; Some of the wider/taller two option menus will not have the screen areas
; they cover be fully saved/restored by the two functions below.
; The bottom and right edges of the menu may remain after the function returns.

TwoOptionMenu_SaveScreenTiles: ; 763e (1:763e)
	ld de, wBuffer
	lb bc, 5, 6
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	push bc
	ld bc, SCREEN_WIDTH - 6
	add hl, bc
	pop bc
	ld c, $6
	dec b
	jr nz, .loop
	ret

TwoOptionMenu_RestoreScreenTiles: ; 7656 (1:7656)
	ld de, wBuffer
	lb bc, 5, 6
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .loop
	push bc
	ld bc, SCREEN_WIDTH - 6
	add hl, bc
	pop bc
	ld c, 6
	dec b
	jr nz, .loop
	call UpdateSprites
	ret

; Format:
; 00: byte width
; 01: byte height
; 02: byte put blank line before first menu item
; 03: word text pointer
TwoOptionMenuStrings: ; 7671 (1:7671)
	db 4,3,0
	dw .YesNoMenu
	db 6,3,0
	dw .NorthWestMenu
	db 6,3,0
	dw .SouthEastMenu
	db 6,3,0
	dw .YesNoMenu
	db 6,3,0
	dw .NorthEastMenu
	db 7,3,0
	dw .TradeCancelMenu
	db 7,4,1
	dw .HealCancelMenu
	db 4,3,0
	dw .NoYesMenu

.NoYesMenu ; 7699 (1:3699)
	db "NO",$4E,"YES@"
.YesNoMenu ; 76a0 (1:36a0)
	db "YES",$4E,"NO@"
.NorthWestMenu ; 76a7 (1:36a7)
	db "NORTH",$4E,"WEST@"
.SouthEastMenu ; 76b2 (1:36b2)
	db "SOUTH",$4E,"EAST@"
.NorthEastMenu ; 76bd (1:36bd)
	db "NORTH",$4E,"EAST@"
.TradeCancelMenu ; 76c8 (1:36c8)
	db "TRADE",$4E,"CANCEL@"
.HealCancelMenu ; 76d5 (1:36d5)
	db "HEAL",$4E,"CANCEL@"

DisplayFieldMoveMonMenu: ; 76e1 (1:76e1)
	xor a
	ld hl, wFieldMoves
	ld [hli], a ; wFieldMoves
	ld [hli], a ; wFieldMoves + 1
	ld [hli], a ; wFieldMoves + 2
	ld [hli], a ; wFieldMoves + 3
	ld [hli], a ; wNumFieldMoves
	ld [hl], 12 ; wFieldMovesLeftmostXCoord
	call GetMonFieldMoves
	ld a, [wNumFieldMoves]
	and a
	jr nz, .fieldMovesExist

; no field moves
	coord hl, 11, 11
	ld b, 5
	ld c, 7
	call TextBoxBorder
	call UpdateSprites
	ld a, 12
	ld [hFieldMoveMonMenuTopMenuItemX], a
	coord hl, 13, 12
	ld de, PokemonMenuEntries
	jp PlaceString

.fieldMovesExist
	push af

; Calculate the text box position and dimensions based on the leftmost X coord
; of the field move names before adjusting for the number of field moves.
	coord hl, 0, 11
	ld a, [wFieldMovesLeftmostXCoord]
	dec a
	ld e, a
	ld d, 0
	add hl, de
	ld b, 5
	ld a, 18
	sub e
	ld c, a
	pop af

; For each field move, move the top of the text box up 2 rows while the leaving
; the bottom of the text box at the bottom of the screen.
	ld de, -SCREEN_WIDTH * 2
.textBoxHeightLoop
	add hl, de
	inc b
	inc b
	dec a
	jr nz, .textBoxHeightLoop

; Make space for an extra blank row above the top field move.
	ld de, -SCREEN_WIDTH
	add hl, de
	inc b

	call TextBoxBorder
	call UpdateSprites

; Calculate the position of the first field move name to print.
	coord hl, 0, 12
	ld a, [wFieldMovesLeftmostXCoord]
	inc a
	ld e, a
	ld d, 0
	add hl, de
	ld de, -SCREEN_WIDTH * 2
	ld a, [wNumFieldMoves]
.calcFirstFieldMoveYLoop
	add hl, de
	dec a
	jr nz, .calcFirstFieldMoveYLoop

	xor a
	ld [wNumFieldMoves], a
	ld de, wFieldMoves
.printNamesLoop
	push hl
	ld hl, FieldMoveNames
	ld a, [de]
	and a
	jr z, .donePrintingNames
	inc de
	ld b, a ; index of name
.skipNamesLoop ; skip past names before the name we want
	dec b
	jr z, .reachedName
.skipNameLoop ; skip past current name
	ld a, [hli]
	cp "@"
	jr nz, .skipNameLoop
	jr .skipNamesLoop
.reachedName
	ld b, h
	ld c, l
	pop hl
	push de
	ld d, b
	ld e, c
	call PlaceString
	ld bc, SCREEN_WIDTH * 2
	add hl, bc
	pop de
	jr .printNamesLoop

.donePrintingNames
	pop hl
	ld a, [wFieldMovesLeftmostXCoord]
	ld [hFieldMoveMonMenuTopMenuItemX], a
	coord hl, 0, 12
	ld a, [wFieldMovesLeftmostXCoord]
	inc a
	ld e, a
	ld d, 0
	add hl, de
	ld de, PokemonMenuEntries
	jp PlaceString

FieldMoveNames: ; 778d (1:778d)
	db "CUT@"
	db "FLY@"
	db "@"
	db "SURF@"
	db "STRENGTH@"
	db "FLASH@"
	db "DIG@"
	db "TELEPORT@"
	db "SOFTBOILED@"

PokemonMenuEntries: ; 77c2 (1:77c2)
	db   "STATS"
	next "SWITCH"
	next "CANCEL@"

GetMonFieldMoves: ; 77d6 (1:77d6)
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld d, h
	ld e, l
	ld c, NUM_MOVES + 1
	ld hl, wFieldMoves
.loop
	push hl
.nextMove
	dec c
	jr z, .done
	ld a, [de] ; move ID
	and a
	jr z, .done
	ld b, a
	inc de
	ld hl, FieldMoveDisplayData
.fieldMoveLoop
	ld a, [hli]
	cp $ff
	jr z, .nextMove ; if the move is not a field move
	cp b
	jr z, .foundFieldMove
	inc hl
	inc hl
	jr .fieldMoveLoop
.foundFieldMove
	ld a, b
	ld [wLastFieldMoveID], a
	ld a, [hli] ; field move name index
	ld b, [hl] ; field move leftmost X coordinate
	pop hl
	ld [hli], a ; store name index in wFieldMoves
	ld a, [wNumFieldMoves]
	inc a
	ld [wNumFieldMoves], a
	ld a, [wFieldMovesLeftmostXCoord]
	cp b
	jr c, .skipUpdatingLeftmostXCoord
	ld a, b
	ld [wFieldMovesLeftmostXCoord], a
.skipUpdatingLeftmostXCoord
	ld a, [wLastFieldMoveID]
	ld b, a
	jr .loop
.done
	pop hl
	ret

; Format: [Move id], [name index], [leftmost tile]
; Move id = id of move
; Name index = index of name in FieldMoveNames
; Leftmost tile = -1 + tile column in which the first letter of the move's name should be displayed
;                 "SOFTBOILED" is $08 because it has 4 more letters than "SURF", for example, whose value is $0C
FieldMoveDisplayData: ; 7823 (1:7823)
	db CUT, $01, $0C
	db FLY, $02, $0C
	db $B4, $03, $0C ; unused field move
	db SURF, $04, $0C
	db STRENGTH, $05, $0A
	db FLASH, $06, $0C
	db DIG, $07, $0C
	db TELEPORT, $08, $0A
	db SOFTBOILED, $09, $08
	db $ff ; list terminator