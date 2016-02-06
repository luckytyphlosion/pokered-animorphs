TrainerDifficulties:
	db 4  ; YOUNGSTER
	db 2  ; BUG_CATCHER
	db 7  ; LASS
	db 6  ; SAILOR
	db 8  ; JR__TRAINER_M
	db 16 ; JR__TRAINER_F
	db 20 ; POKEMANIAC
	db 18 ; SUPER_NERD
	db 5  ; HIKER
	db 22 ; BIKER
	db 30 ; BURGLAR
	db 9  ; ENGINEER
	db 31 ; JUGGLER_X
	db 17 ; FISHER
	db 27 ; SWIMMER
	db 25 ; CUE_BALL
	db 11 ; GAMBLER
	db 23 ; BEAUTY
	db 28 ; PSYCHIC_TR
	db 14 ; ROCKER
	db 31 ; JUGGLER
	db 34 ; TAMER
	db 26 ; BIRD_KEEPER
	db 32 ; BLACKBELT
	db 1  ; SONY1
	db 45 ; PROF_OAK
	db 1  ; CHIEF
	db 24 ; SCIENTIST
	db 33 ; GIOVANNI
	db 15 ; ROCKET
	db 37 ; COOLTRAINER_M
	db 39 ; COOLTRAINER_F
	db 41 ; BRUNO
	db 3  ; BROCK
	db 10 ; MISTY
	db 12 ; LT__SURGE
	db 21 ; ERIKA
	db 35 ; KOGA
	db 38 ; BLAINE
	db 36 ; SABRINA
	db 13 ; GENTLEMAN
	db 29 ; SONY2
	db 44 ; SONY3
	db 40 ; LORELEI
	db 19 ; CHANNELER
	db 42 ; AGATHA
	db 43 ; LANCE

GetEnemyTrainerDVs:
; input:
; wTrainerClass, wCurEnemyLVL, wTrainerNo
; e: which party mon we're iterating
; return dvs in wAddPartyMonDVs

; calculate (L + W)(C^2/4 + S)
	push bc
	push de
	push hl
; calculate C^2
	ld hl, TrainerDifficulties
	ld a, [wTrainerClass]
	dec a
	ld c, a
	ld b, $0
	add hl, bc
	ld a, [hl]
	dec a
	jr nz, .notRival1
; efficiency
	ld hl, $0
	jr .rival1
.notRival1
	ld [H_MULTIPLIER], a
	ld [H_MULTIPLICAND+2], a
	xor a
	ld [H_MULTIPLICAND], a
	ld [H_MULTIPLICAND+1], a
	call Multiply
; calculate C^2/4
	ld a, [H_PRODUCT+2]
	ld h, a
	ld a, [H_PRODUCT+3]
	ld l, a
	srl h
	rr l
	srl h
	rr l
; calculate C^2/4 + S
.rival1
	xor a
	ld [H_MULTIPLICAND], a
	ld b, a
	ld a, [wTrainerNo]
	ld c, a
	add hl, bc
	ld a, h
	ld [H_MULTIPLICAND+1], a
	ld a, l
	ld [H_MULTIPLICAND+2], a
; calculate L + W
	ld a, [wCurEnemyLVL]
	add e
	ld [H_MULTIPLIER], a
; finally, calculate (L + W)(C^2/4 + S)
	call Multiply
	
	ld a, [H_PRODUCT+1]
	and a
	jr z, .doNotSetMaxDVs
	ld bc, $ffff
	jr .writeDVs
.doNotSetMaxDVs
	ld a, [H_PRODUCT+3]
	ld [H_DIVIDEND+1], a
	ld c, a
	ld a, [H_PRODUCT+2]
	ld [H_DIVIDEND], a
	ld b, a
	and a
	jr z, .dvRangeZeroToThreeBits
	and $f0
	ld e, $3
	jr nz, .getDVs
	dec e
	jr .getDVs
.dvRangeZeroToThreeBits
	ld a, c
	and $f0
	ld e, $0
	jr z, .getDVs
	inc e
.getDVs
	ld hl, wBuffer
	xor a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld hl, GetDVJumptable
	ld d, a
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call .doDVFunction
	ld a, 24 ; 24 different functions
	ld [H_DIVISOR], a
	ld b, $2
	call Divide
	ld a, [H_REMAINDER]
	ld hl, GetDV_RandomList
	ld c, a
	ld b, $0
	add hl, bc
	ld c, [hl]
	ld b, $4
	ld hl, wcd6d
.shuffleDVsLoop
	ld de, wBuffer
	ld a, c
	and %11
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	ld a, [de]
	ld [hli], a
	srl c
	srl c
	dec b
	jr nz, .shuffleDVsLoop
	ld hl, wcd6d
	call CompressDVs
.writeDVs
	ld a, b
	ld [wAddPartyMonDVs], a
	ld a, c
	ld [wAddPartyMonDVs+1], a
	pop hl
	pop de
	pop bc
	ret
	

.doDVFunction
	push hl
	ld hl, wBuffer
	ret
	
CompressDVs:
	call .compressDVs
	ld b, c
.compressDVs
	ld a, [hli]
	swap a
	ld c, a
	ld a, [hli]
	or c
	ld c, a
	ret
	
dvrand: MACRO
	db (\1 - 1) << 6 | (\2 - 1) << 4 | (\3 - 1) << 2 | (\4 - 1)
	ENDM

GetDV_RandomList:
; hardcode for efficiency
	dvrand 4, 1, 2, 3
	dvrand 3, 2, 4, 1
	dvrand 2, 4, 1, 3
	dvrand 1, 2, 3, 4
	dvrand 4, 2, 3, 1
	dvrand 1, 2, 4, 3
	dvrand 2, 3, 1, 4
	dvrand 2, 4, 3, 1
	dvrand 4, 2, 1, 3
	dvrand 1, 4, 2, 3
	dvrand 3, 1, 4, 2
	dvrand 1, 3, 2, 4
	dvrand 4, 3, 2, 1
	dvrand 4, 1, 3, 2
	dvrand 4, 3, 1, 2
	dvrand 2, 3, 4, 1
	dvrand 1, 3, 4, 2
	dvrand 3, 4, 1, 2
	dvrand 3, 4, 2, 1
	dvrand 3, 2, 1, 4
	dvrand 1, 4, 3, 2
	dvrand 3, 1, 2, 4
	dvrand 2, 1, 3, 4
	dvrand 2, 1, 4, 3
	
GetDVJumptable:
	dw GetDV_OneBit
	dw GetDV_TwoBits
	dw GetDV_ThreeBits
	dw GetDV_FourBits
	
GetDV_OneBit:
	ld a, $4
.loop
	srl c
	rl [hl]
	inc hl
	dec a
	jr nz, .loop
	ret
	
GetDV_TwoBits:
	lb de, $4, %11
.loop
	ld a, e
	and c
	srl c
	srl c
	ld [hli], a
	dec d
	jr nz, .loop
	ret
	
GetDV_ThreeBits:
	call .getTwoDVs
	sla b
	sla b
	ld a, c
	or b
	ld c, a
.getTwoDVs
	ld a, c
	and %111
	ld [hli], a
	srl c
	srl c
	srl c
	ld a, c
	and %111
	ld [hli], a
	ret
	
GetDV_FourBits:
	call .getTwoDVs
	ld b, c
.getTwoDVs
	ld a, b
	and $f0
	swap a
	ld [hli], a
	ld a, b
	and $f
	ld [hli], a
	ret