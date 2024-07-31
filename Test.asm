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

  





  
;===============================================================================================================================================



main:
reset:
  ldx #$ff
  txs

  lda #%11111111          ; Set all pins on port B to output
  sta DDRB
  lda #PORTA_OUTPUTPINS   ; Set various pins on port A to output
  sta DDRA


  jsr sd_init
  bcs mainfail
  jsr shell_newline
  
;
  ;jsr shell_newline
  lda #$80
  sta SD_sector_id
  stz SD_sector_id+1
  stz SD_sector_id+2
  stz SD_sector_id+3

  lda #$00
  sta SD_bufferPtr
  lda #$c0
  sta SD_bufferPtr+1

  jsr SD_writeSingleSector
  bcs mainfail

  lda #$00
  sta SD_bufferPtr
  lda #$50
  sta SD_bufferPtr+1

  jsr SD_ReadSingleSector

  bcs mainfail
  lda #$00
  sta SD_bufferPtr
  lda #$50
  sta SD_bufferPtr+1
  stz func_size
  ldy #$00
Aloop
  lda (SD_bufferPtr),Y
  jsr printHex
  lda #' '
  jsr print_char
  iny
  dec func_size
  bne Aloop

  jsr shell_newline
  inc SD_bufferPtrHi
  stz func_size
  ldy #$00
Aloop1
  lda (SD_bufferPtr),Y
  jsr printHex
  lda #' '
  jsr print_char
  iny
  dec func_size
  bne Aloop1

  
  jmp $c000
mainfail:
  lda #'F'
  jsr print_char
  jmp $c000

  include "program_functions.asm"

