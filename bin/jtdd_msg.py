#!/usr/bin/python
# Message in the pause menu
import os

ascii_conv = {
    '0':10, '1':11, '2':12, '3':13, '4':14, '5':15,
    '6':16, '7':17, '8':18, '9':19,
    '.':0x0e, '-':0x0d, '&':0x06, '?':0x02,
    '!':0x01, '%':0x05, '(':0x08, ')':0x09, '#':0x03, ',':0x07,
    '+':0x0b, '/':0x0f, '@':0x20, '*':0xa, "'":0x0c,
    'A':0x21, 'B':0x22, 'C':0x23, 'D':0x24, 'E':0x25, 'F':0x26,
    'G':0x27, 'H':0x28, 'I':0x29, 'J':0x2a, 'K':0x2b, 'L':0x2c,
    'M':0x2d, 'N':0x2e, 'O':0x2f, 'P':0x30, 'Q':0x31, 'R':0x32,
    'S':0x33, 'T':0x34, 'U':0x35, 'V':0x36, 'W':0x37, 'X':0x38,
    'Y':0x39, 'Z':0x3a,
    ' ':0x00
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
print_char("                                ")
print_char("      DOUBLE DRAGON             ")
print_char("       CLONE FOR FPGA           ")
print_char("    BROUGHT TO YOU BY JOTEGO.   ")
print_char("  HTTP //PATREON.COM/TOPAPATE   ")
print_char("                                ")
print_char("      THANKS TO MY PATRONS      ")
print_char("                                ")
print_char("                                ")
print_char("      BETA VERSION              ")
print_char("                                ")
print_char("                                ")
print_char("      DO NOT DISTRIBUTE         ")
print_char("                                ")
print_char("                                ")
print_char("     SPECIAL THANKS TO          ")
print_char("      ANDREW MOORE              ")
print_char("                                ")
print_char("     FOR LOANING A              ")
print_char("       DOUBLE DRAGON PCB        ")
print_char("         FOR RESEARCH           ")
print_char("                                ")
print_char("                                ")
print_char("                                ")
print_char("                                ")
print_char("                                ")
print_char("                                ")
print_char("                                ")
print_char("                                ")
print_char("                                ")

save_hex( os.environ['JTROOT']+"/mist/msg.hex", char_ram )
save_bin( os.environ['JTROOT']+"/ver/game/msg.bin", char_ram )
