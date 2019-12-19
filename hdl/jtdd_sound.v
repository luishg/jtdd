/*  This file is part of JTDD.
    JTDD program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTDD program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTDD.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 2-12-2017 */

// Clocks are derived from H counter on the original PCB
// Yet, that doesn't seem to be important and it only
// matters the frequency of the signals:
// E,Q: 3 MHz
// Q is 1/4th of wave advanced

`timescale 1ns/1ps

module jtdd_sound(
    input               clk,
    input               rst,
    (* direct_enable *) input cen_E,
    (* direct_enable *) input cen_Q,
    // communication with main CPU
    input               snd_rstb,
    input               snd_irq,
    input      [7:0]    snd_latch,
    // ROM
    output  [14:0]  rom_addr,
    output  reg     rom_cs,
    input   [ 7:0]  rom_data,
    input           rom_ok,

    // Sound output
    output  signed [15:0] left,
    output  signed [15:0] right,
    output                sample    
);

wire [ 7:0] cpu_dout, ram_dout, fm_dout;
wire [15:0] A;
reg  [ 7:0] cpu_din;
wire        RnW, firq_n, irq_n;

reg ram_cs, latch_cs, ad_cs, fm_cs;

assign rom_addr = A[14:0];

always @(*) begin
    rom_cs   = A[15];
    ram_cs   = 1'b0;
    latch_cs = 1'b0;
    ad_cs    = 1'b0;
    fm_cs    = 1'b0;
    if(!A[15]) case(A[14:11])
        4'd0: ram_cs   = 1'b1;
        4'd2: latch_cs = 1'b1;
        4'd3: ad_cs    = 1'b1;
        4'd5: fm_cs    = 1'b1;
        // 4'd7:
    endcase
end

always @(*) begin
    case(1'b1)
        rom_cs:   cpu_din = rom_data;
        ram_cs:   cpu_din = ram_dout;
        latch_cs: cpu_din = snd_latch;
        fm_cs:    cpu_din = fm_dout;
        ad_cs:    cpu_din = 8'hff;
    endcase
end

reg E,Q;
assign cpu_cen = Q;

always @(negedge clk) begin
    E <= cen_E & (~rom_cs | rom_ok | ~snd_rstb);
    Q <= cen_Q & (~rom_cs | rom_ok | ~snd_rstb);
end

wire ram_we = ram_cs & ~RnW;

jtframe_ff u_ff(
    .clk      ( clk         ),
    .rst      ( rst         ),
    .cen      ( 1'b1        ),
    .din      ( 1'b1        ),
    .q        (             ),
    .qn       ( irq_n       ),
    .set      ( 1'b0        ),    // active high
    .clr      ( latch_cs    ),    // active high
    .sigedge  ( snd_irq     ) // signal whose edge will trigger the FF
);

jtframe_ram #(.aw(11)) u_ram(
    .clk    ( clk         ),
    .cen    ( cen_Q       ),
    .data   ( cpu_dout    ),
    .addr   ( A[10:0]     ),
    .we     ( ram_we      ),
    .q      ( ram_dout    )
);

mc6809i u_cpu(
    .D       ( cpu_din ),
    .DOut    ( cpu_dout),
    .ADDR    ( A       ),
    .RnW     ( RnW     ),
    .clk     ( clk     ),
    .cen_E   ( E       ),
    .cen_Q   ( Q       ),
    .BS      (         ),
    .BA      (         ),
    .nIRQ    ( irq_n   ),
    .nFIRQ   ( firq_n  ),
    .nNMI    ( 1'b1    ),
    .AVMA    (         ),
    .BUSY    (         ),
    .LIC     (         ),
    .nDMABREQ( 1'b1    ),
    .nHALT   ( 1'b1    ),   
    .nRESET  ( snd_rstb),
    .RegData (         )
);

wire cen_fm, cen_fm2;

jtframe_cen3p57 u_fmcen(
    .clk        (  clk       ),       // 48 MHz
    .cen_3p57   (  cen_fm    ),
    .cen_1p78   (  cen_fm2   )
);

jt51 u_jt51(
    .rst        ( rst       ), // reset
    .clk        ( clk       ), // main clock
    .cen        ( cen_fm    ),
    .cen_p1     ( cen_fm2   ),
    .cs_n       ( !fm_cs    ), // chip select
    .wr_n       ( RnW       ), // write
    .a0         ( A[0]      ),
    .din        ( cpu_dout  ), // data in
    .dout       ( fm_dout   ), // data out
    .ct1        (           ),
    .ct2        (           ),
    .irq_n      ( firq_n    ),  // I do not synchronize this signal
    // Low resolution output (same as real chip)
    .sample     ( sample    ), // marks new output sample
    .left       (           ),
    .right      (           ),
    // Full resolution output
    .xleft      ( left      ),
    .xright     ( right     ),
    // unsigned outputs for sigma delta converters, full resolution
    .dacleft    (           ),
    .dacright   (           )
);


endmodule
