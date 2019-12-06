#!/bin/bash

iverilog test.v ../../hdl/jtdd_prom_we.v \
    -D ROM_LEN=22\'h124300 -D PROM_W=2 -D SIMULATION \
    -D ROM_PATH=\"../../rom/JTDD.rom\" \
    -o sim \
    && sim -lxt