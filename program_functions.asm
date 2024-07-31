;SD card stuff
SD_ReadSingleSector:
  ; Read a sector
  ;lda #'r'
  ;jsr print_char
  ;lda #'s'
  ;jsr print_char
  ;lda #':'
  ;jsr print_char

  lda #SD_MOSI
  sta PORTA

  ; Command 17, arg is sector number, crc not checked
  lda #$51           ; CMD17 - READ_SINGLE_BLOCK
  jsr sd_writebyte
  lda SD_sector_id+3           ; sector 24:31
  jsr sd_writebyte
  lda SD_sector_id+2           ; sector 16:23
  jsr sd_writebyte
  lda SD_sector_id+1           ; sector 8:15
  jsr sd_writebyte
  lda SD_sector_id           ; sector 0:7
  jsr sd_writebyte
  lda #$01           ; crc (not checked)
  jsr sd_writebyte

  jsr sd_waitresult
  cmp #$00
  beq .readsuccess
  
  lda #'f'
  jsr print_char
  sec
  rts

.readsuccess
  ;lda #'s'
  ;jsr print_char
  ;lda #':'
  ;jsr print_char

  ; wait for data
  jsr sd_waitresult
  cmp #$fe
  beq .readgotdata
  jsr print_hex
  lda #'f'
  jsr print_char
  sec
  rts

.readgotdata
  ; Need to read 512 bytes.  Read two at a time, 256 times.
  stz SD_tmp_cnt ; counter
  ldy #$00
.readloop
  phy
  jsr sd_readbyte
  ply
  sta (SD_bufferPtr),Y ; byte1
  iny
  dec SD_tmp_cnt ; counter
  bne .readloop

  inc SD_bufferPtrHi
  stz SD_tmp_cnt ; counter
  ldy #$00
.readloop1
  phy
  jsr sd_readbyte
  ply
  sta (SD_bufferPtr),Y ; byte1
  iny
  dec SD_tmp_cnt ; counter
  bne .readloop1



  ; End command
  lda #SD_CS | SD_MOSI
  sta PORTA

  ; Print the last two bytes read, in hex
  ;lda $01 ; byte1
  ;jsr print_hex
  ;lda $02 ; byte2
  ;jsr print_hex
  clc
  rts

SD_writeSingleSector:
  ; Write a sector
  ;lda #'w'
  ;jsr print_char
  ;lda #'s'
  ;jsr print_char
  ;lda #':'
  ;jsr print_char

  lda #SD_MOSI
  sta PORTA

  ; Command 24, arg is sector number, crc not checked
  lda #$58           ; CMD24 - WRITE_SINGLE_BLOCK
  jsr sd_writebyte
  lda SD_sector_id+3           ; sector 24:31
  jsr sd_writebyte
  lda SD_sector_id+2           ; sector 16:23
  jsr sd_writebyte
  lda SD_sector_id+1           ; sector 8:15
  jsr sd_writebyte
  lda SD_sector_id           ; sector 0:7
  jsr sd_writebyte
  lda #$01           ; crc (not checked)
  jsr sd_writebyte

  jsr sd_waitresult
  cmp #$00
  beq .writesuccess

.SD_W_FIAL
  sec
  rts

.writesuccess
  ;lda #'s'
  ;jsr print_char
  ;lda #':'
  ;jsr print_char

  ;; wait for data
  ;jsr sd_waitresult
  ;cmp #$fe
  ;beq .writrgotdata
  lda #$fe
  jsr sd_writebyte  ;data token
;;
  ;lda #'f'
  ;jsr print_char
  ;jmp loop

.writrgotdata

  ; Need to write 512 bytes.  Read two at a time, 256 times.

  ldy #$00
  stz SD_tmp_cnt ; counter
.writeloop
  lda (SD_bufferPtr),Y
  phy
  jsr sd_writebyte
  ply
  iny
  dec SD_tmp_cnt ; counter
  bne .writeloop

  inc SD_bufferPtrHi
  ldy #$00
  stz SD_tmp_cnt ; counter
.writeloop1
  lda (SD_bufferPtr),Y
  phy
  jsr sd_writebyte
  ply
  iny
  dec SD_tmp_cnt ; counter
  bne .writeloop1


  lda #$00
  jsr sd_writebyte
  lda #$00
  jsr sd_writebyte  ;CRC maybe not chekd

  ;lda #'Y'
  ;jsr acia_print_char

  jsr sd_waitresult
  cmp #$E5
  bne .SD_W_FIAL
  ;jsr print_hex
  jsr delay
  jsr sd_waitresult
  cmp #$00
  bne .SD_W_FIAL
  ;jsr print_hex
  jsr delay

  
  ; End command
  lda #SD_CS | SD_MOSI
  sta PORTA
  clc
  rts
  ; loop forever
loop:
  ;lda #'X'
  ;jsr print_char
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
  ;lda #'Y'
  ;jsr print_char
  clc
  rts

.initfailed
  ;lda #'X'
  ;jsr print_char
  sec
  rts


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

  ;lda #'c'
  ;jsr print_char
  ldx #0
  ;lda (zp_sd_cmd_address,x)
  ;jsr print_hex

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
  ;jsr print_hex

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

  ;end of SD card stuff

  ;SPI and other subrutines
  wait:
    phx
    phy
    ldx #$FF
    ldy #$02
.loopY
    ldx #$20
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


;page alined
;a  - start page
;x  - number of pages
print_dump:
  pha
  phx
  phy
  sta func_ptrHi
  stz func_ptr
  stx func_sizeHi
  stz func_size
  stz func_tmp
  ldy #$00
.dloop
  tya
  and #$0F
  beq .dNL
  lda #$01
  sta func_tmp
  tya 
  and #$07
  beq .dSpace
.dSpaceRet
  beq .dNL
  lda (func_ptr),Y
  jsr printHex
  lda #' '
  jsr acia_print_char
  iny
.dskipprint
  dec func_size
  bne .dloop
  inc func_ptrHi
  dec func_sizeHi
  bne .dloop
  jmp .dend
.dNL
  tya
  phy
  lda func_tmp
  cmp #$00
  beq .dNlS
  tya
  clc
  sbc #$10
  tay
  ldx #$11
.dNLloop
  lda (func_ptr),Y
  iny
  clc
  cmp #$20
  bcc .dNLloopBad
  cmp #$80
  bcs .dNLloopBad
  jsr acia_print_char
  dex
  bne .dNLloop
  jmp .dNlS
.dNLloopBad
  lda #'.'
  jsr acia_print_char
  dex 
  bne .dNLloop
.dNlS
  ply
  jsr shell_newline
  lda func_ptrHi
  jsr printHex
  tya
  jsr printHex
  lda #':'
  jsr acia_print_char
  lda #' '
  jsr acia_print_char
  lda (func_ptr),Y
  jsr printHex
  lda #' '
  jsr acia_print_char
  iny
  jmp .dskipprint
.dSpace
  lda #' '
  jsr acia_print_char
  jmp .dSpaceRet
.dend
  ;jsr .chend
  tya
  clc
  sbc #$10
  tay
  ldx #$11
.dNLloop1
  lda (func_ptr),Y
  iny
  clc
  cmp #$20
  bcc .dNLloopBad1
  cmp #$80
  bcs .dNLloopBad1
  jsr acia_print_char
  dex
  bne .dNLloop1
  jmp .dNlS
.dNLloopBad1
  lda #'.'
  jsr acia_print_char
  dex 
  bne .dNLloop1

  ply
  plx
  pla
  rts