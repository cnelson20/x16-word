.DEFINE CHROUT $FFD2
.DEFINE keyboard_get $FFE4
.DEFINE mouse_config $FF68
.DEFINE mouse_get $FF6B


.SEGMENT "STARTUP"
.SEGMENT "INIT"
.SEGMENT "ONCE"
	jmp setup

.include "operations.s"
.include "cursor.s"

temp: 
	.byte $00
frameCounter:
	.byte $00, $00
key_pressed:
	.byte $00
letters_table:
	.incbin "letters_table.bin"
startup_text:
	.incbin "intro_cr.txt"
newdoc_txt:
	.byte $0D, $0D, $20, $20, $20, $20, $50, $52, $45, $53, $53, $20, $41, $20, $4C, $45, $54, $54, $45, $52, $20, $4B, $45, $59, $20, $54, $4F, $20, $4E, $41, $4D, $45, $20, $54, $48, $49, $53, $20, $44, $4F, $43, $55, $4D, $45, $4E, $54, $2E
opendoc_txt:
	.byte $0D, $0D, $20, $20, $20, $20, $50, $52, $45, $53, $53, $20, $54, $48, $45, $20, $4C, $45, $54, $54, $45, $52, $20, $4F, $46, $20, $54, $48, $45, $20, $46, $49, $4C, $45, $20, $59, $4F, $55, $20, $57, $41, $4E, $54, $20, $54, $4F, $20, $4F, $50, $45, $4E, $2E
top_text:
	.byte $57, $4F, $52, $44, $20, $58, $31, $36, $20, $20
document_filename:
	.byte "a.txt"

cursor_x:
	.byte $00
cursor_y:
	.byte $00
restart: 
	jsr reset_irq_handler
setup:
	cld ; clear decimal ; 
	
	jsr preserve_default_irq
	jsr setupMouse
	lda #$0E
	jsr CHROUT
	lda #$93
	jsr CHROUT
	
	ldx #$00
	@textLoop:
	lda startup_text,X
	jsr CHROUT
	inx
	cpx #153
	bcc @textLoop
	
	@l:
	jsr keyboard_get
	cmp #$85 ; F1 key
	beq newDoc
	cmp #$89 ; F2 key
	bne @d 
	jmp loadDoc
	@d:
	
	sec 
	jsr handleMouse
	cmp #$01
	bne @l 
	
	; mouse is clicked ; 
	lda cursor_y
	cmp #06
	beq @f1_y
	cmp #08
	beq @f2_y 	
	
	jmp @l
	
	@f1_y:
	lda cursor_x
	cmp #04
	bcc @l 
	cmp #53
	bcs @l
	jmp newDoc
	
	@f2_y:
	lda cursor_x
	cmp #04
	bcc @l 
	cmp #57
	bcs @l
	jmp loadDoc

newDoc:
	lda #$93
	jsr CHROUT
	ldx #$00
	@t_l:
	lda newdoc_txt,X
	jsr CHROUT
	inx
	cpx #47
	bcc @t_l
	
	jsr getLetterKey
	
	; reserve space in ram ; 
	lda #$80
	sta $03 ; r0h
	lda #$00
	sta $02 ; r0l
	lda #$18
	sta $05 ; r1h
	lda #$00
	sta $04 ; r1l
	
	lda #$20
	jsr $FEE4 ; memory_fill
	
	lda #$80
	sta $10
	lda #80
	sta $11
	
	ldx #$02
	@l:
	lda #$0A
	ldy #80
	sta ($10),Y 
	
	lda $10
	adc #80
	sta $10 
	lda $11
	adc #$00
	sta $11
	
	inx 
	cpx #58
	bcc @l
	
	jmp main
	
loadDoc:
	lda #$93
	jsr CHROUT
	ldx #$00
	@t_l:
	lda opendoc_txt,X
	jsr CHROUT
	inx
	cpx #52
	bcc @t_l
	
	jsr getLetterKey
	
	lda #$80
	sta $03 ; r0h
	sta $11
	lda #$00
	sta $02 ; r0l
	sta $10
	lda #$18
	sta $05 ; r1h
	lda #$00
	sta $04 ; r1l
	
	lda #$20
	jsr $FEE4 ; memory_fill
	
	jsr load ; load document ; 
		
	jmp main ; skip over this

