`timescale 1ns / 1ps
// ============================================================
//  RV32I Single-Cycle - Vivado/XSim Testbench
//
//  How to use in Vivado:
//   1. Add all rtl/*.v files as Design Sources
//   2. Add this file as a Simulation Source
//   3. Set tb_riscv_single_cycle as top simulation module
//   4. Run Behavioral Simulation → Run All
//
//  Groups tested:
//   1. R-type (ADD SUB AND OR XOR SLL SRL SRA SLT SLTU)
//   2. I-type ALU (ADDI ANDI ORI XORI SLTI SLTIU SLLI SRLI SRAI)
//   3. Load/Store (LW LH LHU LB LBU SW SH SB)
//   4. Branch (BEQ BNE BLT BGE BLTU BGEU taken + not-taken)
//   5. Jump (JAL JALR link + target)
//   6. Upper (LUI AUIPC)
//   7. Edge cases (overflow, shift 0/31, x0 lock, sign-ext, SLTU)
// ============================================================
module tb_riscv_single_cycle;

// ── DUT ports ────────────────────────────────────────────────
reg         clk;
reg         rst_n;
wire [31:0] dbg_pc;
wire [31:0] dbg_instr;
wire [31:0] dbg_alu_result;
wire [ 4:0] dbg_rd;
wire [31:0] dbg_rd_val;
wire        dbg_reg_write;

// ── DUT ──────────────────────────────────────────────────────
riscv_single_cycle dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .dbg_pc        (dbg_pc),
    .dbg_instr     (dbg_instr),
    .dbg_alu_result(dbg_alu_result),
    .dbg_rd        (dbg_rd),
    .dbg_rd_val    (dbg_rd_val),
    .dbg_reg_write (dbg_reg_write)
);

// ── Clock 10 ns ───────────────────────────────────────────────
initial clk = 1'b0;
always #5 clk = ~clk;

// ── Test counters ─────────────────────────────────────────────
integer pass_cnt;
integer fail_cnt;

// ── Check task ────────────────────────────────────────────────
task automatic check_val;
    input [255:0] name;
    input [31:0]  got;
    input [31:0]  exp;
    begin
        if (got === exp) begin
            $display("  [PASS] %-40s got=%0d (0x%08h)", name, $signed(got), got);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] %-40s got=%0d (0x%08h)  exp=%0d (0x%08h)",
                     name, $signed(got), got, $signed(exp), exp);
            fail_cnt = fail_cnt + 1;
        end
    end
endtask

// ── Internal memory shortcuts ─────────────────────────────────
`define IM(w) dut.imem.mem[w]
`define DM(a) dut.dmem.mem[a]
`define RF(n) dut.rf.regs[n]

// ── Load instruction word ─────────────────────────────────────
task load_instr;
    input integer w;
    input [31:0]  d;
    begin `IM(w) = d; end
endtask

// ── Fill from word_start to end with NOPs ─────────────────────
task fill_nop;
    input integer from;
    integer j;
    begin
        for (j = from; j < 256; j = j + 1)
            `IM(j) = 32'h0000_0013;
    end
endtask

// ── Reset + clear state ───────────────────────────────────────
task do_reset;
    integer k;
    begin
        rst_n = 1'b0;
        for (k = 0; k < 32;   k = k+1) dut.rf.regs[k] = 32'd0;
        for (k = 0; k < 1024; k = k+1) dut.dmem.mem[k] = 8'h00;
        fill_nop(0);
        @(posedge clk); #1;
        rst_n = 1'b1;
    end
endtask

// ── Advance N clock cycles ─────────────────────────────────────
task tick;
    input integer n;
    integer t;
    begin
        for (t = 0; t < n; t = t+1) begin
            @(posedge clk); #1;
        end
    end
endtask

