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

module jtdd_game(
    input           clk,
    input           rst,
    output          pxl2_cen,
    output          pxl_cen,
    output          LVBL_dly,
    output          LHBL_dly,
    output          HS,
    output          VS,
    // cabinet I/O
    input   [ 1:0]  start_button,
    input   [ 1:0]  coin_input,
    input   [ 6:0]  joystick1,
    input   [ 6:0]  joystick2,
    // SDRAM interface
    input           downloading,
    output          dwnld_busy,
    input           loop_rst,
    output          sdram_req,
    output  [21:0]  sdram_addr,
    input   [31:0]  data_read,
    input           data_rdy,
    input           sdram_ack,
    output          refresh_en,
    // ROM LOAD
    input   [21:0]  ioctl_addr,
    input   [ 7:0]  ioctl_data,
    input           ioctl_wr,
    output  [21:0]  prog_addr,
    output  [ 7:0]  prog_data,
    output  [ 1:0]  prog_mask,
    output          prog_we,
    output          prog_rd,
    // DIP switches
    input   [31:0]  status,     // only bits 31:16 are looked at
    input           dip_pause,
    input           dip_flip,
    input           dip_test,
    input   [ 1:0]  dip_fxlevel, // Not a DIP on the original PCB   
    // Sound output (stereo game)
    output  signed [15:0] snd_left,
    output  signed [15:0] snd_right,
    output          sample,
    input           enable_psg,
    input           enable_fm,
    // video
    output  [ 3:0]  red,
    output  [ 3:0]  green,
    output  [ 3:0]  blue,
    // Debug
    input   [ 3:0]  gfx_en

);

wire       [12:0]  cpu_AB;
wire               pal_cs;
wire               char_cs, scr_cs, obj_cs;
wire               cpu_wrn;
wire       [ 7:0]  cpu_dout;
wire               cen_E, cen_Q;
wire       [ 7:0]  char_dout, scr_dout, obj_dout, pal_dout;
// video signals
wire               VBL, HBL, IMS;
wire               flip;
// ROM access
wire       [14:0]  char_addr;
wire       [ 7:0]  char_data;
wire       [16:0]  scr_addr;
wire       [17:0]  obj_addr;
wire       [15:0]  scr_data, obj_data;
wire               char_ok, scr_ok, obj_ok, main_ok;
wire       [17:0]  main_addr;
wire               main_cs;
wire       [ 7:0]  main_data;
wire       [13:0]  mcu_addr;
wire       [ 7:0]  mcu_data;
wire               mcu_cs, mcu_ok;
// Sound
wire               snd_rstb, snd_irq;
wire       [ 7:0]  snd_latch;
// DIP
wire       [ 7:0]  dipsw_a, dipsw_b;
// MCU
wire               mcu_irqmain, mcu_halt, com_cs, mcu_nmi_set, mcu_ban;
wire       [ 7:0]  mcu_ram;
// PROM programming
wire               prom_prio_we;

wire       [ 8:0]  scrhpos, scrvpos;

assign dwnld_busy = downloading;

wire cen12, cen8, cen6, cen3, cen3q, cen1p5, cen12b, cen6b, cen3b, cen3qb;
wire cpu_cen;
wire rom_ready;

assign cen_E    = cen3b;
assign cen_Q    = cen3qb;
assign pxl_cen  = cen6;
assign pxl2_cen = cen12;

`ifdef MISTER

reg rst_game;

always @(negedge clk)
    rst_game <= rst || !rom_ready;

`else

reg rst_game=1'b1;

always @(posedge clk) begin : rstgame_gen
    reg rst_aux;
    if( rst || !rom_ready ) begin
        {rst_game,rst_aux} <= 2'b11;
    end
    else begin
        {rst_game,rst_aux} <= {rst_aux, downloading };
    end
end

