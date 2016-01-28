_AddPartyMon: ; f2e5 (3:72e5)
; Adds a new mon to the player's or enemy's party.
; [wMonDataLocation] is used in an unusual way in this function.
; If the lower nybble is 0, the mon is added to the player's party, else the enemy's.
; If the entire value is 0, then the player is allowed to name the mon.
	ld de, wPartyCount
	ld a, [wMonDataLocation]
	and $f
	jr z, .next
	ld de, wEnemyPartyCount
.next
	ld a, [de]
	inc a
	cp PARTY_LENGTH + 1
	ret nc ; return if the party is already full
	ld [de], a
	ld a, [de]
	ld [hNewPartyLength], a
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	ld a, [wcf91]
	ld [de], a ; write species of new mon in party list
	inc de
	ld a, $ff ; terminator
	ld [de], a
	ld hl, wPartyMonOT
	ld a, [wMonDataLocation]
	and $f
	jr z, .next2
	ld hl, wEnemyMonOT
.next2
	ld a, [hNewPartyLength]
	dec a
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, wPlayerName
	ld bc, NAME_LENGTH
	call CopyData
	ld a, [wMonDataLocation]
	and a
	jr nz, .skipNaming
	ld hl, wPartyMonNicks
	ld a, [hNewPartyLength]
	dec a
	call SkipFixedLengthTextEntries
	ld a, NAME_MON_SCREEN
	ld [wNamingScreenType], a
	predef AskName
.skipNaming
	ld hl, wPartyMons
	ld a, [wMonDataLocation]
	and $f
	jr z, .next3
	ld hl, wEnemyMons
.next3
	ld a, [hNewPartyLength]
	dec a
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld c, l
	ld b, h ; bc = base address
	ld a, [wcf91]
	ld [wd0b5], a
	call GetMonHeader
	ld a, [wMonHeader]
	ld [bc], a ; species
	ld a, [wMonDataLocation]
	and $f
	jr nz, .trainerMon

; If the mon is being added to the player's party, update the pokedex.
	ld a, [wcf91]
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	dec a
	push bc ; save base mon struct
	
	ld c, a
	ld b, FLAG_TEST
	ld hl, wPokedexOwned
	call FlagAction
	ld a, c ; whether the mon was already flagged as owned
	ld [wUnusedD153], a ; not read
	ld a, [wd11e]
	dec a
	ld c, a
	ld b, FLAG_SET
	push bc
	call FlagAction
	pop bc
	ld hl, wPokedexSeen
	call FlagAction

	pop bc ; restore base mon struct

	ld a, [wIsInBattle]
	and a ; is this a wild mon caught in battle?
	jr nz, .copyEnemyMonData

.trainerMon
	ld hl, wPartyMon1DVs - wPartyMon1
	add hl, bc
	xor a ; no DVs
	ld [hli], a
	ld [hl], a         ; write IVs
	
	ld e, c
	ld d, b ; stash base mon struct in de
	
	ld c, $1 ; calc HP
	call CalcStat      ; calc HP stat (set cur Hp to max HP)
	
	ld c, e
	ld b, d ; store base mon struct back into bc
	ld hl, wPartyMon1HP - wPartyMon1
	add hl, bc
	
	ld a, [H_MULTIPLICAND+1]
	ld [hli], a
	ld a, [H_MULTIPLICAND+2]
	ld [hli], a
	ld a, [wCurEnemyLVL]
	ld [hli], a         ; box level
	xor a
	ld [hli], a         ; status ailments
	jr .copyMonTypesAndMoves
.copyEnemyMonData
	ld hl, wEnemyMon1DVs - wEnemyMon1
	add hl, bc
	ld a, [wEnemyMonDVs] ; copy IVs from cur enemy mon
	ld [hli], a
	ld a, [wEnemyMonDVs + 1]
	ld [hl], a
	ld hl, wEnemyMon1HP - wEnemyMon1
	add hl, bc
	ld a, [wEnemyMonHP]    ; copy HP from cur enemy mon
	ld [hli], a
	ld a, [wEnemyMonHP+1]
	ld [hli], a
	xor a
	ld [hli], a                ; box level
	ld a, [wEnemyMonStatus]   ; copy status ailments from cur enemy mon
	ld [hli], a
.copyMonTypesAndMoves
	ld de, wMonHTypes
	ld a, [de]        ; type 1
	ld [hli], a
	inc de
	ld a, [de]        ; type 2
	ld [hli], a
	inc de
	
	ld a, [de]        ; catch rate (held item in gen 2)
	ld [hli], a
	
	push hl ; save address of moves for AddPartyMon_WriteMovePPs
	
	ld a, [wMonDataLocation]
	and $f ; are we adding to the player party?
	jr nz, .writeFreshMoves
	
	ld a, [wIsInBattle]
	cp $2 ; trainer battle?
	jr nz, .writeFreshMoves
	
	push hl
	push bc
	ld a, [wWhichPokemon]
	ld hl, wEnemyMon1Moves
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	ld d, h
	ld e, l
	pop bc
	pop hl
	
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hl], a
	jr .writeTrainerID
