`include "opcodes.v"

module forward_ecall (
    input [6:0] opcode,
    input [4:0] mem_rd,
    input [4:0] wb_rd,
    input mem_reg_write,
    input wb_reg_write,
    output reg [1:0] signal
);

always @(*) begin
    if (opcode == `ECALL) begin
        if (mem_rd == 5'd17 && mem_reg_write) signal = 2'b01; // MEM 단계에서 x17 사용
		else if (wb_reg_write && wb_rd == 5'd17) signal = 2'b10; // WB 단계에서 x17 사용
        else signal = 2'b00; // Forwarding 불필요
    end
    else signal = 2'b00; // ECALL 아님
end

endmodule
