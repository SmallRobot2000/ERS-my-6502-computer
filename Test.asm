ACIA_DATA   = $0400
ACIA_STATUS = $0401
ACIA_CMD    = $0402
ACIA_CTRL   = $0403

    org $c000
main:
  jsr init_acia

loop:
    lda #65
    jsr acia_send_char
    jmp loop

init_acia:
    pha
    stz ACIA_STATUS ; clear status register
    lda #%00011110  ; 8-N-1, 9600 baud
    sta ACIA_CTRL   ; set control register
    lda #%00001011  ; No parity or rcv echo, RTS true, receive IRQ but no
    sta ACIA_CMD    ; set command register
    pla
    rts

acia_send_char:
    pha
    sta ACIA_DATA  
    
    ldx #$FF
tx_delay1:
    lda #$FF
tx_delay:
    dec
    nop
    nop
    nop
    bne tx_delay
    dex
    bne tx_delay1
    pla
    rts