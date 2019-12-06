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

module jtdd_video(
    input              clk,
    input              rst,
    input              pxl_cen,
    input              cen12,
    // CPU bus
    input      [12:0]  cpu_AB,
    input              cpu_wrn,
    input      [ 7:0]  cpu_dout,
    input              cen_E,
    // Palette
    input              pal_cs,
    output     [ 7:0]  pal_dout,
    // Char
    input              char_cs,
    output     [ 7:0]  char_dout,
    // video signals
    output             VBL,
    output             VS,
    output             HBL,
    output             HS,
    input              flip,
    // ROM access
    output reg [14:0]  char_addr,
    input      [ 7:0]  rom_data,
    input      [ 7:0]  rom_ok,
    output     [ 6:0]  char_pxl,
    // PROM programming
    input [7:0]        prog_addr,
    input [3:0]        prom_din,
    input              prom_prio_we,
    // Pixel output
    output reg [3:0]   red,
    output reg [3:0]   green,
    output reg [3:0]   blue
);

wire [6:0]  char_pxl;  // called mcol in schematics
wire [6:0]  obj_pxl=7'd0;  // called ocol in schematics
wire [6:0]  scr_pxl=7'd0;  // called bcol in schematics
wire [7:0]  HPOS, VPOS;

jtdd_timing u_timing(
    .clk    (  clk      ),
    .rst    (  rst      ),
    .cen12  (  cen12    ),
    .flip   (  flip     ),
    .VPOS   (  VPOS     ),
    .HPOS   (  HPOS     ),
    .VBL    (  VBL      ),
    .VS     (  VS       ),
    .HBL    (  HBL      ),
    .HS     (  HS       ),
    .M      (           )
);

jtdd_char u_char(
    .clk         ( clk              ),
    .rst         ( rst              ),
    .pxl_cen     ( pxl_cen          ),
    .cpu_AB      ( cpu_AB           ),
    .char_cs     ( char_cs          ),
    .cpu_wrn     ( cpu_wrn          ),
    .cpu_dout    ( cpu_dout         ),
    .cen_E       ( cen_E            ),
    .char_dout   ( char_dout        ),
    .HPOS        ( HPOS             ),
    .VPOS        ( VPOS             ),
    .flip        ( flip             ),
    .char_addr   ( char_addr        ),
    .rom_data    ( rom_data         ),
    .rom_ok      ( rom_ok           ),
    .char_pxl    ( char_pxl         )
);

jtdd_colmix u_colmix(
    .clk         ( clk              ),
    .rst         ( rst              ),
    .pxl_cen     ( pxl_cen          ),
    .cpu_dout    ( cpu_dout         ),
    .pal_dout    ( pal_dout         ),
    .cpu_AB      ( cpu_AB           ),
    .VBL         ( VBL              ),
    .HBL         ( HBL              ),
    .char_pxl    ( char_pxl         ),
    .obj_pxl     ( obj_pxl          ),
    .scr_pxl     ( scr_pxl          ),
    .pal_cs      ( pal_cs           ),
    .prog_addr   ( prog_addr        ),
    .prom_din    ( prom_din         ),
    .prom_prio_we( prom_prio_we     ),
    .red         ( red              ),
    .green       ( green            ),
    .blue        ( blue             )
);

endmodule