_DisplayOptionMenu: ; 41c70 (10:5c70)
	call Func_41f06
.optionMenuLoop
	call JoypadLowSensitivity
	ld a, [hJoy5]
	and START | B_BUTTON
	jr nz, .exitOptionMenu
	call Func_41eb7
	jr c, .asm_41c86
	call Func_41c95
	jr c, .exitOptionMenu
.asm_41c86
	call Func_41ee9
	call DelayFrame
	jr .optionMenuLoop
.exitOptionMenu
	ret

Func_41c95: ; 41c95 (10:5c95)
	ld a, [wOptionsCursorLocation]
	ld e, a
	ld d, $0
	ld hl, OptionMenuJumpTable
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

OptionMenuJumpTable: ; 41ca4 (10:5ca4)
	dw OptionsMenu_TextSpeed
	dw OptionsMenu_MenuSpeed
	dw OptionsMenu_BattleAnimations
	dw OptionsMenu_BattleStyle
	dw OptionsMenu_ShakeMoves
	dw OptionsMenu_Metronome
	dw OptionsMenu_Palette
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
	
Op_RegularPalText:
	db "REGULAR@"
Op_InvertedPalText:
	db "INVERT @"
Op_CheaterPalText:
	db "CHEATER@"
	
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
	coord hl, 6, 14
	call PlaceString
	and a
	ret

PalStringsPointerTable:
	dw Op_RegularPalText
	dw Op_InvertedPalText
	dw Op_CheaterPalText

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
	
Func_41eb7: ; 41eb7 (10:5eb7)
	ld hl, wOptionsCursorLocation
	ld a, [hJoy5]
	cp D_DOWN
	jr z, .pressedDown
	cp D_UP
	jr z, .pressedUp
	and a
	ret
.pressedDown
	ld a, [hl]
	inc a
	cp $7 + $1
	jr c, .noWrapAroundUp
	xor a
.noWrapAroundUp
	ld [hl], a
	scf
	ret
.pressedUp
	ld a, [hl]
	dec [hl]
	and a
	jr nz, .noWrapAroundDown
	ld [hl], $7
.noWrapAroundDown
	scf
	ret
	
Func_41ee9: ; 41ee9 (10:5ee9)
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

Func_41f06: ; 41f06 (10:5f06)
	coord hl, 0, 0
	lb bc, SCREEN_HEIGHT - 2, SCREEN_WIDTH - 2
	call TextBoxBorder
	coord hl, 2, 2
	ld de, AllOptionsText
	call PlaceString
	coord hl, 2, 16
	ld de, OptionMenuCancelText
	call PlaceString
	xor a
	ld [wOptionsCursorLocation], a
	ld c, 7
.loop
	push bc
	call Func_41c95
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
	
AllOptionsText: ; 41f3e (10:5f3e)
	db   "TEXT SPEED :"
	next "MENU SPEED :"
	next "ANIMATION  :"
	next "BATTLESTYLE:"
	next "SHAKE MOVES:"
	next "METRONOME  :"
	next "PAL:@"
	
OptionMenuCancelText: ; 41f73 (10:5f73)
	db "CANCEL@"