`include "vending_machine_def.v"

module calculate_current_state(i_input_coin, i_select_item,
current_total, current_total_prev, reset_n, clk, input_total, 
output_total, return_total, current_total_nxt, return_total_nxt, 
o_return_coin, o_available_item, o_output_item, wait_time);
// 현재 State의 자판기 내부 금액을 계산해주는 모듈, input으로 들어온 wait_time을 쓰지 않음.
	input [`kNumCoins-1:0] i_input_coin, o_return_coin; // 투입한 코인(input coin)과 반환하는 코인(return coin)의 종류를 표현해주는 wire -> [2:0]
	input [`kNumItems-1:0]	i_select_item; // 선택한 물품(i_select_item)의 종류를 표현해주는 wire -> [3:0]
	input [`kTotalBits-1:0] current_total, current_total_prev;; // 현재까지 자판기에 들어간 금액을 선언하는 wire -> [30:0]
	input reset_n;
	input clk;
	output reg [`kTotalBits-1:0] input_total, output_total, return_total, current_total_nxt, return_total_nxt;
	output reg [`kNumItems-1:0] o_available_item, o_output_item; // 현재 뽑을 수 있는 물품(o_available_item)과 뽑는 물품(o_output_item) register -> [3:0]
	output reg [31:0] wait_time; // 돈을 반환하기까지 기다리는 시간을 나타내는 변수, wait_time을 정해주는 변수를 check_time_and_coin에서 이곳으로 옮겨서 수행한다.
	// input [31:0] item_price [`kNumItems-1:0]; // 물품의 가격을 나타내주는 wire (2000/1000/500/400)
	// input [31:0] coin_value [`kNumCoins-1:0]; // 코인의 가격을 나타내주는 wire (1000/500/100)
	// 코인의 가격과 물품의 가격은 상수로서 고정되어 있기에 이를 wire로 선언하지 않고 생략한다
	// 또한, input은 wire로 선언해야하고 output은 reg로도 선언할 수 있다.
	
	initial begin
		input_total = 0;
		output_total = 0;
		return_total = 0;
		current_total_nxt = 0;
		return_total_nxt = 0;
		o_available_item = 4'b0000;
		o_output_item = 4'b0000;
		wait_time = 100;
	end

	// Combinational logic for the next states
	always @(*) begin
		// TODO: current_total_nxt, o_output_item, o_available_item
		// You don't have to worry about concurrent activations in each input vector (or array).
		// Calculate the next current_total state.

		// 여기서 하는 역할은 자판기 내에서의 돈 계산과 item을 dispense해주는 것임을 정확하게 인지하고 있어야 한다. 잔돈 반환에 대한 '판단'은 여기서 하지 않는다.
		// check_time_and_coin에서 얼마나 반환할지 계산하여 o_return_coin을 매개변수로 넘기는 것에 따라서 단순히 돈을 차감하는 것만 하는 것임을 명심하자.
		// 또한, 여기서는 어떤 신호가 들어왔을 때 current_total과 연결된 wire를 기반으로 실시간으로 current_total_nxt가 바뀌는 변수임을 생각해야 한다.
		// 즉, 여기서는 변수를 저장하는 것이 아니라 그냥 wire로 연결된 100% 동기화된 변수들이라고 생각하면 될 것이다. 여기서는 그냥 변수들끼리 이어주는 것. 그 이상 그 이하도 아니다.
		// 실제 다음 단계로 가게 하는 것, 즉 current_total이 current_total_nxt로 넘어가게 해주는 것은 change_state에서 하는 것이고 change_state에서 clk에 의해
		// current_total의 값이 바뀌게 될 때야 "비로소" 다음 단계로 넘어가게 되는 것이라는 것이다.
		// 실제로 그래서 굳이 current_total_nxt를 만든 것, 그리고 change_state를 만든 것 또한 이런 구현을 위해서인 것이 일맥상통하다.

		// 최종적으로는 current_total_nxt를 구현해야하는 것은 맞다.
		// 그러나 이를 구현하기 위해서 input_total, output_total, return_total을 먼저 구현하여 이를 이용하여 최종계산해야한다.
		// 물건을 구매했을 때 output_total을 업데이트 및 물건 dispense
		// 물건을 구매할 때는 잔액이 물건의 가격 이상임을 확인해야 한다
		
		// o_output_item 및 output_total 구현
		// current_total으로만 구현할 경우 current_total값이 즉시 차감되어 output_total과 o_output_item이 반영되지 않음.
		// current_total의 상태를 한 clk 더 유지하고자 current_total의 이전값을 저장하는 current_total_prev를 도입함.
		if(i_select_item == 4'b1111 && (current_total_prev >= 3900 || current_total >= 3900)) begin
			output_total = 3900;
			o_output_item = 4'b1111;
		end
		else if(i_select_item == 4'b1110 && (current_total_prev >= 3500 || current_total >= 3500)) begin
			output_total = 3500;
			o_output_item = 4'b1110;
		end
		else if(i_select_item == 4'b1101 && (current_total_prev >= 3400 || current_total >= 3400)) begin
			output_total = 3400;
			o_output_item = 4'b1101;
		end
		else if(i_select_item == 4'b1100 && (current_total_prev >= 3000 || current_total >= 3000)) begin
			output_total = 3000;
			o_output_item = 4'b1100;
		end
		else if(i_select_item == 4'b1011 && (current_total_prev >= 2900 || current_total >= 2900)) begin
			output_total = 2900;
			o_output_item = 4'b1011;
		end
		else if(i_select_item == 4'b1010 && (current_total_prev >= 2500 || current_total >= 2500)) begin
			output_total = 2500;
			o_output_item = 4'b1010;
		end
		else if(i_select_item == 4'b1001 && (current_total_prev >= 2400 || current_total >= 2400)) begin
			output_total = 2400;
			o_output_item = 4'b1001;
		end
		else if(i_select_item == 4'b1000 && (current_total_prev >= 2000 || current_total >= 2000)) begin
			output_total = 2000;
			o_output_item = 4'b1000;
		end
		else if(i_select_item == 4'b0111 && (current_total_prev >= 1900 || current_total >= 1900)) begin
			output_total = 1900;
			o_output_item = 4'b0111;
		end
		else if(i_select_item == 4'b0110 && (current_total_prev >= 1500 || current_total >= 1500)) begin
			output_total = 1500;
			o_output_item = 4'b0110;
		end
		else if(i_select_item == 4'b0101 && (current_total_prev >= 1400 || current_total >= 1400)) begin
			output_total = 1400;
			o_output_item = 4'b0101;
		end
		else if(i_select_item == 4'b0100 && (current_total_prev >= 1000 || current_total >= 1000)) begin
			output_total = 1000;
			o_output_item = 4'b0100;
		end
		else if(i_select_item == 4'b0011 && (current_total_prev >= 900 || current_total >= 900)) begin
			output_total = 900;
			o_output_item = 4'b0011;
		end
		else if(i_select_item == 4'b0010 && (current_total_prev >= 500 || current_total >= 500)) begin
			output_total = 500;
			o_output_item = 4'b0010;
		end
		else if(i_select_item == 4'b0001 && (current_total_prev >= 400 || current_total >= 400)) begin
			output_total = 400;
			o_output_item = 4'b0001;
		end
		else begin
			output_total = 0;
			o_output_item = 4'b0000;
		end
		
		// 돈을 넣었을 때 input_total을 업데이트
		// coin이 중복으로 들어오는 경우도 있기에 모든 경우에 대해서 따져주어야 한다
		if(i_input_coin == 3'b111) begin
			input_total = 1600;
		end
		else if(i_input_coin == 3'b110) begin
			input_total = 1500;
		end
		else if(i_input_coin == 3'b101) begin
			input_total = 1100;
		end
		else if(i_input_coin == 3'b100) begin
			input_total = 1000;
		end
		else if(i_input_coin == 3'b011) begin
			input_total = 600;
		end
		else if(i_input_coin == 3'b010) begin
			input_total = 500;
		end
		else if(i_input_coin == 3'b001) begin
			input_total = 100;
		end
		else begin
			input_total = 0;
		end

		// 돈을 환불했을 때 return_total을 업데이트
		// 돈을 환불할 때는 모든 돈을 return 해야 한다
		// return_total_nxt
		if(o_return_coin == 3'b111) begin
			return_total_nxt = 1600;
		end
		else if(o_return_coin == 3'b110) begin
			return_total_nxt = 1500;
		end
		else if(o_return_coin == 3'b101) begin
			return_total_nxt = 1100;
		end
		else if(o_return_coin == 3'b100) begin
			return_total_nxt = 1000;
		end
		else if(o_return_coin == 3'b011) begin
			return_total_nxt = 600;
		end
		else if(o_return_coin == 3'b010) begin
			return_total_nxt = 500;
		end
		else if(o_return_coin == 3'b001) begin
			return_total_nxt = 100;
		end
		else begin
			return_total_nxt = 0;
		end

		// 위에서 계산한 것을 바탕으로 최종적으로 current_total_nxt를 계산해본다.
		// 아래 식을 기반으로 current_total_nxt는 실시간으로 동기화되고 있다.
		current_total_nxt = current_total + input_total - output_total - return_total;

		// o_available_item 나타내는 부분
		// 큰 금액부터 선언해야 하고 다른 부분은 else if로 선언해야 오류가 생기지 않음을 주의한다
		if(current_total >= 2000) begin
			o_available_item = 4'b1111;
		end
		else if(current_total >= 1000) begin
			o_available_item = 4'b0111;
		end
		else if(current_total >= 500) begin
			o_available_item = 4'b0011;
		end
		else if(current_total >= 400) begin
			o_available_item = 4'b0001;
		end
		else begin
			o_available_item = 4'b0000;
		end

	end
	
	wire reset_wait;
    assign reset_wait = ((i_select_item == 4'b1111 && (current_total_prev >= 3900 || current_total >= 3900)) ||
                         (i_select_item == 4'b1110 && (current_total_prev >= 3500 || current_total >= 3500)) ||
                         (i_select_item == 4'b1101 && (current_total_prev >= 3400 || current_total >= 3400)) ||
                         (i_select_item == 4'b1100 && (current_total_prev >= 3000 || current_total >= 3000)) ||
                         (i_select_item == 4'b1011 && (current_total_prev >= 2900 || current_total >= 2900)) ||
                         (i_select_item == 4'b1010 && (current_total_prev >= 2500 || current_total >= 2500)) ||
                         (i_select_item == 4'b1001 && (current_total_prev >= 2400 || current_total >= 2400)) ||
                         (i_select_item == 4'b1000 && (current_total_prev >= 2000 || current_total >= 2000)) ||
                         (i_select_item == 4'b0111 && (current_total_prev >= 1900 || current_total >= 1900)) ||
                         (i_select_item == 4'b0110 && (current_total_prev >= 1500 || current_total >= 1500)) ||
                         (i_select_item == 4'b0101 && (current_total_prev >= 1400 || current_total >= 1400)) ||
                         (i_select_item == 4'b0100 && (current_total_prev >= 1000 || current_total >= 1000)) ||
                         (i_select_item == 4'b0011 && (current_total_prev >= 900 || current_total >= 900)) ||
                         (i_select_item == 4'b0010 && (current_total_prev >= 500 || current_total >= 500)) ||
                         (i_select_item == 4'b0001 && (current_total_prev >= 400 || current_total >= 400)) ||
                         (i_input_coin)
                        );
	
	always @(posedge clk) begin
		if (!reset_n) begin
		// TODO: reset all states.
			wait_time <= 100;
		end
		else if(reset_wait) begin
			wait_time <= 100;
		end
		else begin
		// TODO: update all states.
		// 시간이 1clk씩 계속 감소 구현 필요
			wait_time <= wait_time - 1;
		end
	end
	
endmodule