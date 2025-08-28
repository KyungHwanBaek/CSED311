`include "opcodes.v"

module alu_control_unit(input [31:0] part_of_inst,
                        output reg [3:0] alu_op
);

wire [6:0] opcode = part_of_inst[6:0];           	// opcode
wire [2:0] func_3 = part_of_inst[14:12];          	// func3
wire [6:0] func_7 = part_of_inst[31:25];          	// func7
// 본 함수에서는 opcode, func3, func7을 조합하여 ALU Control의 input으로 처리한다.
wire _unused_ok = &{part_of_inst[24:15], part_of_inst[11:7]};

always @(*) begin
    
    alu_op = 4'b1111;       						// Default Case: NOP
    if (opcode == `ARITHMETIC) begin  				// R-type
        case (func_3)
            `FUNCT3_ADD: alu_op = (func_7 == `FUNCT7_SUB) ? 4'b0001 : 4'b0000; // SUB or ADD
            `FUNCT3_SLL: alu_op = 4'b0010; 			// Shift Left Logical
            `FUNCT3_XOR: alu_op = 4'b0011; 			// XOR
            `FUNCT3_OR:  alu_op = 4'b0100; 			// OR
            `FUNCT3_AND: alu_op = 4'b0101; 			// AND
            `FUNCT3_SRL: alu_op = 4'b0110; 			// Shift Right Logical
            default: alu_op = 4'b1111;
        endcase
    end
    else if (opcode == `ARITHMETIC_IMM) begin 		// I-type
        case (func_3)
            `FUNCT3_ADD: alu_op = 4'b0000; 			// ADD immediate
            `FUNCT3_SLL: alu_op = 4'b0010; 			// Shift Left Logical
            `FUNCT3_XOR: alu_op = 4'b0011; 			// XOR immediate
            `FUNCT3_OR:  alu_op = 4'b0100; 			// OR immediate
            `FUNCT3_AND: alu_op = 4'b0101; 			// AND immediate
            `FUNCT3_SRL: alu_op = 4'b0110; 			// Shift Right Logical immediate
            default: alu_op = 4'b1111;
        endcase
    end
    else if (opcode == `BRANCH) begin				// Branch operations
        case (func_3)
            `FUNCT3_BEQ: alu_op = 4'b1000; 			// Branch if Equal
            `FUNCT3_BNE: alu_op = 4'b1001; 			// Branch if Not Equal
            `FUNCT3_BLT: alu_op = 4'b1010; 			// Branch if Less Than
            `FUNCT3_BGE: alu_op = 4'b1011; 			// Branch if Greater or Equal
            default: alu_op = 4'b1111;
        endcase
    end
    else if (opcode == `LOAD || opcode == `JALR || opcode == `JAL || opcode == `STORE) begin
        alu_op = 4'b0000;
		// 주소 계산을 위해 ALU ADD 사용하기
    end
end

endmodule
