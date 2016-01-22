_DisplayOptionMenu: ; 41c70 (10:5c70)
	call InitializeOptions
.optionMenuLoop
	call JoypadLowSensitivity
	ld a, [hJoy5]
	and START | B_BUTTON
	jr nz, .exitOptionMenu
	call MoveOptionsCursorLocation
	jr c, .asm_41c86
	call HandleCurrentOption
	jr c, .exitOptionMenu
.asm_41c86
	call RedrawOptionsCursor
	call DelayFrame
	jr .optionMenuLoop
.exitOptionMenu
	ret

HandleCurrentOption: ; 41c95 (10:5c95)
	ld a, [wOptionsCurPage]
	ld e, a
	ld d, $0
	ld hl, OptionMenuJumpTablePointerTable
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wOptionsCursorLocation]
	ld e, a
	ld d, $0
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

OptionMenuJumpTablePointerTable:
	dw OptionMenu1JumpTable
	dw OptionMenu2JumpTable
	dw OptionMenu3JumpTable
	
OptionMenu1JumpTable: ; 41ca4 (10:5ca4)
	dw OptionsMenu_TextSpeed
	dw OptionsMenu_MenuSpeed
	dw OptionsMenu_BattleAnimations
	dw OptionsMenu_BattleStyle
	dw OptionsMenu_ShakeMoves
	dw OptionsMenu_Metronome
	dw OptionsMenu_Page
	dw OptionsMenu_Cancel

OptionMenu2JumpTable:
	dw OptionsMenu_Palette
	dw OptionsMenu_SpinnerHell
	dw OptionsMenu_SpinSpeed
	dw OptionsMenu_SlipRun
	dw OptionsMenu_TrainerRange
	dw OptionsMenu_StartIn
	dw OptionsMenu_Page
	dw OptionsMenu_Cancel
	
OptionMenu3JumpTable:
	dw OptionsMenu_SelectTo
	dw OptionsMenu_SaveScum
	dw OptionsMenu_Dummy
	dw OptionsMenu_Dummy
	dw OptionsMenu_Dummy
	dw OptionsMenu_Dummy
	dw OptionsMenu_Page
	dw OptionsMenu_Cancel
	
OptionsMenu_TextSpeed: ; 41cb4 (10:5cb4)
INST_TEXT EQU 0
FAST_TEXT EQU 1
MID_TEXT  EQU 2
SLOW_TEXT EQU 3
	ld a, [wOptions]
	and %11
	ld c, a
	ld a, [hJoy5]
	bit 4, a ; right
	jr nz, .pressedRight
	bit 5, a
	jr nz, .pressedLeft
	jr .asm_41ce0
.pressedRight
	ld a, c
	cp SLOW_TEXT
	jr c, .noWrapAround
	ld c, INST_TEXT - 1
.noWrapAround
	inc c
	jr .continue
.pressedLeft
	ld a, c
	and a
	jr nz, .noWrapAround2
	ld c, SLOW_TEXT + 1
.noWrapAround2
	dec c
.continue
	ld b, c
	ld a, [wOptions]
	and %11111100
	or b
	ld [wOptions], a
.asm_41ce0
	ld b, $0
	ld hl, TextSpeedStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 14, 2
	call PlaceString
	and a
	ret
	
TextSpeedStringsPointerTable: ; 41cf2 (10:5cf2)
	dw InstText
	dw FastText
	dw MidText
	dw SlowText
	
InstText:
	db "INST@"
FastText: ; 41cf9 (10:5cf9)
	db "FAST@"
MidText: ; 41cfd (10:5cfd)
	db "MID @"
SlowText: ; 41d02 (10:5d02)
	db "SLOW@"
	
OptionsMenu_MenuSpeed:
FAST_MENU EQU 0
MID_MENU  EQU 1
SLOW_MENU EQU 2
REG_MENU  EQU 3

	ld a, [wOptions]
	and %1100
	rrca
	rrca
	ld c, a
	ld a, [hJoy5]
	bit 4, a ; right
	jr nz, .pressedRight
	bit 5, a
	jr nz, .pressedLeft
	jr .asm_41ce0
.pressedRight
	ld a, c
	cp REG_MENU
	jr c, .noWrapAround
	ld c, FAST_MENU - 1
.noWrapAround
	inc c
	jr .continue
.pressedLeft
	ld a, c
	and a
	jr nz, .noWrapAround2
	ld c, REG_MENU + 1
.noWrapAround2
	dec c
.continue
	ld b, c
	sla b
	sla b
	ld a, [wOptions]
	and %11110011
	or b
	ld [wOptions], a
