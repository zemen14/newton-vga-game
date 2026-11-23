# Newton — VGA Game Engine in Verilog

**Personal project · Verilog · FPGA · RTL design**
VGA game engine — 640×480 @ 25MHz, Basys3 FPGA

`Verilog` `FPGA` `VGA` `RTL / no always blocks` `Xilinx Vivado` `Basys3`

---

I built a real-time falling-apple game that renders 640×480 VGA output entirely in Verilog, targeting a Basys3 FPGA. The full pixel pipeline — sync generation, color logic, and game state — is implemented at the register-transfer level using primitive FDREs, with no behavioral `always` blocks anywhere in the design.

---

## What I Built

Eight apples arranged in a 4×2 grid gradually turn from green to red over 240 frames (~4 seconds at 60fps). The player uses left/right buttons to move a 10×10 pixel catcher and a switch to drop a selected apple. All sprites — the green platform, red border, yellow catcher, and colored apples — are drawn purely through pixel coordinate comparisons. No frame buffer, no memory: just combinational logic gated by `hcount` and `vcount`.

```
Top row y=40–49 apple0 apple1 apple2 apple3
x=120 x=250 x=380 x=510

Bottom row y=160–169 apple4 apple5 apple6 apple7
x=120 x=250 x=380 x=510

Platform y=462–471 green · 8px border red
Player y=452–461 10×10px yellow catcher
```

---

## Hard Problems Solved

### 01 · X-propagation through the entire RGB pipeline

Uninitialized `FDRE` outputs start as `X` in simulation — not 0. A single apple position register using `.R(1'b0)` instead of `.R(btnU)` caused X to propagate through the entire reset chain: into all 64 color counter outputs, through `cur_g`, and ultimately corrupting every green pixel on screen. Tracing that full chain and fixing the root register was the key insight.

```verilog
// Wrong — never actually resets
FDRE apple_y_ff (.R(1'b0), ...);

// Correct — tied to global reset
FDRE apple_y_ff (.R(btnU), ...);
```

### 02 · One-pixel RGB bleed at the active region boundary

Registering RGB outputs through flip-flops adds exactly one clock of delay. At `hcount=639` (last active pixel), a nonzero green value gets latched into `gq`. One cycle later, `active=0` but `gq` still holds the stale value — producing a visible bleed pixel. I fixed this by computing active from the *next* cycle's hcount/vcount (`hn`/`vn`), zeroing pixel data one cycle before the boundary so the registered value is already clean when it exits the active region.

```verilog
wire pre_active_h = (hn <= 10'd639);
wire pre_active_v = (vn <= 10'd479) & ~v_wrap;
wire pre_active = pre_active_h & pre_active_v;

wire [3:0] pix_g = ~pre_active ? 4'h0 : platform_color;
```

### 03 · 100 MHz design vs 25 MHz testbench timing mismatch

The simulation testbench drives a 100 MHz clock but its sync-pulse timing constants assume 25 MHz — so `hcount` wraps 4× too fast, generating ~700K sync errors. I solved this with a divide-by-4 `sim_ce` signal gated by `` `ifdef XILINX_SIMULATOR ``, so all pixel-rate FFs effectively run at 25 MHz in simulation while running at full speed on board.

Critically, the divider uses `FDRE #(.INIT(1'b0))`. Without `.INIT`, the counter starts as `X`, making `sim_ce` permanently unknown — breaking every downstream flip-flop at simulation time zero.

```verilog
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
```

---

## FF Register Map

| FF group | CE | R | Notes |
|-----------------------|------------|-----------|----------------------------|
| hcount[9:0], vcount[9:0] | sim_ce | btnU | pixel counters, 25 MHz in sim |
| hs_ff, vs_ff | sim_ce | btnU | sync outputs |
| act_ff | sim_ce | btnU | registered active signal |
| rq/gq/bq [3:0] | sim_ce | btnU | RGB outputs |
| player_x[9:0] | 1'b1 | btnU | game logic, full speed |
| apple_y[9:0] | 1'b1 | btnU | game logic, full speed |
| cnt0–cnt7 [7:0] | color_ce | rst0–rst7 | color counters |
| div4_cnt[1:0] | 1'b1 | btnU | sim-only, INIT=0 |

---

## What's Next

- **Randomness** — LFSR-based apple selector
- **Timing** — 4s auto-drop via frame_pulse counter
- **Gameplay** — Collision detection on catch
- **Scoring** — 7-segment score display
- **Lives** — 4-LED life system on miss
- **Polish** — Apple flash effect on respawn

---

*In progress · Basys3 · Vivado 2024*
`top.v` · `labVGA_clks.v` · `Basys3_Master_lab6.xdc`

---

## Repository contents

- `top.v` — the complete game: VGA sync generation, pixel/color pipeline, player movement, apple drop logic, and color counters, all built from FDRE primitives.
- `tb_top.v` — testbench stub.

The clocking module (`labVGA_clks.v`, a Vivado-generated clocking wizard IP) and the board constraints file live in the Vivado project rather than this repo.
