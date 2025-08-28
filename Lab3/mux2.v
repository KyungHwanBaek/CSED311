module mux2 (input [31:0] mux_in_1,
            input [31:0] mux_in_2,
			input [31:0] mux_in_3,
			input [31:0] mux_in_4,
            input [1:0] select, 
            output [31:0] mux_out);
	
    
    assign mux_out = (select == 2'b00) ? mux_in_1 :
                     (select == 2'b01) ? mux_in_2 :
                     (select == 2'b10) ? mux_in_3 :
                                         mux_in_4;
    

endmodule
