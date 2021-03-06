HPBarLength: ; f9dc (3:79dc)
	call GetPredefRegisters

; calculates bc * 48 / de, the number of pixels the HP bar has
; the result is always at least 1
GetHPBarLength: ; f9df (3:79df)
	push hl
	xor a
	ld hl, H_MULTIPLICAND
	ld [hli], a
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	ld [hl], $30
	call Multiply      ; 48 * bc (hp bar is 48 pixels long)
	ld a, d
	and a
	jr z, .maxHPSmaller256
	srl d              ; make HP in de fit into 1 byte by dividing by 4
	rr e
	srl d
	rr e
	ld a, [H_MULTIPLICAND+1]
	ld b, a
	ld a, [H_MULTIPLICAND+2]
	srl b              ; divide multiplication result as well
	rr a
	srl b
	rr a
	ld [H_MULTIPLICAND+2], a
	ld a, b
	ld [H_MULTIPLICAND+1], a
.maxHPSmaller256
	ld a, e
	ld [H_DIVISOR], a
	ld b, $4
	call Divide
	ld a, [H_MULTIPLICAND+2]
	ld e, a            ; e = bc * 48 / de (num of pixels of HP bar)
	pop hl
	and a
	ret nz
	ld e, $1           ; make result at least 1
	ret

; predef $48
UpdateHPBar: ; fa1d (3:7a1d)
UpdateHPBar2:
	push hl
	ld hl, wHPBarOldHP
	ld a, [hli]
	ld c, a      ; old HP into bc
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld e, a      ; new HP into de
	ld d, [hl]
	pop hl
	push de
	push bc
	call UpdateHPBar_CalcHPDifference
	ld a, e
	ld [wHPBarHPDifference+1], a
	ld a, d
	ld [wHPBarHPDifference], a
	pop bc
	pop de
	call UpdateHPBar_CompareNewHPToOldHP
	ret z
	ld a, $ff
	jr c, .HPdecrease
	ld a, $1
.HPdecrease
	ld [wHPBarDelta], a
	call GetPredefRegisters
	ld a, [wHPBarNewHP]
	ld e, a
	ld a, [wHPBarNewHP+1]
	ld d, a
	ld a, [wIsInBattle]
	and a
	jp nz, .updateHPBar_NoAnimation
.animateHPBarLoop
	push de
	ld a, [wHPBarOldHP]
	ld c, a
	ld a, [wHPBarOldHP+1]
	ld b, a
	call UpdateHPBar_CompareNewHPToOldHP
	jr z, .animateHPBarDone
	jr nc, .HPIncrease
	dec bc        ; subtract 1 HP
	ld a, c
	ld [wHPBarNewHP], a
	ld a, b
	ld [wHPBarNewHP+1], a
	call UpdateHPBar_CalcOldNewHPBarPixels
	ld a, e
	sub d         ; calc pixel difference
	jr .asm_fa7e
.HPIncrease
	inc bc        ; add 1 HP
	ld a, c
	ld [wHPBarNewHP], a
	ld a, b
	ld [wHPBarNewHP+1], a
	call UpdateHPBar_CalcOldNewHPBarPixels
	ld a, d
	sub e         ; calc pixel difference
.asm_fa7e
	call UpdateHPBar_PrintHPNumber
	and a
	jr z, .noPixelDifference
	call UpdateHPBar_AnimateHPBar
.noPixelDifference
	ld a, [wHPBarNewHP]
	ld [wHPBarOldHP], a
	ld a, [wHPBarNewHP+1]
	ld [wHPBarOldHP+1], a
	pop de
	jr .animateHPBarLoop
.animateHPBarDone
	pop de
	ld a, e
	ld [wHPBarOldHP], a
	ld a, d
	ld [wHPBarOldHP+1], a
	or e
	jr z, .monFainted
	call UpdateHPBar_CalcOldNewHPBarPixels
	ld d, e
.monFainted
	call UpdateHPBar_PrintHPNumber
	ld a, $1
	call UpdateHPBar_AnimateHPBar
	jp Delay3
.updateHPBar_NoAnimation
	push de
	ld c, e
	ld b, d ; store new HP in bc
	
	ld a, [wHPBarMaxHP]
	ld e, a
	ld a, [wHPBarMaxHP+1]
	ld d, a ; get max HP
	
	call GetHPBarLength ; get HP Bar length
; e = number of pixels in hp bar
	ld d, $6 ; number of tiles
	call DrawHPBar
	jr .animateHPBarDone
	
	
; animates the HP bar going up or down for (a) ticks (two waiting frames each)
; stops prematurely if bar is filled up
; e: current health (in pixels) to start with
UpdateHPBar_AnimateHPBar: ; fab1 (3:7ab1)
	push hl
.barAnimationLoop
	push af
	push de
	ld d, $6
	call DrawHPBar
	call DelayFrame
	pop de
	ld a, [wHPBarDelta] ; +1 or -1
	add e
	cp $31
	jr nc, .barFilledUp
	ld e, a
	pop af
	dec a
	jr nz, .barAnimationLoop
	pop hl
	ret
.barFilledUp
	pop af
	pop hl
	ret

; compares old HP and new HP and sets c and z flags accordingly
UpdateHPBar_CompareNewHPToOldHP: ; fad1 (3:7ad1)
	ld a, d
	sub b
	ret nz
	ld a, e
	sub c
	ret

; calcs HP difference between bc and de (into de)
UpdateHPBar_CalcHPDifference: ; fad7 (3:7ad7)
	ld a, d
	sub b
	jr c, .oldHPGreater
	jr z, .testLowerByte
.newHPGreater
	ld a, e
	sub c
	ld e, a
	ld a, d
	sbc b
	ld d, a
	ret
.oldHPGreater
	ld a, c
	sub e
	ld e, a
	ld a, b
	sbc d
	ld d, a
	ret
.testLowerByte
	ld a, e
	sub c
	jr c, .oldHPGreater
	jr nz, .newHPGreater
	ld de, $0
	ret

UpdateHPBar_PrintHPNumber: ; faf5 (3:7af5)
	push af
	push de
	ld a, [wHPBarType]
	and a
	jr z, .done ; don't print number in enemy HUD
; convert from little-endian to big-endian for PrintNumber
	ld a, [wHPBarOldHP]
	ld [wHPBarTempHP + 1], a
	ld a, [wHPBarOldHP + 1]
	ld [wHPBarTempHP], a
	push hl
	ld a, [hFlags_0xFFF6]
	bit 0, a
	jr z, .asm_fb15
	ld de, $9
	jr .next
.asm_fb15
	ld de, $15
.next
	add hl, de
	push hl
	ld a, " "
	ld [hli], a
	ld [hli], a
	ld [hli], a
	pop hl
	ld de, wHPBarTempHP
	lb bc, 2, 3
	call PrintNumber
	call DelayFrame
	pop hl
.done
	pop de
	pop af
	ret

; calcs number of HP bar pixels for old and new HP value
; d: new pixels
; e: old pixels
UpdateHPBar_CalcOldNewHPBarPixels: ; fb30 (3:7b30)
	push hl
	
	ld hl, wHPBarMaxHP
	ld a, [hli]  ; max HP into de
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]  ; old HP into bc
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]  ; new HP into hl
	ld h, [hl]
	ld l, a
	
	push hl
	push de
	call GetHPBarLength ; calc num pixels for old HP
	ld a, e
	pop de
	pop bc
	
	push af
	call GetHPBarLength ; calc num pixels for new HP
	pop af
	ld d, e
	ld e, a
	
	pop hl
	ret
