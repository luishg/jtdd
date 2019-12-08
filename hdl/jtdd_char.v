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

// Schematcics 4/9 MAP
// Character layer

module jtdd_char(
    input              clk,
    input              rst,
    (*direct_enable*)  input pxl_cen,
    input      [12:0]  cpu_AB,
    input              char_cs,
    input              cpu_wrn,
    input      [ 7:0]  cpu_dout,
    input              cen_E,
    output reg [ 7:0]  char_dout,
    input      [ 7:0]  HPOS,
    input      [ 7:0]  VPOS,
    input              flip,
    // ROM access
    output reg [14:0]  rom_addr,
    input      [ 7:0]  rom_data,
    input              rom_ok,
    output reg [ 6:0]  char_pxl
);

reg         hi_we, lo_we;
reg  [11:0] ram_addr, scan;
wire [ 7:0] hi_data, lo_data;

always @(*) begin
    lo_we     = char_cs && !cpu_wrn && !cpu_AB[0];
    hi_we     = char_cs && !cpu_wrn &&  cpu_AB[0];
    scan      = { 2'b11, VPOS[7:3], HPOS[7:3] };
    ram_addr  = char_cs ? cpu_AB[12:1] : scan;
    char_dout = cpu_AB[0] ? hi_data : lo_data;
end

reg [7:0] shift;
reg [2:0] pal;

always @(posedge clk) if(pxl_cen) begin
    case( HPOS[0] ) 
        1'b0: begin
            rom_addr <= { hi_data[1:0], lo_data, HPOS[2:1], VPOS[2:0] };
            pal       <= hi_data[7:5];
            shift     <= { 
                rom_data[7], rom_data[5], rom_data[3], rom_data[1],
                rom_data[6], rom_data[4], rom_data[2], rom_data[0] };
            char_pxl  <= { pal, shift[7:4] };
        end
        1'b1: begin
            char_pxl  <= { pal, shift[3:0] };
        end
    endcase
end

jtframe_ram #(.aw(12),.simfile("char_hi.bin")) u_ram_high(
    .clk    ( clk         ),
    .cen    ( cen_E       ),
    .data   ( cpu_dout    ),
    .addr   ( ram_addr    ),
    .we     ( hi_we       ),
    .q      ( hi_data     )
);

jtframe_ram #(.aw(12),.simfile("char_lo.bin")) u_ram_low(
    .clk    ( clk         ),
    .cen    ( cen_E       ),
    .data   ( cpu_dout    ),
    .addr   ( ram_addr    ),
    .we     ( lo_we       ),
    .q      ( lo_data     )
);

endmodule