
module alu(
    input [3:0] alu_op,      		// input
    input [31:0] alu_in_1,   		// input
    input [31:0] alu_in_2,  		// input
    output reg [31:0] alu_result,   // output
    output reg alu_bcond   			// output
);

// ALU는 bit 단위 연산을 시행하므로 bitwise 연산자를 사용해야 한다. ex) bitwise OR 등

always @(*) begin
    alu_result = 0;
    alu_bcond = 0;

    case (alu_op)
        4'b0000: alu_result = alu_in_1 + alu_in_2;  		// ADD
        4'b0001: alu_result = alu_in_1 - alu_in_2;  		// SUB
        4'b0010: alu_result = alu_in_1 << alu_in_2[4:0];  	// Shift Left Logical
        4'b0011: alu_result = alu_in_1 ^ alu_in_2;  		// XOR
        4'b0100: alu_result = alu_in_1 | alu_in_2;  		// OR
        4'b0101: alu_result = alu_in_1 & alu_in_2;  		// AND
        4'b0110: alu_result = alu_in_1 >> alu_in_2[4:0];  	// Shift Right Logical
        
        // Branch conditions
        4'b1000: alu_bcond = (alu_in_1 == alu_in_2) ? 1 : 0;  					// BEQ (Branch if Equal)
        4'b1001: alu_bcond = (alu_in_1 != alu_in_2) ? 1 : 0;  					// BNE (Branch if Not Equal)
        4'b1010: alu_bcond = ($signed(alu_in_1) < $signed(alu_in_2)) ? 1 : 0;  	// BLT (Branch if Less Than)
        4'b1011: alu_bcond = ($signed(alu_in_1) >= $signed(alu_in_2)) ? 1 : 0;  // BGE (Branch if Greater or Equal)
        default: alu_result = 0;
		
    endcase
	
end

endmodule
