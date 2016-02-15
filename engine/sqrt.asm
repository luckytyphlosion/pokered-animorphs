LongIntegerSqrt:
	ld a, [H_QUOTIENT]
	and a
	jp nz, .sqrt32bit
	ld a, [H_QUOTIENT+1]
	and a
	jp z, .regularSqrt
	ld de, 255 * 255
	ld a, [H_QUOTIENT+3]
	sub e
	ld [H_QUOTIENT+3], a
	ld a, [H_QUOTIENT+2]
	sbc d
	ld [H_QUOTIENT+2], a
	ld a, [H_QUOTIENT+1]
	sbc $0
	ld [H_QUOTIENT+1], a
	ld bc, 509 ; (255 * 2) - 1
	ld de, 255
.sqrtLongLoop_24Bit
	inc de
	inc bc
	inc c
	ld a, [H_QUOTIENT+3]
	sub c
	ld [H_QUOTIENT+3], a
	ld a, [H_QUOTIENT+2]
	sbc b
	ld [H_QUOTIENT+2], a
	ld a, [H_QUOTIENT+1]
	sbc $0
	ld [H_QUOTIENT+1], a
	jr nc, .sqrtLongLoop_24Bit
	ret
.sqrt32bit
	ld de, (4095 * 4095) & $ffff
	ld a, [H_QUOTIENT+3]
	sub e
	ld [H_QUOTIENT+3], a
	ld a, [H_QUOTIENT+2]
	sbc d
	ld [H_QUOTIENT+2], a
	ld a, [H_QUOTIENT+1]
	sbc (4095 * 4095) / $10000
	ld [H_QUOTIENT+1], a
	ld a, [H_QUOTIENT]
	sbc $0
	ld [H_QUOTIENT], a
	ld c, 0
	ld hl, 8189 ; (4095 * 2) - 1
	ld de, 4095
.sqrtLongLoop_32Bit
	inc l
	jr nz, .noCarry
	inc h
	jr nz, .noCarry
	inc c
.noCarry
	inc l
	inc de
	ld a, [H_QUOTIENT+3]
	sub l
	ld [H_QUOTIENT+3], a
	ld a, [H_QUOTIENT+2]
	sbc h
	ld [H_QUOTIENT+2], a
	ld a, [H_QUOTIENT+1]
	sbc c
	ld [H_QUOTIENT+1], a
	ld a, [H_QUOTIENT]
	sbc $0
	ld [H_QUOTIENT], a
	jr nc, .sqrtLongLoop_32Bit
	ret
.regularSqrt
	ld a, [H_QUOTIENT+2]
	ld h, a
	ld a, [H_QUOTIENT+3]
	ld l, a
	ld a, -1
	ld bc, $1
.sqrtHLLoop
	inc a
	dec c
	dec bc
	add hl, bc
	jr c, .sqrtHLLoop
	ld e, a
	ld d, $0
	ret