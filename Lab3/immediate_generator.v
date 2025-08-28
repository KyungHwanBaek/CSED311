`include "opcodes.v"

module immediate_generator(input [31:0] part_of_inst,
                            output reg [31:0] imm_gen_out);

wire [6:0] opcode = part_of_inst[6:0];

always @(*) begin
    imm_gen_out = 0;    
    if(opcode == `ARITHMETIC_IMM) imm_gen_out = {{21{part_of_inst[31]}}, part_of_inst[30:20]};
    else if(opcode == `LOAD) imm_gen_out = {{21{part_of_inst[31]}}, part_of_inst[30:20]};
    else if(opcode == `JALR) imm_gen_out = {{21{part_of_inst[31]}}, part_of_inst[30:21], 1'b0};
    else if(opcode == `STORE) imm_gen_out = {{21{part_of_inst[31]}}, part_of_inst[30:25], part_of_inst[11:7]};
    else if(opcode == `BRANCH) imm_gen_out = {{20{part_of_inst[31]}}, part_of_inst[7], part_of_inst[30:25], part_of_inst[11:8], 1'b0};
    else if(opcode == `JAL) imm_gen_out = {{12{part_of_inst[31]}}, part_of_inst[19:12], part_of_inst[20], part_of_inst[30:21], 1'b0};
    else imm_gen_out = 0;
end
endmodule
