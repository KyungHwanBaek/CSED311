`include "opcodes.v"

module control_unit (
    input  [6:0] part_of_inst,
    output reg mem_write,
    output reg mem_read,
    output reg mem_to_reg,
    output reg alu_src,
    output reg [1:0] alu_op,
    output reg write_enable,
    output reg is_ecall,
    output reg is_jalr,
    output reg is_jal,
    output reg pc_to_reg,
    output reg branch
);

    always @* begin
        // 기본값: 모두 0
        { mem_write, mem_read, mem_to_reg,
          alu_src, alu_op,
          write_enable, is_ecall,
          is_jalr, is_jal, pc_to_reg, branch }
        = 12'b0;

        case (part_of_inst)
            `ARITHMETIC:
                { mem_write, mem_read, mem_to_reg,
                  alu_src,   alu_op,
                  write_enable, is_ecall,
                  is_jalr, is_jal, pc_to_reg, branch }
                = { 1'b0, 1'b0, 1'b0,
                    1'b0, 2'b10,
                    1'b1, 1'b0,
                    1'b0, 1'b0, 1'b0, 1'b0 };
            `ARITHMETIC_IMM:
                { mem_write, mem_read, mem_to_reg,
                  alu_src,   alu_op,
                  write_enable, is_ecall,
                  is_jalr, is_jal, pc_to_reg, branch }
                = { 1'b0, 1'b0, 1'b0,
                    1'b1, 2'b11,
                    1'b1, 1'b0,
                    1'b0, 1'b0, 1'b0, 1'b0 };
            `LOAD:
                { mem_write, mem_read, mem_to_reg,
                  alu_src,   alu_op,
                  write_enable, is_ecall,
                  is_jalr, is_jal, pc_to_reg, branch }
                = { 1'b0, 1'b1, 1'b1,
                    1'b1, 2'b00,
                    1'b1, 1'b0,
                    1'b0, 1'b0, 1'b0, 1'b0 };
            `STORE:
                { mem_write, mem_read, mem_to_reg,
                  alu_src,   alu_op,
                  write_enable, is_ecall,
                  is_jalr, is_jal, pc_to_reg, branch }
                = { 1'b1, 1'b0, 1'b0,
                    1'b1, 2'b00,
                    1'b0, 1'b0,
                    1'b0, 1'b0, 1'b0, 1'b0 };
            `ECALL:
                { mem_write, mem_read, mem_to_reg,
                  alu_src,   alu_op,
                  write_enable, is_ecall,
                  is_jalr, is_jal, pc_to_reg, branch }
                = { 1'b0, 1'b0, 1'b0,
                    1'b0, 2'b00,
                    1'b0, 1'b1,
                    1'b0, 1'b0, 1'b0, 1'b0 };
                    
            // Branch, jal, jalr 경우 signal 설정 추가
            `BRANCH:
                { mem_write, mem_read, mem_to_reg,
                  alu_src,   alu_op,
                  write_enable, is_ecall,
                  is_jalr, is_jal, pc_to_reg, branch }
                = { 1'b0, 1'b0, 1'b0,
                    1'b0, 2'b01,
                    1'b0, 1'b0,
                    1'b0, 1'b0, 1'b0, 1'b1 };
            `JALR:
                { mem_write, mem_read, mem_to_reg,
                  alu_src,   alu_op,
                  write_enable, is_ecall,
                  is_jalr, is_jal, pc_to_reg, branch }
                = { 1'b0, 1'b0, 1'b0,
                    1'b1, 2'b00,
                    1'b1, 1'b0,
                    1'b1, 1'b0, 1'b1, 1'b0 };
            `JAL:
                { mem_write, mem_read, mem_to_reg,
                  alu_src,   alu_op,
                  write_enable, is_ecall,
                  is_jalr, is_jal, pc_to_reg, branch }
                = { 1'b0, 1'b0, 1'b0,
                    1'b0, 2'b00,
                    1'b1, 1'b0,
                    1'b0, 1'b1, 1'b1, 1'b0 };
            default: ; // 모든 신호 0 유지
        endcase
    end

endmodule
