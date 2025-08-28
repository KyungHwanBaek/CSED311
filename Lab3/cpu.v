// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required
`include "state5.v"

module cpu(input reset,       // positive reset signal
           input clk,         // clock signal
           output reg is_halted,
           output [31:0]print_reg[0:31]
           ); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [31:0] next_pc, current_pc;
  wire pc_write_cond, pc_write, iord, mem_read, mem_write, mem_to_reg, ir_write, pc_source, alu_src_a, reg_write, is_ecall;
  wire [1:0] alu_op, alu_src_b;
  wire [31:0] rd_din, rs1_dout, rs2_dout;
  wire [4:0] rs1,rs2,rd;
  wire [31:0] addr, dout;
  wire [31:0] imm_gen_out;
  wire [3:0] alu_op_out;			// ALU 연산 종류 (예, 4비트)
  wire [31:0] alu_in_1, alu_in_2;	// ALU 입력 피연산자
  wire [31:0] alu_result;			// ALU 연산 결과
  wire alu_bcond;					// ALU의 분기 조건 결과
  wire and_out;
  wire pc_rewrite;
  wire [2:0] current_state;
  wire [2:0] next_state;
  wire pc_sig;
  reg [31:0] din;
  reg [31:0] part_of_inst;
  reg [6:0] part_of_inst_6;
  
  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.
  assign rs1 = part_of_inst[19:15];
  assign rs2 = part_of_inst[24:20];
  assign rd = part_of_inst[11:7];
  assign part_of_inst_6 = part_of_inst[6:0];
  assign pc_sig = (pc_write_cond && !alu_bcond) ? 1 : 0;

  always @(posedge clk) begin
    if(reset)begin
      A<=0;
      B<=0;
      IR <= 0;
      MDR <= 0;
      ALUOut <=0;
    end
	
	if(!iord && !ir_write) part_of_inst <= IR;
    else if(!iord && ir_write) IR <= dout;
	else MDR <= dout;
    A <= rs1_dout;
    B <= rs2_dout;
	din <= B;
    ALUOut <= alu_result;
  end
  
  wire is_branch;
  assign is_branch = (part_of_inst_6 == 7'b1100011) && (current_state == `EX2);
  wire [31:0] pc_for_alu;
  assign pc_for_alu = is_branch ? (current_pc - 4) : current_pc;

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  pc pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .pc_rewrite(pc_rewrite), //input
	.pc_sig(pc_sig),
    .current_pc(current_pc)   // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(rs1),          // input
    .rs2(rs2),          // input
    .rd(rd),           // input
    .rd_din(rd_din),       // input
    .write_enable(reg_write),    // input
    .is_ecall(is_ecall),
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout),      // output
    .print_reg(print_reg),     // output (TO PRINT REGISTER VALUES IN TESTBENCH)
    .is_halted(is_halted)
  );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(addr),         // input
    .din(din),          // input
    .mem_read(mem_read),     // input
    .mem_write(mem_write),    // input
    .dout(dout)          // output
  );

  // ---------- Control Unit ----------
  control_unit ctrl_unit(
    .clk(clk),
    .reset(reset),
    .part_of_inst(part_of_inst_6),  // input
    .current_state(current_state),
	.pc_write_cond(pc_write_cond),
	.pc_write(pc_write),
	.iord(iord),
    .mem_read(mem_read),      // output
	.mem_write(mem_write),
    .mem_to_reg(mem_to_reg),    // output
	.ir_write(ir_write),
	.pc_source(pc_source),
	.alu_op(alu_op),
	.alu_src_b(alu_src_b),
	.alu_src_a(alu_src_a),
    .reg_write(reg_write),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  immediate_generator imm_gen(
    .part_of_inst(part_of_inst),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  alu_control_unit alu_ctrl_unit(
    .part_of_inst(part_of_inst),  // input
    .alu_op(alu_op),
    .alu_op_out(alu_op_out)         // output
  );

  // ---------- ALU ----------
  alu alu(
    .alu_op_out(alu_op_out),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );
  

  mux1 IorD_mux(
	.mux_in_1(current_pc),
	.mux_in_2(ALUOut),
	.select(iord),
	.mux_out(addr)
  );
  
  mux1 MemtoReg_mux(
	.mux_in_1(ALUOut),
	.mux_in_2(MDR),
	.select(mem_to_reg),
	.mux_out(rd_din)
  );
  
  mux1 ALUSrcA_mux(
    .mux_in_1(pc_for_alu),
	.mux_in_2(A),
	.select(alu_src_a),
	.mux_out(alu_in_1)
  );

  mux1 mux_pc(
    .mux_in_1(alu_result),
	.mux_in_2(ALUOut),
	.select(pc_source),
	.mux_out(next_pc)
  );
 
  
  mux2 ALUSrcB_mux(
    .mux_in_1(B),
	.mux_in_2(4),
	.mux_in_3(imm_gen_out),
	.mux_in_4(0),
	.select(alu_src_b),
	.mux_out(alu_in_2)
  );
  
  gate_and gate_and(
    .in_1(alu_bcond),
    .in_2(pc_write_cond),
    .out(and_out)
  );

  gate_or gate_or(
    .in_1(and_out),
    .in_2(pc_write),
    .out(pc_rewrite)
  );

  micro_control micro_cont(
    .reset(reset),
    .clk(clk),
    .opcode(part_of_inst_6),
    .alu_bcond(alu_bcond),
    .current_state(current_state),
    .next_state(next_state)
  );

  change_state change_state(
    .reset(reset),
    .clk(clk),
    .next_state(next_state),
    .current_state(current_state)
  );
endmodule
