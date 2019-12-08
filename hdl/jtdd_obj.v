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
// Max 32 sprites per line

module jtdd_obj(
    input              clk,
    input              rst,
    (*direct_enable*)  input pxl_cen,
    input      [ 8:0]  cpu_AB,
    input              obj_cs,
    input              cpu_wrn,
    input      [ 7:0]  cpu_dout,
    output reg [ 7:0]  obj_dout,
    // screen
    input      [ 7:0]  HPOS,
    input      [ 7:0]  VPOS,
    input              flip,
    input              HBL,
    // ROM access
    output reg [17:0]  rom_addr,
    input      [15:0]  rom_data,
    input              rom_ok,
    output reg [ 7:0]  obj_pxl
);

assign rom_addr = 18'd0;
assign obj_pxl  = 8'd0;

// RAM area shared with CPU
reg  [ 8:0] ram_addr, scan;
reg  [ 2:0] offset;
reg  [ 4:0] maxline;
wire [ 8:0] next_scan = scan + 9'd5;
wire        scan_done = next_scan == 9'd510;

reg  last_HBL, wait_mem;
wire negedge_HBL = !HBL && last_HBL;

reg  [ 7:0] scan_y, scan_attr, scan_attr2, scan_id, scan_x;
wire [ 8:0] sumy = {1'b0, VPOS } + { 1'b0, scan_y };
wire inzone = &{ sumy[7:5], ~(obj_dout[0]^sumy[8]), sumy[4]|obj_dout[4] };

reg  copy_done;
reg  line, copy;
reg  ram_we;

integer state;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        last_HBL <= 1'b0;
        scan     <= 9'd0;
        offset   <= 3'd0;
        line     <= 1'b1;
        state    <= 0;
        maxline  <= 5'd0;
    end else begin
        last_HBL <= HBL;
        case( state )
            0: if(negedge_HBL) begin // wait for non blanking
                state    <= state+1;
                line     <= ~line;
                scan     <= 9'd0;
                offset   <= 3'd0;
                wait_mem <= 1'b1;
                maxline  <= 5'd0;
            end
            1: begin // get object's y
                wait_mem <= 1'b0;
                if( !wait_mem ) begin
                    scan_y    <= obj_dout; // +0
                    offset   <= 3'd1;
                    wait_mem <= 1'b1;
                    state    <= state+1;
                end
            end
            2: begin // advance until a visible object is found
                wait_mem  <= 1'b0;
                if( !wait_mem ) begin
                    scan_attr <= obj_dout; // +1
                    if( !inzone || !obj_dout[7] /*enable bit*/ ) begin
                        if( !scan_done ) begin
                            state    <= 1;
                            offset   <= 3'd0; // try next object
                            scan     <= next_scan;
                            wait_mem <= 1'b1;
                        end else begin
                            state    <= 0; // wait for next line
                        end
                    end
                    else begin
                        scan_y <= sumy[7:0]; // update the value
                        offset <= 3'd3;
                        state  <= 3;
                    end
                end else begin
                    offset <= 3'd2;
                end
            end
            3: begin
                offset     <= 3'd4;
                scan_attr2 <= obj_dout; // +2
                state      <= 4;
            end
            4: begin
                scan_id <= obj_dout; // +3
                state   <= 5;
            end
            5: begin
                scan_x  <= obj_dout; // +4
                state   <= 6;
                copy    <= 1'b1;
            end
            6: begin
                if( copy_done ) begin
                    if( !scan_done & ~&maxline ) begin
                        state    <= 1;
                        offset   <= 3'd0; // try next object
                        scan     <= next_scan;
                        wait_mem <= 1'b1;
                        maxline  <= maxline + 5'd1;
                    end else begin
                        state    <= 0; // wait for next line
                    end                
                end
            end
        endcase
    end
end

always @(*) begin
    ram_we    = obj_cs && !cpu_wrn;
    ram_addr  = obj_cs ? cpu_AB : ( scan + {5'd0,offset} );
end

jtframe_ram #(.aw(9),.simfile("obj.bin")) u_ram(
    .clk    ( clk         ),
    .cen    ( cen_E       ),
    .data   ( cpu_dout    ),
    .addr   ( ram_addr    ),
    .we     ( ram_we      ),
    .q      ( obj_dout    )
);

// pixel drawing
reg  [3:0] pxl_cnt=0;
reg        copying;
wire       hflip = scan_attr[3];
wire       vflip = scan_attr[2];
wire [3:0] pal   = scan_attr2[7:4];
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        copy_done <= 1'b0;
        copying <= 1'b0;
    end else begin
        copy_done <= 1'b0;
        if( copy && !copying) begin
            copying <= 1'b1;
            pxl_cnt <= 4'd0;
        end
        if( copy || copying ) begin
            rom_addr  <= { scan_attr2[3:0], scan_id, pxl_cnt[3:2], scan_y[3:0] };
        end
        if( copying ) begin
            if(rom_ok) begin
                pxl_cnt <= pxl_cnt+1;
                if(pxl_cnt==4'hf) begin
                    copy_done<=1'b1;
                    copying  <=1'b0;
                end
            end
            case( pxl_cnt[1:0] ) 
                2'b0: begin
                    shift     <= { 
                        rom_data[15], rom_data[11], rom_data[7], rom_data[3],
                        rom_data[14], rom_data[10], rom_data[6], rom_data[2],
                        rom_data[13], rom_data[ 9], rom_data[5], rom_data[1],
                        rom_data[12], rom_data[ 8], rom_data[4], rom_data[0] };
                end
                default: begin
                    shift    <= hflip ? (shift<<4) : (shift>>4);
                end
            endcase            
        end
    end

end


endmodule