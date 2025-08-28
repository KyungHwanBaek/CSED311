`include "CLOG2.v"
`include "cache_state.v"

module Cache #(parameter LINE_SIZE = 16, // block size
               parameter NUM_SETS = 8, // 8개의 set
               parameter NUM_WAYS = 2) (
    input reset,
    input clk,

    input is_input_valid, 
    input [31:0] addr, // Data memory의 Address
    input mem_read,
    input mem_write,
    input [31:0] din, // Write data

    output is_ready,
    output reg is_output_valid,// Data memory의 valid bit
    output reg [31:0] dout,   //출력 데이터
    output reg is_hit         //hit이 되었는지 여부
    );

  // Wire declarations
  wire [2:0] idx; 
  wire [1:0] block_offset; 
  wire [24:0] tag; 
  wire block_0_valid;
  wire block_1_valid;

  // Register declarations
  reg [LINE_SIZE*8-1:0] data_bank [NUM_SETS-1:0][NUM_WAYS-1:0]; //데이터뱅크의 크기
  reg valid_bank [NUM_SETS-1:0][NUM_WAYS-1:0];        
  reg dirty_bank [NUM_SETS-1:0][NUM_WAYS-1:0];
  reg way;
  reg cache_hit;
  reg allocate_block_idx;     //어느 블럭 우리의 경우 2way에 할당하는지
  reg LRU [NUM_SETS-1:0];           //evict할 때의 rule, 오래전에 쓰인 거 체크
  reg [24:0] tag_bank [NUM_SETS-1:0][NUM_WAYS-1:0];   //tag 뱅크
  reg [LINE_SIZE*8-1:0] read_data;                //블럭크기로
  reg [LINE_SIZE*8-1:0] write_data;               //블럭크기로
  reg [2:0] current_state;    
  reg set_status;
  reg empty_block_idx;            //비어있는 블럭 있는지.

  // ****** Data Memory ******
  reg mem_input_valid;
  reg [31:0] mem_addr;
  reg mem_r;
  reg mem_w;
  reg [LINE_SIZE*8-1:0] mem_din;
  wire mem_output_valid;
  wire [LINE_SIZE*8-1:0] data_out;
  wire is_data_mem_ready;

  // Data Memory address shift value
  reg [3:0] clog2;
  assign clog2 = `CLOG2(LINE_SIZE);

  assign block_0_valid = valid_bank[idx][0] == 1'b1 ? 1'b1 : 1'b0;
  assign block_1_valid = valid_bank[idx][1] == 1'b1 ? 1'b1 : 1'b0;
  assign is_ready = current_state == `IDLE ? 1'b1 : 1'b0;
  assign is_hit = (cache_hit == `CACHE_HIT) ? 1'b1 : 1'b0;
  assign block_offset = addr[3:2];    //g:0~1bit
  assign idx = addr[6:4];
  assign tag = addr[31:7];

  assign is_output_valid = ((current_state == `COMPARE_TAG && cache_hit == `CACHE_HIT) || current_state == `IDLE);

  integer i;
  always @(posedge clk) begin
    if (reset) begin // Initialization
      for(i = 0; i < NUM_SETS; i = i + 1) begin
        tag_bank[i][0] <= 0;
        tag_bank[i][1] <= 0;
        data_bank[i][0] <= 0;
        data_bank[i][1] <= 0;
        valid_bank[i][0] <= 0;
        valid_bank[i][1] <= 0;
        dirty_bank[i][0] <= 0;
        dirty_bank[i][1] <= 0;
        LRU[i] <= 0;
      end
      current_state <= `IDLE; 
    end
    else begin
      if (current_state == `IDLE) begin
        if (is_input_valid) // EX 단계에서 current_state가 COMPARE_TAG로 간다
          current_state <= `COMPARE_TAG;  
      end
      else if (current_state == `COMPARE_TAG) begin
        if (cache_hit == `CACHE_HIT) begin
          LRU[idx] <= way;
          if (mem_write) begin
            data_bank[idx][way]  <= write_data;
            dirty_bank[idx][way] <= 1;
          end
          current_state <= `IDLE;
        end
        else begin
          if (set_status == `REMAIN_BLOCK) begin
            allocate_block_idx <= empty_block_idx;
            current_state <= `ALLOCATE;
          end
          else begin
            allocate_block_idx <= !LRU[idx];
            if (dirty_bank[idx][!LRU[idx]] == 1)
              current_state <= `WRITE_BACK;
            else
              current_state <= `ALLOCATE;
          end
        end
      end
      else if (current_state == `ALLOCATE_DELAY) begin
        if (mem_output_valid) begin
          data_bank[idx][allocate_block_idx] <= data_out;
          tag_bank[idx][allocate_block_idx] <= tag;
          valid_bank[idx][allocate_block_idx] <= 1;
          dirty_bank[idx][allocate_block_idx] <= 0;
          current_state <= `COMPARE_TAG;
        end
      end
      else if (current_state == `WRITE_BACK_DELAY) begin
        if (is_data_mem_ready) current_state <= `ALLOCATE;
      end 
      else if (current_state == `WRITE_BACK) begin
        if (is_data_mem_ready) current_state <= `WRITE_BACK_DELAY;
      end
      else if (current_state == `ALLOCATE) begin
        if (is_data_mem_ready) current_state <= `ALLOCATE_DELAY;
      end
    end
  end
  // Cache Hit check
  always @(*) begin
    if(tag_bank[idx][0] == tag && valid_bank[idx][0] == 1'b1) begin // 블럭0에서 히트
      way = `WAY_0;           //첫번째 블럭 사용 표시
      cache_hit = `CACHE_HIT; 
    end
    else if (tag_bank[idx][1] == tag && valid_bank[idx][1] == 1'b1) begin // 블럭1에서 히트
      way = `WAY_1;           //두번째 블럭 사용 표시
      cache_hit = `CACHE_HIT;
    end
    else begin // Cache miss
      way = 1'b0; // for preventing Latch error
      cache_hit = `CACHE_MISS;
    end
  end

  always @(*) begin
    read_data = data_bank[idx][way];
    write_data = read_data;        
    case (block_offset)
      2'b00: begin
        write_data[31:0] = din;
        dout = read_data[31 : 0];
      end
      2'b01: begin
        write_data[63:32] = din;
        dout = read_data[63 : 32];
      end
      2'b10: begin
        write_data[95:64] = din;
        dout = read_data[95 : 64];
      end
      2'b11: begin
        write_data[127:96] = din;
        dout = read_data[127: 96];
      end
    endcase
  end

  always @(*) begin
    mem_input_valid = 0;
    mem_r = 0;
    mem_din = 0;
    mem_addr = 0;
    mem_w = 0;

    //IDLE, COMPARE_TAG, WRITE_BACK_DELAY, ALLOCATE_DELAY의 경우 신호가 0으므로 생략 가능
    case(current_state) 
      `WRITE_BACK: begin
        mem_r = 0;
        mem_w = 1; 
        mem_addr = {tag_bank[idx][allocate_block_idx], idx, block_offset, 2'b00};
        mem_input_valid = 1;
        mem_din = data_bank[idx][allocate_block_idx];
      end
      `ALLOCATE: begin  
        mem_r = 1;
        mem_w = 0;
        mem_input_valid = 1;
        mem_din = 0;
        mem_addr = addr;
      end
      default: begin
      end
    endcase
  end


  always @(*) begin
    if (block_0_valid && block_1_valid) begin // 꽉 차있음
      set_status = `FULL_BLOCK;
      empty_block_idx = 1'b0; 
    end
    else if (!block_0_valid && block_1_valid) begin // 블럭 0 사용 가능
      set_status = `REMAIN_BLOCK;
      empty_block_idx = 1'b0;
    end
    else if (block_0_valid && !block_1_valid) begin // 블럭 1 사용 가능
      set_status = `REMAIN_BLOCK;
      empty_block_idx = 1'b1;
    end
    else begin //둘 다 사용 가능한 경우 0번째 먼저 사용하자
      set_status = `REMAIN_BLOCK;
      empty_block_idx = 1'b0;
    end
  end

  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),
    .is_input_valid(mem_input_valid),

    .addr(mem_addr >> clog2),        // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read(mem_r),
    .mem_write(mem_w),
    .din(mem_din),

    // is output from the data memory valid?
    .is_output_valid(mem_output_valid),
    .dout(data_out),

    // is data memory ready to accept request?
    .mem_ready(is_data_mem_ready)
  );

endmodule
