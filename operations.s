.DEFINE RESULT $10
.DEFINE NUM1 $12
.DEFINE NUM2 $13
; stolen ;
multiply:
	 
	lda #$00
	sta $10
	sta $11

	stx NUM1
	sty NUM2
	
    LDA #$80     ;Preload sentinel bit into RESULT
    STA RESULT
    ASL A        ;Initialize RESULT hi byte to 0
	@L1:
	LSR NUM2     ;Get low bit of NUM2
    BCC @L2       ;0 or 1?
    CLC          ;If 1, add NUM1
    ADC NUM1
	@L2:
	ROR A        ;"Stairstep" shift (catching carry from add)
    ROR RESULT
    BCC @L1       ;When sentinel falls off into carry, we're done
    STA RESULT+1
	
	ldx RESULT
	ldy RESULT+1
	rts
	
toHexChars:
	tax
	and #$0F
	cmp #$0A
	bcs @letter
	
	sbc #$06
	@letter:
	clc
	adc #$37
	tay
	
	txa
	and #$F0
	lsr
	lsr
	lsr
	lsr
	cmp #$0A
	bcs @letter2
	
	sbc #$06
	@letter2:
	clc
	adc #$37
	tax
	rts
	