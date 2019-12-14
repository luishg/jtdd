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
    input              pxl_cen,
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
    input      [13:0]  prog_addr,
    input      [ 7:0]  prom_din,
    input              prom_we

);

reg [8:0] shared_addr;
reg       shared_we;
reg [7:0] shared_data;

wire        mcu_wr;
wire [15:0] mcu_AB;
wire [ 7:0] mcu_dout;

wire    shared_cs = mcu_AB[15:14]==2'b10;
wire    ba;

always @(*) begin
    shared_addr = shared_cs ? mcu_AB[8:0] : cpu_AB;
    shared_data = shared_cs ? mcu_dout : cpu_dout;
    if( shared_cs ) begin
        shared_addr = mcu_AB[8:0];
        shared_data = mcu_dout;
        shared_we   = mcu_wr;
    end else begin
        shared_addr = cpu_AB;
        shared_data = cpu_dout;
        shared_we   = com_cs & ~cpu_wrn;    
    end
end

reg     halted_n;
assign  mcu_ban = halted_n;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        halted_n <= 1'b1;
    end else begin
        if( !mcu_haltn && ba ) halted_n <= 1'b0; // only halt when bus is available
        if( mcu_haltn ) halted_n <= 1'b1;
    end
end

reg cen_halted;
always @(negedge clk) cen_halted <= halted_n;

wire clk2 = clk & pxl_cen & cen_halted;
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
    .RST        ( rst       ),
    .CLKx2      ( clk2      ),
    .BA         ( ba        ),
    .NMI        ( nmi       ),  // NMI
    .IRQ        ( 1'b0      ),  // IRQ1
    .WR         ( mcu_wr    ),  // CS2
    .AD         ( mcu_AB    ),  //  AS ? {PO4,PO3}
    .DO         ( mcu_dout  ),  // ~AS ? {PO3}
    .DI         ( mcu_din   ),  //       {PI3}
    .PI1        ( 8'hff     ),
    .PO1        (           ),
    .PI2        ( 5'h1f     ),
    .PO2        (           ),
    .PI6        ( 8'hff     ),
    .PO6        ( P6        ),
    // PROM programming
    .prog_addr  ( prog_addr ),
    .prom_din   ( prom_din  ),
    .prom_we    ( prom_we   ),
    // for DEBUG
    .phase      (           )
);

jtframe_ram #(.aw(9)) u_shared(
    .clk    ( clk         ),
    .cen    ( 1'b1        ),
    .data   ( shared_data ),
    .addr   ( shared_addr ),
    .we     ( shared_we   ),
    .q      ( shared_dout )
);
/*
wire ram_cs = mcu_AB[15:12] == 4'd0;
wire mcu_we = ram_cs && mcu_wr;

jtframe_ram #(.aw(12)) u_ram(
    .clk    ( clk            ),
    .cen    ( 1'b1           ),
    .data   ( mcu_dout       ),
    .addr   ( mcu_AB[11:0]   ),
    .we     ( mcu_we         ),
    .q      ( ram_dout       )
);
*/
`ifdef SIMULATION
always @(posedge mcu_haltn)   $display("MCU_HALTN rose");
always @(negedge mcu_haltn)   $display("MCU_HALTN fell");
always @(posedge mcu_nmi_set) $display("MCU NMI set");
`endif
endmodule
