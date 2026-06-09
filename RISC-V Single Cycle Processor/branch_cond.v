// ============================================================
//  Branch Condition Unit
//  Evaluates BEQ / BNE / BLT / BGE / BLTU / BGEU
// ============================================================
module branch_cond (
    input  wire [31:0] rs1_val,
    input  wire [31:0] rs2_val,
    input  wire [ 2:0] funct3,
    output reg         taken
);

always @(*) begin
    case (funct3)
        3'b000: taken = (rs1_val == rs2_val);                          // BEQ
        3'b001: taken = (rs1_val != rs2_val);                          // BNE
        3'b100: taken = ($signed(rs1_val) <  $signed(rs2_val));        // BLT
        3'b101: taken = ($signed(rs1_val) >= $signed(rs2_val));        // BGE
        3'b110: taken = (rs1_val <  rs2_val);                          // BLTU
        3'b111: taken = (rs1_val >= rs2_val);                          // BGEU
        default: taken = 1'b0;
    endcase
end

endmodule
