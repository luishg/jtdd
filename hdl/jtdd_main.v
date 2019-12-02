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


module jtdd_main(
    input              clk,
    input              rst,
    input              cpu_cen,
    input              VBL,
    output  reg        blue_cs,
    output  reg        redgreen_cs,
    output  reg        flip,
    // Sound
    output  reg        sres_b, // Z80 reset
    output  reg [7:0]  snd_latch,
    // Characters
    input       [7:0]  char_dout,
    output      [7:0]  cpu_dout,
    output  reg        char_cs,
    input              char_busy,
    // scroll
    input       [7:0]  scr_dout,
    output  reg        scr_cs,
    input              scr_busy,
    output  reg [8:0]  scr_hpos,
    output  reg [8:0]  scr_vpos,
    input              scr_holdn,
    // cabinet I/O
    input       [1:0]  start_button,
    input       [1:0]  coin_input,
    input       [5:0]  joystick1,
    input       [5:0]  joystick2,
    // BUS sharing
    output             bus_ack,
    input              bus_req,
    input              blcnten,
    input   [ 8:0]     obj_AB,
    output  [12:0]     cpu_AB,
    output             RnW,
    output reg         OKOUT,
    output  [7:0]      ram_dout,
    // ROM access
    output  reg        rom_cs,
    output  reg [17:0] rom_addr,
    input       [ 7:0] rom_data,
    input              rom_ok,
    // DIP switches
    input              dip_pause,
    input  [7:0]       dipsw_a,
    input  [7:0]       dipsw_b
);

wire [15:0] A;
wire MRDY, E, Q;
wire nRESET;
reg sound_cs, scrpos_cs, io_cs, flip_cs, ram_cs, bank_cs;

assign cpu_cen = cen3;

reg [7:0] AH;

wire M1Hn = ~M1H;

// These refer to memory locations to which a write operation
// has some hardware effect. In reality A[3] must be high too
// so the labels are incorrect. But I keep the ones used in the
// schematics
reg w3801, w3802, w3803, w3804, w3805, w3806, w3807;

always @(*) begin
    sound_cs    = 1'b0;
    OKOUT       = 1'b0;
    scrpos_cs   = 1'b0;
    scr_cs      = 1'b0;
    io_cs       = 1'b0;
    blue_cs     = 1'b0;
    redgreen_cs = 1'b0;
    flip_cs     = 1'b0;
    ram_cs      = 1'b0;
    char_cs     = 1'b0;
    banked_cs   = 1'b0;
    rom_cs      = 1'b0;
    w3801       = 1'b0;
    w3802       = 1'b0;
    w3803       = 1'b0;
    w3804       = 1'b0;
    w3805       = 1'b0;
    w3806       = 1'b0;
    w3807       = 1'b0;
    if( A[15:14]==2'b00 && M1Hn ) begin
        case(A[13:11])
            3'd0, 3'd1, 3'd3: ram_cs = 1'b1;
            3'd2: pal_cs = 1'b1;
            3'd4: com_cs = mcu_ba;
            3'd5: obj_cs = 1'b1;
            3'd6: scr_cs = 1'b1;
            3'd7: begin
                io_cs  = 1'b1;
                if( RnW ) begin
                end else if(A[3]) begin // write
                    case( A[2:0] )
                        3'd0: misc_cs = 1'b1;
                        3'd1: w3801   = 1'b1;
                        3'd2: w3802   = 1'b1;
                        3'd3: w3803   = 1'b1;
                        3'd4: w3804   = 1'b1;
                        3'd5: w3805   = 1'b1;
                        3'd6: w3806   = 1'b1;
                        3'd7: w3807   = 1'b1;
                    endcase
                end
            end
        endcase
    end else begin
        rom_cs    = A[15] | A[14];
    end
end

// SCROLL H/V POSITION
always @(posedge clk or negedge nRESET)
    if( !nRESET ) begin
        scr_hpos <= 8'd0;
        scr_vpos <= 8'd0;
    end else if(cen6) begin
        if( scrpos_cs && A[3] && scr_holdn)
        case(A[1:0])
            2'd0: scr_hpos[7:0] <= cpu_dout;
            2'd1: scr_hpos[8]   <= cpu_dout[0];
            2'd2: scr_vpos[7:0] <= cpu_dout;
            2'd3: scr_vpos[8]   <= cpu_dout[0];
        endcase
    end

// special registers
reg [2:0] bank;
always @(posedge clk or negedge nRESET)
    if( !nRESET ) begin
        bank   <= 3'd0;
    end
    else if(cen6) begin
        if( bank_cs && !RnW ) begin
            bank <= cpu_dout[2:0];
        end
    end

// CPU reset
jt12_rst u_rst(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .rst_n  ( nRESET    )
);

localparam coinw = 4;
reg [coinw-1:0] coin_cnt1, coin_cnt2;

always @(posedge clk)
    if( rst ) begin
        coin_cnt1 <= {coinw{1'b0}};
        coin_cnt2 <= {coinw{1'b0}};
        flip <= 1'b0;
        sres_b <= 1'b1;
        end
    else if(cen6) begin
        if( flip_cs )
            case(A[2:0])
                3'd0: flip <= cpu_dout[0];
                3'd1: sres_b <= cpu_dout[0];
                3'd2: coin_cnt1 <= coin_cnt1+{ {(coinw-1){1'b0}}, cpu_dout[0] };
                3'd3: coin_cnt2 <= coin_cnt2+{ {(coinw-1){1'b0}}, cpu_dout[0] };
                default:;
            endcase
    end

