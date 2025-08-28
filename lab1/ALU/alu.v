module ALU #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C,
       	output reg OverflowFlag);
// Do not use delay in your implementation.

// You can declare any variables as needed.
/*
	YOUR VARIABLE DECLARATION...
*/

initial begin
	C = 0;
	OverflowFlag = 0;
end   	

// TODO: You should implement the functionality of ALU!
// (HINT: Use 'always @(...) begin ... end')
	always @(*) begin
    	if(FuncCode == 4'b0000) begin
			C = A+B;
		 	OverflowFlag = (A[data_width-1] == B[data_width-1] && C[data_width-1]!= A[data_width-1]);
		end 
		else if(FuncCode == 4'b0001) begin
			C = A-B;
			OverflowFlag = (A[data_width-1] != B[data_width-1] && C[data_width-1] != A[data_width-1]);
		end 
		else if(FuncCode == 4'b0010) begin
			OverflowFlag = 0;
			C = A;
		end 
		else if(FuncCode == 4'b0011) begin
			OverflowFlag = 0;
			C = ~A;
		end 
		else if(FuncCode == 4'b0100) begin
		    OverflowFlag = 0;
			C = (A&B);
		end 
		else if(FuncCode == 4'b0101) begin
		    OverflowFlag = 0;
			C = (A|B);
		end 
		else if(FuncCode == 4'b0110) begin
		    OverflowFlag = 0;
			C = ~(A&B);
		end 
		else if(FuncCode == 4'b0111) begin
		    OverflowFlag = 0;
			C = ~(A|B);
		end 
		else if(FuncCode == 4'b1000) begin
		    OverflowFlag = 0;
			C = (A^B);
		end 
		else if(FuncCode == 4'b1001) begin
		    OverflowFlag = 0;
			C = ~(A^B);
		end 
		else if(FuncCode == 4'b1010) begin
		    OverflowFlag = 0;
			C = A<<1;
		end 
		else if(FuncCode == 4'b1011) begin
		    OverflowFlag = 0;
			C = A>>1;
		end 
		else if(FuncCode == 4'b1100) begin
		    OverflowFlag = 0;
			C = A<<<1;
		end 
		else if(FuncCode == 4'b1101) begin
		    OverflowFlag = 0;
			C = A>>>1;
		end 
		else if(FuncCode == 4'b1110)begin
		    OverflowFlag = 0;
			C = ~A + 1;
		end 
		else if(FuncCode == 4'b1111) begin
		    OverflowFlag = 0;
			C = 0;
		end
		else begin
		    OverflowFlag = 0;
			C = 0;
		end
	end
endmodule

