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

wire        vma;
reg         shared_cs;
reg [8:0]   shared_addr;
reg         shared_we;
reg [7:0]   shared_data;

wire        rnw;
wire [15:0] mcu_AB;
wire [ 7:0] mcu_dout;

assign  mcu_ban = vma;

always @(*) begin
    shared_addr = shared_cs ? mcu_AB[8:0] : cpu_AB;
    shared_data = shared_cs ? mcu_dout : cpu_dout;
    if( vma ) begin
        shared_addr = mcu_AB[8:0];
        shared_data = mcu_dout;
        shared_we   = ~rnw & shared_cs;
    end else begin
        shared_addr = cpu_AB;
        shared_data = cpu_dout;
        shared_we   = com_cs & ~cpu_wrn;    
    end
end

reg  [7:0] p6_dout;
wire       nmi;
wire       nmi_clr = ~p6_dout[0];

assign mcu_irqmain =  p6_dout[1];

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

// Address decoder
always @(*) begin
    rom_cs    = 1'b0;
    ram_cs    = 1'b0;
    shared_cs = 1'b0;
    port_cs   = 1'b0;
    if( vma ) begin
        if( A[15:14]==2'b11 )        rom_cs    = 1'b1; // Cxxx
        if( A>=16'h40 && A<16'h140 ) ram_cs    = 1'b1;
        if( A[15:12]==4'h8  )        shared_cs = 1'b1; // 8xxx
        if( A<16'h28 )               port_cs   = 1'b1;
    end
end

// Ports
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        p6_dout <= 8'd0;
    end else begin
        if( port_cs && A[5:0]==6'h17 ) p6_dout <= data_out;
    end
end

`ifdef SIMULATION
always @(posedge port_cs) begin
    if( A[5:0] !=6'h17 ) $display("WARNING: Access at non-supported MCU port %X", A[5:0] );
end
`endif

// Input multiplexer
always @(*) begin
    case(1'b1)
        default:   data_in = rom_data;
        ram_cs:    data_in = ram_dout;
        shared_cs: data_in = shared_dout;
    endcase
end

// Clock enable
reg  waitn;
wire cpu_cen = cen6 & waitn;

always @(negedge clk) begin : cpu_clockenable
    reg last_cs;
    last_cs <= rom_cs;
    if( rom_cs && !last_cs ) waitn <= 1'b0;
    else if( rom_ok) waitn <= 1'b1;
end

m6801 u_6801(   
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen        ( cpu_cen       ),
    .rw         ( rnw           ),
    .vma        ( vma           ),
    .address    ( address       ),
    .data_in    ( data_in       ),
    .data_out   ( data_out      ),        
    .halt       ( halt          ),
    .irq        ( irq           ),
    .nmi        ( nmi           ),
    .irq_icf    ( irq_icf       ),
    .irq_ocf    ( irq_ocf       ),
    .irq_tof    ( irq_tof       ),
    .irq_sci    ( irq_sci       )
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
