IO_START   = $400
SYS_IO_ADD = IO_START|$F0

PORT_A = SYS_IO_ADD+1
PORT_B = SYS_IO_ADD+0
DDRA = SYS_IO_ADD+3
DDRB = SYS_IO_ADD+2
      org $0700

      lda #$FF
      sta DDRA
      sta DDRB

loop:
      inc
      sta PORT_A
      sta PORT_B
      jmp loop