`endif

jtframe_cen48 u_cen(
    .clk     (  clk      ),    // 48 MHz
    .cen12   (  cen12    ),
    .cen8    (  cen8     ),
    .cen6    (  cen6     ),
    .cen3    (  cen3     ),
    .cen3b   (  cen3b    ),
    .cen3q   (  cen3q    ), // 1/4 advanced with respect to cen3
    .cen3qb  (  cen3qb   ), // 1/4 advanced with respect to cen3b
    .cen1p5  (  cen1p5   ),
    .cen12b  (  cen12b   ),
    .cen6b   (  cen6b    )
);

jtdd_prom_we u_prom(
    .clk          ( clk             ),
    .downloading  ( downloading     ),
    .ioctl_addr   ( ioctl_addr      ),
    .ioctl_data   ( ioctl_data      ),
    .ioctl_wr     ( ioctl_wr        ),
    .prog_addr    ( prog_addr       ),
    .prog_data    ( prog_data       ),
    .prog_mask    ( prog_mask       ),
    .prog_we      ( prog_we         ),
    .prom_we      ( prom_prio_we    )
);

jtdd_dip u_dip(
    .clk        (  clk          ),
    .status     (  status       ),
    .dip_pause  (  dip_pause    ),
    .dip_test   (  dip_test     ),
    .dip_flip   (  dip_flip     ),
    .dipsw_a    (  dipsw_a      ),
    .dipsw_b    (  dipsw_b      )
);

jtdd_main u_main(
    .clk            ( clk           ),
    .rst            ( rst_game      ),
    .cen_E          ( cen_E         ),
    .cen_Q          ( cen_Q         ),
    .cpu_cen        ( cpu_cen       ),
    .VBL            ( VBL           ),
    .IMS            ( IMS           ), // =VPOS[3]
    // MCU
    .mcu_irqmain    ( mcu_irqmain   ),
    .mcu_halt       ( mcu_halt      ),
    .mcu_ban        ( mcu_ban       ),
    .com_cs         ( com_cs        ),
    .mcu_nmi_set    ( mcu_nmi_set   ),
    .mcu_ram        ( mcu_ram       ),
    // Palette
    .pal_cs         ( pal_cs        ),
    .pal_dout       ( pal_dout      ),
    .flip           ( flip          ),
    // Sound
    .snd_rstb       ( snd_rstb      ),
    .snd_irq        ( snd_irq       ),
    .snd_latch      ( snd_latch     ),
    // Characters
    .char_dout      ( char_dout     ),
    .cpu_dout       ( cpu_dout      ),
    .char_cs        ( char_cs       ),
    // Objects
    .obj_dout       ( obj_dout      ),
    .obj_cs         ( obj_cs        ),
    // scroll
    .scr_dout       ( scr_dout      ),
    .scr_cs         ( scr_cs        ),
    .scrhpos        ( scrhpos       ),
    .scrvpos        ( scrvpos       ),
    // cabinet I/O
    .start_button   ( start_button  ),
    .coin_input     ( coin_input    ),
    .joystick1      ( joystick1     ),
    .joystick2      ( joystick2     ),
    // BUS sharing
    .cpu_AB         ( cpu_AB        ),
    .RnW            ( cpu_wrn       ),
    // ROM access
    .rom_cs         ( main_cs       ),
    .rom_addr       ( main_addr     ),
    .rom_data       ( main_data     ),
    .rom_ok         ( main_ok       ),
    // DIP switches
    .dip_pause      ( dip_pause     ),
    .dip_test       ( dip_test      ),
    .dipsw_a        ( dipsw_a       ),
    .dipsw_b        ( dipsw_b       )
);

`ifndef NOMCU
jtdd_mcu u_mcu(
    .clk          (  clk             ),
    .rst          (  rst_game        ),
    .cen_Q        (  cpu_cen         ),
    .cen6         (  cen6            ),
    // CPU bus
    .cpu_AB       (  cpu_AB[8:0]     ),
    .cpu_wrn      (  cpu_wrn         ),
    .cpu_dout     (  cpu_dout        ),
    .shared_dout  (  mcu_ram         ),
    // CPU Interface
    .com_cs       (  com_cs          ),
    .mcu_nmi_set  (  mcu_nmi_set     ),
    .mcu_halt     (  mcu_halt        ),
    .mcu_irqmain  (  mcu_irqmain     ),
    .mcu_ban      (  mcu_ban         ),
    // PROM programming
    .rom_addr     (  mcu_addr        ),
    .rom_data     (  mcu_data        ),
    .rom_cs       (  mcu_cs          ),
    .rom_ok       (  mcu_ok          )
);
`else 
reg    irqmain;
assign mcu_irqmain = irqmain;
assign mcu_ban = 1'b0;
always @(posedge clk) irqmain <= mcu_nmi_set;
wire shared_we = com_cs && !cpu_wrn;
jtframe_ram #(.aw(9)) u_shared(
    .clk    ( clk         ),
    .cen    ( cpu_cen     ),
    .data   ( cpu_dout    ),
    .addr   ( cpu_AB[8:0] ),
    .we     ( shared_we   ),
    .q      ( mcu_ram     )
);
`endif

