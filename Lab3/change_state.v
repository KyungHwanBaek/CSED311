`include "state5.v"

module change_state(input reset,
                    input clk,
                    input [2:0] next_state,
                    output reg [2:0] current_state
);

    always @(posedge clk) begin
        if(reset) current_state <= `IF1;
        else current_state <= next_state;
    end

endmodule
