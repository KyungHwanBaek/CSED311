// Submit this file with other files you created.
// Do not touch port declarations of the module 'cpu'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,                     // positive reset signal
           input clk,                       // clock signal
           output is_halted,                // Whehther to finish simulation
           output [31:0] print_reg [0:31]); // TO PRINT REGISTER VALUES IN TESTBENCH (YOU SHOULD NOT USE THIS)
  /***** Wire declarations *****/
  wire [31:0] next_pc, current_pc;
  wire [31:0] rd_din, rs1_dout, rs2_dout;
  wire [31:0] part_of_inst;
  wire [31:0] imm_gen_out;

  wire [4:0] rs1 = part_of_inst[19:15];
  wire [4:0] rs2 = part_of_inst[24:20];
  wire [4:0] rd = part_of_inst[11:7];
  
  wire [6:0] cu_poi = part_of_inst[6:0];    //control unit의 input

  wire is_jal, is_jalr, branch, mem_read, mem_to_reg, mem_write, alu_src, write_enable, pc_to_reg, is_ecall, pc_src_1;

  // ALU 제어 유닛 출력
  wire [3:0] alu_op;   		// ALU 연산 종류 (예, 4비트)
  
  // ALU 관련 신호
  wire [31:0] alu_in_2;  	// ALU 입력 피연산자
  wire [31:0] alu_result;	// ALU 연산 결과
  wire alu_bcond;			// ALU의 분기 조건 결과
  
  // data_memory 신호
  wire [31:0] dout;
  
  // MUX 관련 신호 (예: 레지스터 파일 쓰기 데이터 선택)
  wire [31:0] mem_to_mux, pc_plus_4, pc_plus_imm, pc_jal;

  //and 결과 신호
  wire and_out;

  /***** Register declarations *****/
  

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  pc pc(
    .reset(reset),				// input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),					// input
    .next_pc(next_pc),			// input
    .current_pc(current_pc)		// output
  );
  
  // ---------- Instruction Memory ----------
  instruction_memory imem(
    .reset(reset),  			// input
    .clk(clk),     				// input
    .addr(current_pc),    		// input
    .dout(part_of_inst)     	// output
  );


  // ---------- Register File ----------
  register_file reg_file (
    .reset (reset),        			// input
    .clk (clk),          			// input
    .rs1 (rs1), 					// input
    .rs2 (rs2), 					// input
    .rd (rd), 						// input
    .rd_din (rd_din),       		// input
    .write_enable (write_enable), 	// input
    .is_ecall(is_ecall),
    .rs1_dout (rs1_dout),     		// output
    .rs2_dout (rs2_dout),     		// output
    .print_reg (print_reg),  		//DO NOT TOUCH THIS
    .is_halted (is_halted)
  );
  // testbench에서는 최종 register value를 출력해봄으로써 본 구현을 판단하고 print_reg()는 이를 위해 존재한다.

  // ---------- Control Unit ----------
  control_unit ctrl_unit (
    .part_of_inst(cu_poi),  	// input
    .is_jal(is_jal),        	// output
    .is_jalr(is_jalr),     		// output
    .branch(branch),        	// output
    .mem_read(mem_read),      	// output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     	// output
    .alu_src(alu_src),       	// output
    .write_enable(write_enable),// output
    .pc_to_reg(pc_to_reg),     	// output
    .is_ecall(is_ecall)       	// output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  immediate_generator imm_gen(
    .part_of_inst(part_of_inst),// input
    .imm_gen_out(imm_gen_out)   // output
  );

  // ---------- ALU Control Unit ----------
  alu_control_unit alu_ctrl_unit (
    .part_of_inst(part_of_inst),// input
    .alu_op(alu_op)        		// output
  );

  // ---------- ALU ----------
  alu alu (
    .alu_op(alu_op),      		// input
    .alu_in_1(rs1_dout),    	// input  
    .alu_in_2(alu_in_2),    	// input
    .alu_result(alu_result),	// output
    .alu_bcond(alu_bcond)    	// output
  );

  // ---------- Data Memory ---------- 
  data_memory dmem(
    .reset (reset),      		// input
    .clk (clk),        			// input
    .addr (alu_result),       	// input
    .din (rs2_dout),        	// input
    .mem_read (mem_read),   	// input
    .mem_write (mem_write),  	// input
    .dout (dout)				// output
  );

  // ---------- MUX ----------- 
  mux PCtoReg_mux(
    .mux_in_1(mem_to_mux),
    .mux_in_2(pc_plus_4),
    .select(pc_to_reg),
    .mux_out(rd_din)
  );
  mux ALUSrc_mux(
    .mux_in_1(rs2_dout),
    .mux_in_2(imm_gen_out),
    .select(alu_src),
    .mux_out(alu_in_2)
  );
  mux PCSrc1_mux(
    .mux_in_1(pc_plus_4),
    .mux_in_2(pc_plus_imm),
    .select(pc_src_1),
    .mux_out(pc_jal)
  );
  mux PCSrc2_mux(
    .mux_in_1(pc_jal),
    .mux_in_2(alu_result),
    .select(is_jalr),
    .mux_out(next_pc)
  );
  mux MEmtoReg_mux(
    .mux_in_1(alu_result),
    .mux_in_2(dout),
    .select(mem_to_reg),
    .mux_out(mem_to_mux)
  );

  // --------- gate ----------
  gate_and gate_and(
    .in_1(branch),
    .in_2(alu_bcond),
    .out(and_out)
  );
  gate_or gate_or(
    .in_1(is_jal),
    .in_2(and_out),
    .out(pc_src_1)
  );

  alu add_4(
    .alu_op(4'b0000),
    .alu_in_1(current_pc),
    .alu_in_2(4),
    .alu_result(pc_plus_4),
    .alu_bcond(alu_bcond)
  );

  alu add_(
    .alu_op(4'b0000),
    .alu_in_1(current_pc),
    .alu_in_2(imm_gen_out),
    .alu_result(pc_plus_imm),
    .alu_bcond(alu_bcond)
  );


endmodule
