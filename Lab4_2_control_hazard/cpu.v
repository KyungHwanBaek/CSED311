`include "opcodes.v"
// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,       // positive reset signal
           input clk,         // clock signal
           output reg is_halted, // Whehther to finish simulation
           output [31:0]print_reg[0:31]); // Whehther to finish simulation
  /***** Wire declarations *****/
  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  // 추가된 것
  reg [31:0] IF_ID_pc;
  reg [31:0] IF_ID_next_pc;
  reg IF_ID_flush;
  reg [4:0]  IF_ID_pht_index; // next_pc를 결정할 때 참조할 PHT의 index를 저장해놓는다.
  // 추가된 것.
  
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [1:0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_is_ecall;
  // 추가된 것.
  reg ID_EX_is_branch, ID_EX_is_jal, ID_EX_is_jalr;
  reg [31:0] ID_EX_pc, ID_EX_next_pc;
  reg ID_EX_pc_to_reg, ID_EX_is_controlflow;
  reg [4:0]  ID_EX_pht_index;
  // 추가된 것.
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [4:0] ID_EX_rd;
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;
  reg [31:0] ID_EX_inst;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_ALU_ctrl_unit_input;

  /***** EX/MEM pipeline registers *****/
  
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_is_ecall;
  // 추가된 것.
  reg EX_MEM_pc_to_reg;
  reg [31:0] EX_MEM_pc;
  // 추가된 것.

  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  // 추가된 것.
  reg MEM_WB_pc_to_reg;
  reg [31:0] MEM_WB_pc;
  // 추가된 것.
  
  // From others
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;
  wire is_real_halted;
  wire is_ecall;
  wire [31:0] mux_forward_out;
  wire hazard_out;
  assign is_real_halted = ((mux_forward_out == 10) && is_ecall && !hazard_out) ? 1 : 0;
  wire [31:0] next_pc;
  wire [31:0] current_pc;
  wire [31:0] inst_dout;
  wire [31:0] mux1_is_ecall;
  wire [4:0] mux1_is_ecall_4_0;
  assign mux1_is_ecall_4_0 = mux1_is_ecall[4:0];
  wire [31:0] rd_din;
  wire [4:0] IF_ID_inst_24_20;
  wire [4:0] IF_ID_inst_19_15;
  wire [6:0] IF_ID_inst_6_0;
  assign IF_ID_inst_24_20 = IF_ID_inst[24:20];
  assign IF_ID_inst_19_15 = IF_ID_inst[19:15];
  assign IF_ID_inst_6_0 = IF_ID_inst[6:0];
  reg [4:0] MEM_WB_rd;
  wire [31:0] rs1_dout, rs2_dout;
  wire mem_read;
  wire mem_to_reg;
  wire mem_write;
  wire alu_src;
  wire write_enable;
  wire [1:0] alu_op;
  wire [31:0] imm_gen_out;
  wire [3:0] alu_op_out;
  wire [31:0] alu_in_1; // wire [31:0] forward_value_1;
  wire [31:0] alu_in_2;
  wire [31:0] alu_result;
  wire [31:0] Read_data;
  wire alu_bcond;
  wire bcond_nothing;
  wire pc_write;
  wire IF_ID_write;
  wire [1:0] forward_rs1;
  wire [1:0] forward_rs2;
  wire [1:0] ecall_signal;
  wire [31:0] forward_value_2;
 
  // 추가된 것.
  wire real_taken;
  wire prediction_correct;
  wire [31:0] branch_target, increment_pc, first_pc_mux_out;
  wire pcSrc1;
  wire [31:0] real_pc_target;
  wire [31:0] btb_next_pc;
  wire [4:0]  accessed_pht_index;
  wire is_jalr, is_jal, pc_to_reg, branch;
  // 추가된 것.

  assign real_taken = (alu_bcond & ID_EX_is_branch) || ID_EX_is_jal || ID_EX_is_jalr; // taken되었는지 여부
  assign prediction_correct = !ID_EX_is_controlflow || (real_pc_target == ID_EX_next_pc);


  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .pc_write(pc_write),
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(inst_dout)     // output
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
		IF_ID_inst <= 0;
		// 추가됨.
		IF_ID_pc <= 0;
		IF_ID_next_pc <= 0;
		IF_ID_flush <= 0;
		IF_ID_pht_index <= 0;
		// 추가됨.
	end
    else begin 
		if(IF_ID_write) begin
			IF_ID_inst <= inst_dout;
			// 추가됨.
			IF_ID_pc <= current_pc;
			IF_ID_next_pc <= next_pc;     //바로 다음으로 갈 주소
			IF_ID_pht_index <= accessed_pht_index;    //이건 나중에 Gshare모듈에서, pht 수정하기 위한 거임
			IF_ID_flush <= !prediction_correct;     //예측이 틀린걸 알게 된 순간 flush결정해야함. 위에서 next_pc를 real_pc_target으로 변경함으로써
			// 추가됨.                                //잘못실행한 거 bubble처리되고 다시 real_pc_target부터해서 동작을 이어나감.
		end
	end
  end

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (mux1_is_ecall_4_0),          // input
    .rs2 (IF_ID_inst_24_20),          // input
    .rd (MEM_WB_rd),           // input
    .rd_din (rd_din),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout),      // output
    .print_reg(print_reg)
  );


  // ---------- Control Unit ----------
  control_unit ctrl_unit (
    .part_of_inst(IF_ID_inst_6_0),  // input
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(write_enable),  // output
    .alu_op(alu_op),        // output
    .is_ecall(is_ecall),       // output (ecall inst)
	// 추가됨.
	  .is_jalr(is_jalr),
    .is_jal(is_jal),
	  .pc_to_reg(pc_to_reg),
    .branch(branch)
	// 추가됨.
  );

  // ---------- Immediate Generator ----------
  immediate_generator imm_gen(
    .part_of_inst(IF_ID_inst),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      ID_EX_alu_op <= 0;        
      ID_EX_alu_src <= 0;   
      ID_EX_mem_write <= 0;   
      ID_EX_mem_read <= 0;     
      ID_EX_mem_to_reg <= 0;     
      ID_EX_reg_write <= 0;     
      ID_EX_rs1_data <= 0;
      ID_EX_rs2_data <= 0;
      ID_EX_imm <= 0;
      ID_EX_ALU_ctrl_unit_input <= 0;
      ID_EX_rd <= 0;
      ID_EX_rs1 <= 0;
      ID_EX_rs2 <= 0;      
      ID_EX_is_ecall <= 0;
      ID_EX_inst <= 0;
	  // 추가됨.
      ID_EX_is_branch <= 0;
      ID_EX_is_jal <= 0;
      ID_EX_is_jalr <= 0;
      ID_EX_pc <= 0;
      ID_EX_next_pc <= 0;
      ID_EX_pht_index <= 0;
      ID_EX_pc_to_reg <= 0;
      ID_EX_is_controlflow <= 0;
	  // 추가됨.
    end
    else begin
      ID_EX_inst <= IF_ID_inst;
      ID_EX_rs1_data <= mux_forward_out;
      ID_EX_rs2_data <= rs2_dout;
      ID_EX_imm <= imm_gen_out;
      ID_EX_ALU_ctrl_unit_input <= IF_ID_inst;
      ID_EX_rd <= IF_ID_inst[11:7];
      ID_EX_rs1 <= IF_ID_inst[19:15];
      ID_EX_rs2 <= IF_ID_inst[24:20];
	  // 추가됨.
      ID_EX_pc <= IF_ID_pc;
      ID_EX_next_pc <= IF_ID_next_pc;     //이게 왜 필요하냐? => 다음으로 갈 주소를 미리 가져옴. 왜? precdict_correct미리 체크해서, 
      ID_EX_pht_index <= IF_ID_pht_index; //flush할지, 안전하게 계속하면 될지 체크하기 위해서
	  
      if(hazard_out || IF_ID_flush || !prediction_correct) begin
        ID_EX_is_branch <= 0;
        ID_EX_is_jal <= 0;
        ID_EX_is_jalr <= 0;
        ID_EX_pc_to_reg <= 0;
        ID_EX_is_controlflow <= 0;
        ID_EX_alu_op <= 0;
        ID_EX_alu_src <= 0;
        ID_EX_mem_write <= 0;
        ID_EX_mem_read <= 0;
        ID_EX_mem_to_reg <= 0;
        ID_EX_reg_write <= 0;
        ID_EX_is_ecall <= 0;
      end
      else begin
        ID_EX_is_branch <= branch;
        ID_EX_is_jal <= is_jal;
        ID_EX_is_jalr <= is_jalr;
        ID_EX_pc_to_reg <= pc_to_reg;
        ID_EX_is_controlflow <= (is_jal || is_jalr || branch);
        ID_EX_alu_op <= alu_op;
        ID_EX_alu_src <= alu_src;
        ID_EX_mem_to_reg <= mem_to_reg;
        ID_EX_reg_write <= write_enable;
        ID_EX_mem_write <= mem_write;
        ID_EX_mem_read <= mem_read;
        ID_EX_is_ecall <= is_real_halted;		
      end
	  // 추가됨.  
    end
  end

  // ---------- ALU Control Unit ----------
  alu_control_unit alu_ctrl_unit (
    .part_of_inst(ID_EX_inst),  // input
    .alu_op(ID_EX_alu_op),       // output
	.alu_op_out(alu_op_out)
  );

  // ---------- ALU ----------
  alu alu (
    .alu_op_out(alu_op_out),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );
  
  alu adder_branch (
    .alu_op_out(`ALU_ADD),
    .alu_in_1(ID_EX_pc),
    .alu_in_2(ID_EX_imm),
    .alu_result(branch_target),
    .alu_bcond(bcond_nothing)
  );
  
  alu adder_4 (
    .alu_op_out(`ALU_ADD),      // input
    .alu_in_1(ID_EX_pc),    // input  
    .alu_in_2(4),    // input
    .alu_result(increment_pc),  // output
    .alu_bcond(bcond_nothing)     // output
  );
  
  //여기서 여러가지 mux가 등장하여 next_pc를 결정함. mux 모듈을 생성하기 보다 이렇게 보는 게 편해서 이렇게 함
  //먼저 그냥 pc+4와 branch/jal 결과 중 뭐 선택할지 => first_pc_mux_out
  //다음으로 jalr이냐 아니냐에 따라서 real_pc_target이 결정됨.
  //마지막으로, next_pc를 결정하게 되는데 이는 predict가 맞았냐에 따라 다름
  //1. 예측이 맞았으면 그냥 다음 btb_next_pc에 따라 계속해서 동작하면됨
  //2. 예측이 틀렸으면 real_pc_target,즉 이전에 틀린 부분으로 roll back함. flush필요.
  assign pcSrc1 = (ID_EX_is_branch && alu_bcond) || ID_EX_is_jal; // Branch이면서 taken이거나 JAL일 때 pcSrc1가 1이 된다.   이게 branch and 모듈을 ID_EX로 당긴 부분. 즉 bubble 감소
  assign first_pc_mux_out = pcSrc1 ? branch_target : increment_pc; // JALR일 때 ID_EX_is_jalr이 1이 된다.
  assign real_pc_target = ID_EX_is_jalr ? alu_result : first_pc_mux_out;
  assign next_pc = prediction_correct ? btb_next_pc : real_pc_target;
  
  wire [31:0] mem_to_reg_mux_out;

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write <= 0;     
      EX_MEM_mem_read <= 0;         
      EX_MEM_mem_to_reg <= 0;    
      EX_MEM_alu_out <= 0;
      EX_MEM_dmem_data <= 0;
      EX_MEM_rd <= 0;
      EX_MEM_is_ecall <= 0;
	  // 추가됨.
      EX_MEM_pc_to_reg <= 0;
      EX_MEM_pc <= 0;
	  // 추가됨.
    end
    else begin
      EX_MEM_mem_write <= ID_EX_mem_write;     
      EX_MEM_mem_read <= ID_EX_mem_read;      
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;   
      EX_MEM_reg_write <= ID_EX_reg_write;     
      EX_MEM_alu_out <= alu_result;
      EX_MEM_dmem_data <= forward_value_2;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_is_ecall <= ID_EX_is_ecall;
	  // 추가됨.
	    EX_MEM_pc_to_reg <= ID_EX_pc_to_reg;
      EX_MEM_pc <= ID_EX_pc;
	  // 추가됨.
    end
  end

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .dout (Read_data)        // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg <= 0;    
      MEM_WB_reg_write <= 0;     
      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
      MEM_WB_rd <= 0;
      is_halted <= 0;
	  // 추가됨.
      MEM_WB_pc_to_reg <= 0;
      MEM_WB_pc <= 0;
	  // 추가됨.
    end
    else begin
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;   
      MEM_WB_reg_write <= EX_MEM_reg_write;   
      MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out;
      MEM_WB_mem_to_reg_src_2 <= Read_data;
      MEM_WB_rd <= EX_MEM_rd;
      is_halted <= EX_MEM_is_ecall;
	  // 추가됨.
      MEM_WB_pc_to_reg <= EX_MEM_pc_to_reg;
      MEM_WB_pc <= EX_MEM_pc;
	  // 추가됨.
    end
  end

  Hazard_Detection Hazard_Detection ( 
    .id_rs1 (IF_ID_inst_19_15),      // input 
    .id_rs2 (IF_ID_inst_24_20),      // input 
    .ex_rd (ID_EX_rd),       // input 
    .mem_rd (EX_MEM_rd),      // input 
    .ex_mem_read (ID_EX_mem_read), // input 
    .ex_reg_write (ID_EX_reg_write),// input 
    .mem_mem_read (EX_MEM_mem_read),// input 
    .id_opcode (IF_ID_inst_6_0),   // input 
    .pc_write (pc_write),    // output
    .if_id_write (IF_ID_write), // output
    .is_hazard(hazard_out)     // output
  );
  
  forward forward ( 
    .ex_rs1 (ID_EX_rs1),      // input
    .ex_rs2 (ID_EX_rs2),      // input
    .mem_rd (EX_MEM_rd),      // input
    .wb_rd (MEM_WB_rd),       // input
    .mem_reg_write (EX_MEM_reg_write), // input
    .wb_reg_write (MEM_WB_reg_write),  // input
    .forward_rs1 (forward_rs1), // output
    .forward_rs2 (forward_rs2)   // output
  );

  forward_ecall forward_ecall ( 
    .opcode (IF_ID_inst_6_0),      // input
    .mem_rd (EX_MEM_rd),      // input
    .wb_rd (MEM_WB_rd),       // input
    .mem_reg_write (EX_MEM_reg_write), // input
    .wb_reg_write (MEM_WB_reg_write),  // input
    .signal(ecall_signal)        // output
  );

  mux1 mux1_mem_to_reg ( 
    .mux_in_1 (MEM_WB_mem_to_reg_src_1),    // input
    .mux_in_2 (MEM_WB_mem_to_reg_src_2),    // input
    .select (MEM_WB_mem_to_reg),      // input
    .mux_out(mem_to_reg_mux_out)       // output
  );
  
  assign rd_din = MEM_WB_pc_to_reg ? (MEM_WB_pc + 4) : mem_to_reg_mux_out;      //jal, jalr이 들어오면 pc+4저장해야하기에
  
  mux1 mux1_alu_in_2 ( 
    .mux_in_1 (forward_value_2),    // input
    .mux_in_2 (ID_EX_imm),    // input
    .select (ID_EX_alu_src),      // input
    .mux_out(alu_in_2)       // output
  );
  
  mux1 mux1_ecall ( 
    .mux_in_1 ({27'b0, IF_ID_inst_19_15}),    // input
    .mux_in_2 (17),    // input
    .select (is_ecall),      // input
    .mux_out(mux1_is_ecall)       // output
  );

  mux2 mux2_ecall ( 
    .mux_in_1 (rs1_dout),    // input
    .mux_in_2 (EX_MEM_alu_out),    // input
    .mux_in_3 (rd_din),    // input
    .mux_in_4 (0),    // input
    .select (ecall_signal),      // input
    .mux_out(mux_forward_out)       // output
  );

  mux2 mux2_alu_in_1 ( 
    .mux_in_1 (ID_EX_rs1_data),    // input
    .mux_in_2 (EX_MEM_alu_out),    // input
    .mux_in_3 (rd_din),    // input
    .mux_in_4 (0),    // input
    .select (forward_rs1),      // input
    .mux_out(alu_in_1)       // output
  );
  
  mux2 mux2_alu_in_2 ( 
    .mux_in_1 (ID_EX_rs2_data),    // input
    .mux_in_2 (EX_MEM_alu_out),    // input
    .mux_in_3 (rd_din),    // input
    .mux_in_4 (0),    // input
    .select (forward_rs2),      // input
    .mux_out(forward_value_2)       // output
  );

// 추가됨.
  gshare gshare(
    .reset(reset),
    .clk(clk),
    .is_branch(ID_EX_is_branch),
    .is_jal(ID_EX_is_jal),
    .is_jalr(ID_EX_is_jalr),
    .pht_update_index(ID_EX_pht_index),
    .current_pc(current_pc),
    .ID_EX_pc(ID_EX_pc),
    .actual_branch_target(real_pc_target),
    .real_taken(real_taken),
    .prediction_correct(prediction_correct),
    .pht_index(accessed_pht_index),
    .next_pc(btb_next_pc)
  );
// 추가됨.


endmodule
