`include "opcodes.v"

module alu(
    input [3:0] alu_op_out,
    input [31:0] alu_in_1,   		
    input [31:0] alu_in_2,  		
    output reg [31:0] alu_result,   
    output reg alu_bcond   			
);
// ALU는 bit 단위 연산을 시행하므로 bitwise 연산자를 사용해야 한다. ex) bitwise OR 등

always @(*) begin
    alu_result = 0;
    alu_bcond = 0;
	
    case (alu_op_out)
		`ALU_ADD: alu_result = alu_in_1 + alu_in_2;
		`ALU_SUB: alu_result = alu_in_1 - alu_in_2;
		`ALU_SLL: alu_result = alu_in_1 << alu_in_2[4:0];
		`ALU_XOR: alu_result = alu_in_1 ^ alu_in_2;
		`ALU_OR:  alu_result = alu_in_1 | alu_in_2;
		`ALU_AND: alu_result = alu_in_1 & alu_in_2;
		`ALU_SRL: alu_result = alu_in_1 >> alu_in_2[4:0];
		`ALU_BEQ: alu_bcond = (alu_in_1 == alu_in_2) ? 1 : 0;
		`ALU_BNE: alu_bcond = (alu_in_1 != alu_in_2) ? 1 : 0;
		`ALU_BLT: alu_bcond = ($signed(alu_in_1) < $signed(alu_in_2)) ? 1 : 0;
		`ALU_BGE: alu_bcond = ($signed(alu_in_1) >= $signed(alu_in_2)) ? 1 : 0;
        default: begin
            alu_result = 32'b0;
            alu_bcond  = 1'b0;
        end
    endcase
end
endmodule
