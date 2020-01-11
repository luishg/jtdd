#!/usr/bin/python
# Message in the pause menu
import os

ascii_conv = {
    '0':10, '1':11, '2':12, '3':13, '4':14, '5':15,
    '6':16, '7':17, '8':18, '9':19,
    '.':0x0e, '-':0x0d, '&':0x06, '?':0x02,
    '!':0x01, '%':0x05, '(':0x08, ')':0x09, '#':0x03, ',':0x07,
    '+':0x0b, '/':0x0f, '@':0x1a, '*':0xa, "'":0x0c,
    'A':0x1b, 'B':0x1c, 'C':0x1d, 'D':0x1e, 'E':0x1f, 'F':0x20,
    'G':0x21, 'H':0x22, 'I':0x23, 'J':0x24, 'K':0x25, 'L':0x26,
    'M':0x27, 'N':0x28, 'O':0x29, 'P':0x2a, 'Q':0x2b, 'R':0x2c,
    'S':0x2d, 'T':0x2e, 'U':0x2f, 'V':0x30, 'W':0x31, 'X':0x32,
    'Y':0x33, 'Z':0x34,
    ' ':0x00, 'o':0x57
}

char_ram = [ 0x20 for x in range(0x400) ]
row=0

def save_hex(filename, data):
    with open(filename,"w") as f:
        for k in data:
            f.write( "%X" % k )
            f.write( "\n" )
        f.close()

def save_bin(filename, data):
    with open(filename,"wb") as f:
        f.write( bytearray(data) )
        f.close()

def print_char( msg ):
    global row
    pos = row
    for a in msg:
        char_ram[pos] = ascii_conv[a]
        pos = pos+1
    row = row+32

r_g  = [ 0 for x in range(256) ]
blue = [ 0 for x in range(256) ]

for col in range(256):
    r_g  [col] = (col%8)| 0x80 | ((col%8)<<4)
    blue [col] = col%16



#           00000000001111111111222222222233
#           01234567890123456789012345678901
print_char("oooooooooooooooooooooooooooooooo")
print_char("oooooooooooooooooooooooooooooooo")
print_char("o                              o")
print_char("o      DOUBLE DRAGON II        o")
print_char("o      CLONE FOR FPGA          o")
print_char("o   BROUGHT TO YOU BY JOTEGO.  o")
print_char("o HTTP //PATREON.COM/TOPAPATE  o")
print_char("o                              o")
print_char("o     THANKS TO MY PATRONS     o")
print_char("o                              o")
print_char("o  DIRECTORS                   o")
print_char("o      FREDERIC MAHE           o")
print_char("o      SUV                     o")
print_char("o                              o")
print_char("o                              o")
print_char("o                              o")
print_char("o     BETA VERSION             o")
print_char("o                              o")
print_char("o                              o")
print_char("o     DO NOT DISTRIBUTE        o")
print_char("o                              o")
print_char("o   THANKS TO PORKCHOP EXPRESS o")
print_char("o     AND RETROSHOP.PT FOR     o")
print_char("o       THEIR HARDWARE SUPPORT o")
print_char("o                              o")
print_char("o                              o")
print_char("o                              o")
print_char("o                              o")
print_char("o                              o")
print_char("o                              o")
print_char("oooooooooooooooooooooooooooooooo")

save_hex( os.environ['JTROOT']+"/cores/dd/mist/msg.hex", char_ram )
save_bin( os.environ['JTROOT']+"/cores/dd/ver/game/msg.bin", char_ram )
