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
      jmp main    ;test sd
;      lda #SPI0_CE_BIT|SPI0_CLK_BIT|SPI0_DATA_BIT_OUT
;      sta DDRA
;      lda #SPI0_CE_BIT ;set SPI
;      sta PORT_A
;
;
;      lda #$01
;      jsr SPI0_SEL
;      lda #$80
;      jsr SPI0_send
;      lda #$00
;      jsr SPI0_send
;      lda #'A'
;      jsr SPI0_send
;      lda #$00
;      jsr SPI0_SEL
;
;      lda #$01
;      jsr SPI0_SEL
;      lda #$00
;      jsr SPI0_send
;      lda #$00
;      jsr SPI0_send
;      jsr SPI0_receve
;      pha
;      lda #$00
;      jsr SPI0_SEL
;      pla
;      jsr printHex
;loop:
;      jmp *
;      lda #$01
;      jsr SPI0_SEL
;      lda #$80
;      jsr SPI0_send
;      lda #$00
;      jsr SPI0_send
;      lda #'A'
;      jsr SPI0_send
;      lda #$00
;      jsr SPI0_SEL
;      jsr wait
;      jsr wait
;      jsr wait
;      jsr wait
;      jsr wait
;      jsr wait
;      jsr wait
;      jsr wait
;      jmp loop
wait:
    phx
    phy
    ldx #$FF
    ldy #$02
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
hex_print_byte:
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
shell_newline:
      pha
      lda #10
      jsr wait
      sta ACIA_DATA
      jsr wait
      lda #13
      sta ACIA_DATA
      jsr wait
      pla
      rts

print_char:
acia_print_char:
      pha
      jsr wait
      sta ACIA_DATA
      jsr wait
      pla
      rts
HEXarray:
    byte '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'

sys_exit:
      jsr shell_newline
      lda #'E'
      jsr acia_print_char
      lda #'n'
      jsr acia_print_char
      lda #'d'
      jsr acia_print_char
      jmp *
;===============================================================================================================================================

PORTA = PORT_A

;DDRA = DDRA


SD_CS   = SPI0_CE1_BIT
SD_SCK  = SPI0_CLK_BIT
SD_MOSI = SPI0_DATA_BIT_OUT
SD_MISO = SPI0_DATA_BIT_IN

PORTA_OUTPUTPINS = SD_CS | SD_SCK | SD_MOSI

zp_sd_cmd_address = $40

main:
reset:
  ldx #$ff
  txs

  lda #%11111111          ; Set all pins on port B to output
  sta DDRB
  lda #PORTA_OUTPUTPINS   ; Set various pins on port A to output
  sta DDRA


  jsr sd_init


  ; Read a sector
  lda #'r'
  jsr print_char
  lda #'s'
  jsr print_char
  lda #':'
  jsr print_char

  lda #SD_MOSI
  sta PORTA

  ; Command 17, arg is sector number, crc not checked
  lda #$51           ; CMD17 - READ_SINGLE_BLOCK
  jsr sd_writebyte
  lda #$00           ; sector 24:31
  jsr sd_writebyte
  lda #$00           ; sector 16:23
  jsr sd_writebyte
  lda #$00           ; sector 8:15
  jsr sd_writebyte
  lda #$00           ; sector 0:7
  jsr sd_writebyte
  lda #$01           ; crc (not checked)
  jsr sd_writebyte

  jsr sd_waitresult
  cmp #$00
  beq .readsuccess

  lda #'f'
  jsr print_char
  jmp loop

.readsuccess
  lda #'s'
  jsr print_char
  lda #':'
  jsr print_char

  ; wait for data
  jsr sd_waitresult
  cmp #$fe
  beq .readgotdata

  lda #'f'
  jsr print_char
  jmp loop

.readgotdata
  ; Need to read 512 bytes.  Read two at a time, 256 times.
  lda #0
  sta $00 ; counter
.readloop
  jsr sd_readbyte
  sta $01 ; byte1
  jsr sd_readbyte
  sta $02 ; byte2
  dec $00 ; counter
  bne .readloop

  ; End command
  lda #SD_CS | SD_MOSI
  sta PORTA

  ; Print the last two bytes read, in hex
  lda $01 ; byte1
  jsr print_hex
  lda $02 ; byte2
  jsr print_hex


  ; loop forever
loop:
  jmp loop



sd_init:
  ; Let the SD card boot up, by pumping the clock with SD CS disabled

  ; We need to apply around 80 clock pulses with CS and MOSI high.
  ; Normally MOSI doesn't matter when CS is high, but the card is
  ; not yet is SPI mode, and in this non-SPI state it does care.

  lda #SD_CS | SD_MOSI
  ldx #160               ; toggle the clock 160 times, so 80 low-high transitions
.preinitloop:
  eor #SD_SCK
  sta PORTA
  dex
  bne .preinitloop
  

.cmd0 ; GO_IDLE_STATE - resets card to idle state, and SPI mode
  lda #<cmd0_bytes
  sta zp_sd_cmd_address
  lda #>cmd0_bytes
  sta zp_sd_cmd_address+1

  jsr sd_sendcommand

  ; Expect status response $01 (not initialized)
  cmp #$01
  bne .initfailed

