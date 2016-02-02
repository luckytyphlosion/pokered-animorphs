DisplayEffectiveness: ; 2fb7b (b:7b7b)
	ld a, [wDamageMultipliers]
	ld hl, ConfusedDoesntAffectMonText
	and a, $7F
	cp 10 + (SE_MULTIPLIER - 10) * 2 + 1 ; check if the result is "negative" in the semi-impossible case of a double little effect (e.g. ghost against normal/psychic)
	jr nc, .done
	cp 10
	ret z
	ld hl, SuperEffectiveText
	jr nc, .done
	cp (10 - LE_MULTIPLIER) + 1
	ld hl, NotVeryEffectiveText
	jr nc, .done
	ld hl, LittleEffectText
.done
	jp PrintText

SuperEffectiveText: ; 2fb8e (b:7b8e)
	TX_FAR _SuperEffectiveText
	db "@"

NotVeryEffectiveText: ; 2fb93 (b:7b93)
	TX_FAR _NotVeryEffectiveText
	db "@"

LittleEffectText:
	TX_FAR _LittleEffectText
	db "@"

ConfusedDoesntAffectMonText:
	TX_FAR _ConfusedDoesntAffectMonText
	db "@"