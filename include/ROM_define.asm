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