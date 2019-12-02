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


module jtdd_colmix(
    input              clk,
    input              rst,
    input              pxl_cen,
    input [7:0]        cpu_dout,
    input [8:0]        cpu_addr,
    input              pal_cs,
    input [7:0]        prog_addr,
    input              prom_prio_we,
    output [3:0]       red,
    output [3:0]       green,
    output [3:0]       blue
);

wire [7:0] pal_rg;
wire [3:0] pal_b;
reg        pal_rg_we, pal_b_we;
reg  [8:0] pal_addr;
reg  [7:0] seladdr;
wire [1:0] prio;

jtframe_ram #(.aw(9)) u_pal_rg(
    .clk    ( clk         ),
    .cen    ( pxl_cen     ),
    .data   ( cpu_dout    ),
    .addr   ( pal_addr    ),
    .we     ( pal_rg_we   ),
    .q      ( pal_rg      )
);

jtframe_ram #(.aw(9)) u_pal_b(
    .clk    ( clk         ),
    .cen    ( pxl_cen     ),
    .data   ( cpu_dout    ),
    .addr   ( pal_addr    ),
    .we     ( pal_b_we    ),
    .q      ( pal_b       )
);

jtframe_prom #(.aw(8),.dw(2),.simfile(SIM_PRIO)) u_prio(
    .clk    ( clk           ),
    .cen    ( 1'b1          ),
    .data   ( prom_din[1:0] ),
    .rd_addr( seladdr       ),
    .wr_addr( prog_addr     ),
    .we     ( prom_prio_we  ),
    .q      ( prio          )
);

endmodule