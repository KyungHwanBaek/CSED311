`include "vending_machine_def.v"


module check_time_and_coin(current_total, i_trigger_return, wait_time, o_return_coin);
// module의 이름은 check_time_and_coin이나, time을 check하는 것이 calculate_current_state로 이동하게 되면서 사실상 coin을 check하는 역할만 한다.
	input [`kTotalBits-1:0] current_total; //상품을 실제 구매할 수 있는지, return할 돈을 체크하는 데 사용하기 위해 추가한 변수
	input i_trigger_return; // return 버튼을 눌렀는지 확인하기 위해 추가한 변수
	input wait_time;
	output reg [`kNumCoins-1:0] o_return_coin;

	// initiate values
	initial begin
		// TODO: initiate values
		o_return_coin = 3'b000;
	end

	always @(*) begin
	// TODO: o_return_coin
	// i_trigger_return 신호가 들어오거나 wait_time이 0보다 작으면 o_return_coin을 출력한다.
	// 0 미만으로 하고 싶었으나 0 혹은 -1 일 때 wait_time이 해당 숫자가 아님에도 불구하고 조건문을 참으로 만드는 glitch가 발생하는 바람에 불가피하게 -1 미만으로 설정하게 되었다.
		if(i_trigger_return == 1 || $signed(wait_time) < -1) begin
			if(current_total >= 1600) begin
				o_return_coin = 3'b111;
			end
			else if(current_total >= 1500) begin
				o_return_coin = 3'b110;
			end
			else if(current_total >= 1100) begin
				o_return_coin = 3'b101;
			end
			else if(current_total >= 1000) begin
				o_return_coin = 3'b100;
			end
			else if(current_total >= 600) begin
				o_return_coin = 3'b011;
			end
			else if(current_total >= 500) begin
				o_return_coin = 3'b010;
			end
			else if(current_total >= 100) begin
				o_return_coin = 3'b001;
			end
			else begin
				o_return_coin = 3'b000;
			end
		end
		else begin
			o_return_coin = 3'b000;
		end
	end

endmodule 