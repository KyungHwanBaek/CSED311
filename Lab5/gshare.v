module gshare(
    input reset,
    input clk,
    input is_branch,
    input is_jal,
    input is_jalr,
    input [31:0] actual_branch_target,
    input actual_taken,
    input prediction_correct,
    input [4:0] pht_update_index,
    input [31:0] current_pc,
    input [31:0] ID_EX_pc,
    output reg [4:0] pht_index,
    output reg [31:0] next_pc
);

    reg [1:0] pht [0:31]; 
    reg [4:0] bhsr;
    reg [24:0] tag_table [0:31];
    reg [31:0] btb [0:31];
	
    wire [4:0] btb_idx_read = current_pc[6:2];
    wire [24:0] tag_current = current_pc[31:7];
    wire [4:0]  pht_idx_comb = bhsr ^ btb_idx_read;
    wire [31:0] branch_target = btb[btb_idx_read];
	wire [4:0] btb_idx_write = ID_EX_pc[6:2];
    wire tag_match = (tag_current == tag_table[btb_idx_read]);
    wire pht_pred_bit  = pht[pht_idx_comb][1];
    wire gshare_taken  = pht_pred_bit & tag_match;

    always @(*) begin
        pht_index = pht_idx_comb;
    end

    integer i;
    always @(posedge clk) begin
        if (reset) begin
            bhsr <= 5'd0;
            for (i = 0; i < 32; i = i + 1) begin
                pht[i] <= 2'b11;
                tag_table[i] <= 25'h1FFFFFF;
                btb[i] <= 32'b0;
            end
        end
        else begin
            // 1) BTB / TAG 갱신 (branch, jal, jalr 공통)
            if ((is_branch && ~prediction_correct && actual_taken) || ((is_jal | is_jalr) && ~prediction_correct))
				begin
					btb[btb_idx_write] <= actual_branch_target;
					tag_table[btb_idx_write] <= ID_EX_pc[31:7];
				end
            // 2) PHT(2‑bit counter) 갱신
            if ( (is_branch | is_jal | is_jalr) ) begin
                if (actual_taken) begin
                    if (pht[pht_update_index] != 2'b11)
                        pht[pht_update_index] <= pht[pht_update_index] + 2'b01;
                end
                else begin
                    if (pht[pht_update_index] != 2'b00)
                        pht[pht_update_index] <= pht[pht_update_index] - 2'b01;
                end
            end
            // 3) BHSR
            if (is_branch)
                bhsr <= {actual_taken, bhsr[4:1]};
        end

    end

    always @(*) begin
        next_pc = gshare_taken ? branch_target: (current_pc + 4);
    end

endmodule
