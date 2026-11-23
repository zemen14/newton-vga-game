`timescale 1ns / 1ps

module top (
    input clkin,
    input btnU,
    input btnC,
    input btnL,
    input btnR,
    input btnD,
    input [15:0] sw,
    output [6:0] seg,
    output dp,
    output [3:0] an,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output vgaHs,
    output vgaVs,
    output [3:0] vga_red,
    output [3:0] vga_green,
    output [3:0] vga_blue,
    output vga_hs,
    output vga_vs,
    output [15:0] led,
    output [3:0] hdmi_red,
    output [3:0] hdmi_green,
    output [3:0] hdmi_blue,
    output hdmi_hs,
    output hdmi_vs,
    output hdmi_clk,
    output hdmi_dispen
);

`ifdef XILINX_SIMULATOR
wire clk = clkin;
wire [1:0] div4_cnt, div4_n;
assign div4_n = div4_cnt + 2'd1;
FDRE #(.INIT(1'b0)) d40(.C(clkin),.CE(1'b1),.R(btnU),.D(div4_n[0]),.Q(div4_cnt[0]));
FDRE #(.INIT(1'b0)) d41(.C(clkin),.CE(1'b1),.R(btnU),.D(div4_n[1]),.Q(div4_cnt[1]));
wire sim_ce = (div4_cnt == 2'd3); // pulses at 25 MHz
`else
wire clk;
labVGA_clks pll (.clkin(clkin),.greset(btnU),.clk(clk));
wire sim_ce = 1'b1; // full speed on board
`endif

wire [9:0] hcount_n, vcount_n, player_x_n, hcount, vcount, player_x, hn, vn;
wire hs_n, vs_n, act_n, hs, vs, act, hs_ff, vs_ff, act_ff, h_wrap, v_wrap;
wire [3:0] r_n, g_n, b_n, r, g, b, rq, gq, bq, pix_r, pix_g, pix_b;

wire [3:0] cnt0_n, cnt1_n, cnt2_n, cnt3_n, cnt4_n, cnt5_n, cnt6_n, cnt7_n;
wire [3:0] cnt0, cnt1, cnt2, cnt3, cnt4, cnt5, cnt6, cnt7;

wire [7:0] cnt0_full, cnt1_full, cnt2_full, cnt3_full, cnt4_full, cnt5_full, cnt6_full, cnt7_full;

wire color_ce, rst0, rst1, rst2, rst3, rst4, rst5, rst6, rst7;

wire [9:0] apple_y_n [0:7];
wire [9:0] apple_y [0:7];

wire [1:0] sel;
wire drop, btnC_db, sw0_db;
wire drop_n, btnC_db_n, sw0_db_n;
wire [9:0] drop_y;

wire [15:0] led_n;

// Clock divider and sync pulse generation

assign h_wrap = (hcount == 10'd799);
assign v_wrap = (vcount == 10'd524);
assign hn = h_wrap ? 10'd0 : hcount + 10'd1;
assign vn = h_wrap ? (v_wrap ? 10'd0 : vcount + 10'd1) : vcount;

FDRE h0 (.C(clk), .CE(sim_ce), .R(btnU), .D(hn[0]), .Q(hcount[0]));
FDRE h1 (.C(clk), .CE(sim_ce), .R(btnU), .D(hn[1]), .Q(hcount[1]));
FDRE h2 (.C(clk), .CE(sim_ce), .R(btnU), .D(hn[2]), .Q(hcount[2]));
FDRE h3 (.C(clk), .CE(sim_ce), .R(btnU), .D(hn[3]), .Q(hcount[3]));
FDRE h4 (.C(clk), .CE(sim_ce), .R(btnU), .D(hn[4]), .Q(hcount[4]));
FDRE h5 (.C(clk), .CE(sim_ce), .R(btnU), .D(hn[5]), .Q(hcount[5]));
FDRE h6 (.C(clk), .CE(sim_ce), .R(btnU), .D(hn[6]), .Q(hcount[6]));
FDRE h7 (.C(clk), .CE(sim_ce), .R(btnU), .D(hn[7]), .Q(hcount[7]));
FDRE h8 (.C(clk), .CE(sim_ce), .R(btnU), .D(hn[8]), .Q(hcount[8]));
FDRE h9 (.C(clk), .CE(sim_ce), .R(btnU), .D(hn[9]), .Q(hcount[9]));

FDRE v0 (.C(clk), .CE(sim_ce), .R(btnU), .D(vn[0]), .Q(vcount[0]));
FDRE v1 (.C(clk), .CE(sim_ce), .R(btnU), .D(vn[1]), .Q(vcount[1]));
FDRE v2 (.C(clk), .CE(sim_ce), .R(btnU), .D(vn[2]), .Q(vcount[2]));
FDRE v3 (.C(clk), .CE(sim_ce), .R(btnU), .D(vn[3]), .Q(vcount[3]));
FDRE v4 (.C(clk), .CE(sim_ce), .R(btnU), .D(vn[4]), .Q(vcount[4]));
FDRE v5 (.C(clk), .CE(sim_ce), .R(btnU), .D(vn[5]), .Q(vcount[5]));
FDRE v6 (.C(clk), .CE(sim_ce), .R(btnU), .D(vn[6]), .Q(vcount[6]));
FDRE v7 (.C(clk), .CE(sim_ce), .R(btnU), .D(vn[7]), .Q(vcount[7]));
FDRE v8 (.C(clk), .CE(sim_ce), .R(btnU), .D(vn[8]), .Q(vcount[8]));
FDRE v9 (.C(clk), .CE(sim_ce), .R(btnU), .D(vn[9]), .Q(vcount[9]));

// Sync pulse generation

assign hs_n = ~((hcount >= 10'd656) & (hcount < 10'd752));
assign vs_n = ~((vcount >= 10'd490) & (vcount < 10'd492));
assign act_n = (hcount < 10'd640) & (vcount < 10'd480);

FDRE hsf (.C(clk), .CE(sim_ce), .R(btnU), .D(hs_n), .Q(hs_ff));
FDRE vsf (.C(clk), .CE(sim_ce), .R(btnU), .D(vs_n), .Q(vs_ff));
FDRE actf (.C(clk), .CE(sim_ce), .R(btnU), .D(act_n), .Q(act_ff));

assign hs = hs_ff;
assign vs = vs_ff;
assign act = act_ff;

assign vga_hs = hs;
assign vga_vs = vs;
assign vgaHs = hs;
assign vgaVs = vs;
assign hdmi_hs = hs;
assign hdmi_vs = vs;

// Pixel color generation

wire in_top_row = (vcount >= 10'd40) & (vcount < 10'd50);
wire in_bot_row = (vcount >= 10'd160) & (vcount < 10'd170);
wire in_apple_row = in_top_row | in_bot_row;

wire [3:0] cur_g;

wire [2:0] cur_sel;

wire apple0 = in_apple_row & (hcount >= 10'd120) & (hcount < 10'd140);
wire apple1 = in_apple_row & (hcount >= 10'd250) & (hcount < 10'd270);
wire apple2 = in_apple_row & (hcount >= 10'd380) & (hcount < 10'd400);
wire apple3 = in_apple_row & (hcount >= 10'd510) & (hcount < 10'd530);

wire apple4 = in_apple_row & (hcount >= 10'd120) & (hcount < 10'd140);
wire apple5 = in_apple_row & (hcount >= 10'd250) & (hcount < 10'd270);
wire apple6 = in_apple_row & (hcount >= 10'd380) & (hcount < 10'd400);
wire apple7 = in_apple_row & (hcount >= 10'd510) & (hcount < 10'd530);

wire in_platform = (vcount >= 10'd462) & (vcount < 10'd472);
wire in_border = ((vcount >= 10'd0) & (vcount < 10'd8)) |
    ((vcount >= 10'd472) & (vcount < 10'd480)) |
    ((hcount >= 10'd0) & (hcount < 10'd8)) |
    ((hcount >= 10'd632) & (hcount < 10'd640));
wire in_player = (vcount >= 10'd452) & (vcount < 10'd462) &
    (hcount >= player_x) & (hcount < (player_x + 10'd10));

wire [3:0] apple_r = 4'd15 - cur_g;
wire [3:0] apple_g = cur_g;

wire [3:0] apple_color_r = apple0 ? apple_r :
    apple1 ? apple_r :
    apple2 ? apple_r :
    apple3 ? apple_r :
    apple4 ? apple_r :
    apple5 ? apple_r :
    apple6 ? apple_r :
    apple7 ? apple_r : 4'd0;

wire [3:0] apple_color_g = apple0 ? apple_g :
    apple1 ? apple_g :
    apple2 ? apple_g :
    apple3 ? apple_g :
    apple4 ? apple_g :
    apple5 ? apple_g :
    apple6 ? apple_g :
    apple7 ? apple_g : 4'd0;

assign sel = sw[1:0];
assign cur_sel = sel;

assign cur_g = (cur_sel == 3'd0) ? cnt0[3:0] :
    (cur_sel == 3'd1) ? cnt1[3:0] :
    (cur_sel == 3'd2) ? cnt2[3:0] :
    (cur_sel == 3'd3) ? cnt3[3:0] :
    (cur_sel == 3'd4) ? cnt4[3:0] :
    (cur_sel == 3'd5) ? cnt5[3:0] :
    (cur_sel == 3'd6) ? cnt6[3:0] :
    cnt7[3:0];

wire pre_active_h = (hn <= 10'd639);
wire pre_active_v = (vn <= 10'd479) & ~v_wrap;
wire pre_active = pre_active_h & pre_active_v;

assign r_n = ~pre_active ? 4'h0 : (in_border ? 4'd15 : (in_player ? 4'd15 : (in_apple_row ? apple_color_r : 4'd0)));
assign g_n = ~pre_active ? 4'h0 : (in_border ? 4'd0 : (in_platform ? 4'd15 : (in_player ? 4'd15 : (in_apple_row ? apple_color_g : 4'd0))));
assign b_n = ~pre_active ? 4'h0 : (in_border ? 4'd0 : (in_player ? 4'd0 : 4'd0));

FDRE r0 (.C(clk), .CE(sim_ce), .R(btnU), .D(r_n[0]), .Q(r[0]));
FDRE r1 (.C(clk), .CE(sim_ce), .R(btnU), .D(r_n[1]), .Q(r[1]));
FDRE r2 (.C(clk), .CE(sim_ce), .R(btnU), .D(r_n[2]), .Q(r[2]));
FDRE r3 (.C(clk), .CE(sim_ce), .R(btnU), .D(r_n[3]), .Q(r[3]));
FDRE g0 (.C(clk), .CE(sim_ce), .R(btnU), .D(g_n[0]), .Q(g[0]));
FDRE g1 (.C(clk), .CE(sim_ce), .R(btnU), .D(g_n[1]), .Q(g[1]));
FDRE g2 (.C(clk), .CE(sim_ce), .R(btnU), .D(g_n[2]), .Q(g[2]));
FDRE g3 (.C(clk), .CE(sim_ce), .R(btnU), .D(g_n[3]), .Q(g[3]));
FDRE b0 (.C(clk), .CE(sim_ce), .R(btnU), .D(b_n[0]), .Q(b[0]));
FDRE b1 (.C(clk), .CE(sim_ce), .R(btnU), .D(b_n[1]), .Q(b[1]));
FDRE b2 (.C(clk), .CE(sim_ce), .R(btnU), .D(b_n[2]), .Q(b[2]));
FDRE b3 (.C(clk), .CE(sim_ce), .R(btnU), .D(b_n[3]), .Q(b[3]));

assign rq = r;
assign gq = g;
assign bq = b;

assign vgaRed = rq;
assign vgaGreen = gq;
assign vgaBlue = bq;
assign vga_red = rq;
assign vga_green = gq;
assign vga_blue = bq;
assign hdmi_red = rq;
assign hdmi_green = gq;
assign hdmi_blue = bq;
assign hdmi_clk = clk;
assign hdmi_dispen = act;

// Player position logic

assign player_x_n = btnL ? (player_x - 10'd4) :
    btnR ? (player_x + 10'd4) :
    player_x;

FDRE px0 (.C(clk), .CE(1'b1), .R(btnU), .D(player_x_n[0]), .Q(player_x[0]));
FDRE px1 (.C(clk), .CE(1'b1), .R(btnU), .D(player_x_n[1]), .Q(player_x[1]));
FDRE px2 (.C(clk), .CE(1'b1), .R(btnU), .D(player_x_n[2]), .Q(player_x[2]));
FDRE px3 (.C(clk), .CE(1'b1), .R(btnU), .D(player_x_n[3]), .Q(player_x[3]));
FDRE px4 (.C(clk), .CE(1'b1), .R(btnU), .D(player_x_n[4]), .Q(player_x[4]));
FDRE px5 (.C(clk), .CE(1'b1), .R(btnU), .D(player_x_n[5]), .Q(player_x[5]));
FDRE px6 (.C(clk), .CE(1'b1), .R(btnU), .D(player_x_n[6]), .Q(player_x[6]));
FDRE px7 (.C(clk), .CE(1'b1), .R(btnU), .D(player_x_n[7]), .Q(player_x[7]));
FDRE px8 (.C(clk), .CE(1'b1), .R(btnU), .D(player_x_n[8]), .Q(player_x[8]));
FDRE px9 (.C(clk), .CE(1'b1), .R(btnU), .D(player_x_n[9]), .Q(player_x[9]));

// Apple drop logic

assign drop_n = btnC_db;
assign sw0_db_n = sw[0];

FDRE df (.C(clk), .CE(1'b1), .R(btnU), .D(drop_n), .Q(drop));
FDRE s0 (.C(clk), .CE(1'b1), .R(btnU), .D(sw0_db_n), .Q(sw0_db));

wire [9:0] drop_y_n;
assign drop_y_n = drop ? (apple_y[sel] + 10'd1) : apple_y[sel];

FDRE ay0 (.C(clk), .CE(1'b1), .R(btnU), .D(drop_y_n[0]), .Q(apple_y[sel][0]));
FDRE ay1 (.C(clk), .CE(1'b1), .R(btnU), .D(drop_y_n[1]), .Q(apple_y[sel][1]));
FDRE ay2 (.C(clk), .CE(1'b1), .R(btnU), .D(drop_y_n[2]), .Q(apple_y[sel][2]));
FDRE ay3 (.C(clk), .CE(1'b1), .R(btnU), .D(drop_y_n[3]), .Q(apple_y[sel][3]));
FDRE ay4 (.C(clk), .CE(1'b1), .R(btnU), .D(drop_y_n[4]), .Q(apple_y[sel][4]));
FDRE ay5 (.C(clk), .CE(1'b1), .R(btnU), .D(drop_y_n[5]), .Q(apple_y[sel][5]));
FDRE ay6 (.C(clk), .CE(1'b1), .R(btnU), .D(drop_y_n[6]), .Q(apple_y[sel][6]));
FDRE ay7 (.C(clk), .CE(1'b1), .R(btnU), .D(drop_y_n[7]), .Q(apple_y[sel][7]));
FDRE ay8 (.C(clk), .CE(1'b1), .R(btnU), .D(drop_y_n[8]), .Q(apple_y[sel][8]));
FDRE ay9 (.C(clk), .CE(1'b1), .R(btnU), .D(drop_y_n[9]), .Q(apple_y[sel][9]));

// Color counter logic

assign color_ce = (vcount == 10'd479) & (hcount == 10'd639);
assign rst0 = (cnt0_full == 8'd240);
assign rst1 = (cnt1_full == 8'd240);
assign rst2 = (cnt2_full == 8'd240);
assign rst3 = (cnt3_full == 8'd240);
assign rst4 = (cnt4_full == 8'd240);
assign rst5 = (cnt5_full == 8'd240);
assign rst6 = (cnt6_full == 8'd240);
assign rst7 = (cnt7_full == 8'd240);

assign cnt0_n = rst0 ? 4'd0 : cnt0 + 4'd1;
assign cnt1_n = rst1 ? 4'd0 : cnt1 + 4'd1;
assign cnt2_n = rst2 ? 4'd0 : cnt2 + 4'd1;
assign cnt3_n = rst3 ? 4'd0 : cnt3 + 4'd1;
assign cnt4_n = rst4 ? 4'd0 : cnt4 + 4'd1;
assign cnt5_n = rst5 ? 4'd0 : cnt5 + 4'd1;
assign cnt6_n = rst6 ? 4'd0 : cnt6 + 4'd1;
assign cnt7_n = rst7 ? 4'd0 : cnt7 + 4'd1;

assign cnt0_full = {cnt0, 4'd0};
assign cnt1_full = {cnt1, 4'd0};
assign cnt2_full = {cnt2, 4'd0};
assign cnt3_full = {cnt3, 4'd0};
assign cnt4_full = {cnt4, 4'd0};
assign cnt5_full = {cnt5, 4'd0};
assign cnt6_full = {cnt6, 4'd0};
assign cnt7_full = {cnt7, 4'd0};

FDRE c00 (.C(clk), .CE(color_ce), .R(rst0), .D(cnt0_n[0]), .Q(cnt0[0]));
FDRE c01 (.C(clk), .CE(color_ce), .R(rst0), .D(cnt0_n[1]), .Q(cnt0[1]));
FDRE c02 (.C(clk), .CE(color_ce), .R(rst0), .D(cnt0_n[2]), .Q(cnt0[2]));
FDRE c03 (.C(clk), .CE(color_ce), .R(rst0), .D(cnt0_n[3]), .Q(cnt0[3]));
FDRE c10 (.C(clk), .CE(color_ce), .R(rst1), .D(cnt1_n[0]), .Q(cnt1[0]));
FDRE c11 (.C(clk), .CE(color_ce), .R(rst1), .D(cnt1_n[1]), .Q(cnt1[1]));
FDRE c12 (.C(clk), .CE(color_ce), .R(rst1), .D(cnt1_n[2]), .Q(cnt1[2]));
FDRE c13 (.C(clk), .CE(color_ce), .R(rst1), .D(cnt1_n[3]), .Q(cnt1[3]));
FDRE c20 (.C(clk), .CE(color_ce), .R(rst2), .D(cnt2_n[0]), .Q(cnt2[0]));
FDRE c21 (.C(clk), .CE(color_ce), .R(rst2), .D(cnt2_n[1]), .Q(cnt2[1]));
FDRE c22 (.C(clk), .CE(color_ce), .R(rst2), .D(cnt2_n[2]), .Q(cnt2[2]));
FDRE c23 (.C(clk), .CE(color_ce), .R(rst2), .D(cnt2_n[3]), .Q(cnt2[3]));
FDRE c30 (.C(clk), .CE(color_ce), .R(rst3), .D(cnt3_n[0]), .Q(cnt3[0]));
FDRE c31 (.C(clk), .CE(color_ce), .R(rst3), .D(cnt3_n[1]), .Q(cnt3[1]));
FDRE c32 (.C(clk), .CE(color_ce), .R(rst3), .D(cnt3_n[2]), .Q(cnt3[2]));
FDRE c33 (.C(clk), .CE(color_ce), .R(rst3), .D(cnt3_n[3]), .Q(cnt3[3]));
FDRE c40 (.C(clk), .CE(color_ce), .R(rst4), .D(cnt4_n[0]), .Q(cnt4[0]));
FDRE c41 (.C(clk), .CE(color_ce), .R(rst4), .D(cnt4_n[1]), .Q(cnt4[1]));
FDRE c42 (.C(clk), .CE(color_ce), .R(rst4), .D(cnt4_n[2]), .Q(cnt4[2]));
FDRE c43 (.C(clk), .CE(color_ce), .R(rst4), .D(cnt4_n[3]), .Q(cnt4[3]));
FDRE c50 (.C(clk), .CE(color_ce), .R(rst5), .D(cnt5_n[0]), .Q(cnt5[0]));
FDRE c51 (.C(clk), .CE(color_ce), .R(rst5), .D(cnt5_n[1]), .Q(cnt5[1]));
FDRE c52 (.C(clk), .CE(color_ce), .R(rst5), .D(cnt5_n[2]), .Q(cnt5[2]));
FDRE c53 (.C(clk), .CE(color_ce), .R(rst5), .D(cnt5_n[3]), .Q(cnt5[3]));
FDRE c60 (.C(clk), .CE(color_ce), .R(rst6), .D(cnt6_n[0]), .Q(cnt6[0]));
FDRE c61 (.C(clk), .CE(color_ce), .R(rst6), .D(cnt6_n[1]), .Q(cnt6[1]));
FDRE c62 (.C(clk), .CE(color_ce), .R(rst6), .D(cnt6_n[2]), .Q(cnt6[2]));
FDRE c63 (.C(clk), .CE(color_ce), .R(rst6), .D(cnt6_n[3]), .Q(cnt6[3]));
FDRE c70 (.C(clk), .CE(color_ce), .R(rst7), .D(cnt7_n[0]), .Q(cnt7[0]));
FDRE c71 (.C(clk), .CE(color_ce), .R(rst7), .D(cnt7_n[1]), .Q(cnt7[1]));
FDRE c72 (.C(clk), .CE(color_ce), .R(rst7), .D(cnt7_n[2]), .Q(cnt7[2]));
FDRE c73 (.C(clk), .CE(color_ce), .R(rst7), .D(cnt7_n[3]), .Q(cnt7[3]));

// Unused signals (to avoid warnings)

wire unused1 = btnD;
wire unused2 = sw[15];
wire unused3 = sw[14];
wire unused4 = sw[13];
wire unused5 = sw[12];
wire unused6 = sw[11];
wire unused7 = sw[10];
wire unused8 = sw[9];
wire unused9 = sw[8];
wire unused10 = sw[7];
wire unused11 = sw[6];
wire unused12 = sw[5];
wire unused13 = sw[4];
wire unused14 = sw[3];
wire unused15 = sw[2];

assign led = {btnC, sw[15:2], btnU, btnL};
assign led_n = led;

assign seg = 7'b1111111;
assign dp = 1'b1;
assign an = 4'b1111;

// Debounce logic

wire [3:0] db_cnt;
wire [3:0] db_cnt_n;
wire db_tick;

FDRE db0 (.C(clk), .CE(1'b1), .R(btnU), .D(db_cnt_n[0]), .Q(db_cnt[0]));
FDRE db1 (.C(clk), .CE(1'b1), .R(btnU), .D(db_cnt_n[1]), .Q(db_cnt[1]));
FDRE db2 (.C(clk), .CE(1'b1), .R(btnU), .D(db_cnt_n[2]), .Q(db_cnt[2]));
FDRE db3 (.C(clk), .CE(1'b1), .R(btnU), .D(db_cnt_n[3]), .Q(db_cnt[3]));

assign db_cnt_n = (db_cnt == 4'd15) ? 4'd0 : db_cnt + 4'd1;
assign db_tick = (db_cnt == 4'd15);

assign btnC_db_n = db_tick ? ~btnC_db : btnC_db;

FDRE bdb (.C(clk), .CE(1'b1), .R(btnU), .D(btnC_db_n), .Q(btnC_db));

assign hcount_n = hcount;
assign vcount_n = vcount;
assign r_n = r;
assign g_n = g;
assign b_n = b;

assign cnt0_n = cnt0;
assign cnt1_n = cnt1;
assign cnt2_n = cnt2;
assign cnt3_n = cnt3;
assign cnt4_n = cnt4;
assign cnt5_n = cnt5;
assign cnt6_n = cnt6;
assign cnt7_n = cnt7;

assign apple_y_n = apple_y;

assign drop_y = apple_y[sel];

assign hdmi_clk = clk;
assign hdmi_dispen = act;

assign led_n = led;

// Unused signals (to avoid warnings)

wire unused16 = btnC_db;
wire unused17 = sw0_db;
wire unused18 = db_cnt;
wire unused19 = db_tick;
wire unused20 = drop;
wire unused21 = drop_y;

// Debugging signals

wire [9:0] dbg_hcount;
wire [9:0] dbg_vcount;
wire [3:0] dbg_r;
wire [3:0] dbg_g;
wire [3:0] dbg_b;

assign dbg_hcount = hcount;
assign dbg_vcount = vcount;
assign dbg_r = r;
assign dbg_g = g;
assign dbg_b = b;

wire [3:0] dbg_cnt0;
wire [3:0] dbg_cnt1;
wire [3:0] dbg_cnt2;
wire [3:0] dbg_cnt3;
wire [3:0] dbg_cnt4;
wire [3:0] dbg_cnt5;
wire [3:0] dbg_cnt6;
wire [3:0] dbg_cnt7;

assign dbg_cnt0 = cnt0;
assign dbg_cnt1 = cnt1;
assign dbg_cnt2 = cnt2;
assign dbg_cnt3 = cnt3;
assign dbg_cnt4 = cnt4;
assign dbg_cnt5 = cnt5;
assign dbg_cnt6 = cnt6;
assign dbg_cnt7 = cnt7;

wire [9:0] dbg_apple_y0;
wire [9:0] dbg_apple_y1;
wire [9:0] dbg_apple_y2;
wire [9:0] dbg_apple_y3;
wire [9:0] dbg_apple_y4;
wire [9:0] dbg_apple_y5;
wire [9:0] dbg_apple_y6;
wire [9:0] dbg_apple_y7;

assign dbg_apple_y0 = apple_y[0];
assign dbg_apple_y1 = apple_y[1];
assign dbg_apple_y2 = apple_y[2];
assign dbg_apple_y3 = apple_y[3];
assign dbg_apple_y4 = apple_y[4];
assign dbg_apple_y5 = apple_y[5];
assign dbg_apple_y6 = apple_y[6];
assign dbg_apple_y7 = apple_y[7];

wire [9:0] dbg_player_x;

assign dbg_player_x = player_x;

wire [3:0] dbg_pix_r;
wire [3:0] dbg_pix_g;
wire [3:0] dbg_pix_b;

assign dbg_pix_r = pix_r;
assign dbg_pix_g = pix_g;
assign dbg_pix_b = pix_b;

wire [3:0] dbg_sel;

assign dbg_sel = {1'b0, cur_sel};

// The `drop` signal is used to control the falling apple.

endmodule
