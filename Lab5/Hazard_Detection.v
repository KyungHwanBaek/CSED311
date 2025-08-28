`include "opcodes.v"

module Hazard_Detection (
    input [4:0] id_rs1,
    input [4:0] id_rs2,
    input [4:0] ex_rd,
    input [4:0] mem_rd,
    input ex_mem_read,
    input ex_reg_write,
    input mem_mem_read,
    input [6:0] id_opcode,
    output reg pc_write,
    output reg if_id_write,
    output reg is_hazard
);

reg use_rs1, use_rs2;

always @(*) begin
	use_rs1 = 0;
	use_rs2 = 0;
	
	if (id_opcode != `JAL && id_rs1 != 5'b0) use_rs1 = 1;
    if ((id_opcode == `ARITHMETIC || id_opcode == `STORE || id_opcode == `BRANCH) && id_rs2 != 5'b0) use_rs2 = 1;
end

always @(*) begin
    pc_write    = 1;
    if_id_write = 1;
    is_hazard   = 0;
	// STALL하지 않는 기본값
	
    if (id_opcode == `ECALL) begin
        if ((ex_rd == 17) && ex_reg_write) begin
            pc_write    = 0;
            if_id_write = 0;
            is_hazard   = 1;
        end
        else if ((mem_rd == 17) && mem_mem_read) begin
            pc_write    = 0;
            if_id_write = 0;
            is_hazard   = 1;
        end
    end
	// ECALL 명령어가 들어올 때 hazard 발생시켜서 일단 stall하도록 하고 나중에 
    else begin
        if (ex_mem_read &&(((use_rs1 && (id_rs1 == ex_rd)) || (use_rs2 && (id_rs2 == ex_rd))))) begin
            pc_write    = 1'b0;
            if_id_write = 1'b0;
            is_hazard   = 1'b1;
        end
    end
end

endmodule
