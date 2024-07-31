    include "include/ROM_define.asm"
      org $0700

      lda #$FF
      
      sta DDRB
      SEI                     ; NO INTERRUPTS
                                ; INITIALIZE ACIA

        LDA     #$0B            ; TRANSMIT AND RECEIVE, NO INTERRUPTS
        STA     ACIACMD
        LDA     #$10            ; 19200 8 N 1, USE BAUD RATE GENERATOR
        STA     ACIACTL

      lda #SPI0_CE_BIT|SPI0_CLK_BIT|SPI0_DATA_BIT_OUT
      sta DDRA
      lda #SPI0_CE_BIT ;set SPI
      sta PORT_A


      lda #$01
      jsr SPI0_SEL
      lda #$80
      jsr SPI0_send
      lda #$00
      jsr SPI0_send
      lda #'A'
      jsr SPI0_send
      lda #$00
      jsr SPI0_SEL

      lda #$01
      jsr SPI0_SEL
      lda #$00
      jsr SPI0_send
      lda #$00
      jsr SPI0_send
      jsr SPI0_receve
      pha
      lda #$00
      jsr SPI0_SEL
      pla
      jsr printHex
loop:
      jmp *
      lda #$01
      jsr SPI0_SEL
      lda #$80
      jsr SPI0_send
      lda #$00
      jsr SPI0_send
      lda #'A'
      jsr SPI0_send
      lda #$00
      jsr SPI0_SEL
      jsr wait
      jsr wait
      jsr wait
      jsr wait
      jsr wait
      jsr wait
      jsr wait
      jsr wait
      jmp loop
wait:
    phx
    phy
    ldx #$FF
    ldy #$20
.loopY
    ldx #$FF
.loopX
    nop
    nop
    dex
    bne .loopX
    dey
    bne .loopY
    ply
    plx

    rts
;for now != 1 - select
SPI0_SEL:
      cmp #$00
      bne .sel
      lda #SPI0_CE_BIT
      sta PORT_A
      rts
.sel
      lda #$00
      sta PORT_A
      rts

;A - data
SPI0_send:
      pha 
      phx
      phy
      sta SPI_DATA_TMP
      ldy #8
.sloop
      cpy #$00
      beq .send
      lda #$00 ;set CLK low and CE low
      sta PORT_A
      asl SPI_DATA_TMP
      bcs .sb1
.sb0
      lda #$00
      sta PORT_A
      lda #SPI0_CLK_BIT
      nop
      nop
      sta PORT_A
      lda #$00
      sta PORT_A
      dey
      jmp .sloop

.sb1
      lda #SPI0_DATA_BIT_OUT
      sta PORT_A
      lda #SPI0_DATA_BIT_OUT|SPI0_CLK_BIT
      nop
      nop
      sta PORT_A
      lda #SPI0_DATA_BIT_OUT
      sta PORT_A
      dey
      jmp .sloop
.send

      lda #00
      sta PORT_A
      ply
      plx
      pla
      rts


;A - data
SPI0_receve:
      phx
      phy
      stz SPI_DATA_TMP
      ldy #8
.sloop
      cpy #$00
      beq .rend
      lda #$00 ;set CLK low and CE low
      sta PORT_A
      lda #SPI0_CLK_BIT
      nop
      nop
      sta PORT_A
      lda PORT_A
      and #SPI0_DATA_BIT_IN
      bne .rb1
.rb0
      clc
      ror SPI_DATA_TMP
      lda #$00
      sta PORT_A
      dey
      jmp .sloop

.rb1
      sec
      ror SPI_DATA_TMP
      lda #$00
      sta PORT_A
      dey
      jmp .sloop
.rend

      lda #00
      sta PORT_A
      ply
      plx
      lda SPI_DATA_TMP
      rts



;A byte to print in HEX
printHex:
    pha
    phx
    phy
    pha
    and #$F0
    lsr
    lsr
    lsr
    lsr
    tax
    lda HEXarray,X
    sta ACIA_DATA
    jsr wait
    pla
    and #$0F
    tax
    lda HEXarray,X
    sta ACIA_DATA
    jsr wait 
    ply
    plx
    pla
    rts

HEXarray:
    byte '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'