// =============================================================
//  MAIN TEST BODY
// =============================================================
initial begin
    pass_cnt = 0;
    fail_cnt = 0;
    rst_n    = 1'b0;
    @(posedge clk); #1;

    // ----------------------------------------------------------
    $display("\n==============================================");
    $display("  GROUP 1 - R-TYPE INSTRUCTIONS");
    $display("==============================================");
    // x1=15  x2=-7
    do_reset;
    load_instr(0,  32'h00f00093); // addi x1,x0,15
    load_instr(1,  32'hff900113); // addi x2,x0,-7
    load_instr(2,  32'h002081b3); // add  x3,x1,x2   -> 8
    load_instr(3,  32'h40208233); // sub  x4,x1,x2   -> 22
    load_instr(4,  32'h0020f2b3); // and  x5,x1,x2   -> 9
    load_instr(5,  32'h0020e333); // or   x6,x1,x2   -> -1
    load_instr(6,  32'h0020c3b3); // xor  x7,x1,x2   -> 15^-7
    load_instr(7,  32'h00112433); // slt  x8,x2,x1   -> 1 (-7<15)
    load_instr(8,  32'h001134b3); // sltu x9,x2,x1   -> 0 (big>=15)
    load_instr(9,  32'h00200593); // addi x11,x0,2
    load_instr(10, 32'h00b09633); // sll  x12,x1,x11 -> 60
    load_instr(11, 32'h00b0d6b3); // srl  x13,x1,x11 -> 3
    load_instr(12, 32'hfff00713); // addi x14,x0,-1
    load_instr(13, 32'h40b75793); // sra  x15,x14,x11-> -1
    fill_nop(14);
    tick(20);
    check_val("ADD  x3 = 8",          `RF(3),  32'd8);
    check_val("SUB  x4 = 22",         `RF(4),  32'd22);
    check_val("AND  x5 = 9",          `RF(5),  32'd9);
    check_val("OR   x6 = -1",         `RF(6),  32'hFFFF_FFFF);
    check_val("XOR  x7 = 15^(-7)",    `RF(7),  32'hFFFF_FFF6);
    check_val("SLT  x8 = 1",          `RF(8),  32'd1);
    check_val("SLTU x9 = 0",          `RF(9),  32'd0);
    check_val("SLL  x12= 60",         `RF(12), 32'd60);
    check_val("SRL  x13= 3",          `RF(13), 32'd3);
    check_val("SRA  x15= -1",         `RF(15), 32'hFFFF_FFFF);

    // ----------------------------------------------------------
    $display("\n==============================================");
    $display("  GROUP 2 - I-TYPE ALU");
    $display("==============================================");
    do_reset;
    load_instr(0,  32'h00500093); // addi  x1,x0,5
    load_instr(1,  32'h00208193); // addi  x3,x1,2      -> 7
    load_instr(2,  32'h00a0a213); // slti  x4,x1,10     -> 1
    load_instr(3,  32'h0020b293); // sltiu x5,x1,2      -> 0
    load_instr(4,  32'hff500313); // addi  x6,x0,-11
    load_instr(5,  32'h00f34393); // xori  x7,x6,0xf    -> -11^15
    load_instr(6,  32'h00f36413); // ori   x8,x6,0xf    -> -11|15
    load_instr(7,  32'h00f37493); // andi  x9,x6,0xf    -> -11&15
    load_instr(8,  32'h00309513); // slli  x10,x1,3     -> 40
    load_instr(9,  32'h00335593); // srli  x11,x6,3
    load_instr(10, 32'h40335613); // srai  x12,x6,3     -> -2
    fill_nop(11);
    tick(16);
    check_val("ADDI  x3 = 7",         `RF(3),  32'd7);
    check_val("SLTI  x4 = 1",         `RF(4),  32'd1);
    check_val("SLTIU x5 = 0",         `RF(5),  32'd0);
    check_val("XORI  x7 = -11^15",    `RF(7),  32'hFFFF_FFFA);
    check_val("ORI   x8 = -11|15",    `RF(8),  32'hFFFF_FFFF);
    check_val("ANDI  x9 = -11&15",    `RF(9),  32'h5);
    check_val("SLLI  x10= 40",        `RF(10), 32'd40);
    check_val("SRAI  x12= -2",        `RF(12), 32'hFFFF_FFFE);

    // ----------------------------------------------------------
    $display("\n==============================================");
    $display("  GROUP 3 - LOAD / STORE");
    $display("==============================================");
    do_reset;
    `DM(100) = 8'hAB; `DM(101) = 8'hCD; `DM(102) = 8'hEF; `DM(103) = 8'h12;
    load_instr(0,  32'h06400093); // addi x1,x0,100
    load_instr(1,  32'h0000a103); // lw   x2,0(x1)  -> 0x12EFCDAB
    load_instr(2,  32'h00008183); // lb   x3,0(x1)  -> sign(0xAB)=-85
    load_instr(3,  32'h0000c203); // lbu  x4,0(x1)  -> 171
    load_instr(4,  32'h00009283); // lh   x5,0(x1)  -> sign(0xCDAB)
    load_instr(5,  32'h0000d303); // lhu  x6,0(x1)  -> 0xCDAB
    // SW roundtrip at byte 400
    load_instr(6,  32'h19000393); // addi x7,x0,400
    load_instr(7,  32'h0023a023); // sw   x2,0(x7)
    load_instr(8,  32'h0003a403); // lw   x8,0(x7)  -> == x2
    // SB at byte 500
    load_instr(9,  32'h1f400493); // addi x9,x0,500
    load_instr(10, 32'h00148023); // sb   x1,0(x9)  -> 0x64
    load_instr(11, 32'h0004a503); // lbu  x10,0(x9) -> 0x64
    // SH at byte 600
    load_instr(12, 32'h25800613); // addi x12,x0,600
    load_instr(13, 32'h00261023); // sh   x2,0(x12) -> lower 16b=0xCDAB
    load_instr(14, 32'h00061703); // lh   x14,0(x12)-> sign(0xCDAB)
    load_instr(15, 32'h00065783); // lhu  x15,0(x12)-> 0xCDAB
    fill_nop(16);
    tick(22);
    check_val("LW   0x12EFCDAB",       `RF(2),  32'h12EF_CDAB);
    check_val("LB   sign(0xAB)=-85",  `RF(3),  32'hFFFF_FFAB);
    check_val("LBU  0xAB=171",         `RF(4),  32'h0000_00AB);
    check_val("LH   sign(0xCDAB)",     `RF(5),  32'hFFFF_CDAB);
    check_val("LHU  0xCDAB",           `RF(6),  32'h0000_CDAB);
    check_val("SW+LW roundtrip",       `RF(8),  `RF(2));
    check_val("SB+LBU = 0x64",         `RF(10), 32'h64);
    check_val("SH+LH  signed",         `RF(14), 32'hFFFF_CDAB);
    check_val("SH+LHU unsigned",       `RF(15), 32'h0000_CDAB);

    // ----------------------------------------------------------
    $display("\n==============================================");
    $display("  GROUP 4 - BRANCH INSTRUCTIONS");
    $display("==============================================");
    do_reset;
    // BEQ taken: x1==x2 -> skip word3, exec word4 -> x3=1
    load_instr(0,  32'h00500093); // addi x1,x0,5
    load_instr(1,  32'h00500113); // addi x2,x0,5
    load_instr(2,  32'h00208463); // beq  x1,x2,+8   taken->word4
    load_instr(3,  32'h0ff00193); // addi x3,x0,255  SKIP
    load_instr(4,  32'h00100193); // addi x3,x0,1
    // BNE not-taken -> x4 gets 2 then 3 (sequential)
    load_instr(5,  32'h00209463); // bne  x1,x2,+8   NOT taken
    load_instr(6,  32'h00200213); // addi x4,x0,2
    load_instr(7,  32'h00300213); // addi x4,x0,3
    // BLT taken: -1 < 1
    load_instr(8,  32'hfff00293); // addi x5,x0,-1
    load_instr(9,  32'h00100313); // addi x6,x0,1
    load_instr(10, 32'h0062c463); // blt  x5,x6,+8   taken->word12
    load_instr(11, 32'h0aa00393); // addi x7,x0,0xAA SKIP
    load_instr(12, 32'h07700393); // addi x7,x0,0x77
    // BGE taken: 10>=5
    load_instr(13, 32'h00a00413); // addi x8,x0,10
    load_instr(14, 32'h00500493); // addi x9,x0,5
    load_instr(15, 32'h00945463); // bge  x8,x9,+8   taken->word17
    load_instr(16, 32'h00000513); // addi x10,x0,0   SKIP
    load_instr(17, 32'h00100513); // addi x10,x0,1
    // BLTU not-taken: 0xFFFFFFFE NOT < 1
    load_instr(18, 32'hffe00593); // addi x11,x0,-2
    load_instr(19, 32'h00100613); // addi x12,x0,1
    load_instr(20, 32'h00c5e463); // bltu x11,x12,+8 NOT taken
    load_instr(21, 32'h00200693); // addi x13,x0,2
    load_instr(22, 32'h00300693); // addi x13,x0,3
    // BGEU taken: 0xFFFFFFFE >= 1 unsigned
    load_instr(23, 32'hffe00793); // addi x15,x0,-2
    load_instr(24, 32'h00100813); // addi x16,x0,1
    load_instr(25, 32'h010ff463); // bgeu x15,x16,+8 taken->word27
    load_instr(26, 32'h00000893); // addi x17,x0,0   SKIP
    load_instr(27, 32'h00100893); // addi x17,x0,1
    fill_nop(28);
    tick(40);
    check_val("BEQ  taken  x3=1",     `RF(3),  32'd1);
    check_val("BNE  not-taken x4=3",  `RF(4),  32'd3);
    check_val("BLT  taken  x7=0x77",  `RF(7),  32'h77);
    check_val("BGE  taken  x10=1",    `RF(10), 32'd1);
    check_val("BLTU not-taken x13=3", `RF(13), 32'd3);
    check_val("BGEU taken  x17=1",    `RF(17), 32'd1);

    // ----------------------------------------------------------
    $display("\n==============================================");
    $display("  GROUP 5 - JAL / JALR");
    $display("==============================================");
    do_reset;
    // word0(PC=0): JAL x1,+12 -> PC=12, x1=4
    // word1(PC=4): addi x2,x0,0xDD   <- JALR lands + halts
    // word2(PC=8): jal x0,0           (halt, prevent fall-through)
    // word3(PC=12): addi x2,x0,0xBB  <- JAL target
    // word4(PC=16): jalr x3,x1,0  -> PC=4=word1, x3=20
    // word5(PC=20): addi x4,x0,0xCC  SKIPPED
    load_instr(0,  32'h00c000ef); // jal  x1,+12
    load_instr(1,  32'h0dd00113); // addi x2,x0,0xDD
    load_instr(2,  32'h0000006f); // jal  x0,0   (halt)
    load_instr(3,  32'h0bb00113); // addi x2,x0,0xBB
    load_instr(4,  32'h000081e7); // jalr x3,x1,0
    load_instr(5,  32'h0cc00213); // addi x4,x0,0xCC  SKIPPED
    fill_nop(6);
    tick(15);
    check_val("JAL  link x1=4",       `RF(1),  32'd4);
    check_val("JALR target x2=0xDD",  `RF(2),  32'hDD);
    check_val("JALR link  x3=20",     `RF(3),  32'd20);
    check_val("JALR skip  x4=0",      `RF(4),  32'd0);

    // ----------------------------------------------------------
    $display("\n==============================================");
    $display("  GROUP 6 - LUI / AUIPC");
    $display("==============================================");
    do_reset;
    load_instr(0,  32'habcde0b7); // lui   x1,0xABCDE -> 0xABCDE000
    load_instr(1,  32'h00001137); // lui   x2,1
    load_instr(2,  32'hfff10113); // addi  x2,x2,-1   -> 0xFFF
    load_instr(3,  32'h00000197); // auipc x3,0        PC=12
    load_instr(4,  32'h00001217); // auipc x4,1        PC=16 -> 4112
    fill_nop(5);
    tick(10);
    check_val("LUI  x1=0xABCDE000",   `RF(1),  32'hABCDE000);
    check_val("LUI+ADDI x2=0xFFF",    `RF(2),  32'h0000_0FFF);
    check_val("AUIPC x3=12",          `RF(3),  32'd12);
    check_val("AUIPC x4=16+0x1000",   `RF(4),  32'd4112);

    // ----------------------------------------------------------
    $display("\n==============================================");
    $display("  GROUP 7 - EDGE CASES");
    $display("==============================================");

    // 7a: x0 always 0
    do_reset;
    load_instr(0, 32'h00500013); // addi x0,x0,5 -> must stay 0
    fill_nop(1);
    tick(5);
    check_val("x0 hardwired to 0",    `RF(0),  32'd0);

    // 7b: ADD overflow wraps
    do_reset;
    load_instr(0, 32'h800000b7); // lui  x1,0x80000 -> 0x80000000
    load_instr(1, 32'hfff08093); // addi x1,x1,-1   -> 0x7FFFFFFF
    load_instr(2, 32'h00108133); // add  x2,x1,x1   -> wraps 0xFFFFFFFE
    fill_nop(3);
    tick(8);
    check_val("ADD overflow=0xFFFFFFFE", `RF(2), 32'hFFFF_FFFE);

    // 7c: Shift by 0
    do_reset;
    load_instr(0, 32'h00a00093); // addi x1,x0,10
    load_instr(1, 32'h00009113); // slli x2,x1,0  -> 10
    load_instr(2, 32'h0000d193); // srli x3,x1,0  -> 10
    fill_nop(3);
    tick(8);
    check_val("SLLI shift-by-0 = 10", `RF(2), 32'd10);
    check_val("SRLI shift-by-0 = 10", `RF(3), 32'd10);

    // 7d: Shift by 31
    do_reset;
    load_instr(0, 32'hfff00093); // addi x1,x0,-1  -> 0xFFFFFFFF
    load_instr(1, 32'h01f09113); // slli x2,x1,31  -> 0x80000000
    load_instr(2, 32'h01f0d193); // srli x3,x1,31  -> 1
    load_instr(3, 32'h41f0d213); // srai x4,x1,31  -> -1
    fill_nop(4);
    tick(10);
    check_val("SLLI -1<<31=0x80000000", `RF(2), 32'h8000_0000);
    check_val("SRLI -1>>31=1",          `RF(3), 32'd1);
    check_val("SRAI -1>>31=-1",         `RF(4), 32'hFFFF_FFFF);

    // 7e: SLTU boundary
    do_reset;
    load_instr(0, 32'hfff00093); // addi x1,x0,-1  -> 0xFFFFFFFF
    load_instr(1, 32'h00000113); // addi x2,x0,0
    load_instr(2, 32'h0020b1b3); // sltu x3,x1,x2  -> 0
    load_instr(3, 32'h00113233); // sltu x4,x2,x1  -> 1
    fill_nop(4);
    tick(10);
    check_val("SLTU max<0  = 0",      `RF(3), 32'd0);
    check_val("SLTU 0<max  = 1",      `RF(4), 32'd1);

    // 7f: LUI exact upper bits
    do_reset;
    load_instr(0, 32'hfffff0b7); // lui x1,0xFFFFF -> 0xFFFFF000
    fill_nop(1);
    tick(5);
    check_val("LUI 0xFFFFF000",       `RF(1), 32'hFFFFF000);

    // 7g: BGEU not-taken (1 < 0xFFFFFFFF unsigned)
    do_reset;
    load_instr(0, 32'hfff00093); // addi x1,x0,-1
    load_instr(1, 32'h00100113); // addi x2,x0,1
    load_instr(2, 32'h00117463); // bgeu x2,x1,+8  NOT taken
    load_instr(3, 32'h00100193); // addi x3,x0,1   executes
    load_instr(4, 32'h00200193); // addi x3,x0,2   executes
    fill_nop(5);
    tick(10);
    check_val("BGEU not-taken x3=2",  `RF(3), 32'd2);

    // 7h: BGEU taken
    do_reset;
    load_instr(0, 32'hfff00093); // addi x1,x0,-1
    load_instr(1, 32'h00100113); // addi x2,x0,1
    load_instr(2, 32'h0020f463); // bgeu x1,x2,+8  taken
    load_instr(3, 32'h00000193); // addi x3,x0,0   SKIP
    load_instr(4, 32'h00100193); // addi x3,x0,1
    fill_nop(5);
    tick(10);
    check_val("BGEU taken x3=1",      `RF(3), 32'd1);

    // ----------------------------------------------------------
    $display("\n==============================================");
    $display("  SUMMARY");
    $display("==============================================");
    $display("  PASSED : %0d", pass_cnt);
    $display("  FAILED : %0d", fail_cnt);
    if (fail_cnt == 0)
        $display("  *** ALL TESTS PASSED ***");
    else
        $display("  *** %0d FAILURE(S) - check waveform ***", fail_cnt);
    $display("==============================================\n");

    $finish;
end

// Watchdog
initial begin
    #200000;
    $display("[WATCHDOG] Simulation timed out!");
    $finish;
end

endmodule