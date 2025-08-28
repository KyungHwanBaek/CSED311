`include "opcodes.v"

module control_unit (
    input [6:0] part_of_inst,
    output reg mem_write,
    output reg mem_read,
    output reg mem_to_reg,
    output reg alu_src,
    output reg [1:0] alu_op,
    output reg write_enable,
    output reg is_ecall
);
    always @(*) begin
        {mem_write, mem_read, mem_to_reg, alu_src, alu_op, write_enable, is_ecall} = 8'b0;
        case (part_of_inst)
            `ARITHMETIC:                                        //alu_src=0으로 할당함으로써 rs2값 사용하도록 함.   
                {mem_write, mem_read, mem_to_reg,
                 alu_src,   alu_op,                             //alu_op 값을 10으로 주어 alu_control_unit에서 나머지 비트와 조합하여 적절한 arithmetic이 동작하도록 함.
                 write_enable, is_ecall} = {1'b0,1'b0,1'b0,     //write_enable은 reg에 WB될 수 있도록 하는 신호
                                            1'b0,2'b10,
                                            1'b1,1'b0};
            `ARITHMETIC_IMM:                                   //alu_src값 1으로 할당. => 상수값 사용
                {mem_write, mem_read, mem_to_reg,
                 alu_src,   alu_op,
                 write_enable, is_ecall} = {1'b0,1'b0,1'b0,
                                            1'b1,2'b11,
                                            1'b1,1'b0};
            `STORE:                                             //메모리에 값을 작성해야 하기에 mem_write = 1
                {mem_write, mem_read, mem_to_reg,
                 alu_src,   alu_op,
                 write_enable, is_ecall} = {1'b1,1'b0,1'b0,
                                            1'b1,2'b00,
                                            1'b0,1'b0};
            `LOAD:                                            
                {mem_write, mem_read, mem_to_reg,               //메모리에서 값을 읽고, 그 값을 레지스터에 쓰기 위해 각각 1로 할당
                 alu_src,   alu_op,                             //상수 값 가져옴. 메모리 주소 계산하기 위하여
                 write_enable, is_ecall} = {1'b0,1'b1,1'b1,
                                            1'b1,2'b00,
                                            1'b1,1'b0};
            `ECALL:          
                {mem_write, mem_read, mem_to_reg,               
                 alu_src,   alu_op,
                 write_enable, is_ecall} = {1'b0,1'b0,1'b0,             //다른 값 필요없이, is_ecall만 조절함으로써 종료 조건 확인. => cpu.v에 구현.
                                            1'b0,2'b00,
                                            1'b0,1'b1};
            default: ; // 모든 신호 0 유지
        endcase
    end

endmodule
