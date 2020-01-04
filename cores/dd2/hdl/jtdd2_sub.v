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
    Date: 2-12-2019 */

`timescale 1ns/1ps

// Port 4 configured as output --> use as address bus
// Port 6 configured as output

module jtdd2_sub(
    input              clk,
    input              rst,
    input              cen4,
    // CPU bus
    input      [ 9:0]  main_AB,
    input              main_wrn,
    input      [ 7:0]  main_dout,
    output     [ 7:0]  shared_dout,
    // CPU Interface
    input              com_cs,
    output             mcu_ban,
    input              mcu_nmi_set,
    input              mcu_halt,
    output  reg        mcu_irqmain,
    // ROM interface
    output     [15:0]  rom_addr,
    input      [ 7:0]  rom_data,
    output reg         rom_cs,
    input              rom_ok

);

wire        vma;
reg         port_cs, ram_cs, shared_cs;
reg [8:0]   shared_addr;
reg         shared_we;
reg [7:0]   shared_data;

wire        rnw;
wire [15:0] A;
wire [ 7:0] mcu_dout;
reg  [ 7:0] cpu_din;

assign  mcu_ban = vma;

always @(*) begin
    if( vma ) begin
        shared_addr = A[8:0];
        shared_data = mcu_dout;
        shared_we   = ~rnw & shared_cs;
    end else begin
        shared_addr = main_AB;
        shared_data = main_dout;
        shared_we   = ~main_wrn & com_cs;
    end
end

wire       int_n, mreq_n;
reg        irq_clr;

jtframe_ff u_nmi(
    .clk     (   clk          ),
    .rst     (   rst          ),
    .cen     (   1'b1         ),
    .sigedge (   mcu_nmi_set  ),
    .din     (   1'b1         ),
    .clr     (   irq_clr      ),
    .set     (   1'b0         ),
    .q       (                ),
    .qn      (   int_n        )
);

wire [7:0] ram_dout;
assign rom_addr = A;

// Address decoder
always @(*) begin
    rom_cs      = 1'b0;
    shared_cs   = 1'b0;
    mcu_irqmain = 1'b0;
    irq_clr     = 1'b0;
    if( !mreq_n ) begin
        if( A[15:14]==2'b00 )
            rom_cs    = 1'b1; // < Cxxx
        else begin
            case( A[13:12])
                2'b00: shared_cs   = 1'b1;
                2'b01: mcu_irqmain = 1'b1;
                2'b10: irq_clr     = 1'b1;
                default:;
            endcase
        end
    end
end

// Input multiplexer
wire [7:0] sh2mcu_dout;

always @(*) begin
    case(1'b1)
        rom_cs:    cpu_din = rom_data;
        shared_cs: cpu_din = sh2mcu_dout;
        default:   cpu_din = 8'hff;
    endcase
end

wire halted;

jtframe_z80_wait u_sub(
    .rst_n      ( ~rst          ),
    .clk        ( clk           ),
    .cen        ( cen4          ),
    .int_n      ( int_n         ),
    .nmi_n      ( 1'b1          ),
    .busrq_n    ( 1'b1          ),
    .m1_n       (               ),
    .mreq_n     ( mreq_n        ),
    .iorq_n     (               ),
    .rd_n       (               ),
    .wr_n       (               ),
    .rfsh_n     (               ),
    .halt_n     (               ),
    .busak_n    (               ),
    .A          ( A             ),
    .din        ( cpu_din       ),
    .dout       ( cpu_dout      ),
    // ROM access
    .rom_cs     ( rom_cs        ),
    .rom_ok     ( rom_ok        )
);

jtframe_dual_ram #(.aw(10)) u_shared(
    .clk0   ( clk         ),
    .clk1   ( clk         ),

    .data0  ( mcu_dout    ),
    .addr0  ( A[9:0]      ),
    .we0    ( ~rnw & shared_cs  ),
    .q0     ( sh2mcu_dout ),
    
    .data1  ( main_dout    ),
    .addr1  ( main_AB[9:0] ),
    .we1    ( ~main_wrn & com_cs /*& halted*/),
    .q1     ( shared_dout )
);

`ifdef SIMULATION
always @(posedge mcu_halt)   $display("MCU_HALT rose");
always @(negedge mcu_halt)   $display("MCU_HALT fell");
always @(posedge mcu_nmi_set) $display("MCU NMI set");
`endif
endmodule
