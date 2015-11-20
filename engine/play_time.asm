TrackPlayTime: ; 18dee (6:4dee)
	call CountDownIgnoreInputBitReset
	ld a, [wd732]
	bit 0, a
	ret z
	ld a, [wSRAMEnabled]
	push af
	ld a, [wSRAMBank]
	push af
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [MBC1SRamBank], a
	call TrackPlayTime_
	ld hl, sPlayTimeHours
	ld bc, (wPlayTimeFrames + 1) - wPlayTimeHours
	ld de, wPlayTimeHours
	call CopyData
	pop af
	ld [MBC1SRamBank], a
	pop af
	ld [MBC1SRamEnable], a
	ret

TrackPlayTime_:
	ld a, [sPlayTimeMinutes]
	and a
	ret nz
	ld a, [sPlayTimeFrames]
	inc a
	ld [sPlayTimeFrames], a
	cp 60
	ret nz
	xor a
	ld [sPlayTimeFrames], a
	ld a, [sPlayTimeSeconds]
	inc a
	ld [sPlayTimeSeconds], a
	cp 60
	ret nz
	xor a
	ld [sPlayTimeSeconds], a
	ld a, [sPlayTimeMinutes + 1]
	inc a
	ld [sPlayTimeMinutes + 1], a
	cp 60
	ret nz
	xor a
	ld [sPlayTimeMinutes + 1], a
	ld a, [sPlayTimeHours + 1]
	inc a
	ld [sPlayTimeHours + 1], a
	cp $ff
	ret nz
	ld a, $ff
	ld [sPlayTimeMinutes], a
	ret

CountDownIgnoreInputBitReset: ; 18e36 (6:4e36)
	ld a, [wIgnoreInputCounter]
	and a
	jr nz, .asm_18e40
	ld a, $ff
	jr .asm_18e41
.asm_18e40
	dec a
.asm_18e41
	ld [wIgnoreInputCounter], a
	and a
	ret nz
	ld a, [wd730]
	res 1, a
	res 2, a
	bit 5, a
	res 5, a
	ld [wd730], a
	ret z
	xor a
	ld [hJoyPressed], a
	ld [hJoyHeld], a
	ret
