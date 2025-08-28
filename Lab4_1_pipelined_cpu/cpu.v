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
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [1:0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_is_ecall;
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_ALU_ctrl_unit_input;
  reg [4:0] ID_EX_rd;
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;
  reg [31:0] ID_EX_inst;
  /***** EX/MEM pipeline registers *****/
  
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_is_ecall;

  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  // From others
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;
  wire is_real_halted;
  wire is_ecall;
  wire [31:0] mux_forward_out;
  wire hazard_out;
  assign is_real_halted = ((mux_forward_out == 10) && is_ecall && !hazard_out) ? 1 : 0;     //is_ecall일 때 mux_forward_out은, x17의 register값임. 10인지 비교
  wire [31:0] next_pc;                                                                      //!hazard_out인 이유: hazard가 끝났을 때의 x17값인지 확인해야 함. 즉, 1cycle stall시켜서 x17에 최신값이 들어오도록 함.
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
  wire [31:0] alu_in_2; //선언은 해놨지만 안 씀. 왜냐? mux1_alu_in_2변수로 썼기때문.
  wire [31:0] alu_result;
  wire [31:0] Read_data;
  wire bcond;           //이 bcond는 다음 control hazard에서 사용할 예정
  wire bcond_nothing;   //pc+4역할 adder에 사용한 alu를 위한 값으로서 아무 의미 없음
  wire pc_write;
  wire IF_ID_write;
  wire [1:0] forward_rs1;
  wire [1:0] forward_rs2;
  wire [1:0] ecall_signal;
  wire [31:0] forward_value_2;
  
  

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
    if (reset) IF_ID_inst <= 0;
    else begin 
		  if(IF_ID_write) IF_ID_inst <= inst_dout;              //IF_ID_write 일때, inst_memory의 out을 pipeline에 집어넣음
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
    //.pc_to_reg(pc_to_reg),     // output  원래 PC+4와, 점프할 값 중 고르는 mux에 주어야하는 신호이지만, Branch를 고려 안 해도 되기에 주석처리
    .alu_op(alu_op),        // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  immediate_generator imm_gen(
    .part_of_inst(IF_ID_inst),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset) begin                            //처음에 모두 0으로 초기화, 
      ID_EX_alu_op <= 0;                        
      ID_EX_alu_src <= 0;   
      ID_EX_mem_write <= 0;   
      ID_EX_mem_read <= 0;     
      ID_EX_mem_to_reg <= 0;     
      ID_EX_imm <= 0;
      ID_EX_ALU_ctrl_unit_input <= 0;
      ID_EX_rd <= 0;
      ID_EX_rs1 <= 0;
      ID_EX_rs2 <= 0;
      ID_EX_reg_write <= 0;     
      ID_EX_rs1_data <= 0;
      ID_EX_rs2_data <= 0;      
      ID_EX_is_ecall <= 0;
      ID_EX_inst <= 0;
    end
    else begin
      ID_EX_ALU_ctrl_unit_input <= IF_ID_inst;
      ID_EX_inst <= IF_ID_inst;
      ID_EX_rs1_data <= mux_forward_out;
      ID_EX_rs2_data <= rs2_dout;
      ID_EX_rs1 <= IF_ID_inst[19:15];
      ID_EX_rs2 <= IF_ID_inst[24:20];
      ID_EX_rd <= IF_ID_inst[11:7];
      ID_EX_imm <= imm_gen_out;
      ID_EX_is_ecall <= is_real_halted;

      if(hazard_out) begin 
        ID_EX_alu_op <= 0;
        ID_EX_mem_read <= 0;     
        ID_EX_mem_to_reg <= 0;     
        ID_EX_reg_write <= 0;         
        ID_EX_alu_src <= 0;   
        ID_EX_mem_write <= 0;      
      end
      else begin 
        ID_EX_alu_op <= alu_op;        
        ID_EX_alu_src <= alu_src ;   
        ID_EX_mem_write <= mem_write;     
        ID_EX_mem_read <= mem_read;     
        ID_EX_mem_to_reg <= mem_to_reg;     
        ID_EX_reg_write <= write_enable;     
      end
    end
  end

  // ---------- ALU Control Unit ----------
  alu_control_unit alu_ctrl_unit (
    .part_of_inst(ID_EX_inst),  // input
    .alu_op(ID_EX_alu_op),       // output
    .alu_op_out(alu_op_out)     // output
  );

  // ---------- ALU ----------
  alu alu (
    .alu_op_out(alu_op_out),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(bcond)     // output
  );
  
  alu adder (                             //next_pc를 업데이트하기 위한 pc+4  수행. 자원 재사용
    .alu_op_out(`ALU_ADD),      // input
    .alu_in_1(current_pc),    // input  
    .alu_in_2(4),    // input
    .alu_result(next_pc),  // output
    .alu_bcond(bcond_nothing)     // output           Bxx명령어에 대한 처리가 필요없으므로 nothing으로 빈 값을 할당함.
  );

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin    
      EX_MEM_is_ecall <= 0;
      EX_MEM_mem_write <= 0;     
      EX_MEM_mem_read <= 0;      
      EX_MEM_is_branch <= 0;    
      EX_MEM_alu_out <= 0;
      EX_MEM_dmem_data <= 0;
      EX_MEM_rd <= 0; 
      EX_MEM_mem_to_reg <= 0;
    end
    else begin   
      EX_MEM_alu_out <= alu_result;
      EX_MEM_dmem_data <= forward_value_2;     
      EX_MEM_mem_read <= ID_EX_mem_read;      
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_is_ecall <= ID_EX_is_ecall;
      EX_MEM_mem_write <= ID_EX_mem_write;   
      EX_MEM_reg_write <= ID_EX_reg_write;  
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
    end
    else begin
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;   
      MEM_WB_reg_write <= EX_MEM_reg_write;   
      MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out;
      MEM_WB_mem_to_reg_src_2 <= Read_data;
      MEM_WB_rd <= EX_MEM_rd;
      is_halted <= EX_MEM_is_ecall;
    end
  end

  mux1 mux1_mem_to_reg (                  //WB단계에서 어떤 값을 내보낼지. data_mem에서 가져온 값, alu계산 값 중 선택
    .mux_in_1 (MEM_WB_mem_to_reg_src_1),    // input
    .mux_in_2 (MEM_WB_mem_to_reg_src_2),    // input
    .select (MEM_WB_mem_to_reg),      // input
    .mux_out(rd_din)       // output
  );
  
  mux1 mux1_alu_in_2 (                  //alu의 2번째 입력을 무엇으로 줄지. imm 또는 data forwading / rs2 값 중 선택
    .mux_in_1 (forward_value_2),    // input
    .mux_in_2 (ID_EX_imm),    // input
    .select (ID_EX_alu_src),      // input
    .mux_out(alu_in_2)       // output
  );
  
  mux1 mux1_ecall (                   //ecall명령어가 들어왔을 때 17을 내놓아 inst_mem에서 x17을 볼 수 있도록 함.
    .mux_in_1 ({27'b0, IF_ID_inst_19_15}),    // input
    .mux_in_2 (17),    // input
    .select (is_ecall),      // input
    .mux_out(mux1_is_ecall)       // output
  );

  mux2 mux2_ecall (                 //inst_mem에서 가져온 rs1값을 기본으로, 만약 ecall명령어가 왔을 때 x17의 값을 ID/EX로 넘겨줌.
    .mux_in_1 (rs1_dout),    // input
    .mux_in_2 (EX_MEM_alu_out),    // input
    .mux_in_3 (rd_din),    // input
    .mux_in_4 (0),    // input
    .select (ecall_signal),      // input
    .mux_out(mux_forward_out)       // output
  );

  mux2 mux2_alu_in_1 (              //alu의 첫 번째 입력 결정. rs1값, forwarding 값 중 정함.
    .mux_in_1 (ID_EX_rs1_data),    // input
    .mux_in_2 (EX_MEM_alu_out),    // input
    .mux_in_3 (rd_din),    // input
    .mux_in_4 (0),    // input
    .select (forward_rs1),      // input
    .mux_out(alu_in_1)       // output
  );
  
  mux2 mux2_alu_in_2 (            //alu의 두 번째 입력 결정. rs2값, forwarding 값 중 정함.
    .mux_in_1 (ID_EX_rs2_data),    // input
    .mux_in_2 (EX_MEM_alu_out),    // input
    .mux_in_3 (rd_din),    // input
    .mux_in_4 (0),    // input
    .select (forward_rs2),      // input
    .mux_out(forward_value_2)       // output
  );

  forward_ecall forward_ecall (       // ecall 입력이 들어왔을 때 x17의 값이 forwading 필요한지 신호를 생성
    .opcode (IF_ID_inst_6_0),      // input
    .mem_rd (EX_MEM_rd),      // input
    .wb_rd (MEM_WB_rd),       // input
    .mem_reg_write (EX_MEM_reg_write), // input
    .wb_reg_write (MEM_WB_reg_write),  // input
    .signal(ecall_signal)        // output
  );
  
  Hazard_Detection Hazard_Detection (         //id, ex단계의 rs1/2, rd간의 관계를 파악하여 data hazard가 발생하였는지 체크
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
  
  forward forward (             //data forwarding이 가능한 경우 해당 값을 선택하도록 mux에 신호를 줌.
    .ex_rs1 (ID_EX_rs1),      // input
    .ex_rs2 (ID_EX_rs2),      // input
    .mem_rd (EX_MEM_rd),      // input
    .wb_rd (MEM_WB_rd),       // input
    .mem_reg_write (EX_MEM_reg_write), // input
    .wb_reg_write (MEM_WB_reg_write),  // input
    .forward_rs1 (forward_rs1), // output
    .forward_rs2 (forward_rs2)   // output
  );


endmodule
