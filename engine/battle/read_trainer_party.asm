SECTION "randomize trainers", ROMX[$5c53], BANK[$E]
ReadTrainer: ; 39c53 (e:5c53)
; don't change any moves in a link battle
	ld a,[wLinkState]
	and a
	ret nz

; set [wEnemyPartyCount] to 0, [wEnemyPartyMons] to FF
; XXX first is total enemy pokemon?
; XXX second is species of first pokemon?
	ld hl,wEnemyPartyCount
	xor a
	ld [hli],a
	dec a
	ld [hl],a

; get the pointer to trainer data for this class
	ld a,[wCurOpponent]
	sub $C9 ; convert value from pokemon to trainer
	add a,a
	ld hl,TrainerDataPointers
	ld c,a
	ld b,0
	add hl,bc ; hl points to trainer class
	ld a,[hli]
	ld h,[hl]
	ld l,a
	ld a,[wTrainerNo]
	ld b,a
; At this point b contains the trainer number,
; and hl points to the trainer class.
; Our next task is to iterate through the trainers,
; decrementing b each time, until we get to the right one.
	jr .outer
.inner
	ld a,[hli]
	and a
	jr nz,.inner
.outer
	dec b
	jr nz,.inner
; if the first byte of trainer data is FF,
; - each pokemon has a specific level
;      (as opposed to the whole team being of the same level)
; - if [wLoneAttackNo] != 0, one pokemon on the team has a special move
; else the first byte is the level of every pokemon on the team
	ld e, $0
	ld a,[hli]
	cp $FF ; is the trainer special?
	jr z,.specialTrainer ; if so, check for special moves
	ld [wCurEnemyLVL],a
.LoopTrainerData
	ld a,[hli]
	and a ; have we reached the end of the trainer data?
	jp z,.finishUp
	push de
	ld [wcf91],a ; write species somewhere (XXX why?)
	call GetEnemyTrainerDVs
	ld a,ENEMY_PARTY_DATA
	ld [wMonDataLocation],a
	push hl
	call AddPartyMon
	pop hl
	pop de
	inc e
	jr .LoopTrainerData
.specialTrainer
; if this code is being run:
; - each pokemon has a specific level
;      (as opposed to the whole team being of the same level)
; - if [wLoneAttackNo] != 0, one pokemon on the team has a special move
	ld a,[hli]
	and a ; have we reached the end of the trainer data?
	jr z,.addAdditionalMoveData
	push de
	ld [wCurEnemyLVL],a
	ld a,[hli]
	ld [wcf91],a
	call GetEnemyTrainerDVs
	ld a,ENEMY_PARTY_DATA
	ld [wMonDataLocation],a
	push hl
	call AddPartyMon
	pop hl
	pop de
	inc e
	jr .specialTrainer
.addAdditionalMoveData
; does the trainer have additional move data?
	ld a, [wTrainerClass]
	ld b, a
	ld a, [wTrainerNo]
	ld c, a
	ld hl, SpecialTrainerMoves
.loopAdditionalMoveData
	ld a, [hli]
	cp $ff
	jr z, .finishUp
	cp b
	jr nz, .skipOverCurrentMoveData
	ld a, [hli]
	cp c
	jr nz, .skipOverCurrentMoveData
	ld d, h
	ld e, l
.writeAdditionalMoveDataLoop
	ld a, [de]
	inc de
	and a
	jp z, .finishUp
	dec a
	ld hl, wEnemyMon1Moves
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	ld a, [de]
	inc de
	dec a
	ld c, a
	ld b, 0
	add hl,bc
	ld a, [de]
	push af ; save move for later
	inc de
	ld [hl], a
	ld bc, wEnemyMon1PP - wEnemyMon1Moves
	add hl, bc
	pop af
	dec a
	push hl
	ld hl, Moves + 5
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld a, [hl]
	pop hl
	ld [hl], a ; write PP
	jr .writeAdditionalMoveDataLoop
.skipOverCurrentMoveData
	ld a, [hli]
	and a
	jr nz, .skipOverCurrentMoveData
	jr .loopAdditionalMoveData
.finishUp
; clear wAmountMoneyWon addresses
	xor a
	ld de,wAmountMoneyWon
	ld [de],a
	inc de
	ld [de],a
	inc de
	ld [de],a
	ld a,[wCurEnemyLVL]
	ld b,a
.lastLoop
; update wAmountMoneyWon addresses (money to win) based on enemy's level
	ld hl,wTrainerBaseMoney + 1
	ld c,2 ; wAmountMoneyWon is a 3-byte number
	push bc
	predef AddBCDPredef
	pop bc
	inc de
	inc de
	dec b
	jr nz,.lastLoop ; repeat wCurEnemyLVL times
	ret