// ============================================================
//  Instruction Memory — ROM (synchronous reset, async read)
//  Size: 1024 words = 4 KB
// ============================================================
module instr_mem #(
    parameter MEM_SIZE = 1024   // words
)(
    input  wire [31:0] addr,
    output wire [31:0] instr
);

reg [31:0] mem [0:MEM_SIZE-1];

integer i;
initial begin
    for (i = 0; i < MEM_SIZE; i = i + 1)
        mem[i] = 32'h0000_0013;  // NOP (ADDI x0, x0, 0)
end

// Word-aligned read; ignore bottom 2 bits
assign instr = mem[addr[31:2]];

endmodule
