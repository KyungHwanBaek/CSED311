`include "opcodes.v"
`include "state5.v"

module control_unit(input clk,
                    input reset,
                    input [6:0] part_of_inst,
                    input reg [2:0] current_state,
                    output reg pc_write_cond,
                    output reg pc_write,
                    output reg iord,
                    output reg mem_read,
                    output reg mem_write,
                    output reg mem_to_reg,
                    output reg ir_write,
                    output reg pc_source,
                    output reg [1:0] alu_op,
                    output reg [1:0] alu_src_b,
                    output reg alu_src_a,
                    output reg reg_write,
                    output reg is_ecall
                    );

always @(*) begin
    pc_write_cond = 0; // 1일 때 Branch, 0일 때 Branch가 아님을 나타낸다.
    pc_write      = 0; // 1이면, Branch가 아니고 PC에 값을 쓸 수 있다.
    iord          = 0; // 0이면 Instruction memory, 1이면 Data memory로 접근한다.
    mem_read      = 0; // 1이면 memory를 읽는다.
    mem_write     = 0; // 1이면 memory에 값을 쓴다.
    mem_to_reg    = 0; // MDR로부터 값을 쓰면(LOAD) 1, ALUOut에서 값을 쓰면(R/I) 0
    ir_write      = 0; // 1이면 IR에 새로 Instruction Fetch하고, 0이면 IR에서 값을 가져온다.
    pc_source     = 0; // 0이면 ALU Result를 바로 대입, 1이면 한 cycle 지연된 ALUOut을 대입
    alu_op        = 2'b00; // 어떤 ALU 연산을 할지 결정 (Bxx, R, I)
    alu_src_b     = 2'b00; // ALU의 두 번째 source로 어떤 것을 선택할지 결정(B, 4, imm)
    alu_src_a     = 0; // ALU의 첫 번째 source로 어떤 것을 선택할지 결정(PC, A)
    reg_write     = 0; // 1이면 register file에 값을 쓴다.
    is_ecall      = 0; // 프로그램을 중단여부를 결정하는 신호
    
    case(current_state)
        `IF1: begin
            iord = 0;
            mem_read = 1;
            ir_write = 1;
        end
		// next_pc로부터 주소를 받아 current_pc를 업데이트가 되었으며, memory에서 해당 pc에서 읽을 데이터가 dout으로 나온 상태. 다음 단계에 IR에 write를 해주기 위해서 ir_write = 1로 세팅해놓는다.
        `IF2: ir_write = 0;
		// current_pc의 주소로부터 Memory Data에서 명령어를 IR에 전달한 상태. 아직, IR에서 아직 part_of_inst를 내보내지 않았으며 다음 클럭 신호 때 part_of_inst를 내보내게 하기 위해서 ir_write = 0으로 세팅해놓는다.
		// IF 단계는 IR에서 IRWrite가 1일 때는 다음 cycle에 IR에 넣는 작업만, 0일 때는 다음 cycle에 IR에서 읽어오는 작업만 할 수 있기 때문에 적어도 2cycle은 필요하다.
		
        `ID: begin
            alu_op = 2'b00; // Branch
			alu_src_a = 0;     // PC
            alu_src_b = 2'b01; // Branch에서 Not Taken시에 jump할 주소 ALUOut에 세팅하기 위한 변수
			// 현재 PC+4의 값이 ALU의 input으로 들어가서 연산결과로 PC+4가 저장되어 있으며, ALUOut에 저장되기 직전이며 EX1에 ALUOut에 저장된다.
			// ALUOut에 미리 넣어놓기 위해서 미리 계산하는 것이다.
			if (part_of_inst == `ECALL) begin
				is_ecall = 1;
				pc_write = 1;
                alu_src_a = 0;
				alu_src_b = 2'b01;
				pc_source = 0;
            end
        end
		// 이 단계에서 드디어 IR에서 값이 나와서 part_ot_inst가 정상적으로 나오게 되는 시기이다. 또한, 다시 말해서 register file에서는 read값은 비동기적으로 업데이트되므로 해당 part_of_inst가 읽고 있는 register값이 A와 B에 들어가기 직전에 있다. 다음 cycle에 바로 A와 B의 값이 세팅될 것이다.
		// 또한, 이 단계에서 part_of_inst가 처음으로 나오게 되는데 이것이 ECALL과 같으면서 rf[17] == 10이라면 프로그램이 중지되어 상관없으나 중지되지 않는 경우를 대비해서 NOP로 작동하도록 다음 PC = PC+4로 업데이트 해준다.
        `EX1:
            if(part_of_inst == `BRANCH) begin
                alu_src_a = 1;
				alu_src_b = 2'b00;
				alu_op    = 2'b01;
                pc_write_cond = 1;
                pc_source = 1;  
            end    
		// 이 단계에서 드디어 part_of_inst를 기반으로 A와 B register의 값이 세팅되는 순간이다. 또한, mux가 잘 세팅되어 있어 A와 B의 값을 받아 Branch 단계라면 ALU에서 Branch 연산을 진행할 수 있다.
		// 또한, Branch 단계라면 pc_write_cond와 pc_source를 1로 세팅하여 alu_bcond가 1이 나오게 되면 next_PC에 ID 단계에서 저장해놓았던 값인 ALUOut에 들어가 있던 PC+4를 즉시 쓰게 할 수 있다. 어떻게 보면 어불성설인 것이 alu_bcond가 1이면 taken이라서 분기된 주소로 jump해야하기 때문이다. 또한, alu_bcond가 0이면 not-taken이라서 PC+4로 jump해야하는데 막상 bcond가 0이 아니라서 jump할 수가 없다. 이 아이러니는 micro_control와 pc_rewrite_sig를 보면 해결이 된다.
		// alu_bcond = 0인 경우: 이 경우에는 pc_rewrite는 0이 되기 때문에 이를 보정하고자 pc_write_cond가 1이면서 alu_bcond가 0이 되면 pc_sig가 1이 되는 구조인 pc_sig라는 신호를 추가하였다. pc_write_cond를 1로, alu_bcond를 0으로 가지고 다음 단계에 IF1으로 jump하게 되면 이 단계에 pc_sig가 1이 되면서 next_pc를 받아오게 되고, 여기서 ALUOut에 있던 PC+4를 쓰게 해놓았기 때문에 바로 PC+4로 업데이트 될 수 있는 것이다.
		// alu_bcond = 1인 경우: alu_bcond가 1이 되어 pc_rewrite 신호가 생겨서 next_pc가 업데이트되더라도 alu_bcond가 1인 경우에는 micro_control에서 보면 알 수 있듯이 IF1으로 가는 것이 아니라 EX2로 가게 되기 때문에 현 next_pc값은 아무 의미가 없게 된다. 따라서 이 구현은 alu_bcond=0인 경우를 고려하여 구현한 것이다.
        `EX2: begin
            case(part_of_inst)
                `ARITHMETIC: begin
                    alu_src_a = 1;
                    alu_op    = 2'b10;
                    alu_src_b = 2'b00;
                end
                `ARITHMETIC_IMM: begin
                    alu_src_a = 1;
                    alu_op    = 2'b11;
                    alu_src_b = 2'b10;
                end
                `LOAD: begin
                    alu_src_a = 1;
                    alu_op    = 2'b00;
                    alu_src_b = 2'b10;
                end
                `STORE: begin
                    alu_src_a = 1;
                    alu_op    = 2'b00;
                    alu_src_b = 2'b10;
                end
                `JAL, `JALR: begin
                    alu_src_a = 0;
                    alu_op    = 2'b00;
                    alu_src_b = 2'b01;
                end
				`BRANCH: begin
					pc_write      = 1;
					pc_source     = 0;
					alu_op        = 2'b00;
					alu_src_a     = 0;
					alu_src_b = 2'b10;					
				end
                default:begin
                end
            endcase
        end
		// Branch 경우: bcond가 1일 때 들어와서 ALU로 다음 PC 주소를 계산하게 되는 구조로서 이를 PC+4로 계산하고 PCSource를 0으로 세팅하여 이를 바로 nextPC값으로 넘겨서 이를 IF 단계에서 current pc로 저장하게 한다.
		// JAL, JALR의 경우: PC+4값을 ALU로 계산하여 ALUOut에 들어가기 직전에 넣어놓는다.
		// LOAD, STORE의 경우: rs1+imm을 진행하여 이를 ALUOUT에 들어가기 직전에 넣어놓는다.
		// ARITHMETIC, ARITHMETIC_IMM의 경우: rs1 op rs2를 진행하여 ALUOut에 들어가기 직전에 넣어놓는다.
        `MEM1: begin
            case(part_of_inst)
                `LOAD: begin
                    mem_read = 1;
                    iord = 1;
                end
                `STORE: begin
                    mem_write = 1;
                    iord = 1;
                end
                default: begin
                end

            endcase
        end
		// Load 경우: mem_read를 1로, iord를 1로 세팅하여 Mem에서 읽어와서 MDR에 넣기 직전이다. 다음 clock 때 MDR에 넣는다.
		// Store의 경우: mem_write를 1로, iord를 1로 세팅하여 Mem에서 쓰기 직전이다. 다음 clock 때 Mem에 써진다.
        `MEM2: begin
            case(part_of_inst)
                `STORE: begin
                    alu_src_a = 0;
                    alu_src_b = 2'b01;
                    alu_op = 2'b00;
                    pc_write = 1;
                    pc_source = 0;
                end
                default: begin
                end

            endcase
        end
		// Load의 경우: mem_to_reg가 0이므로 register의 write data 앞에서 기다리고 있다가 다음 단계인 WB 단계에서 register에 써진다.
		// Store의 경우: Mem에 값을 쓰고 다음에 바로 PC+4를 계산하고 pc_write를 1로 세팅하여 IF1 단계로 가게 된다.
        `WB: begin
            case(part_of_inst)
                `ARITHMETIC, `ARITHMETIC_IMM: begin
                    reg_write  = 1;
                    alu_src_a = 0;
                    alu_src_b = 2'b01;
                    alu_op = 2'b00;
                    pc_write = 1;
                    pc_source = 0;
                end
                `JAL: begin
				    reg_write = 1;
                    alu_src_a = 0;
                    alu_src_b = 2'b10;
                    alu_op = 2'b00;
                    pc_write = 1;
                    pc_source = 0;
				end
				`JALR: begin
                    reg_write = 1;
                    alu_src_a = 1;
                    alu_src_b = 2'b10;
                    alu_op = 2'b00;
                    pc_write = 1;
                    pc_source = 0;
                end
                `LOAD: begin
                    mem_to_reg = 1;
                    reg_write = 1;
                    alu_src_a = 0;
                    alu_src_b = 2'b01;
                    alu_op = 2'b00;
                    pc_write = 1;
                    pc_source = 0;
                end
                default: begin
                end
            endcase
        end
		// Arithmetic, Arithmetic_imm의 경우: reg_write를 1로 세팅하여 다음 cycle에 값이 써지도록 설정해놓고, PC+4를 계산하여 다음 cycle에 IF1으로 가서 값을 쓰도록 한다.
		// JAL, JALR의 경우: 다음 PC를 ALU로 계산하여 세팅하고 다음 cycle에 IF1으로 가서 값을 쓰도록 한다.
		// Load의 경우: mem_to_reg를 1로 설정하여 register에 써넣고 마찬가지로 PC+4로 다음 주소를 준비한다.
		
        default: begin
            pc_write_cond = 0;
            pc_write      = 0;
            iord          = 0;
            mem_read      = 0;
            mem_write     = 0;
            mem_to_reg    = 0;
            ir_write      = 0;
            pc_source     = 0;
            alu_op        = 2'b00;
            alu_src_b     = 2'b00;
            alu_src_a     = 0;
            reg_write     = 0;
            is_ecall      = 0;
        end
    endcase
end
endmodule
