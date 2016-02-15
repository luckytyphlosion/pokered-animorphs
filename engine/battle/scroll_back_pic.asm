Func_f429f:: ; f429f (3d:429f)
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	coord hl, 0,5
	ld c,$0
.asm_f42a4
	inc c
	ld a,c
	cp $9
	ret z
	ld d,$5b
	push bc
	push hl
.asm_f42ad
	call Func_f42c2
	dec hl
	ld a,d
	sub $7
	ld d,a
	dec c
	jr nz,.asm_f42ad
	ld c,$2
	call DelayFrames
	pop hl
	pop bc
	inc hl
	jr .asm_f42a4
	
Func_f42c2:: ; f42c2 (3d:f42c2)
	push hl
	push de
	push bc
	ld e,$7
.loop
	ld a,d
	cp $31
	jr nc,.asm_f42ce
	ld a,$7f
.asm_f42ce
	ld [hl],a
	ld bc,$14
	add hl,bc
	inc d
	dec e
	jr nz,.loop
	pop bc
	pop de
	pop hl
	ret