TrueIGT_TM:
	ld hl, wPlayTimeFrames
	xor a
	ld [wMultiplyBy60Power], a
	ld a, [hld]
	call MultiplyBy60ToThewcd3d
	ld a, [hld]
	call MultiplyBy60ToThewcd3d
	ld a, [hld]
	call MultiplyBy60ToThewcd3d
	dec hl
	ld a, [hl]
	call MultiplyBy60ToThewcd3d
; total amount of frames = stored in wcd6d
; time to multiply by 24000 (geez)
; first, multiply by 64, i.e. add itself * 6
	ld hl, wBuffer + 5
	ld b, 6
.multiplyBy64Loop_outer
	ld c, 6
	push hl
.multiplyBy64Loop_inner
	ld a, [hl]
	add a
	ld [hl], a
	dec hl
	call c, TrueIGT_TM_HandleCarry
	dec c
	jr nz, .multiplyBy64Loop_inner
	pop hl
	dec b
	jr nz, .multiplyBy64Loop_outer
; second, multiply by 5 three times
; hl is wBuffer + 5 from earlier
	ld b, 3
.multiplyBy5Loop_outer
	xor a
	ld [hHighByteValue], a
	ld c, 6
	push hl
.multiplyBy5Loop_inner
	ld a, [hl]
	push hl
	ld l, a
	ld e, a
	xor a
	ld h, a
	ld d, a
	add hl, hl
	add hl, hl ; multiply by 4
	add hl, de ; multiply by 5
	ld a, [hHighByteValue]
	add l
	jr nc, .noCarry
	inc h
.noCarry
	ld l, a
	ld a, h
	ld [hHighByteValue], a
	ld a, l
	pop hl
	ld [hld], a
	dec c
	jr nz, .multiplyBy5Loop_inner
	pop hl
	dec b
	jr nz, .multiplyBy5Loop_outer
; finally, multiply by 3
	lb bc, 6, 0
; c = hHighByteValue
.multiplyBy3Loop
	ld a, [hl]
	push hl
	ld l, a
	ld e, a
	xor a
	ld h, a
	ld d, a
	add hl, hl ; multiply by 2
	add hl, de ; multiply by 3
	ld a, c
	add l
	jr nc, .noCarry2
	inc h
.noCarry2
	ld l, a
	ld a, h
	ld c, a
	ld a, l
	pop hl
	ld [hld], a
	dec b
	jr nz, .multiplyBy3Loop
; now, time to divide by 23891
; can't use Divide for this as it doesn't support 16-bit division
	ld hl, H_DIVIDEBUFFER
	xor a
	ld [hOldQuotient], a
	rept 5 ; clear scratch space
	ld [hli], a
	endr
	
	ld [hl], a
	
	
	ld hl, TrueIGT_TM_23891_LookupTable
	lb bc, 8, (H_DIVIDEBUFFER + 3) & $ff
	ld d, c
	ld e, 0
.shiftLoop
	ld c, d
	ld a, [hli]
	ld [$ff00+c], a
	inc c
	ld a, [hli]
	ld [$ff00+c], a
	inc c
	ld a, [hli]
	ld [$ff00+c], a
	inc e
	call TrueIGT_TM_StringCmp
	jr c, .goBackOne
	dec b
	jr nz, .shiftLoop
	dec d
	ld hl, TrueIGT_TM_23891_LookupTable
	jr .shiftLoop
.goBackOne
	ld a, 8
	sub b
	ld b, a
	jr .continue
.loop2
	ld c, d
	dec b
	; are we at the beginning of the loop?
.continue
	jr nz, .dontShiftDivideBuffer ; if not, don't wrap around
	ld a, c
	cp (H_DIVIDEBUFFER + 6) & $ff
	ld b, $8
	jr c, .notFinalPart
	cp (H_DIVIDEBUFFER + 7) & $ff
	jr z, .done
	ld b, $6
.notFinalPart
	inc c
	inc d
	ld hl, TrueIGT_TM_23891_LookupTableEnd
	
.dontShiftDivideBuffer
	ld a, [hld]
	ld [$ff00+c], a
	dec c
	ld a, [hld]
	ld [$ff00+c], a
	dec c
	ld a, [hld]
	ld [$ff00+c], a
	
	call TrueIGT_TM_StringCmp
	jr nc, .loop2
	push hl
	ld hl, wBuffer + 5
	
	call TrueIGT_TM_Subtract
	pop hl
	push bc
	ld a, [hOldQuotient]
	ld b, a
	and a
.shiftQuotientLoop
	ld c, (H_QUOTIENT+3) & $ff
	ld a, [$ff00+c]
	sla a
	ld [$ff00+c], a
	dec c
	
	ld a, [$ff00+c]
	rla
	ld [$ff00+c], a
	dec c
	
	ld a, [$ff00+c]
	rla
	ld [$ff00+c], a
	dec c
	
	ld a, [$ff00+c]
	rla
	ld [$ff00+c], a
	dec b
	jr nz, .shiftQuotientLoop
	pop bc
	
	jr .loop2
.done
	
	
	