always @(posedge clk)
    if( rst )
        snd_latch <= 8'd0;
    else if(cen6) begin
        if( sound_cs ) snd_latch <= cpu_dout;
    end

reg [7:0] cabinet_input;

always @(*)
    case( cpu_AB[3:0])
        4'd0: cabinet_input = { coin_input, // COINS
                     4'hf, // undocumented. The game start screen has background when set to 0!
                     start_button }; // START
        4'd1: cabinet_input = { 2'b11, joystick1 };
        4'd2: cabinet_input = { 2'b11, joystick2 };
        4'd3: cabinet_input = dipsw_a;
        4'd4: cabinet_input = dipsw_b;
        default: cabinet_input = 8'hff;
    endcase


// RAM, 8kB
wire cpu_ram_we = ram_cs && !RnW;
assign cpu_AB = A[12:0];

wire [12:0] RAM_addr = blcnten ? { 4'hf, obj_AB } : cpu_AB;
wire RAM_we   = blcnten ? 1'b0 : cpu_ram_we;

jtframe_ram #(.aw(13)) u_ram(
    .clk        ( clk       ),
    .cen        ( cen6      ),
    .addr       ( RAM_addr  ),
    .data       ( cpu_dout  ),
    .we         ( RAM_we    ),
    .q          ( ram_dout  )
);

reg [7:0] cpu_din;

always @(*)
    case( {ram_cs, char_cs, scr_cs, rom_cs, io_cs} )
        5'b10_000: cpu_din =  ram_dout;
        5'b01_000: cpu_din = char_dout;
        5'b00_100: cpu_din =  scr_dout;
        5'b00_010: cpu_din =  rom_data;
        5'b00_001: cpu_din =  cabinet_input;
        default:   cpu_din =  rom_data;
    endcase

always @(A,bank) begin
    rom_addr[12:0] = A[12:0];
    casez( A[15:13] )
        3'b1??: rom_addr[16:13] = { 2'h0, A[14:13] }; // 8N, 9N (32kB) 0x8000-0xFFFF
        3'b011: rom_addr[16:13] = 4'b101; // 10N - 0x6000-0x7FFF (8kB)
        3'b010:  // 0x4000-0x5FFF
          rom_addr[16:13] = bank==3'd4 ? 4'b100 : {2'd0,bank[1:0]}+4'b110; // 13N
        default: rom_addr[16:13] = 4'd0;
    endcase
end

// Bus access
reg nIRQ, last_LVBL;
wire BS,BA;

assign bus_ack = BA && BS;

always @(posedge clk) if(cen6) begin
    last_LVBL <= LVBL;
    if( {BS,BA}==2'b10 )
        nIRQ <= 1'b1;
    else
        if(last_LVBL && !LVBL ) nIRQ<=1'b0 | ~dip_pause; // when LVBL goes low
end

jtframe_z80wait #(2) u_wait(
    .rst_n      ( nRESET    ),
    .clk        ( clk       ),
    .cpu_cen    ( cpu_cen   ),
    // manage access to shared memory
    .dev_busy   ( { scr_busy, char_busy } ),
    // manage access to ROM data from SDRAM
    .rom_cs     ( rom_cs    ),
    .rom_ok     ( rom_ok    ),

    .wait_n     ( MRDY      )
);

wire nIRQ, nFIRQ, nNMI;

jtframe_ff #(.W(3)) u_irq(
    .clk    (   clk                   ),
    .clk    (   rst                   ),
    .cen    (   1'b1                  ),
    .edge   ( { VBL, IMS, irq2 }      ),
    .clr    ( { w3803, w3804, w3805 } ),
    .set    ( 3'b0                    ),
    .q      (                         ),
    .qn     ( { nNMI, nFIRQ, nIRQ }   )
);

// cycle accurate core
mc6809e u_cpu(
    .D       ( cpu_din ),
    .DOut    ( cpu_dout),
    .ADDR    ( A       ),
    .RnW     ( RnW     ),
    .E       ( clk_E   ),
    .Q       ( clk_Q   ),
    .BS      (         ),
    .BA      (         ),
    .nIRQ    ( nIRQ    ),
    .nFIRQ   ( nFIRQ   ),
    .nNMI    ( nNMI    ),
    .AVMA    (         ),
    .BUSY    (         ),
    .LIC     (         ),
    .nHALT   ( 1'b1    ),   
    .nRESET  ( nRESET  )
);

endmodule // jtdd_main