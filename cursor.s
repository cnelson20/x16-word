old_cursor:
	.byte $00, $00
cursor_color:
	.byte $00
color_table:
	.byte $61, $16
Default_irq_handler: 
	.byte $00, $00
bottom_text:
	.byte "f3=save f4=save&quit f6=quit f7=menu"
save_text:
	.byte $53, $41, $56, $45, $44, $21
set_custom_irq_handler:
    sei
    lda #<custom_irq_handler
    sta $0314
    lda #>custom_irq_handler
    sta $0315
    cli
    rts

reset_irq_handler: 
	sei
    lda Default_irq_handler
    sta $0314
    lda Default_irq_handler+1
    sta $0315
    cli
	rts 
	
preserve_default_irq:
    lda $0314
    sta Default_irq_handler
    lda $0315
    sta Default_irq_handler+1
    rts
	
custom_irq_handler:
    lda $9F27
    and #$01
    beq @irq_done
	; vsync ;
	inc frameCounter
	
	ldx frameCounter+1
	cpx #$00
	bne @skip
	jsr write_text
	@skip:
	dex 
	stx frameCounter+1
	
	jsr cursor_control 

    @irq_done:
    jmp (Default_irq_handler)

write_text:
	ldx #$00
	stx $9F20
	lda #59
	sta $9F21 
	lda #$20
	sta $9F22 
	@l:
	lda bottom_text,X
	sta $9F23 
	inx 
	cpx #36
	bcc @l

	ldx #$00
	rts 
cursor_control:
	lda old_cursor+1
	cmp cursor_y
	bne @fixOldCursor
	lda old_cursor
	cmp cursor_x
	bne @fixOldCursor_b
	
	lda frameCounter
	lsr A
	bcs @end 
	lsr A
	bcs @end
	lsr A
	bcs @end
	lsr A
	bcs @end
	
	jmp @toggleNewCursor
	
	@fixOldCursor:
	lda old_cursor
	@fixOldCursor_b:
	asl 
	clc 
	adc #$01
	sta $9F20
	lda old_cursor+1
	sta $9F21
	
	ldy #$61
	sty $9F23
	
	@toggleNewCursor:
	lda cursor_x
	sta old_cursor
	asl 
	clc 
	adc #$01
	sta $9F20
	lda cursor_y
	sta old_cursor+1
	sta $9F21
	
	lda #$01
	eor cursor_color
	sta cursor_color
	tay 
	ldx color_table,y
	stx $9F23 

	@end:
	rts 
display_save_text:
	ldx #$00
	stx $9F20
	lda #59
	sta $9F21 
	lda #$20
	sta $9F22 
	@l:
	lda save_text,X
	sta $9F23 
	inx 
	cpx #6
	bcc @l
	
	ldx #$80
	stx frameCounter+1
	rts
	