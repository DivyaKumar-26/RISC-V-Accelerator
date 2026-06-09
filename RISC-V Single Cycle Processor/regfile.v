// ============================================================
//  Register File — 32 x 32-bit, x0 hardwired to 0
//  Two async read ports, one sync write port
// ============================================================
module regfile (
    input  wire        clk,
    input  wire        we,        // write enable
    input  wire [ 4:0] rs1,       // read addr 1
    input  wire [ 4:0] rs2,       // read addr 2
    input  wire [ 4:0] rd,        // write addr
    input  wire [31:0] wd,        // write data
    output wire [31:0] rd1,       // read data 1
    output wire [31:0] rd2        // read data 2
);

reg [31:0] regs [31:0];

integer i;
initial begin
    for (i = 0; i < 32; i = i + 1)
        regs[i] = 32'd0;
end

// Synchronous write, x0 always 0
always @(posedge clk) begin
    if (we && rd != 5'd0)
        regs[rd] <= wd;
end

// Asynchronous read; x0 always returns 0
assign rd1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
assign rd2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

endmodule
