module forward (input [4:0] ex_rs1,
                       input [4:0] ex_rs2,
                       input [4:0] mem_rd,
                       input [4:0] wb_rd,
                       input mem_reg_write,
                       input wb_reg_write,
                       output reg [1:0] forward_rs1,
                       output reg [1:0] forward_rs2);

always @(*) begin
    if (ex_rs1 != 5'b0 && ex_rs1 == mem_rd && mem_reg_write) forward_rs1 = 2'b01;
    else if (ex_rs1 != 5'b0 && ex_rs1 == wb_rd && wb_reg_write) forward_rs1 = 2'b10;
    else forward_rs1 = 2'b00;
	
	if (ex_rs2 != 5'b0 && ex_rs2 == mem_rd && mem_reg_write) forward_rs2 = 2'b01;
    else if (ex_rs2 != 5'b0 && ex_rs2 == wb_rd && wb_reg_write) forward_rs2 = 2'b10;
    else forward_rs2 = 2'b00;
end

endmodule
