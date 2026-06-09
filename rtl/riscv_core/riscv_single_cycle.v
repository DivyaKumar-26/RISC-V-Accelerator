`timescale 1ns / 1ps
// ============================================================
//  RV32I Single-Cycle Processor - Top Level (Vivado/XSim)
//  NO `include statements - all modules added separately
// ============================================================
module riscv_single_cycle (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instr,
    output wire [31:0] dbg_alu_result,
    output wire [ 4:0] dbg_rd,
    output wire [31:0] dbg_rd_val,
    output wire        dbg_reg_write
);

// ── PC ───────────────────────────────────────────────────────
reg  [31:0] pc;
wire [31:0] pc_plus4 = pc + 32'd4;
wire [31:0] pc_next;

// ── Instruction Fetch ────────────────────────────────────────
wire [31:0] instr;
instr_mem imem (.addr(pc), .instr(instr));

// ── Decode fields ────────────────────────────────────────────
wire [ 6:0] opcode   = instr[ 6: 0];
wire [ 4:0] rd_addr  = instr[11: 7];
wire [ 2:0] funct3   = instr[14:12];
wire [ 4:0] rs1_addr = instr[19:15];
wire [ 4:0] rs2_addr = instr[24:20];
wire        funct7_5 = instr[30];

// ── Control Unit ─────────────────────────────────────────────
wire        reg_write, mem_read, mem_write, mem_to_reg;
wire        alu_src, branch, jump, jalr, lui, auipc;
wire [ 2:0] imm_sel;
wire [ 3:0] alu_ctrl;

control_unit ctrl (
    .opcode    (opcode),    .funct3    (funct3),
    .funct7_5  (funct7_5),  .reg_write (reg_write),
    .mem_read  (mem_read),  .mem_write (mem_write),
    .mem_to_reg(mem_to_reg),.alu_src   (alu_src),
    .branch    (branch),    .jump      (jump),
    .jalr      (jalr),      .lui       (lui),
    .auipc     (auipc),     .imm_sel   (imm_sel),
    .alu_ctrl  (alu_ctrl)
);

// ── Register File ────────────────────────────────────────────
wire [31:0] rs1_val, rs2_val, rd_wdata;
regfile rf (
    .clk(clk), .we(reg_write),
    .rs1(rs1_addr), .rs2(rs2_addr), .rd(rd_addr),
    .wd(rd_wdata),  .rd1(rs1_val),  .rd2(rs2_val)
);

// ── Immediate Generator ──────────────────────────────────────
wire [31:0] imm;
imm_gen immgen (.instr(instr), .imm_sel(imm_sel), .imm_out(imm));

// ── ALU ──────────────────────────────────────────────────────
wire [31:0] alu_a    = auipc   ? pc  : rs1_val;
wire [31:0] alu_b    = alu_src ? imm : rs2_val;
wire [31:0] alu_result;
wire        alu_zero;
alu alu_inst (.a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl),
              .result(alu_result), .zero(alu_zero));

// ── Data Memory ──────────────────────────────────────────────
wire [31:0] mem_rdata;
data_mem dmem (
    .clk(clk),         .mem_read(mem_read), .mem_write(mem_write),
    .addr(alu_result), .wdata(rs2_val),      .funct3(funct3),
    .rdata(mem_rdata)
);

// ── Branch Condition ─────────────────────────────────────────
wire branch_taken;
branch_cond bcond (.rs1_val(rs1_val), .rs2_val(rs2_val),
                   .funct3(funct3), .taken(branch_taken));

// ── Write-back ───────────────────────────────────────────────
wire link_write = jump | jalr;
assign rd_wdata = link_write ? pc_plus4  :
                  mem_to_reg ? mem_rdata :
                               alu_result;

// ── PC targets (declared after imm and alu_result) ───────────
wire [31:0] pc_branch = pc + imm;
wire [31:0] pc_jal    = pc + imm;
wire [31:0] pc_jalr   = {alu_result[31:1], 1'b0};

assign pc_next = jalr                    ? pc_jalr  :
                 jump                    ? pc_jal   :
                 (branch & branch_taken) ? pc_branch:
                                           pc_plus4;

always @(posedge clk) begin
    if (!rst_n) pc <= 32'h0000_0000;
    else        pc <= pc_next;
end

// ── Debug outputs ────────────────────────────────────────────
assign dbg_pc         = pc;
assign dbg_instr      = instr;
assign dbg_alu_result = alu_result;
assign dbg_rd         = rd_addr;
assign dbg_rd_val     = rd_wdata;
assign dbg_reg_write  = reg_write;

endmodule