.asm_41ce0
	ld b, $0
	ld hl, MenuSpeedStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 14, 4
	call PlaceString
	and a
	ret

MenuSpeedStringsPointerTable: ; 41cf2 (10:5cf2)
	dw FastText
	dw MidText
	dw SlowText
	dw RegMenu
	
RegMenu:
	db "REG @"

OptionsMenu_BattleAnimations: ; 41d26 (10:5d26)
	ld a, [hJoy5]
	and D_RIGHT | D_LEFT
	jr nz, .asm_41d33
	ld a, [wOptions]
	and $80 ; mask other bits
	jr .asm_41d3b
.asm_41d33
	ld a, [wOptions]
	xor $80
	ld [wOptions], a
.asm_41d3b
	ld bc, $0
	sla a
	rl c
	ld hl, AnimationOptionStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 14, 6
	call PlaceString
	and a
	ret
	
AnimationOptionStringsPointerTable: ; 41d52 (10:5d52)
	dw AnimationOnText
	dw AnimationOffText
	
AnimationOnText: ; 41d56 (10:5d56)
	db "ON @"
AnimationOffText: ; 41d5a (10:5d5a)
	db "OFF@"
	
OptionsMenu_BattleStyle: ; 41d5e (10:5d5e)
	ld a, [hJoy5]
	and D_LEFT | D_RIGHT
	jr nz, .asm_41d6b
	ld a, [wOptions]
	and %1000000 ; mask other bits
	jr .asm_41d73
.asm_41d6b
	ld a, [wOptions]
	xor %1000000
	ld [wOptions], a
.asm_41d73
	ld bc, $0
	sla a
	sla a
	rl c
	ld hl, BattleStyleOptionStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 14, 8
	call PlaceString
	and a
	ret
	
BattleStyleOptionStringsPointerTable: ; 41d8c (10:5d8c)
	dw BattleStyleShiftText
	dw BattleStyleSetText
	
BattleStyleShiftText: ; 41d90 (10:5d90)
	db "SHIFT@"
BattleStyleSetText: ; 41d96 (10:5d96)
	db "SET  @"

OptionsMenu_ShakeMoves:
	ld a, [hJoy5]
	and D_RIGHT | D_LEFT
	jr nz, .asm_41d33
	ld a, [wOptions]
	and %10000 ; mask other bits
	jr .asm_41d3b
.asm_41d33
	ld a, [wOptions]
	xor %10000
	ld [wOptions], a
.asm_41d3b
	ld b, $0
	swap a
	and $1
	ld c, a
	ld hl, ShakeMovesOptionStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 14, 10
	call PlaceString
	and a
	ret
	
ShakeMovesOptionStringsPointerTable: ; 41d52 (10:5d52)
	dw AllShakeMovesText
	dw RegularShakeMovesText

AllShakeMovesText: ; 41d56 (10:5d56)
	db "ALL@"
RegularShakeMovesText: ; 41d5a (10:5d5a)
	db "REG@"
	
OptionsMenu_Metronome:
	ld a, [hJoy5]
	and D_RIGHT | D_LEFT
	jr nz, .asm_41d33
	ld a, [wOptions]
	and %100000 ; mask other bits
	jr .asm_41d3b
.asm_41d33
	ld a, [wOptions]
	xor %100000
	ld [wOptions], a
.asm_41d3b
	ld b, $0
	swap a
	sra a
	and $1
	ld c, a
	ld hl, MetronomeOptionStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 14, 12
	call PlaceString
	and a
	ret

MetronomeOptionStringsPointerTable:
	dw AnimationOffText
	dw AnimationOnText

OptionsMenu_Palette:
REGULAR_OP_PAL EQU 0
INVERTED_OP_PAL EQU 1
CHEATER_OP_PAL EQU 2

	ld a, [wCurPalette]
	ld c, a
	ld a, [hJoy5]
	bit 4, a ; right
	jr nz, .pressedRight
	bit 5, a
	jr nz, .pressedLeft
	jr .asm_41ce0
.pressedRight
	ld a, c
	cp CHEATER_OP_PAL
	jr c, .noWrapAround
	ld c, REGULAR_OP_PAL - 1
.noWrapAround
	inc c
	jr .continue
.pressedLeft
	ld a, c
	and a
	jr nz, .noWrapAround2
	ld c, CHEATER_OP_PAL + 1
.noWrapAround2
	dec c
.continue
	ld a, c
	ld [wCurPalette], a
.asm_41ce0
	ld b, $0
	ld hl, PalStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 6, 2
	call PlaceString
	and a
	ret

