// ============================================================
//  Control Unit — RV32I single-cycle
//  Decodes opcode + funct3 + funct7[5] → control signals
// ============================================================
module control_unit (
    input  wire [ 6:0] opcode,
    input  wire [ 2:0] funct3,
    input  wire        funct7_5,   // bit 30 of instruction

    // Datapath control
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,  // 1 = data from mem, 0 = from ALU
    output reg         alu_src,     // 1 = imm, 0 = rs2
    output reg         branch,
    output reg         jump,        // JAL
    output reg         jalr,        // JALR
    output reg         lui,         // LUI special path
    output reg         auipc,       // AUIPC

    // Immediate selector
    output reg  [ 2:0] imm_sel,

    // ALU control (fed directly to ALU)
    output reg  [ 3:0] alu_ctrl
);

// Opcode constants
localparam OP_R      = 7'b0110011;
localparam OP_I_ALU  = 7'b0010011;
localparam OP_LOAD   = 7'b0000011;
localparam OP_STORE  = 7'b0100011;
localparam OP_BRANCH = 7'b1100011;
localparam OP_JAL    = 7'b1101111;
localparam OP_JALR   = 7'b1100111;
localparam OP_LUI    = 7'b0110111;
localparam OP_AUIPC  = 7'b0010111;

// IMM_SEL
localparam IMM_I = 3'd0;
localparam IMM_S = 3'd1;
localparam IMM_B = 3'd2;
localparam IMM_U = 3'd3;
localparam IMM_J = 3'd4;

// ALU ops
localparam ALU_ADD  = 4'd0;
localparam ALU_SUB  = 4'd1;
localparam ALU_AND  = 4'd2;
localparam ALU_OR   = 4'd3;
localparam ALU_XOR  = 4'd4;
localparam ALU_SLL  = 4'd5;
localparam ALU_SRL  = 4'd6;
localparam ALU_SRA  = 4'd7;
localparam ALU_SLT  = 4'd8;
localparam ALU_SLTU = 4'd9;
localparam ALU_LUI  = 4'd10;

// ── funct3 aliases ──────────────────────────────────────────
// R / I-ALU
localparam F3_ADD_SUB = 3'b000;
localparam F3_SLL     = 3'b001;
localparam F3_SLT     = 3'b010;
localparam F3_SLTU    = 3'b011;
localparam F3_XOR     = 3'b100;
localparam F3_SRL_SRA = 3'b101;
localparam F3_OR      = 3'b110;
localparam F3_AND     = 3'b111;
// Branch
localparam F3_BEQ  = 3'b000;
localparam F3_BNE  = 3'b001;
localparam F3_BLT  = 3'b100;
localparam F3_BGE  = 3'b101;
localparam F3_BLTU = 3'b110;
localparam F3_BGEU = 3'b111;

always @(*) begin
    // Safe defaults
    reg_write = 0; mem_read  = 0; mem_write = 0;
    mem_to_reg= 0; alu_src   = 0; branch    = 0;
    jump      = 0; jalr      = 0; lui       = 0; auipc = 0;
    imm_sel   = IMM_I;
    alu_ctrl  = ALU_ADD;

    case (opcode)
        // ── R-type ─────────────────────────────────────────
        OP_R: begin
            reg_write = 1;
            case (funct3)
                F3_ADD_SUB: alu_ctrl = funct7_5 ? ALU_SUB : ALU_ADD;
                F3_SLL    : alu_ctrl = ALU_SLL;
                F3_SLT    : alu_ctrl = ALU_SLT;
                F3_SLTU   : alu_ctrl = ALU_SLTU;
                F3_XOR    : alu_ctrl = ALU_XOR;
                F3_SRL_SRA: alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL;
                F3_OR     : alu_ctrl = ALU_OR;
                F3_AND    : alu_ctrl = ALU_AND;
                default   : alu_ctrl = ALU_ADD;
            endcase
        end

        // ── I-type ALU ──────────────────────────────────────
        OP_I_ALU: begin
            reg_write = 1; alu_src = 1; imm_sel = IMM_I;
            case (funct3)
                F3_ADD_SUB: alu_ctrl = ALU_ADD;          // ADDI
                F3_SLL    : alu_ctrl = ALU_SLL;          // SLLI
                F3_SLT    : alu_ctrl = ALU_SLT;          // SLTI
                F3_SLTU   : alu_ctrl = ALU_SLTU;         // SLTIU
                F3_XOR    : alu_ctrl = ALU_XOR;          // XORI
                F3_SRL_SRA: alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL; // SRLI/SRAI
                F3_OR     : alu_ctrl = ALU_OR;           // ORI
                F3_AND    : alu_ctrl = ALU_AND;          // ANDI
                default   : alu_ctrl = ALU_ADD;
            endcase
        end

        // ── Load ────────────────────────────────────────────
        OP_LOAD: begin
            reg_write  = 1; mem_read  = 1;
            mem_to_reg = 1; alu_src   = 1;
            imm_sel    = IMM_I; alu_ctrl = ALU_ADD;
        end

        // ── Store ───────────────────────────────────────────
        OP_STORE: begin
            mem_write = 1; alu_src = 1;
            imm_sel   = IMM_S; alu_ctrl = ALU_ADD;
        end

        // ── Branch ──────────────────────────────────────────
        OP_BRANCH: begin
            branch  = 1; imm_sel = IMM_B;
            // ALU computes comparison; branch logic in top-level
            case (funct3)
                F3_BEQ, F3_BNE  : alu_ctrl = ALU_SUB;
                F3_BLT, F3_BGE  : alu_ctrl = ALU_SLT;
                F3_BLTU, F3_BGEU: alu_ctrl = ALU_SLTU;
                default          : alu_ctrl = ALU_SUB;
            endcase
        end

        // ── JAL ─────────────────────────────────────────────
        OP_JAL: begin
            reg_write = 1; jump = 1;
            imm_sel = IMM_J; alu_ctrl = ALU_ADD;
        end

        // ── JALR ────────────────────────────────────────────
        OP_JALR: begin
            reg_write = 1; jalr = 1;
            alu_src = 1; imm_sel = IMM_I; alu_ctrl = ALU_ADD;
        end

        // ── LUI ─────────────────────────────────────────────
        OP_LUI: begin
            reg_write = 1; lui = 1; alu_src = 1;
            imm_sel = IMM_U; alu_ctrl = ALU_LUI;
        end

        // ── AUIPC ───────────────────────────────────────────
        OP_AUIPC: begin
            reg_write = 1; auipc = 1; alu_src = 1;
            imm_sel = IMM_U; alu_ctrl = ALU_ADD;
        end

        default: ; // NOP
    endcase
end

endmodule
