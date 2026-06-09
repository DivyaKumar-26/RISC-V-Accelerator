// ============================================================
//  ALU — RV32I
//  Supports: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
// ============================================================
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [ 3:0] alu_ctrl,   // see defines
    output reg  [31:0] result,
    output wire        zero
);

// ALU control encoding
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
localparam ALU_LUI  = 4'd10;  // pass b

wire [31:0] sum_sub;
wire        sub_mode = (alu_ctrl == ALU_SUB) || (alu_ctrl == ALU_SLT) || (alu_ctrl == ALU_SLTU);
assign sum_sub = sub_mode ? (a - b) : (a + b);

always @(*) begin
    case (alu_ctrl)
        ALU_ADD  : result = sum_sub;
        ALU_SUB  : result = sum_sub;
        ALU_AND  : result = a & b;
        ALU_OR   : result = a | b;
        ALU_XOR  : result = a ^ b;
        ALU_SLL  : result = a << b[4:0];
        ALU_SRL  : result = a >> b[4:0];
        ALU_SRA  : result = $signed(a) >>> b[4:0];
        ALU_SLT  : result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
        ALU_SLTU : result = (a < b)                   ? 32'd1 : 32'd0;
        ALU_LUI  : result = b;
        default  : result = 32'd0;
    endcase
end

assign zero = (result == 32'd0);

endmodule
