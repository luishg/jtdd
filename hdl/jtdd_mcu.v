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

`timescale 1ns/1ps

module jtdd_mcu(
    input              clk,
    input              rst,
    input              cen_Q,
    input              pxl_cen,
    // CPU bus
    input      [ 8:0]  cpu_AB,
    input              cpu_wrn,
    input      [ 7:0]  cpu_dout,
    output     [ 7:0]  mcu_ram,
    // CPU Interface
    input              com_cs,
    output             mcu_ban,
    input              mcu_nmi_set,
    input              mcu_haltn,
    output             mcu_irqmain,
    // PROM programming
    input      [13:0]  prog_addr,
    input      [ 7:0]  prom_din,
    input              prom_we

);

assign mcu_irqmain = 1'b0;

reg [8:0] ram_addr;
reg       ram_we;
reg [7:0] ram_data;

wire        mcu_wrn;
wire [15:0] mcu_AB;
wire [ 7:0] mcu_dout;

wire        ram_cs = mcu_AB[15:14]==2'b10;
assign     mcu_ban = ~ram_cs;

always @(*) begin
    ram_addr = ram_cs ? mcu_AB[8:0] : cpu_AB;
    ram_data = ram_cs ? mcu_dout : cpu_dout;
    if( ram_cs ) begin
        ram_addr =  mcu_AB[8:0];
        ram_data =  mcu_dout;
        ram_we   = ~mcu_wrn;
    end else begin
        ram_addr = cpu_AB;
        ram_data = cpu_dout;
        ram_we   = com_cs & ~cpu_wrn;    
    end
end

wire clk2 = clk & pxl_cen & ~mcu_haltn;
wire [7:0] P6;
wire       nmi;

assign mcu_irqmain = ~P6[1];

jtframe_ff u_nmi(
    .clk     (   clk          ),
    .rst     (   rst          ),
    .cen     (   1'b1         ),
    .sigedge (   mcu_nmi_set  ),
    .din     (   1'b1         ),
    .clr     ( ~P6[0]         ),
    .set     (   1'b0         ),
    .q       (   nmi          ),
    .qn      (                )
);

jt63701 u_mcu(
    .RST        ( rst       ),
    .CLKx2      ( clk2      ),
    .NMI        ( nmi       ),    // NMI
    .IRQ        ( 1'b0      ),    // IRQ1
    .RW         ( mcu_wrn   ),   // CS2
    .AD         ( mcu_AB    ),   //  AS ? {PO4,PO3}
    .DO         ( mcu_dout  ),   // ~AS ? {PO3}
    .DI         ( mcu_ram   ),   //       {PI3}
    .PI1        ( 8'hff     ),    // Port1 IN
    .PO1        (           ),    //      OUT
    .PI2        ( 5'h1f     ),    // Port2 IN
    .PO2        (           ),    //      OUT
    .PI6        ( 8'hff     ),
    .PO6        ( P6        ),
    // PROM programming
    .prog_addr  ( prog_addr ),
    .prom_din   ( prom_din  ),
    .prom_we    ( prom_we   ),
    // for DEBUG
    .phase      (           )
);

jtframe_ram #(.aw(9)) u_ram_high(
    .clk    ( clk         ),
    .cen    ( 1'b1        ),
    .data   ( ram_data    ),
    .addr   ( ram_addr    ),
    .we     ( ram_we      ),
    .q      ( mcu_ram     )
);

endmodule