PalStringsPointerTable:
	dw Op_RegularPalText
	dw Op_InvertedPalText
	dw Op_CheaterPalText

Op_RegularPalText:
	db "REGULAR @"
Op_InvertedPalText:
	db "INVERTED@"
Op_CheaterPalText:
	db "CHEATER @"
	
OptionsMenu_Page:
NUM_OPTION_PAGES EQU 3
	ld a, [wOptionsCurPage]
	ld c, a
	ld a, [hJoy5]
	bit 4, a ; right
	jr nz, .pressedRight
	bit 5, a
	jr nz, .pressedLeft
	jr .leftOrRightNotPressed
.pressedRight
	ld a, c
	cp NUM_OPTION_PAGES - 1
	jr c, .noWrapAround
	ld c, -1
.noWrapAround
	inc c
	jr .continue
.pressedLeft
	ld a, c
	and a
	jr nz, .noWrapAround2
	ld c, NUM_OPTION_PAGES
.noWrapAround2
	dec c
.continue
	ld a, c
	ld [wOptionsCurPage], a
.leftOrRightNotPressed
	ld b, $0
	ld hl, OptionsPageNumberPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 7, 14
	call PlaceString
	ld a, [hJoy5]
	and D_LEFT | D_RIGHT
	ret z
	xor a
	ld [hJoy5], a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld a, [wOptionsCursorLocation]
	push af
	call RedrawOptions
	pop af
	ld [wOptionsCursorLocation], a
	and a
	ret
	
OptionsPageNumberPointerTable:
	dw OptionsPage1
	dw OptionsPage2
	dw OptionsPage3
	
OptionsPage1:
	db "1@"
OptionsPage2:
	db "2@"
OptionsPage3:
	db "3@"

OptionsMenu_SpinnerHell:
	ld a, [hJoy5]
	and D_RIGHT | D_LEFT
	jr nz, .asm_41d33
	ld a, [wOptions2]
	and $1 ; mask other bits
	jr .asm_41d3b
.asm_41d33
	ld a, [wOptions2]
	xor $1
	ld [wOptions2], a
.asm_41d3b
	and $1
	ld c, a
	ld b, 0
	ld hl, SpinnerHellOptionsStringPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 14, 4
	call PlaceString
	callab LoadMapSpriteMovementBytes ; in bank0, but preserve return location bank
	and a
	ret
	
SpinnerHellOptionsStringPointerTable:
	dw SpinnerHellEwText
	dw SpinnerHellGLText
	
SpinnerHellEwText:
	db "EW@"
SpinnerHellGLText:
	db "GL@"

OptionsMenu_SpinSpeed:
	ld a, [wOptions2]
	swap a
	and $f
	ld c, a
	ld a, [hJoy5]
	bit 4, a ; right
	jr nz, .pressedRight
	bit 5, a
	jr nz, .pressedLeft
	jr .leftOrRightNotPressed
.pressedRight
	ld a, c
	cp 15
	jr c, .noWrapAround
	ld c, -1
.noWrapAround
	inc c
	jr .continue
.pressedLeft
	ld a, c
	and a
	jr nz, .noWrapAround2
	ld c, 15 + 1
.noWrapAround2
	dec c
.continue
	ld b, c
	swap b
	ld a, [wOptions2]
	and %1111
	or b
	ld [wOptions2], a
.leftOrRightNotPressed
	ld b, $0
	ld hl, OptionsSpinSpeedStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 14, 6
	call PlaceString
	and a
	ret

OptionsSpinSpeedStringsPointerTable:
	dw OptionsSpinSpeed1
	dw OptionsSpinSpeed2
	dw OptionsSpinSpeed3
	dw OptionsSpinSpeed4
	dw OptionsSpinSpeed5
	dw OptionsSpinSpeed6
	dw OptionsSpinSpeed7
	dw OptionsSpinSpeed8
	dw OptionsSpinSpeed9
	dw OptionsSpinSpeed10
	dw OptionsSpinSpeed11
	dw OptionsSpinSpeed12
	dw OptionsSpinSpeed13
	dw OptionsSpinSpeed14
	dw OptionsSpinSpeed15
	dw OptionsSpinSpeed16

OptionsSpinSpeed1:
	db " 1@"
OptionsSpinSpeed2:
	db " 2@"
OptionsSpinSpeed3:
	db " 3@"
OptionsSpinSpeed4:
	db " 4@"
OptionsSpinSpeed5:
	db " 5@"
OptionsSpinSpeed6:
	db " 6@"
OptionsSpinSpeed7:
	db " 7@"
OptionsSpinSpeed8:
	db " 8@"