.writeFreshMoves
	push hl ; save address of moves for WriteMonMoves
	
	
	ld de, wMonHMoves ; header moves
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hl], a
	
	xor a
	ld [wLearningMovesFromDayCare], a
	pop de
	
	predef WriteMonMoves
.writeTrainerID
	ld hl, wPartyMon1OTID - wPartyMon1
	add hl, bc ; trainer ID
	
	ld a, [wPlayerID]  ; set trainer ID to player ID
	ld [hli],a
	ld a, [wPlayerID + 1]
	ld [hli], a
	
	push hl ; save EXP address
	push bc ; save base mon struct
	ld a, [wCurEnemyLVL]
	ld d, a
	callab CalcExperience
	pop bc ; restore regs
	pop hl
	
	ld a, [hExperience] ; write experience
	ld [hli], a
	ld a, [hExperience + 1]
	ld [hli], a
	ld a, [hExperience + 2]
	ld [hli], a

	xor a
	ld d, NUM_STATS * 2
.writeEVsLoop              ; set all EVs to 0
	ld [hli], a
	dec d
	jr nz, .writeEVsLoop
	
	inc hl
	inc hl ; skip past dvs
	
	ld d, h
	ld e, l
	pop hl ; restore address of moves from way back
	
	push bc
	call AddPartyMon_WriteMovePP
	pop bc

	ld a, [wCurEnemyLVL]
	ld [de], a
	
	ld a, [wIsInBattle]
	dec a
	jr nz, .calcFreshStats
	ld hl, wEnemyMonMaxHP
	ld bc, (wEnemyMonSpecial + 1) - wEnemyMonMaxHP
	call CopyData          ; copy stats of cur enemy mon
	jr .done
.calcFreshStats
	ld hl, wPartyMon1MaxHP - wPartyMon1
	add hl, bc
	ld d, b
	ld e, c
	call CalcStats         ; calculate fresh set of stats
.done
	scf
	ret

LoadMovePPs: ; f473 (3:7473)
	call GetPredefRegisters
	; fallthrough
AddPartyMon_WriteMovePP: ; f476 (3:7476)
; input:
; hl = address of mon moves
; de = pp of mon moves
	ld b, NUM_MOVES
.pploop
	ld a, [hli]     ; read move ID
	and a
	jr z, .empty
	dec a
	push hl
	push de
	push bc
	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld de, wcd6d
	ld a, BANK(Moves)
	call FarCopyData
	pop bc
	pop de
	pop hl
	ld a, [wcd6d + 5] ; PP is byte 5 of move data
.empty
	ld [de], a
	inc de
	dec b
	jr nz, .pploop ; there are still moves to read
	ret

; adds enemy mon [wcf91] (at position [wWhichPokemon] in enemy list) to own party
; used in the cable club trade center
_AddEnemyMonToPlayerParty: ; f49d (3:749d)
	ld hl, wPartyCount
	ld a, [hl]
	cp PARTY_LENGTH
	scf
	ret z            ; party full, return failure
	inc a
	ld [hl], a       ; add 1 to party members
	ld c, a
	ld b, $0
	add hl, bc
	ld a, [wcf91]
	ld [hli], a      ; add mon as last list entry
	ld [hl], $ff     ; write new sentinel
	ld hl, wPartyMons
	ld a, [wPartyCount]
	dec a
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld e, l
	ld d, h
	ld hl, wLoadedMon
	call CopyData    ; write new mon's data (from wLoadedMon)
	ld hl, wPartyMonOT
	ld a, [wPartyCount]
	dec a
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, wEnemyMonOT
	ld a, [wWhichPokemon]
	call SkipFixedLengthTextEntries
	ld bc, NAME_LENGTH
	call CopyData    ; write new mon's OT name (from an enemy mon)
	ld hl, wPartyMonNicks
	ld a, [wPartyCount]
	dec a
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, wEnemyMonNicks
	ld a, [wWhichPokemon]
	call SkipFixedLengthTextEntries
	ld bc, NAME_LENGTH
	call CopyData    ; write new mon's nickname (from an enemy mon)
	ld a, [wcf91]
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	dec a
	ld c, a
	ld b, FLAG_SET
	ld hl, wPokedexOwned
	push bc
	call FlagAction ; add to owned pokemon
	pop bc
	ld hl, wPokedexSeen
	call FlagAction ; add to seen pokemon
	and a
	ret                  ; return success