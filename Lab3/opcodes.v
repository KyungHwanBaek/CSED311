// OPCODE
`define ARITHMETIC      7'b0110011
`define ARITHMETIC_IMM  7'b0010011
`define LOAD            7'b0000011
`define JALR            7'b1100111
`define STORE           7'b0100011
`define BRANCH          7'b1100011
`define JAL             7'b1101111
`define ECALL           7'b1110011

// FUNCT3
`define FUNCT3_BEQ      3'b000
`define FUNCT3_BNE      3'b001
`define FUNCT3_BLT      3'b100
`define FUNCT3_BGE      3'b101
`define FUNCT3_LW       3'b010
`define FUNCT3_SW       3'b010
`define FUNCT3_ADD      3'b000
`define FUNCT3_SUB      3'b000
`define FUNCT3_SLL      3'b001
`define FUNCT3_XOR      3'b100
`define FUNCT3_OR       3'b110
`define FUNCT3_AND      3'b111
`define FUNCT3_SRL      3'b101

// ALU CONTROL OUTPUT
`define ALU_ADD   4'b0000
`define ALU_SUB   4'b0001
`define ALU_SLL   4'b0010
`define ALU_XOR   4'b0011
`define ALU_OR    4'b0100
`define ALU_AND   4'b0101
`define ALU_SRL   4'b0110
`define ALU_BEQ   4'b1000
`define ALU_BNE   4'b1001
`define ALU_BLT   4'b1010
`define ALU_BGE   4'b1011
`define ALU_NONE  4'b1111
