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

// Port 4 configured as output --> use as address bus
// Port 6 configured as output

module jtdd_mcu(
    input              clk,
    input              rst,
    input              cen_Q,
    input              cen12,
    input              cen12b,
    input              cen6,
    input              cen6b,
    // CPU bus
    input      [ 8:0]  cpu_AB,
    input              cpu_wrn,
    input      [ 7:0]  cpu_dout,
    output     [ 7:0]  shared_dout,
    // CPU Interface
    input              com_cs,
    output             mcu_ban,
    input              mcu_nmi_set,
    input              mcu_haltn,
    output             mcu_irqmain,
    // PROM programming
    output     [13:0]  rom_addr,
    input      [ 7:0]  rom_data,
    output             rom_cs,
    input              rom_ok

);

reg [8:0] shared_addr;
reg       shared_we;
reg [7:0] shared_data;

wire        mcu_wr;
wire [15:0] mcu_AB;
wire [ 7:0] mcu_dout;

wire    shared_cs = mcu_AB[15:14]==2'b10;
wire    ba;
assign  mcu_ban = ~ba;

always @(*) begin
    shared_addr = shared_cs ? mcu_AB[8:0] : cpu_AB;
    shared_data = shared_cs ? mcu_dout : cpu_dout;
    if( !ba ) begin
        shared_addr = mcu_AB[8:0];
        shared_data = mcu_dout;
        shared_we   = mcu_wr;
    end else begin
        shared_addr = cpu_AB;
        shared_data = cpu_dout;
        shared_we   = com_cs & ~cpu_wrn;    
    end
end

wire [7:0] P6;
wire       nmi;
wire       nmi_clr = ~P6[0];

assign mcu_irqmain =  P6[1];

jtframe_ff u_nmi(
    .clk     (   clk          ),
    .rst     (   rst          ),
    .cen     (   1'b1         ),
    .sigedge (   mcu_nmi_set  ),
    .din     (   1'b1         ),
    .clr     (   nmi_clr      ),
    .set     (   1'b0         ),
    .q       (   nmi          ),
    .qn      (                )
);

//wire [7:0] ram_dout;
wire [7:0] mcu_din = shared_dout; //shared_cs ? shared_dout : ram_dout;

jt63701 u_mcu(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen_rise2  ( cen12         ),
    .cen_fall2  ( cen12b        ),
    .cen_rise   ( cen6          ),
    .cen_fall   ( cen6b         ),
    // Control lines
    .haltn      ( mcu_haltn     ),    
    .ba         ( ba            ),
    .nmi        ( nmi           ),
    .irq        ( 1'b0          ),
    .wr         ( mcu_wr        ),
    .AD         ( mcu_AB        ),
    .dout       ( mcu_dout      ),
    .din        ( mcu_din       ),
    .p1_din     ( 8'hff         ),
    .p1_dout    (               ),
    .p2_din     ( 5'h1f         ),
    .p2_dout    (               ),
    .p6_din     ( 8'hff         ),
    .p6_dout    ( P6            ),
    // PROM programming
    .rom_addr   ( rom_addr      ),
    .rom_data   ( rom_data      ),
    .rom_cs     ( rom_cs        ),
    .rom_ok     ( rom_ok        )
);

jtframe_ram #(.aw(9)) u_shared(
    .clk    ( clk         ),
    .cen    ( cen6        ),
    .data   ( shared_data ),
    .addr   ( shared_addr ),
    .we     ( shared_we   ),
    .q      ( shared_dout )
);

`ifdef SIMULATION
always @(posedge mcu_haltn)   $display("MCU_HALTN rose");
always @(negedge mcu_haltn)   $display("MCU_HALTN fell");
always @(posedge mcu_nmi_set) $display("MCU NMI set");
`endif
endmodule