TrueIGT_TM_Subtract:
	push de
	ld a, [$ff00+c]
	ld e, a
	ld a, [hl]
	sub e
	ld [hld], a
	
	rept 5
	dec c
	ld a, [$ff00+c]
	ld e, a
	ld a, [hl]
	sub e
	ld [hld], a
	endr
	pop de
	ret
	
	; baa6000000 = max value
	
TrueIGT_TM_23891_LookupTable:
	db $00,$5d,$53
	db $00,$ba,$a6
	db $01,$75,$4c
	db $02,$ea,$98
	db $05,$d5,$30
	db $0b,$aa,$60
	db $17,$54,$c0
	db $2e,$a9,$80
TrueIGT_TM_23891_LookupTableEnd:

TrueIGT_TM_StringCmp:
	ld c, H_DIVIDEBUFFER & $ff
	push hl
	ld hl, wBuffer
	ld a, [$ff00+c]
	cp [hl]
	jr c, .returnFalse
	jr nz, .returnTrue
	inc c
	inc hl
	ld a, [$ff00+c]
	cp [hl]
	jr c, .returnFalse
	jr nz, .returnTrue
	inc c
	inc hl
	ld a, [$ff00+c]
	cp [hl]
	jr c, .returnFalse
	jr nz, .returnTrue
	inc c
	inc hl
	ld a, [$ff00+c]
	cp [hl]
	jr c, .returnFalse
	jr nz, .returnTrue
	inc c
	inc hl
	ld a, [$ff00+c]
	cp [hl]
	jr c, .returnFalse
	jr nz, .returnTrue
	inc c
	inc hl
	ld a, [$ff00+c]
	cp [hl]
	jr c, .returnFalse
.returnTrue
	scf
	ret
.returnFalse
	and a
	ret
	
	
TrueIGT_TM_HandleCarry:
	ld d, h
	ld e, l
.handleCarry_loop
	inc [hl]
	dec hl
	jr z, .handleCarry_loop
	ld h, d
	ld l, e
	ret

MultiplyBy60ToThewcd3d:
; return in H_PRODUCT I guess
	ld [wMultiplyBy60Multiplicand], a
	push hl
	ld a, [wMultiplyBy60Power]
	ld hl, MultiplyBy60JumpTable
	and $3
	add a
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wMultiplyBy60Multiplicand]
	call _hl_
	lb bc, 4, (H_PRODUCT + 3) & $ff
	ld hl, wBuffer + 3 + 2
.loop
	ld a, [$ff00+c]
	add [hl]
	ld [hl], a
	dec hl
	call c, TrueIGT_TM_HandleCarry
	dec b
	jr nz, .loop
	pop hl
	ld a, [wMultiplyBy60Power]
	inc a
	ld [wMultiplyBy60Power], a
	ret

	
	
MultiplyBy60JumpTable:
	dw MultiplyBy60_Power0
	dw MultiplyBy60_Power1
	dw MultiplyBy60_Power2
	dw MultiplyBy60_Power3
	
MultiplyBy60_Power0:
	ld [H_PRODUCT+3], a
	ret
	
MultiplyBy60_Power1:
	ld l, a
	ld h, 0
; multiply by 4
	add hl, hl
	add hl, hl
; mutliply by 3
	ld b, h
	ld c, l
	ld a, $3
	call AddNTimes
; mutiply by 5
	ld b, h
	ld c, l
	ld a, $5
	call AddNTimes
	ld a, h
	ld [H_PRODUCT+2], a
	ld a, l
	ld [H_PRODUCT+3], a
	ret
	
MultiplyBy60_Power2:
	call MultiplyBy60_Power1
	add hl, hl ; multiply by 4 again
	add hl, hl ; max value: $3750
; multiply by 3
	ld b, h
	ld c, l
	ld a, $3
	call AddNTimes ; max value: $af50
; use multiply for this one
	ld c, H_MULTIPLICAND & $ff
	xor a
	ld [$ff00+c], a ; H_MULTIPLICAND
	inc c
	ld a, h
	ld [$ff00+c], a ; H_MULTIPLICAND + 1
	inc c
	ld a, l
	ld [$ff00+c], a ; H_MULTIPLICAND + 2
	inc c
	ld a, $5
	ld [$ff00+c], a ; H_MULTIPLIER
	jp Multiply ; result is automatically stored in H_PRODUCT
	
MultiplyBy60_Power3:
; MultiplyBy60_Power2 assumes the max value is 59
; so we can't call that then MultiplyBy60 again
	call MultiplyBy60_Power1
	ld c, H_MULTIPLICAND & $ff
	xor a
	ld [$ff00+c], a ; H_MULTIPLICAND
	inc c
	ld a, h
	ld [$ff00+c], a ; H_MULTIPLICAND + 1
	inc c
	ld a, l
	ld [$ff00+c], a ; H_MULTIPLICAND + 2
	inc c
	ld a, 60
	ld [$ff00+c], a ; H_MULTIPLIER
	call Multiply
; no need to copy over H_PRODUCT as they overlap
	ld a, 60
	ld [$ff00+c], a
; multiply again
	jp Multiply
	