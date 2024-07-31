ACIA_DATA   = $0400
ACIA_STATUS = $0401
ACIA_CMD    = $0402
ACIA_CTRL   = $0403

ACIA_RX = ACIA_DATA
ACIA_TX = ACIA_DATA

SYS_IO      = $04F0
SYS_PORTB   = $04F0
SYS_PORTA   = $04F1
SYS_DDRB    = $04F2
SYS_DDRA    = $04F3

PORT_B = SYS_PORTB 
PORT_A = SYS_PORTA 
DDRB =  SYS_DDRB  
DDRA =  SYS_DDRA  

ACIA    EQU $0400       ; BASE ADDRESS OF 6551 ACIA

ACIAD   EQU ACIA+0      ; ACIA DATA
ACIAS   EQU ACIA+1      ; ACIA STATUS
ACIACMD EQU ACIA+2      ; ACIA COMMAND
ACIACTL EQU ACIA+3      ; ACIA CONTROL

;SPI bit mask
SPI0_DATA_BIT_IN  = %00001000
SPI0_DATA_BIT_OUT = %00000001
SPI0_CLK_BIT      = %00000010
SPI0_CE_BIT       = %00000100
SPI0_CE1_BIT       = %00010000

func_ptr    = $00
func_ptrHi  = $01
func_size   = $02
func_sizeHi = $03
func_tmp    = $04
func_tmpHI  = $05
func_chsum  = $06
CRC         = $07
func_chk    = $08
prog_start  = $09
prog_startHi= $0A
SPI_DATA_TMP= $0B
SPI_PORT_TMP= $0C

string_ptr  = $0D        ; Pointer for printing
out_tmp:    = $0F        ; Used for shifting bit out
in_tmp:     = $10        ; Used when shifing bits in
SD_tmp_cnt  = $11
SD_bufferPtr= $12       ;Must be page alined!
SD_bufferPtrHi= $13
zp_sd_cmd_address = $14
PORTA = PORT_A

SD_CS   = SPI0_CE1_BIT
SD_SCK  = SPI0_CLK_BIT
SD_MOSI = SPI0_DATA_BIT_OUT
SD_MISO = SPI0_DATA_BIT_IN

PORTA_OUTPUTPINS = SD_CS | SD_SCK | SD_MOSI



SD_sector_id       = $0300              ;.res 4; 4 bytes
SD_buffer         = $0500               ;.res 512