getLetterKey:
	@waitKey:
	jsr keyboard_get
	
	cmp #$41 ; >= A
	bcc @waitKey
	cmp #$5B ; < Z
	bcs @waitKey
	sta document_filename
	rts
	
main:
	lda #$00
	sta cursor_x
	lda #$02 
	sta cursor_y
	
	lda #$93
	jsr CHROUT ; clear screen ;
	lda #$0E
	jsr CHROUT 
	lda #$0F
	jsr CHROUT 
	
	lda #$20
	sta $9F22
	
	ldx #$00
	stx $9F20
	stx $9F21 
	@l:
	lda top_text,X
	sta $9F23 
	inx 
	cpx #15 ; 10 + 5 (filename)
	bcc @l
	
	ldx #$00
	stx frameCounter+1
	
	lda #$01
	sta $9F21
	@l2_outer:
	ldx #$00
	stx $9F20
	lda #$2D
	@l2:
	sta $9F23 
	inx 
	cpx #80
	bcc @l2
	lda $9F21 
	adc #56
	sta $9F21 
	cmp #$60 
	bcc @l2_outer
	
	lda #$00
	sta $9F20
	ldx #$02
	stx $9F21
	sta $10
	ldy #$80
	sty $11
	ldy #$00
	sty $12 
	
	@loop_lRam:
	ldy #$00
	lda ($10),Y
	sta $9F23 
	
	clc
	lda $10
	adc #$01
	sta $10 
	lda $11
	adc #$00
	sta $11
	
	ldy $12 
	iny  
	sty $12 
	cpy #80
	bcc @loop_lRam
	
	ldy #$00
	sty $9F20
	sty $12 
	
	inx 
	stx $9F21 
	cpx #58
	bcc @loop_lRam
	
	jsr set_custom_irq_handler
	
main_loop:
	jsr handleMouse
	cmp #$01
	bne @mouseNotPressed
	ldx cursor_x
	ldy cursor_y
	@mouseNotPressed:
	
	jsr keyboard_get
	sta key_pressed
	cmp #$00
	beq main_loop
	tax
	lda letters_table,X
	cmp #$01
	beq @type 
	
	txa 
	cmp #134 ; f3
	bne @not134 
	jsr save ; save file to disk 
	@not134:
	cmp #138 ; f4
	bne @not138 ; save & quit 
	jsr save;
	jmp end 
	@not138: 
	cmp #139 ; f6 
	bne @not139 ; quit w/o save 
	jmp end 
	@not139: 
	cmp #136 ; f7
	bne @not136 ; go to menu
	jmp restart 
	@not136:
	
	cmp #$91 ; up
	bne @notUp
	jsr cursor_up
	jmp main_loop
	@notUp:
	cmp #$11 ; down
	bne @notDown
	jsr cursor_down
	jmp main_loop
	@notDown:
	cmp #$9D ; left
	bne @notLeft
	jsr cursor_left 
	jmp main_loop
	@notLeft:	
	cmp #$1D ; right
	bne @notRight 
	jsr cursor_right
	jmp main_loop
	@notRight:
	
	cmp #$09
	bne @notTab
	jsr cursor_tab
	jmp main_loop
	@notTab:
	cmp #$0D ; return
	bne @notReturn 
	jsr cursor_return 
	jmp main_loop
	@notReturn:	
	cmp #$14 ; delete
	bne @notDelete
	jsr cursor_left
	lda #$20
	sta key_pressed
	jsr manageChar
	jsr cursor_left
	jmp main_loop
	@notDelete:

	jmp main_loop

	@type:
	jsr manageChar
	
	jmp main_loop
	
