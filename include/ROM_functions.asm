    nop
init_acia:
    pha
    lda #%00011110  ; 8-N-1, 9600 baud
    sta ACIA_CTRL   ; set control register
    lda #%00001011  ; No parity or rcv echo, RTS true, receive IRQ but no
    sta ACIA_CMD    ; set command register
    pla
    rts

acia_wait:
    pha
    phx
    ldx #$FF
.tx_delay1:
    lda #$FF
.tx_delay:
    dec
    nop
    nop
    nop
    bne .tx_delay
    dex
    bne .tx_delay1
    plx
    pla
    rts

acia_send_char:
    jsr acia_wait
    jsr init_acia   ;to be safe
    sta ACIA_DATA  
    jsr acia_wait
    rts




; Like acia_recv_char, but terminates after a short time if nothing is received
shell_rx_receive_with_timeout:

  

  lda ACIA_STATUS
  and #$08
  bne .got
  rts
.got
  lda ACIA_DATA
  pha
  lda #'Y'
  jsr acia_send_char
  jsr acia_wait
  pla
  jsr acia_send_char
  jsr acia_wait
  rts


  