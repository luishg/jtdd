#!/bin/bash

function rom_len {
    echo $(printf "%05X" $(du --bytes JTDD.rom | cut -f 1))
}

function dump {
    printf "%-22s = 22'h%s;\n" "$1" "$(rom_len)"
    shift
    for i in $*; do
        if [ ! -e $i ]; then
            echo cannot find file $i
            exit 1
        fi
        cat $i >> JTDD.rom
    done
}

rm -f JTDD.rom
touch JTDD.rom

dump "localparam BANK_ADDR"  21j-2-3.25 21j-3.24  21j-4-1.23 21j-4-1.23 # last one is repeated
dump "localparam MAIN_ADDR"  21j-1-5.26
dump "localparam SND_ADDR"   21j-0-1
dump "localparam ADPCM_1"    21j-6
dump "localparam ADPCM_2"    21j-7
dump "localparam CHAR_ADDR"  21j-5 21j-5 # repeated once

# Scroll
echo // Scroll
# lower bytes
dump "localparam SCRZW_ADDR" 21j-a 21j-b 21j-c 21j-d 
# upper bytes
dump "localparam SCRXY_ADDR" 21j-e 21j-f 21j-g 21j-h
## Objects
echo // objects
    # lower bytes
    dump "localparam OBJWZ_ADDR"  21j-8 21j-9
    # upper bytes
    dump "localparam OBJXY_ADDR"  21j-i 21j-j

# Not in SDRAM:
echo // FPGA BRAM:
dump "localparam MCU_ADDR"  21jm-0.ic55
dump "localparam PROM_ADDR" 21j-k-0 21j-l-0
echo // ROM length $(rom_len)