end:	
	lda #$00 ; turn off mouse
	ldx #$00
	jsr mouse_config
	
	jsr reset_irq_handler
	
	sec ; cold start for basic 
	jmp $FF47 ; go back to basic ;
	;rts ;  not necessary at all

manageChar:
	; send key pressed to screen ;
	ldx key_pressed
	
	lda cursor_y
	sta $9F21 
	lda cursor_x
	cmp #80
	bcs @saveRAM
	asl
	sta $9F20 
	stx $9F23 
	
	@saveRAM:
	; save it to ram ;
	ldx cursor_y 
	dex
	dex 
	ldy #80 
	jsr multiply
	
	lda $11
	clc 
	adc #$80 ; starts at $8000
	sta $11 
	
	lda key_pressed
	ldy cursor_x
	sta ($10),Y 
	
	jsr cursor_right
	
	rts 

cursor_left:
	ldx cursor_x
	dex 
	cpx #$FF
	stx cursor_x 
	bne @end	
	
	ldx cursor_y 
	dex 
	cpx #02
	bcc @pre 
	stx cursor_y
	ldx #79 
	stx cursor_x 
	jmp @end 
	
	@pre:
	ldx #$00
	stx cursor_x
	@end:
	rts 
cursor_right:
	ldx cursor_x
	inx 
	cpx #80
	bcs cursor_return 
	stx cursor_x 
	rts 
cursor_up:
	ldx cursor_y
	dex  
	cpx #02
	bcc @end 
	stx cursor_y
	@end:
	rts 
cursor_down:
	ldx cursor_y
	inx 
	cpx #58
	bcs @end
	stx cursor_y
	@end:
	rts 
cursor_tab:
	ldy #$04
	@l2:
	jsr cursor_right
	dey 
	cpy #$00
	bne @l
	rts 
	@l:
	lda cursor_x 
	cmp #$00
	beq @eL
	lsr A
	bcc @l2
	lsr A
	bcc @l2
	@eL:
	rts
cursor_return:
	ldx cursor_y
	inx 
	cpx #58
	bcs @end 
	stx cursor_y
	ldx #$00
	stx cursor_x 
	@end:
	rts 

load: 
	lda #$FF ; file #
	ldx #$08 ; device no #8 (sd card / disk drive)
	ldy #$FF ; needs to be here 
	jsr $FFBA
	
	lda #$05 ; filename length 5 "x.txt"
	ldx #.lobyte(document_filename)
	ldy #.hibyte(document_filename)
	jsr $FFBD ; SETNAM
	
	lda #$00 ; load 
	ldx #$00 ; low byte, address to load to
	ldy #$80 ; high byte 
	jsr $FFD5 ; load
	
	rts
	
save:
	lda #$FF ; logical file
	ldx #$08 ; device number
	ldy #$FF ; secondary address (nothing)
	jsr $FFBA
	
	lda #$05 ; filename length 5 "x.txt"
	ldx # .lobyte(document_filename)
	ldy # .hibyte(document_filename)
	jsr $FFBD ; SETNAM
	lda #$80
	sta $11
	lda #$00
	sta $10
	
	lda #$10
	ldy #( $80 + $11 ) ; starting address + 4480 bytes (1180 hex)
	ldx #$80
	jsr $FFD8
	
	bcs @e
	jsr display_save_text
	@e:
	rts

setupMouse:
	lda #$01 ; turn mouse on, dont change shape 
	ldx #$01 ; 640 x 480
	jsr mouse_config
	rts 
handleMouse:
	jsr mouse_get
	and #$01
	cmp #$01
	bne @end 
	tay
	cmp #$01

	lda $00,X
	lsr
	lsr 
	lsr
	sta $00,X
	lda $01,X
	clc
	ror A
	ror A
	ror A
	ror A
	adc $00,X
	sta cursor_x 
	
	lda $02,X
	lsr
	lsr 
	lsr
	sta $02,X
	lda $03,X
	clc
	ror A
	ror A
	ror A
	ror A
	adc $02,X
	sta cursor_y
	
	tya 
	@end:
	rts

