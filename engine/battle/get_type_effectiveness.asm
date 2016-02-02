AIGetTypeEffectiveness: ; 3e449 (f:6449)
	ld a, [wEnemyMoveType]
	ld d, a                     ; d = type of enemy move
	ld hl, wBattleMonType
	ld a, [hli]                 ; b = type 1 of player's pokemon
	ld b, a
	ld c, [hl]                  ; c = type 2 of player's pokemon
	;ld a, $10
	;ld [wTypeEffectiveness], a ; initialize to neutral effectiveness
	ld e, $10                   ; e = initial weighting
	ld hl, TypeEffects
	jr .loop
.nextTypePair1
	inc hl
.nextTypePair2
	inc hl
.loop
	ld a,[hli]
	cp a,$ff
	jr z, .done
	cp d                      ; match the type of the move
	jr nz,.nextTypePair1
	ld a,[hli]
	cp b                      ; match with type 1 of pokemon
	jr z,.applyModification
	cp c                      ; or match with type 2 of pokemon
	jr nz,.nextTypePair2
.applyModification
	ld a, [hli]
	cp SE_MULTIPLIER
	jr nz, .checkForNVEMultiplier
	ld a, $5
	add e
	ld e, a
	jr .loop
.checkForNVEMultiplier
	cp NVE_MULTIPLIER
	jr nz, .checkForLEMultiplier
	ld a, e
	sub $5
	ld e, a
	jr .loop
.checkForLEMultiplier
	cp LE_MULTIPLIER
	jr nz, .loop ; error checking
	ld a, e
	sub $8
	ld e, a
	jr .loop	
.done
	ld a, e
	ld [wTypeEffectiveness],a ; store damage multiplier
	ret