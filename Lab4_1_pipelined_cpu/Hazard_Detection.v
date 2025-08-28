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

reg use_rs1, use_rs2;                   //rs1, rs2이 진짜 사용되는 register인지 확인

always @(*) begin 
    if ((id_opcode == `STORE) || (id_opcode == `ARITHMETIC)) use_rs2 = (id_rs2 != 0);       //rs2를 쓰는건 stor/r-type밖에 없음
	else use_rs2 = 0;
    use_rs1 = (id_rs1 != 0); 
end

always @(*) begin
    pc_write    = 1;
    if_id_write = 1;
    is_hazard   = 0;
	
    if (id_opcode == `ECALL) begin                      //ecall명령어 전용 hazard_detect
        if ((ex_rd == 17) && ex_reg_write) begin
            is_hazard   = 1;
            pc_write    = 0;
            if_id_write = 0;
        end
        else if ((mem_rd == 17) && mem_mem_read) begin
            is_hazard   = 1;
            pc_write    = 0;
            if_id_write = 0;
        end
    end
    else begin                                            //ecall제외, data hazard발생 체크용. dataforwarding 고려하였기에, ID와 EX단계의 register만 비교하면 됨.
        if ((((use_rs1 && (id_rs1 == ex_rd)) || (use_rs2 && (id_rs2 == ex_rd)))) && ex_mem_read) begin
            is_hazard   = 1;
            pc_write    = 0;
            if_id_write = 0;
        end
    end
end

endmodule