OptionsSpinSpeed9:
	db " 9@"
OptionsSpinSpeed10:
	db "10@"
OptionsSpinSpeed11:
	db "11@"
OptionsSpinSpeed12:
	db "12@"
OptionsSpinSpeed13:
	db "13@"
OptionsSpinSpeed14:
	db "14@"
OptionsSpinSpeed15:
	db "15@"
OptionsSpinSpeed16:
	db "16@"

OptionsMenu_SlipRun:
	ld a, [hJoy5]
	and D_RIGHT | D_LEFT
	jr nz, .asm_41d33
	ld a, [wOptions2]
	and %10 ; mask other bits
	jr .asm_41d3b
.asm_41d33
	ld a, [wOptions2]
	xor %10
	ld [wOptions2], a
.asm_41d3b
	srl a
	and $1
	ld c, a
	ld b, 0
	ld hl, MetronomeOptionStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 14, 8
	call PlaceString
	and a
	ret

OptionsMenu_TrainerRange:
	ld a, [hJoy5]
	and D_RIGHT | D_LEFT
	jr nz, .asm_41d33
	ld a, [wOptions2]
	and %100 ; mask other bits
	jr .asm_41d3b
.asm_41d33
	ld a, [wOptions2]
	xor %100
	ld [wOptions2], a
.asm_41d3b
	srl a
	srl a
	and $1
	ld c, a
	ld b, 0
	ld hl, TrainerRangeOptionStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 14, 10
	call PlaceString
	and a
	ret

TrainerRangeOptionStringsPointerTable:
	dw RegularShakeMovesText
	dw TrainerRangeMaxText
	
TrainerRangeMaxText:
	db "MAX@"
	
OptionsMenu_StartIn:
	ld a, [wOptions3]
	and $f
	ld c, a
	ld a, [hJoy5]
	bit 4, a ; right
	jr nz, .pressedRight
	bit 5, a
	jr nz, .pressedLeft
	jr .leftOrRightNotPressed
.pressedRight
	ld a, c
	cp 3
	jr c, .noWrapAround
	ld c, -1
.noWrapAround
	inc c
	jr .continue
.pressedLeft
	ld a, c
	and a
	jr nz, .noWrapAround2
	ld c, 3 + 1
.noWrapAround2
	dec c
.continue
	ld b, c
	ld a, [wOptions3]
	and $f0
	or b
	ld [wOptions3], a
.leftOrRightNotPressed
	ld b, $0
	ld hl, OptionsStartInStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 10, 12
	call PlaceString
	and a
	ret

OptionsStartInStringsPointerTable:
	dw StartInNormalText
	dw StartInEeveeHouseText
	dw StartInSilphLaprasText
	dw StartInSafariZoneText
	
StartInNormalText:
	db "NORMAL@"
	
StartInEeveeHouseText:
	db "EEVEE @"
	
StartInSilphLaprasText:
	db "LAPRAS@"

StartInSafariZoneText:
	db "SAFARI@"
	
OptionsMenu_SelectTo:
	ld a, [wOptions3]
	and %110000
	swap a
	ld c, a
	ld a, [hJoy5]
	bit 4, a ; right
	jr nz, .pressedRight
	bit 5, a
	jr nz, .pressedLeft
	jr .asm_41ce0
.pressedRight
	ld a, c
	cp 3
	jr c, .noWrapAround
	ld c, -1
.noWrapAround
	inc c
	jr .continue
.pressedLeft
	ld a, c
	and a
	jr nz, .noWrapAround2
	ld c, 3 + 1
.noWrapAround2
	dec c
.continue
	ld b, c
	swap b
	ld a, [wOptions3]
	and %11001111
	or b
	ld [wOptions3], a
.asm_41ce0
	ld b, $0
	ld hl, OptionsSelectToStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 13, 2
	call PlaceString
	and a
	ret

OptionsSelectToStringsPointerTable:
	dw SelectToNone
	dw SelectToBike
	dw SelectToJack
	dw SelectToCrit
	
SelectToNone:
	db "NONE@"
SelectToBike:
	db "BIKE@"
SelectToJack:
	db "JACK@"
SelectToCrit:
	db "CRIT@"
	
OptionsMenu_SaveScum:
	ld a, [hJoy5]
	and D_RIGHT | D_LEFT
	jr nz, .leftOrRightPressed
	ld a, [wOptions3]
	and %1000000 ; mask other bits
	jr .noButtonsPressed
.leftOrRightPressed
	ld a, [wOptions3]
	xor %1000000
	ld [wOptions3], a
