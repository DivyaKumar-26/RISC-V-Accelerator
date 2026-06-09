// ============================================================
//  Immediate Generator — RV32I all formats
//  I / S / B / U / J
// ============================================================
module imm_gen (
    input  wire [31:0] instr,
    input  wire [ 2:0] imm_sel,   // 000=I 001=S 010=B 011=U 100=J
    output reg  [31:0] imm_out
);

localparam IMM_I = 3'd0;
localparam IMM_S = 3'd1;
localparam IMM_B = 3'd2;
localparam IMM_U = 3'd3;
localparam IMM_J = 3'd4;

always @(*) begin
    case (imm_sel)
        IMM_I : imm_out = {{20{instr[31]}}, instr[31:20]};
        IMM_S : imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        IMM_B : imm_out = {{19{instr[31]}}, instr[31], instr[7],
                            instr[30:25], instr[11:8], 1'b0};
        IMM_U : imm_out = {instr[31:12], 12'd0};
        IMM_J : imm_out = {{11{instr[31]}}, instr[31], instr[19:12],
                            instr[20], instr[30:21], 1'b0};
        default: imm_out = 32'd0;
    endcase
end

endmodule
