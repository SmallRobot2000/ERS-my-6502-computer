ERS 6502 (Extendable Retro Machine)

This is my take at 6502 world.
This project started in mid 2021 but I didn’t post anything, because I was very new in 6502 world and 8-bit world in general, I don't say that I'm the best now but I'm better in 8-bit computers now.
This is a fresh new start on my "old" hardware design from 2021. The old software was a lot more finished, but it was very unstable, and I didn't want to work on it anymore, so I started from the beginning.
The old system had:
|||
| --- | --- |
|CPU|	65c02 @4Mhz|
|VDU|	TMS9929a|
|AUDIO|	SN76489|
|SERIAL|	N/A|
|STORAGE|	SD card (FAT 32) and floppy (with my own file system)|
|RAM|	32k 62256  (with expansion to 256k but never used it)|
|ROM|	16k used upper half of 28c256|
|KEYBOARD|	PS/2 Keyboard design from Ben Eather (Thank you, because of you I started this my 8-bit hobby)|

I had my own OS witch was GUI, Kernel and drivers all in one, it was called ERS-OS.
But that is all int the past now, let's get to the present.
Specs currently are:

|||
| --- | --- |
|CPU|	65c02 @4Mhz (Maybe I will be able to make it go to 8Mhz)|
|VDU|	N/A (Gameduino with SPI works but nothig graphical added)|
|AUDIO|	N/A (Gameduino with SPI works but nothig graphical added)|
|SERIAL|	WDC6551|
|STORAGE|	N/A (SD card working read write sector plan to make custom file system, floppy planed)|
|RAM|	32k 62256 (plan to use expansion to 256k)|
|ROM|	16k used upper half of 28c256|
|KEYBOARD|	N/A (plan to use Spectrum like matrix keyboard)|

In this new project I aim to make a ROM what contains a custom terminal OS (something like CP/M or DOS), kernel and hardware "driver"(assembler subroutines).
For now I got wdc6551 to work and receive my own file format.
I plan to use Gameduino as VDP and audio, for keyboard I plan to use a Spectrum like matrix keyboard and try to get a SD card working with custom file system for speed because I will not transfer files with it because I got serial.

*I will add all old and new schematics in the future.
