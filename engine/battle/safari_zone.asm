PrintSafariZoneBattleText: ; 4277 (1:4277)
	ld a, [wSafariZoneRockBaitFlags]
	bit 0, a
	jr nz, .eatingBait
	bit 1, a
	jr z, .done ; not doing anything
; angry at rock
	ld hl, SafariZoneAngryText
	jr .printText
.eatingBait
	ld hl, SafariZoneEatingText
.printText
	call PrintText
.done
	xor a
	ld [wSafariZoneRockBaitFlags], a
	jp LoadScreenTilesFromBuffer1

SafariZoneEatingText: ; 42a7 (1:42a7)
	TX_FAR _SafariZoneEatingText
	db "@"

SafariZoneAngryText: ; 42ac (1:42ac)
	TX_FAR _SafariZoneAngryText
	db "@"
