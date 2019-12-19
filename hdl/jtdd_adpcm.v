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
    Date: 19-12-2019 */

// Clocks are derived from H counter on the original PCB
// Yet, that doesn't seem to be important and it only
// matters the frequency of the signals:
// E,Q: 3 MHz
// Q is 1/4th of wave advanced

`timescale 1ns/1ps

module jtdd_adpcm(
    input               clk,
    input               rst,
    (*direct_input*)    input cpu_cen,
    (*direct_input*)    input cen_oki,        // 375 kHz
    // communication with main CPU
    input   [ 7:0]      cpu_dout,
    input   [ 1:0]      cpu_AB,
    input               cs,
    // ROM
    output reg [15:0]   rom_addr,
    output reg          rom_cs,
    input      [ 7:0]   rom_data,
    input               rom_ok,

    // Sound output
    output  signed [11:0] snd
);

reg [9:0] cnt;
reg [7:0] addr0, addr1;
reg       ad_rst;
wire      sample;
wire      over = addr0 == addr1;

always @(posedge clk, posedge rst) begin
    if(rst) begin
        addr0  <= 8'd0;
        addr1  <= 8'd0;
        ad_rst <= 1'b1;
        cnt    <= 10'd0;
    end else begin
        if(cs & cpu_cen) begin
            case(cpu_AB)
                2'd0: ad_rst <= 1'b0;       // start
                2'd1: addr1  <= cpu_dout;
                2'd2: addr0  <= cpu_dout;
                2'd3: ad_rst <= 1'b1;       // stop
            endcase
        end
        if( !ad_rst ) begin
            if( sample ) begin
                cnt <= cnt + 10'd1;
                if(&cnt) addr0 <= addr0+8'd1;
            end
            if( over ) begin
                ad_rst <= 1'b1;
                cnt    <= 10'd0;
            end
        end
    end
end

always @(posedge clk) begin
    rom_addr <= { addr0[6:0], cnt[9:1] };
    rom_cs   <= ~ad_rst;
end

wire [3:0] din = !cnt[0] ? rom_data[7:4] : rom_data[3:0];

jt5205 u_decod(
    .rst    ( ad_rst    ),
    .clk    ( clk       ),
    .cen    ( cen_oki   ),
    .sel    ( 2'b10     ),
    .din    ( din       ),
    .sound  ( snd       ),
    .irq    ( sample    )
);

endmodule