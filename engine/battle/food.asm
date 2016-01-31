HealMonAfterBattle:
; heal player mon, depending on how similar the mon is to the enemy mon
; compare:
; - species (1 byte)
; - base stats (5 bytes)
; - types (2 bytes)
; - move PPs (4 bytes)
; - moves (4 bytes)
	ld a, [wEnemyMonSpecies]
	ld [wd0b5], a
	call GetMonHeader
	ld hl, wMonHIndex
	ld bc, wMonHCatchRate - wMonHIndex
	ld de, wcd6d
	
	push hl
	push de
	
	call CopyData
	ld a, [wBattleMonSpecies]
	ld [wd0b5], a
	call GetMonHeader
	
	pop de
	pop hl
	
	lb bc, wMonHCatchRate - wMonHIndex, $0
	call CountSameBytes
	
	ld hl, wEnemyMonMoves
	ld de, wEnemyMonPP
	push de
	predef LoadMovePPs
	ld hl, wBattleMonMoves
	ld de, wBattleMonPP
	push de
	predef LoadMovePPs
	
	pop hl
	pop de
	
	ld b, NUM_MOVES
	call CountSameBytes
	
	ld hl, wBattleMonMoves
	ld de, wEnemyMonMoves
	ld b, NUM_MOVES
	call CountSameBytes
	
	ld a, c
	swap a
	jr nz, .notValueZero
	inc a
.notValueZero
	ld [wFoodPercentageAmount], a
	call HealWithFood_DetermineFoodType
	call HealWithFood_DetermineHealType
	ld hl, AfterBattleHealJumptable
	sla c
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push bc
	call .healFunction
	pop bc
	
	ld hl, AfterBattleHealTextPointers
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call PrintText
	ld c, 30
	jp DelayFrames

.healFunction
	push hl ; pseudo jp hl
	ld a, [wPlayerMonNumber]
	ld hl, wPartyMon1
	ld bc, wPartyMon2 - wPartyMon1
	jp AddNTimes
	
CountSameBytes:
; calculate how many bytes match between [hl] and [de], with length b
; return count in c
	ld a, [de]
	cp [hl]
	jr nz, .noMatch
	inc c
.noMatch
	inc hl
	inc de
	dec b
	jr nz, CountSameBytes
	ret

	
AfterBattleHealJumptable:
	dw HealWithFood_HP
	dw HealWithFood_FullHP
	dw HealWithFood_PP
	dw HealWithFood_FullPP
	
AfterBattleHealTextPointers:
	dw GotFoodText
	dw GotSuperFoodText
	dw GotMilkText
	dw GotSuperMilkText
	
GotFoodText:
	TX_FAR _GotFoodText
	db "@"

GotSuperFoodText:
	TX_FAR _GotSuperFoodText
	db "@"
	
GotMilkText:
	TX_FAR _GotMilkText
	db "@"
	
GotSuperMilkText:
	TX_FAR _GotSuperMilkText
	db "@"
	
HealWithFood_DetermineFoodType:
; input:
; c: number of similarities
; output:
; c: partial index to jumptable
	call Random
	and $1f ; get random number between 0 and 31
	cp c ; is the random number less than the number of similarities?
	ld c, $0
	jr c, .doSuperFood
	res 0, c
	ret
.doSuperFood
	set 0, c
	ret
	
HealWithFood_DetermineHealType:
; for now, heal type will be random
	call Random
	and $1
	jr nz, .healPP
	res 1, c ; heal HP
	ret
.healPP
	set 1, c ; heal PP
	ret
	
HealWithFood_HP:
	push hl
	ld de, wPartyMon1MaxHP - wPartyMon1
	add hl, de
	ld a, [hli]
	ld b, a
	ld c, [hl] ; bc = max HP
	pop hl
	
	push bc ; save max HP
	call HealWithFood_GetRange
	
	
	pop de
	; bc = hp delta
	; de = max hp
	push hl
	inc hl
	ld a, [hli]
	ld l, [hl]
	ld h, a
	add hl, bc
	ld b, h
	ld c, l
	pop hl
	