.noButtonsPressed
	ld bc, $0
	sla a
	sla a
	rl c
	ld hl, OptionsSaveScumStringsPointerTable
	add hl, bc
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, 13, 4
	call PlaceString
	and a
	ret

OptionsSaveScumStringsPointerTable:
	dw SaveScumRegularText
	dw SaveScumBNModeText
	
SaveScumRegularText:
	db "REG   @"
SaveScumBNModeText:
	db "BNMODE@"

OptionsMenu_Dummy: ; 41eab (10:5eab)
	and a
	ret

OptionsMenu_Cancel: ; 41ead (10:5ead)
	ld a, [hJoy5]
	and A_BUTTON
	jr nz, .pressedCancel
	and a
	ret
.pressedCancel
	scf
	ret
	
MoveOptionsCursorLocation: ; 41eb7 (10:5eb7)
	ld hl, wOptionsCursorLocation
	ld a, [hJoy5]
	cp D_DOWN
	jr z, .pressedDown
	cp D_UP
	jr z, .pressedUp
	and a
	ret
.pressedDown
	ld a, [hli]
	cp $7
	jr nz, .noWrapAround1
	dec hl
	xor a
	ld [hl], a
	scf
	ret
.noWrapAround1
	ld b, [hl]
	dec hl
	cp b ; b = number of options minus cancel and page on the screen
	jr nz, .regularIncrement
	ld [hl], $5 ; increment to PAGE
.regularIncrement
	inc [hl]
	scf
	ret
.pressedUp
	ld a, [hli]
	cp $6
	jr nz, .noWrapAround2
	ld a, [hld] ; copy the max amount minus PAGE and CANCEL button
	ld [hl], a
	scf
	ret
.noWrapAround2
	and a
	dec hl
	jr nz, .regularDecrement
	ld [hl], $8
.regularDecrement
	dec [hl]
	scf
	ret

RedrawOptionsCursor: ; 41ee9 (10:5ee9)
	coord hl, 1, 1
	ld de, SCREEN_WIDTH
	ld c, 16
.loop
	ld [hl], " "
	add hl, de
	dec c
	jr nz, .loop
	coord hl, 1, 2
	ld bc, SCREEN_WIDTH * 2
	ld a, [wOptionsCursorLocation]
	call AddNTimes
	ld [hl], "▶"
	ret

InitializeOptions: ; 41f06 (10:5f06)
	xor a
	ld [wOptionsCurPage], a
	
; fallthrough
RedrawOptions:
	ld hl, wOptionsCursorLocation
	xor a
	ld [hli], a
	ld [hl], a
	coord hl, 0, 0
	lb bc, SCREEN_HEIGHT - 2, SCREEN_WIDTH - 2
	call TextBoxBorder
	ld hl, OptionsOptionsPointerTable
	ld a, [wOptionsCurPage]
	add a
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hli]
	ld d, [hl]
	ld e, a
	coord hl, 2, 2
	call PlaceString
	coord hl, 2, 14
	ld de, OptionMenuPageAndCancelText
	call PlaceString
	call GetOptionsPageLength
	ld c, 7
.loop
	push bc
	call HandleCurrentOption
	pop bc
	ld hl, wOptionsCursorLocation
	inc [hl]
	dec c
	jr nz, .loop
	xor a
	ld [wOptionsCursorLocation], a
	inc a
	ld [H_AUTOBGTRANSFERENABLED], a
	jp DelayFrame

GetOptionsPageLength:
	push hl
	ld a, [wOptionsCurPage]
	ld hl, OptionsPageLength
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	ld a, [hl]
	ld [wOptionsNumOptions], a
	pop hl
	ret
	
OptionsOptionsPointerTable:
	dw Options1OptionsText
	dw Options2OptionsText
	dw Options3OptionsText

OptionsPageLength:
; number of options minus page, cancel and 1
	db 5
	db 5
	db 1

Options1OptionsText: ; 41f3e (10:5f3e)
	db   "TEXT SPEED :"
	next "MENU SPEED :"
	next "ANIMATION  :"
	next "BATTLESTYLE:"
	next "SHAKE MOVES:"
	next "METRONOME  :@"
	
Options2OptionsText:
	db "PAL:"
	next "SPINNERHELL:"
	next "SPIN SPEED :"
	next "BIKESLIPRUN:"
	next "TRAINERANGE:"
	next "STARTIN:@"
	
Options3OptionsText:
	db   "SELECTTO:"
	next "SAVESCUM:@"
	

OptionMenuPageAndCancelText: ; 41f73 (10:5f73)
	db "PAGE:"
	next "CANCEL@"