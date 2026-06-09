// ============================================================
//  Data Memory — supports byte / half-word / word access
//  Signed and unsigned loads (funct3 encoding matches RV32I)
//  Size: 1024 words = 4 KB
// ============================================================
module data_mem #(
    parameter MEM_SIZE = 1024
)(
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [ 2:0] funct3,   // width + signed/unsigned
    output reg  [31:0] rdata
);

reg [7:0] mem [0:MEM_SIZE*4-1]; // byte-addressable

integer i;
initial begin
    for (i = 0; i < MEM_SIZE*4; i = i + 1)
        mem[i] = 8'h00;
end

wire [31:0] base = addr;  // byte address

// ── Synchronous write ──────────────────────────────────────
always @(posedge clk) begin
    if (mem_write) begin
        case (funct3[1:0])
            2'b00: begin  // SB
                mem[base] <= wdata[7:0];
            end
            2'b01: begin  // SH
                mem[base  ] <= wdata[ 7: 0];
                mem[base+1] <= wdata[15: 8];
            end
            2'b10: begin  // SW
                mem[base  ] <= wdata[ 7: 0];
                mem[base+1] <= wdata[15: 8];
                mem[base+2] <= wdata[23:16];
                mem[base+3] <= wdata[31:24];
            end
            default: ;
        endcase
    end
end

// ── Asynchronous read ──────────────────────────────────────
always @(*) begin
    rdata = 32'd0;
    if (mem_read) begin
        case (funct3)
            3'b000: rdata = {{24{mem[base][7]}},   mem[base]};           // LB
            3'b001: rdata = {{16{mem[base+1][7]}}, mem[base+1], mem[base]}; // LH
            3'b010: rdata = {mem[base+3], mem[base+2], mem[base+1], mem[base]}; // LW
            3'b100: rdata = {24'b0, mem[base]};                          // LBU
            3'b101: rdata = {16'b0, mem[base+1], mem[base]};             // LHU
            default: rdata = 32'd0;
        endcase
    end
end

endmodule
