    include "include/ROM_define.asm"

    org $c000


reset:
        NOP
        NOP
        NOP
        SEI                     ; NO INTERRUPTS
                                ; INITIALIZE ACIA

        LDA     #$0B            ; TRANSMIT AND RECEIVE, NO INTERRUPTS
        STA     ACIACMD
        LDA     #$10            ; 19200 8 N 1, USE BAUD RATE GENERATOR
        STA     ACIACTL




    lda #'S'
    sta ACIA_DATA

    jsr ReceveDataBin

    lda #<$0700
    sta func_ptr
    lda #>$0700
    sta func_ptrHi

    jsr wait
    lda #':'
    sta ACIA_DATA
    jsr wait
    ldx #<JUM_STR
    ldy #>JUM_STR
    jsr printString
    jmp (prog_start)
    ldy #$00

loop:
    lda (func_ptr),Y
    sta ACIA_DATA
    jsr wait
    iny
    cpy #$20
    bne loop
    jmp *

   
wait:
    phx
    phy
    ldx #$FF
    ldy #$01
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
;ReceveDataBin
;func_ptr/HI - used
;func_size - used
;func_ptr/HI and func_size/HI are used and are no longer valid
; A,X,Y are saved
ReceveDataBin:
    pha
    phx
    phy
    stz CRC
    jsr wait
    lda #'R'
    sta ACIA_DATA
    jsr wait
;Get start add
.RXloopAddLo
    lda ACIA_STATUS
    and #$08
    beq .RXloopAddLo
    lda ACIA_DATA
    sta func_ptr
.RXloopAddHi
    lda ACIA_STATUS
    and #$08
    beq .RXloopAddHi
    lda ACIA_DATA
    sta func_ptrHi
;get size
.RXloopSizeLo
    lda ACIA_STATUS
    and #$08
    beq .RXloopSizeLo
    lda ACIA_DATA
    sta func_size
.RXloopSizeHi
    lda ACIA_STATUS
    and #$08
    beq .RXloopSizeHi
    lda ACIA_DATA
    sta func_sizeHi
;get cheksum
.RXloopChek
    lda ACIA_STATUS
    and #$08
    beq .RXloopChek
    lda ACIA_DATA
    sta func_chk

    lda func_ptr
    sta prog_start
    lda func_ptrHi
    sta prog_startHi
    ldy #$00
.RXloop
    lda func_size
    ora func_sizeHi
    beq .exitRx
    lda ACIA_STATUS
    and #$08
    beq .RXloop
    lda ACIA_DATA
    sta (func_ptr),Y
    clc
    adc CRC
    sta CRC
    lda func_size
    beq .decSizeHi
    dec func_size
.skipSizeDec
    cpy #$FF
    beq .RxchkEnd
    iny
    jmp .RXloop
.RxchkEnd
    lda #'.'
    sta ACIA_DATA
    ldy #$00
    inc func_ptrHi 
    jmp .RXloop
.decSizeHi
    dec func_sizeHi
    lda #$FF
    sta func_size
    jmp .skipSizeDec
.exitRx

    lda CRC
    jsr wait
    jsr printHex
    cmp func_chk
    bne .RXfailed
    ldx #<RX_STRING_GOOD
    ldy #>RX_STRING_GOOD
    jsr printString

    ply
    plx
    pla
    rts
.RXfailed
    ldx #<RX_STRING_BAD
    ldy #>RX_STRING_BAD
    jsr printString
    ply
    plx
    pla
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
;printString
;X, Y - address of string start, string max 255 characters endinw with 0
;func_ptr and func_ptrHi are used
printString:
    pha
    phx
    phy
    stx func_ptr
    sty func_ptrHi
    ldy #$00
.stringLoop:
    jsr wait
    lda (func_ptr),Y
    cmp #$00
    beq .stringLoopEnd
    sta ACIA_DATA
    iny
    jmp .stringLoop
.stringLoopEnd
    ply
    plx
    pla
    rts
RX_STRING_GOOD:
    ASCIIZ 13,10,"Transfer successful!",0
RX_STRING_BAD:
    ASCIIZ 13,10,"Transfer failed!",0
JUM_STR:
    ASCIIZ 13,10,"Jumping to ram ...",13,10,0
HEXarray:
    byte '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'



wait_fast:
    phx
    phy
    ldx #$02
    ldy #$FF
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