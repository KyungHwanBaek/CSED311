module mux (input [31:0] mux_in_1,
            input [31:0] mux_in_2,
            input select, 
            output [31:0] mux_out);

    assign mux_out = ~select ? mux_in_1 : mux_in_2;
	// ~select가 True -> mux_in_1
	// ~select가 False -> mux_in_2
endmodule
