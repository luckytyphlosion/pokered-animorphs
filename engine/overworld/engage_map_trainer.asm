_EngageMapTrainer:
	ld hl, wMapSpriteExtraData
	ld d, $0
	ld a, [wSpriteIndex]
	dec a
	add a
	ld e, a
	add hl, de     ; seek to engaged trainer data
	ld a, [hli]    ; load trainer class
	ld [wEngagedTrainerClass], a
	ld a, [hl]     ; load trainer mon set
	ld [wEnemyMonAttackMod], a

PlayTrainerMusic:: ; 33e8 (0:33e8)
	ld a, [wEngagedTrainerClass]
	cp OPP_SONY1
	ret z
	cp OPP_SONY2
	ret z
	cp OPP_SONY3
	ret z
	ld a, [wGymLeaderNo]
	and a
	ret nz
	xor a
	ld [wAudioFadeOutControl], a
	ld a, $ff
	call PlaySound
	ld a, BANK(Music_MeetEvilTrainer)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, [wEngagedTrainerClass]
	ld b, a
	ld hl, EvilTrainerList
.evilTrainerListLoop
	ld a, [hli]
	cp $ff
	jr z, .noEvilTrainer
	cp b
	jr nz, .evilTrainerListLoop
	ld a, MUSIC_MEET_EVIL_TRAINER
	jr .PlaySound
.noEvilTrainer
	ld hl, FemaleTrainerList
.femaleTrainerListLoop
	ld a, [hli]
	cp $ff
	jr z, .maleTrainer
	cp b
	jr nz, .femaleTrainerListLoop
	ld a, MUSIC_MEET_FEMALE_TRAINER
	jr .PlaySound
.maleTrainer
	ld a, MUSIC_MEET_MALE_TRAINER
.PlaySound
	ld [wNewSoundID], a
	jp PlaySound

INCLUDE "data/trainer_types.asm"