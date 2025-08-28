`include "opcodes.v"
`include "state5.v"

module micro_control(input reset,
                     input clk,
                      input [6:0] opcode,
                      input alu_bcond,
                      input [2:0] current_state,
                      output reg [2:0] next_state);

    always @(*) begin
        case (current_state)
            `IF1: next_state = `IF2;
            `IF2: begin
                if (opcode == `JAL) next_state = `EX1;
                else if (opcode == `ECALL) next_state = `IF1;
                else next_state = `ID;
            end
            `ID: next_state = `EX1;
            `EX1: begin
				if(opcode == `BRANCH) begin
					if(alu_bcond == 0) next_state = `IF1;
					else next_state = `EX2;
				end
				else next_state = `EX2;
			end
            `EX2: begin
                if (opcode == `BRANCH) next_state = `IF1;
                else if (opcode == `ARITHMETIC || opcode == `ARITHMETIC_IMM || opcode == `JALR || opcode == `JAL) next_state = `WB;
                else if (opcode == `LOAD || opcode == `STORE) next_state = `MEM1;
                else next_state = `MEM1;
            end
            `MEM1: next_state = `MEM2;
            `MEM2: begin
                if (opcode == `LOAD) next_state = `WB;
                else next_state = `IF1;
            end
            `WB: next_state = `IF1;
            default: next_state = `IF1;
        endcase
    end


endmodule
