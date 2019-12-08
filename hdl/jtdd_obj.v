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

// Schematics 3-7/10 OBJ
// Object layer

module jtdd_obj(
    input              clk,
    input              rst,
    (*direct_enable*)  input pxl2_cen,
    (*direct_enable*)  input pxl_cen,
    input      [ 7:0]  cpu_AB,
    input              obj_cs,
    input              cpu_wrn,
    input      [ 7:0]  cpu_dout,
    input              cen_E,
    output reg [ 7:0]  obj_dout,
    // screen
    input      [ 7:0]  HPOS,
    input      [ 7:0]  hn,
    input      [ 7:0]  VPOS,
    input              flip,
    input              VBL,
    // ROM access
    output reg [17:0]  rom_addr,
    input      [15:0]  rom_data,
    input              rom_ok,
    output reg [ 7:0]  obj_pxl
);

// RAM area shared with CPU
reg  [ 7:0] ram_addr, scan;
reg  last_VBL;
wire negedge_VBL = !VBL && last_VBL;

always @(posedge clk, posedge rst) begin : copy_cnt
    if( rst ) begin
        last_VBL <= 1'b0;
        scan     <= 8'd0;
    end else if(pxl_cen) begin
        last_VBL <= VBL;
        if( negedge_VBL )
    end
end

always @(*) begin
    ram_we    = scr_cs && !cpu_wrn;
    ram_addr  = obj_cs ? : hn;
end

jtframe_ram #(.aw(8),.simfile("obj.bin")) u_ram(
    .clk    ( clk         ),
    .cen    ( cen_E       ),
    .data   ( cpu_dout    ),
    .addr   ( ram_addr    ),
    .we     ( ram_we      ),
    .q      ( obj_dout    )
);

// Line obj data buffers
reg         line;
reg [7:0]   databuf0_D, databuf1_D, databuf0_A, databuf1_A;
reg         databuf0_W, databuf1_W;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        line      <= 1'b0;
    end else begin
        if( negedge_VBL ) begin
            line      <= ~line;
    end 
end

always @(*) begin
    if( line ) begin
        
    end else begin
    end
end

jtframe_ram #(.aw(8)) u_databuf0(
    .clk    ( clk         ),
    .cen    ( 1'b1        ),
    .data   ( databuf0_D  ),
    .addr   ( databuf0_A  ),
    .we     ( databuf0_W  ),
    .q      ( databuf0_Q  )
);

jtframe_ram #(.aw(8)) u_databuf1(
    .clk    ( clk         ),
    .cen    ( 1'b1        ),
    .data   ( databuf1_D  ),
    .addr   ( databuf1_A  ),
    .we     ( databuf1_W  ),
    .q      ( databuf1_Q  )
);

// Line pixel buffers

reg         hi_we, lo_we;
wire [ 7:0] hi_data, lo_data;



reg  [15:0] shift;
reg  [ 3:0] pal;
reg         hflip;
wire [ 3:0] mux = hflip ? shift[15:12] : shift[3:0];

// pixel output
always @(posedge clk) if(pxl_cen) begin
    case( HPOS[1:0] ) 
        2'b0: begin
            rom_addr  <= { hi_data[2:0], lo_data, hscr[3:2]^{2{hi_data[6]}}, vscr[3:0] };
            pal       <= { hi_data[7], hi_data[5:3] }; // bit 7 affects priority
            hflip     <= hi_data[6];
            shift     <= { 
                rom_data[15], rom_data[11], rom_data[7], rom_data[3],
                rom_data[14], rom_data[10], rom_data[6], rom_data[2],
                rom_data[13], rom_data[ 9], rom_data[5], rom_data[1],
                rom_data[12], rom_data[ 8], rom_data[4], rom_data[0] };
            scr_pxl  <= { pal, mux };
        end
        default: begin
            scr_pxl  <= { pal, shift[3:0] };
            shift    <= hflip ? (shift<<4) : (shift>>4);
        end
    endcase
end

jtframe_ram #(.aw(10),.simfile("scr_hi.bin")) u_ram_high(
    .clk    ( clk         ),
    .cen    ( cen_E       ),
    .data   ( cpu_dout    ),
    .addr   ( ram_addr    ),
    .we     ( hi_we       ),
    .q      ( hi_data     )
);

jtframe_ram #(.aw(10),.simfile("scr_lo.bin")) u_ram_low(
    .clk    ( clk         ),
    .cen    ( cen_E       ),
    .data   ( cpu_dout    ),
    .addr   ( ram_addr    ),
    .we     ( lo_we       ),
    .q      ( lo_data     )
);

endmodule