jtdd_video u_video(
    .clk          (  clk             ),
    .rst          (  rst             ),
    .pxl_cen      (  pxl_cen         ),
    .cen12        (  cen12           ),
    .cpu_AB       (  cpu_AB          ),
    .pal_cs       (  pal_cs          ),
    .char_cs      (  char_cs         ),
    .scr_cs       (  scr_cs          ),
    .obj_cs       (  obj_cs          ),
    .cpu_wrn      (  cpu_wrn         ),
    .cpu_dout     (  cpu_dout        ),
    .cen_Q        (  cpu_cen         ),
    .char_dout    (  char_dout       ),
    .scr_dout     (  scr_dout        ),
    .obj_dout     (  obj_dout        ),
    .pal_dout     (  pal_dout        ),
    // Scroll position
    .scrhpos      ( scrhpos          ),
    .scrvpos      ( scrvpos          ),
    // video signals
    .VBL          (  VBL             ),
    .LVBL_dly     (  LVBL_dly        ),
    .VS           (  VS              ),
    .HBL          (  HBL             ),
    .LHBL_dly     (  LHBL_dly        ),
    .HS           (  HS              ),
    .IMS          (  IMS             ),
    .flip         (  flip            ),
    // ROM access
    .char_addr    (  char_addr       ),
    .char_data    (  char_data       ),
    .char_ok      (  char_ok         ),
    .scr_addr     (  scr_addr        ),
    .scr_data     (  scr_data        ),
    .scr_ok       (  scr_ok          ),
    .obj_addr     (  obj_addr        ),
    .obj_data     (  obj_data        ),
    .obj_ok       (  obj_ok          ),
    // PROM programming
    .prog_addr    (  prog_addr[7:0]  ),
    .prom_prio_we (  prom_prio_we    ),
    .prom_din     (  prog_data[3:0]  ),
    // Pixel output
    .red          (  red             ),
    .green        (  green           ),
    .blue         (  blue            )
);

// Same as locations inside JTDD.rom file
localparam BANK_ADDR   = 22'h0_0000;
localparam MAIN_ADDR   = 22'h2_0000;
localparam SND_ADDR    = 22'h2_8000;
localparam ADPCM_1     = 22'h3_0000;
localparam ADPCM_2     = 22'h4_0000;
localparam CHAR_ADDR   = 22'h5_0000;

// reallocated:
localparam SCR_ADDR  = 22'h4_0000;
localparam OBJ_ADDR  = 22'h8_0000;


jtframe_rom #(
    .char_aw    ( 15              ),
    .char_dw    ( 8               ),
    .main_aw    ( 18              ),
    .obj_aw     ( 18              ),
    .scr1_aw    ( 17              ),
    .scr2_aw    ( 15              ),
    .snd2_aw    ( 14              ), // MCU
    // MAP slots used for ADPCM
    .snd_offset ( SND_ADDR>>1     ),
    .snd2_offset( 22'hC_0000      ), // MCU
    .char_offset( CHAR_ADDR>>1    ),
    .scr1_offset( SCR_ADDR        ),
    .scr2_offset(  ),
    .obj_offset ( OBJ_ADDR        )
) u_rom (
    .rst         ( rst           ),
    .clk         ( clk           ),
    .LVBL        ( ~VBL          ),
    .pause       ( ~dip_pause    ),

    .main_cs     ( main_cs       ),
    .snd_cs      ( 1'b0          ),
    .snd2_cs     ( mcu_cs        ),
    .main_ok     ( main_ok       ),
    .snd_ok      (               ),
    .snd2_ok     ( mcu_ok        ),
    .scr1_ok     ( scr_ok        ),
    .scr2_ok     (               ),
    .char_ok     ( char_ok       ),
    .obj_ok      ( obj_ok        ),

    .char_addr   ( char_addr     ),
    .main_addr   ( main_addr     ),
    .snd_addr    ( 15'd0         ),
    .snd2_addr   ( mcu_addr      ),
    .obj_addr    ( obj_addr      ),
    .scr1_addr   ( scr_addr      ),
    .scr2_addr   ( 15'd0         ),
    .map1_addr   ( 14'd0         ),
    .map2_addr   ( 14'd0         ),

    .char_dout   ( char_data     ),
    .main_dout   ( main_data     ),
    .snd_dout    (               ),
    .snd2_dout   ( mcu_data      ),
    .obj_dout    ( obj_data      ),
    .map1_dout   (               ),
    .map2_dout   (               ),
    .scr1_dout   ( scr_data      ),
    .scr2_dout   (               ),

    .ready       ( rom_ready     ),
    // SDRAM interface
    .sdram_req   ( sdram_req     ),
    .sdram_ack   ( sdram_ack     ),
    .data_rdy    ( data_rdy      ),
    .downloading ( downloading   ),
    .loop_rst    ( loop_rst      ),
    .sdram_addr  ( sdram_addr    ),
    .data_read   ( data_read     ),
    .refresh_en  ( refresh_en    )
);

endmodule