.cmd8 ; SEND_IF_COND - tell the card how we want it to operate (3.3V, etc)
  lda #<cmd8_bytes
  sta zp_sd_cmd_address
  lda #>cmd8_bytes
  sta zp_sd_cmd_address+1

  jsr sd_sendcommand

  ; Expect status response $01 (not initialized)
  cmp #$01
  bne .initfailed

  ; Read 32-bit return value, but ignore it
  jsr sd_readbyte
  jsr sd_readbyte
  jsr sd_readbyte
  jsr sd_readbyte

.cmd55 ; APP_CMD - required prefix for ACMD commands
  lda #<cmd55_bytes
  sta zp_sd_cmd_address
  lda #>cmd55_bytes
  sta zp_sd_cmd_address+1

  jsr sd_sendcommand

  ; Expect status response $01 (not initialized)
  cmp #$01
  bne .initfailed

.cmd41 ; APP_SEND_OP_COND - send operating conditions, initialize card
  lda #<cmd41_bytes
  sta zp_sd_cmd_address
  lda #>cmd41_bytes
  sta zp_sd_cmd_address+1

  jsr sd_sendcommand

  ; Status response $00 means initialised
  cmp #$00
  beq .initialized

  ; Otherwise expect status response $01 (not initialized)
  cmp #$01
  bne .initfailed

  ; Not initialized yet, so wait a while then try again.
  ; This retry is important, to give the card time to initialize.
  jsr delay
  jmp .cmd55


.initialized
  lda #'Y'
  jsr print_char
  rts

.initfailed
  lda #'X'
  jsr print_char
.loop
  jmp .loop


cmd0_bytes
  byte $40, $00, $00, $00, $00, $95
cmd8_bytes
  byte $48, $00, $00, $01, $aa, $87
cmd55_bytes
  byte $77, $00, $00, $00, $00, $01
cmd41_bytes
  byte $69, $40, $00, $00, $00, $01



sd_readbyte:
  ; Enable the card and tick the clock 8 times with MOSI high, 
  ; capturing bits from MISO and returning them

  ldx #8                      ; we'll read 8 bits
.loop:

  lda #SD_MOSI                ; enable card (CS low), set MOSI (resting state), SCK low
  sta PORTA

  lda #SD_MOSI | SD_SCK       ; toggle the clock high
  sta PORTA

  lda PORTA                   ; read next bit
  and #SD_MISO

  clc                         ; default to clearing the bottom bit
  beq .bitnotset              ; unless MISO was set
  sec                         ; in which case get ready to set the bottom bit
.bitnotset:

  tya                         ; transfer partial result from Y
  rol                         ; rotate carry bit into read result
  tay                         ; save partial result back to Y

  dex                         ; decrement counter
  bne .loop                   ; loop if we need to read more bits

  rts


sd_writebyte:
  ; Tick the clock 8 times with descending bits on MOSI
  ; SD communication is mostly half-duplex so we ignore anything it sends back here

  ldx #8                      ; send 8 bits

.loop:
  asl                         ; shift next bit into carry
  tay                         ; save remaining bits for later

  lda #0
  bcc .sendbit                ; if carry clear, don't set MOSI for this bit
  ora #SD_MOSI

.sendbit:
  sta PORTA                   ; set MOSI (or not) first with SCK low
  eor #SD_SCK
  sta PORTA                   ; raise SCK keeping MOSI the same, to send the bit

  tya                         ; restore remaining bits to send

  dex
  bne .loop                   ; loop if there are more bits to send

  rts


sd_waitresult:
  ; Wait for the SD card to return something other than $ff
  jsr sd_readbyte
  cmp #$ff
  beq sd_waitresult
  rts


sd_sendcommand:
  ; Debug print which command is being executed

  lda #'c'
  jsr print_char
  ldx #0
  lda (zp_sd_cmd_address,x)
  jsr print_hex

  lda #SD_MOSI           ; pull CS low to begin command
  sta PORTA

  ldy #0
  lda (zp_sd_cmd_address),y    ; command byte
  jsr sd_writebyte
  ldy #1
  lda (zp_sd_cmd_address),y    ; data 1
  jsr sd_writebyte
  ldy #2
  lda (zp_sd_cmd_address),y    ; data 2
  jsr sd_writebyte
  ldy #3
  lda (zp_sd_cmd_address),y    ; data 3
  jsr sd_writebyte
  ldy #4
  lda (zp_sd_cmd_address),y    ; data 4
  jsr sd_writebyte
  ldy #5
  lda (zp_sd_cmd_address),y    ; crc
  jsr sd_writebyte

  jsr sd_waitresult
  pha

  ; Debug print the result code
  jsr print_hex

  ; End command
  lda #SD_CS | SD_MOSI   ; set CS high again
  sta PORTA

  pla   ; restore result code
  rts








print_hex:
  pha
  ror
  ror
  ror
  ror
  jsr print_nybble
  pla
print_nybble:
  and #15
  cmp #10
  bmi .skipletter
  adc #6
.skipletter
  adc #48
  jsr print_char
  rts


delay
  ldx #0
  ldy #0
.loop
  dey
  bne .loop
  dex
  bne .loop
  rts

longdelay
  jsr mediumdelay
  jsr mediumdelay
  jsr mediumdelay
mediumdelay
  jsr delay
  jsr delay
  jsr delay
  jmp delay

