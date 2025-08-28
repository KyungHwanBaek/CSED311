module pc (input reset,
           input clk,
           input [31:0] next_pc,
           input pc_rewrite,
		   input pc_sig,
           output reg [31:0] current_pc);

always @(posedge clk) begin
	if (reset) current_pc <= 0;
	else if (pc_rewrite || pc_sig) current_pc <= next_pc;
end

endmodule