; bc = new HP
; de = max HP
	
	ld a, b
	cp d
	jr c, .setHealValueAsModifiedHP
	jr nz, .healPokemonWithFood
	ld a, c
	cp e
	jr nc, .healPokemonWithFood
.setHealValueAsModifiedHP
	ld d, b
	ld e, c
.healPokemonWithFood
	inc hl
	ld a, d
	ld [hli], a
	ld [hl], e
	ret

HealWithFood_FullHP:
	push hl
	ld bc, wPartyMon1MaxHP - wPartyMon1
	add hl, bc
	ld a, [hli]
	ld b, a
	ld c, [hl]
	pop hl
	inc hl
	ld a, b
	ld [hli], a
	ld [hl], c
	ret
	
HealWithFood_PP_CreatePPList:
	push hl
	ld a, [wPlayerMonNumber]
	ld [wWhichPokemon], a
	ld bc, wPartyMon1Moves - wPartyMon1
	add hl, bc
	
	xor a
	ld [wMonDataLocation], a
	ld b, a
	
	ld d, h
	ld e, l
	ld hl, wBuffer
	push hl
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	pop hl
.getPPOfMonLoop
	ld a, [de]
	and a
	jr z, .getPPOfMonLoopDone
	inc de
	push bc
	push hl
	push de
	ld a, b
	ld [wCurrentMenuItem], a
	callab GetMaxPP
	ld a, [wMaxPP]
	pop de
	pop hl
	pop bc
	ld [hli], a
	inc b
	ld a, b
	cp NUM_MOVES
	jr nz, .getPPOfMonLoop
.getPPOfMonLoopDone
	pop hl ; restore base struct
	ret

HealWithFood_PP:
	call HealWithFood_PP_CreatePPList
	ld a, b
	and a
	ret z ; error checking
	ld bc, wPartyMon1PP - wPartyMon1
	add hl, bc
	ld de, wBuffer

.modifyMovePPLoop
	push af
	ld a, [de]
	ld c, a
	ld b, $0
	call HealWithFood_GetRange
	ld a, [hl]
	and $3f ; get pp value
	add c
	ld c, a
	ld a, [de] ; max pp value
	inc de
	cp c ; is the max pp value greater than the modified pp value?
	jr nc, .useModifiedValue
	ld c, a ; modified value is now max PP value
.useModifiedValue
	ld a, [hl]
	and %11000000 ; mask non-PP up values
	or c ; get new PP value
	ld [hli], a
	pop af
	dec a
	jr nz, .modifyMovePPLoop
	ret
	
HealWithFood_FullPP:
	call HealWithFood_PP_CreatePPList
	ld a, b
	and a
	ret z ; error checking
	ld bc, wPartyMon1PP - wPartyMon1
	add hl, bc
	ld d, h
	ld e, l
	ld hl, wBuffer
	ld c, %11000000
.writeMaxPPLoop
	ld a, [de]
	and c
	or [hl]
	ld [de], a
	inc de
	inc hl
	dec b
	jr nz, .writeMaxPPLoop
	ret
	
HealWithFood_GetRange:
; input:
; wFoodPercentageAmount: base value of range
; bc: value to manipulate
; return output in bc
	push de
	xor a
	ld [H_MULTIPLICAND], a
	ld a, b
	ld [H_MULTIPLICAND+1], a
	ld a, c
	ld [H_MULTIPLICAND+2], a
	
	ld a, [wFoodPercentageAmount]
	ld d, a
	dec a ; are we dealing with base value 1?
	lb bc, $f, $7
	jr nz, .regularValue
	lb bc, $7, $0
.regularValue
	call Random
	
	and b
	sub c ; get range between -7 and 8, or 0 and 7
	
	add d
	
	ld [H_MULTIPLIER], a
	
	call Multiply
	
; divide by 256 by ignoring the lowest byte
	ld a, [H_PRODUCT+2]
	ld c, a
	ld a, [H_PRODUCT+1]
	ld b, a
	inc bc ; ceiling
	pop de
	ret