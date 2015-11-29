PewterGuys: ; 37ca1 (d:7ca1)
	ld hl, wSimulatedJoypadStatesEnd
	ld a, [wSimulatedJoypadStatesIndex]
	dec a ; this decrement causes it to overwrite the last byte before $FF in the list
	ld [wSimulatedJoypadStatesIndex], a
	ld d, 0
	ld e, a
	add hl, de
	ld d, h
	ld e, l
	ld hl, PointerTable_37ce6
	ld a, [wWhichPewterGuy]
	add a
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wYCoord]
	ld b, a
	ld a, [wXCoord]
	ld c, a
	push de
	ld a, [hli]
	ld d, a
.findMatchingCoordsLoop
	ld a, [hli]
	cp b
	jr nz, .nextEntry1
	ld a, [hli]
	cp c
	jr nz, .nextEntry2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop de
.copyMovementDataLoop
	ld a, h
	cp $40
	ld a, [wSimulatedJoypadStatesIndex]
	jp nc, CopyUntilFF
	ld a, $40
	add h
	ld h, a
	jp BrockThroughWallsCopyOriginalData
.nextEntry1
	inc hl
.nextEntry2
	inc hl
	inc hl
	ld a, d
	and a
	jr z, .findMatchingCoordsLoop
	dec d
	jr nz, .findMatchingCoordsLoop
.alignPointerLoop
	ld a, l
	and $f
	inc hl
	cp $2
	jr z, .alignedPointer
	cp $6
	jr z, .alignedPointer
	cp $a
	jr z, .alignedPointer
	cp $e
	jr nz, .alignPointerLoop
.alignedPointer
	dec hl
	jr .findMatchingCoordsLoop
	
PointerTable_37ce6: ; 37ce6 (d:7ce6)
	dw PewterMuseumGuyCoords
	dw PewterGymGuyCoords

; these are the four coordinates of the spaces below, above, to the left and
; to the right of the museum guy, and pointers to different movements for
; the player to make to get positioned before the main movement.
PewterMuseumGuyCoords: ; 37cea (d:7cea)
	db (.end - .start) / 4
.start
	db 18, 27
	dw .down
	db 16, 27
	dw .up
	db 17, 26
	dw .left
	db 17, 28
	dw .right
.end
	
.down
	db D_UP, D_UP, $ff
.up
	db D_RIGHT, D_LEFT, $ff
.left
	db D_UP, D_RIGHT, $ff
.right
	db D_UP, D_LEFT, $ff

; these are the five coordinates which trigger the gym guy and pointers to
; different movements for the player to make to get positioned before the
; main movement
; $00 is a pause
PewterGymGuyCoords: ; 37d06 (d:7d06)
	db (.end - .start) / 4
.start
	db 16, 34
	dw .one
	db 17, 35
	dw .two
	db 18, 37
	dw .three
	db 19, 37
	dw .four
	db 17, 36
	dw .five
.end
	
.one
	db D_LEFT, D_DOWN, D_DOWN, D_RIGHT, $ff
.two
	db D_LEFT, D_DOWN, D_RIGHT, D_LEFT, $ff
.three
	db D_LEFT, D_LEFT, D_LEFT, $00, $00, $00, $00, $00, $00, $00, $00, $ff
.four
	db D_LEFT, D_LEFT, D_UP, D_LEFT, $ff
.five
	db D_LEFT, D_DOWN, D_LEFT, $00, $00, $00, $00, $00, $00, $00, $00, $ff
