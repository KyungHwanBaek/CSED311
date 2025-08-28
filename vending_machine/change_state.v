`include "vending_machine_def.v"


module change_state(clk, reset_n, current_total_nxt, return_total_nxt, 
i_trigger_return, current_total, current_total_prev, return_total);
	input clk;
	input reset_n;
	input [`kTotalBits-1:0] current_total_nxt, return_total_nxt;
	input i_trigger_return;
	output reg [`kTotalBits-1:0] current_total, current_total_prev, return_total;
	
	// Sequential circuit to reset or update the states
	// 이 부분이 왜 필요하나 생각할 수도 있다. 그러나 이 부분이 이 Verilog 구현의 꽃이다.
	// calculate_current_state에서는 단순히 wire로 변수들 간에 실시간 동기화가 되도록 만들어 놓아서 사용자가 input을 입력하면 바로 반영이 되었다면
	// 여기서는 clk 신호에 의해 "실질적으로" 저장되는 구현을 하는 것이다.

	always @(posedge clk) begin
		if (!reset_n) begin
			// TODO: reset all states.
			current_total <= 0;
		end
		else begin
			// TODO: update all states.
			current_total <= current_total_nxt;
		end
	end
	
	always @(posedge clk) begin
		current_total_prev <= current_total;
	end

	reg temp1, temp2;
	always @(posedge clk) begin
	// 두 클럭 후에 return_total_nxt 값을 return_total에 할당
	// 아래와 같이 구현함으로써 입력 신호를 두 단계 지연시킬 수 있다
		if (!reset_n) begin
		// 초기값 설정
			temp1 <= 0;
			temp2 <= 0;
			return_total <= 0;
		end
		else begin
			temp1 <= i_trigger_return;
			temp2 <= temp1;
			if (temp2)
            return_total <= return_total_nxt;
		end
	end

endmodule 