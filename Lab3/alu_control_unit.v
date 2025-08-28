`include "opcodes.v"

module alu_control_unit(
    input  [31:0] part_of_inst,   // 32비트 명령어 전체
    input  [1:0]  alu_op,         // 상위 제어 유닛으로부터 전달된 2비트 ALU 연산 코드
    output reg [3:0] alu_op_out   // ALU에 전달할 4비트 제어 신호
);

// part_of_inst[14:12]: func3 코드
always @(*) begin
    alu_op_out = `ALU_NONE;
    case (alu_op)
        // 2'b00: Load/Store
        2'b00: alu_op_out = `ALU_ADD;
        // 2'b01: Branch
        2'b01: begin
            case (part_of_inst[14:12])
                `FUNCT3_BEQ: alu_op_out = `ALU_BEQ;
                `FUNCT3_BNE: alu_op_out = `ALU_BNE;
                `FUNCT3_BLT: alu_op_out = `ALU_BLT;
                `FUNCT3_BGE: alu_op_out = `ALU_BGE;
                default: alu_op_out = `ALU_NONE;
            endcase
        end
        // 2'b10: R-Type
        2'b10: begin
            case (part_of_inst[14:12])
                `FUNCT3_ADD: begin
                    if (part_of_inst[30] == 1'b0) alu_op_out = `ALU_ADD;  
                    else alu_op_out = `ALU_SUB;     
                end
                `FUNCT3_SLL: alu_op_out = `ALU_SLL;
                `FUNCT3_XOR: alu_op_out = `ALU_XOR;
                `FUNCT3_OR:  alu_op_out = `ALU_OR;
                `FUNCT3_AND: alu_op_out = `ALU_AND;
                `FUNCT3_SRL: begin
                    if (part_of_inst[30] == 1'b0) alu_op_out = `ALU_SRL;
                    else alu_op_out = `ALU_NONE;   
                end
                default: alu_op_out = `ALU_NONE;
            endcase
        end
        // 2'b11: I-type
        2'b11: begin
            case (part_of_inst[14:12])
                `FUNCT3_ADD: alu_op_out = `ALU_ADD;
                `FUNCT3_SLL: alu_op_out = `ALU_SLL;
                `FUNCT3_SRL: begin
                    if (part_of_inst[30] == 1'b0) alu_op_out = `ALU_SRL;
                    else alu_op_out = `ALU_NONE;
                end
                `FUNCT3_XOR: alu_op_out = `ALU_XOR;
                `FUNCT3_OR:  alu_op_out = `ALU_OR;
                `FUNCT3_AND: alu_op_out = `ALU_AND;
                default: alu_op_out = `ALU_NONE;
            endcase
        end
        default: alu_op_out = `ALU_NONE;
    endcase
end

endmodule
