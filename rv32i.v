// 定义alu的operation的id
`define ALU_ADD   0
`define ALU_SUB   1
`define ALU_AND   2
`define ALU_OR    3
`define ALU_XOR   4
`define ALU_SLL   5
`define ALU_SRL   6
`define ALU_SRA   7
`define ALU_SEQ   8
`define ALU_SNE   9
`define ALU_SLT  10
`define ALU_SGE  11
`define ALU_SLTU 12
`define ALU_SGEU 13
// opcode: 指令[6:0]
`define OPCODE_OP     7'b0110011
`define OPCODE_OP_IMM 7'b0010011
`define OPCODE_LUI    7'b0110111
`define OPCODE_AUIPC  7'b0010111
`define OPCODE_JAL    7'b1101111
`define OPCODE_JALR   7'b1100111
`define OPCODE_BRANCH 7'b1100011
`define OPCODE_SYSTEM 7'b1110011
// funct3:指令[14:12]
// 整数运算
`define FUNCT3_ADD_SUB 3'b000
`define FUNCT3_SLL     3'b001
`define FUNCT3_SLT     3'b010
`define FUNCT3_SLTU    3'b011
`define FUNCT3_XOR     3'b100
`define FUNCT3_SRL_SRA 3'b101
`define FUNCT3_OR      3'b110
`define FUNCT3_AND     3'b111
// 分支跳转
`define FUNCT3_BEQ  3'b000
`define FUNCT3_BNE  3'b001
`define FUNCT3_BLT  3'b100
`define FUNCT3_BGE  3'b101
`define FUNCT3_BLTU 3'b110
`define FUNCT3_BGEU 3'b111
// Timers and Counters
`define SYSTEM_RDCYCLE    20'b11000000000000000010
`define SYSTEM_RDCYCLEH   20'b11001000000000000010
`define SYSTEM_RDTIME     20'b11000000000100000010
`define SYSTEM_RDTIMEH    20'b11001000000100000010
`define SYSTEM_RDINSTRET  20'b11000000001000000010
`define SYSTEM_RDINSTRETH 20'b11001000001000000010
// ALU
// （好暴力
module alu (input [3:0]       operation,
            input [31:0]      s1,
            input [31:0]      s2,
            output reg [31:0] d
            );
   wire [4:0]                 shamt = s2[4:0];
   always @ *
     case(operation)
       `ALU_ADD:  d = s1 + s2;
       `ALU_SUB:  d = s1 - s2;
       `ALU_AND:  d = s1 & s2;
       `ALU_OR:   d = s1 | s2;
       `ALU_XOR:  d = s1 ^ s2;
       `ALU_SLL:  d = s1 << shamt;
       `ALU_SRL:  d = s1 >> shamt;
       `ALU_SRA:  d = $signed(s1) >>> shamt;
       `ALU_SEQ:  d = s1 == s2 ? 1 : 0;
       `ALU_SNE:  d = s1 == s2 ? 0 : 1;
       `ALU_SLT:  d = $signed(s1) < $signed(s2) ? 1 : 0;
       `ALU_SGE:  d = $signed(s1) < $signed(s2) ? 0 : 1;
       `ALU_SLTU: d = s1 < s2 ? 1 : 0;
       `ALU_SGEU: d = s1 < s2 ? 0 : 1;
       default:   d = 0;
     endcase
endmodule

module adder (input [31:0]      s1,
              input [31:0]      s2,
              output reg [31:0] d
              );
   always @ * begin
      d = s1 + s2;
   end
endmodule

// 译码器
module decoder(input [31:0]      insn,
               input [31:0]      pc,
               input [63:0]      cycle,
               input [63:0]      instret,
               input [31:0]      regs [1:31],

               output [4:0]      rd,
               output reg        s1_is_imm,
               output [4:0]      rs1,
               output reg [31:0] s1_imm,
               output reg        s2_is_imm,
               output [4:0]      rs2,
               output reg [31:0] s2_imm,
               output reg [3:0]  op_alu,
               output reg        is_jump,
               output reg        is_branch,
               output [31:0]     jump_target
               );
   wire [6:0]                    opcode = insn[ 6: 0];
   wire [2:0]                    funct3 = insn[14:12];
   wire [6:0]                    funct7 = insn[31:25];
   wire [31:0]                   imm12  = {{21{insn[31]}}, insn[30:20]};
   wire [31:0]                   imm20  = {insn[31:12], 12'b0};
   wire [31:0]                   imm12b = {{20{insn[31]}}, insn[7], insn[30:25], insn[11:8], 1'b0};
   wire [31:0]                   imm20j = {{12{insn[31]}}, insn[19:12], insn[20], insn[30:21], 1'b0};
   wire [31:0]                   imm11j = {{21{insn[31]}}, insn[30:20]};
   reg                           rd_write_disable;
   reg                           is_jump_reg;

   assign rd = rd_write_disable ? 0 : insn[11:7];
   assign rs2 = insn[24:20];
   assign rs1 = insn[19:15];
   // 下行内容参考JAL、JALR以及分支跳转的注释
   assign jump_target = (is_jump_reg ? (regs[rs1] + imm11j) : (pc - 4 + (is_branch ? imm12b : imm20j)));

   always @ * begin
      rd_write_disable = 0;
      s1_imm = 0;
      s1_is_imm = 0;
      s2_imm = 0;
      s2_is_imm = 0;
      is_jump = 0;
      is_branch = 0;
      op_alu = `ALU_ADD;
      case(opcode)
        // 寄存器运算
        `OPCODE_OP: begin
           case(funct3)
             `FUNCT3_ADD_SUB: op_alu = funct7[5] ? `ALU_SUB : `ALU_ADD;
             `FUNCT3_SLL:     op_alu = `ALU_SLL;
             `FUNCT3_SLT:     op_alu = `ALU_SLT;
             `FUNCT3_SLTU:    op_alu = `ALU_SLTU;
             `FUNCT3_XOR:     op_alu = `ALU_XOR;
             `FUNCT3_SRL_SRA: op_alu = funct7[5] ? `ALU_SRA : `ALU_SRL;
             `FUNCT3_OR:      op_alu = `ALU_OR;
             `FUNCT3_AND:     op_alu = `ALU_AND;
           endcase
        end
        // 立即数运算
        `OPCODE_OP_IMM: begin
           // 立即数赋值
           s2_imm = imm12;
           // 是立即数
           s2_is_imm = 1;
           case(funct3)
             `FUNCT3_ADD_SUB: op_alu = `ALU_ADD;
             `FUNCT3_SLT:     op_alu = `ALU_SLT;
             `FUNCT3_SLTU:    op_alu = `ALU_SLTU;
             `FUNCT3_XOR:     op_alu = `ALU_XOR;
             `FUNCT3_OR:      op_alu = `ALU_OR;
             `FUNCT3_AND:     op_alu = `ALU_AND;
             `FUNCT3_SLL:     op_alu = `ALU_SLL;
             `FUNCT3_SRL_SRA: op_alu = funct7[5] ? `ALU_SRA : `ALU_SRL;
           endcase
        end
        // 加载立即数到高位
        `OPCODE_LUI: begin
           s1_imm = imm20;
           s1_is_imm = 1;
           s2_is_imm = 1;
        end
        // Add Upper Imm to PC
        // 向pc高位加上立即数
        `OPCODE_AUIPC: begin
           s1_imm = imm20;
           s1_is_imm = 1;
           s2_imm = pc;
           s2_is_imm = 1;
        end
        // jump an link 
        // 跳转并链接
        // 将 PC + 4 写入 rd
        // 后把 PC 设置为当前值加上符号位扩展的offset
        ///////////////////////////////////////////
        // 这里实在是很迷啊，按照这个流水线的写法
        // 在译码的时候pc已经相对取值加4了
        // 所以其实pc是不用加的
        `OPCODE_JAL: begin
           s1_is_imm = 1;
           s1_imm = pc;
           s2_is_imm = 1;
           is_jump = 1;
           is_jump_reg = 0;
        end
        // Jump and Link Register
        // 寄存器跳转并链接
        // 将 PC + 4 写入 rd
        // 把 PC 设置为 x[rs1] 加上符号位扩展的offset，
        // 把计算出的地址的最低有效位设为 0(草，我直接不要最低位不就好了)
        `OPCODE_JALR: begin
           s1_is_imm = 1;
           s1_imm = pc;
           s2_is_imm = 1;
           is_jump = 1;
           is_jump_reg = 1;
        end
        // 分支跳转
        `OPCODE_BRANCH: begin
           is_jump = 1;
           is_branch = 1;
           rd_write_disable = 1;
           case(funct3)
             `FUNCT3_BEQ:  op_alu = `ALU_SEQ;
             `FUNCT3_BNE:  op_alu = `ALU_SNE;
             `FUNCT3_BLT:  op_alu = `ALU_SLT;
             `FUNCT3_BGE:  op_alu = `ALU_SGE;
             `FUNCT3_BLTU: op_alu = `ALU_SLTU;
             `FUNCT3_BGEU: op_alu = `ALU_SGEU;
           endcase
        end
        // 读取计数器
        `OPCODE_SYSTEM: begin
           s1_is_imm = 1;
           s2_is_imm = 1;
           case(insn[31:12])
             `SYSTEM_RDCYCLE:    s1_imm = cycle[31:0];
             `SYSTEM_RDCYCLEH:   s1_imm = cycle[63:32];
             `SYSTEM_RDTIME:     s1_imm = cycle[31:0];
             `SYSTEM_RDTIMEH:    s1_imm = cycle[63:32];
             `SYSTEM_RDINSTRET:  s1_imm = instret[31:0];
             `SYSTEM_RDINSTRETH: s1_imm = instret[63:32];
           endcase
        end
      endcase
   end
endmodule
// 核心逻辑
module ezpipe (input         clk,
               input         reset,
               output [31:0] ibus_addr,
               input [31:0]  ibus_data
               // output reg [31:0] dbus_addr,
               // output reg [31:0] dbus_data_wr,
               // input [31:0]      dbus_data_rd,
               // input [31:0]      dbus_data_ready,
               // output reg        dbus_rd,
               // output reg        dbus_wr
               );
   /* registers and counters */
   reg [31:0]                regs [1:31];
   reg [31:0]                pc;
   reg [63:0]                cycle;
   reg [63:0]                instret;
   // There is no counter for RDTIME/RDTIMEH, those instructions just use the cycle register.
   // 不知道为什么作者这里懒得实现TIME计数器，但是没啥大问题

   /* pipeline registers */
   // from FETCH to DECODE
   reg [31:0]                f_insn;       // 指令
   reg [31:0]                f_pc;         // 程序计数器
   reg                       f_valid;      // 是否取指
   // from DECODE to EXECUTE
   reg [31:0]                d_s1;
   reg [31:0]                d_s2;
   reg [3:0]                 d_op_alu;
   reg [4:0]                 d_rd;
   reg                       d_is_jump;
   reg                       d_is_branch;
   reg [31:0]                d_jump_target;
   reg                       d_valid;
   // from EXECUTE to WRITE
   reg [4:0]                 e_rd;
   reg [31:0]                e_d;
   reg                       e_is_jump;
   reg                       e_is_branch;
   reg [31:0]                e_jump_target;
   reg                       e_valid;

   /* instances */
   wire [4:0]                dec_rd;
   wire [4:0]                dec_rs1;
   wire [31:0]               dec_s1_imm;
   wire                      dec_s1_is_imm;
   wire [4:0]                dec_rs2;
   wire [31:0]               dec_s2_imm;
   wire                      dec_s2_is_imm;
   wire [3:0]                dec_op_alu;
   wire                      dec_is_jump;
   wire                      dec_is_branch;
   wire [31:0]               dec_jump_target;
   decoder dec(.pc(f_pc),
               .insn(f_insn),
               .cycle(cycle),
               .instret(instret),
               .regs(regs),
               .op_alu(dec_op_alu),
               .rd(dec_rd),
               .rs1(dec_rs1),
               .s1_is_imm(dec_s1_is_imm),
               .s1_imm(dec_s1_imm),
               .rs2(dec_rs2),
               .s2_is_imm(dec_s2_is_imm),
               .s2_imm(dec_s2_imm),
               .is_jump(dec_is_jump),
               .is_branch(dec_is_branch),
               .jump_target(dec_jump_target)
               );

   wire [31:0]               alu_d;
   alu alu(.s1(d_s1),
           .s2(d_s2),
           .operation(d_op_alu),
           .d(alu_d)
           );

   assign ibus_addr = pc;

   /* the actual pipeline */
   reg                       jumping;
   reg [1:0]                 stall;
   always @ * begin
      // does the decoded instruction depend on a instruction in the d_* or e_* registers?
      // stall = 0;
      // 如果读写（读:rs1/rs2，写:rd）冲突，则阻塞流水线执行
      // 理论上来说，这是一个保险的策略，读写冲突的解决一般由编译器解决
      // if(d_valid && |d_rd) begin
      //    if(|dec_rs1 && !dec_s1_is_imm && dec_rs1==d_rd)
      //      stall = 1;
      //    if(|dec_rs2 && !dec_s2_is_imm && dec_rs2==d_rd)
      //      stall = 1;
      // end
      // if(e_valid && |e_rd) begin
      //    if(|dec_rs1 && !dec_s1_is_imm && dec_rs1==e_rd)
      //      stall = 1;
      //    if(|dec_rs2 && !dec_s2_is_imm && dec_rs2==e_rd)
      //      stall = 1;
      // end

      // is there a taken branch/jump sitting in the e_* registers?
      // 默认清空跳转标识符
      jumping = 0;
      // 处理跳转指令
      if(e_valid)
        if(e_is_jump) begin
           if(e_is_branch)
             jumping = e_d[0];
           else
             jumping = 1;
        end
   end

   always @(posedge clk) begin
      // 重置  
      if(reset) begin
         pc <= 0;
         f_valid <= 0;
         d_valid <= 0;
         e_valid <= 0;
         cycle <= 0;
         instret <= 0;
         stall <=0;
      end else begin
         // 周期+1
         cycle <= cycle + 1;

         // 它这里实现了四级流水线
         // 取指、译码、执行、回写 

         /* FETCH */
         // 跳转则暂停执行指令
         f_valid <= !jumping;
         // 不阻塞，取指
         if(!(|stall)) begin
            f_insn <= ibus_data;
            f_pc <= pc;
            pc <= pc + 4;
         end else begin
            stall <= stall - 1;
         end

         /* DECODE */
         if(!(|stall)) begin
            // 读取操作数
            if(dec_s1_is_imm) d_s1 <= dec_s1_imm;
            else              d_s1 <= |dec_rs1 ? regs[dec_rs1] : 0;
            if(dec_s2_is_imm) d_s2 <= dec_s2_imm;
            else              d_s2 <= |dec_rs2 ? regs[dec_rs2] : 0;
            // 将译码结果传递至下一级
            d_rd <= dec_rd;
            d_op_alu <= dec_op_alu;
            d_jump_target <= dec_jump_target;
            d_is_branch <= dec_is_branch;
            d_is_jump <= dec_is_jump;
            d_valid <= f_valid && !jumping;
         end else begin
            // can't issue this instruction yet; send a bubble down the pipeline
            //读写冲突也会导致阻塞
            d_valid <= 0;
         end

         /* EXECUTE */
         // 获取alu执行结果
         e_d <= alu_d;
         // 将译码结果继续传递至下一级
         e_rd <= d_rd;
         e_is_jump <= d_is_jump;
         e_is_branch <= d_is_branch;
         e_jump_target <= d_jump_target;
         //在这里，跳转标识符阻塞后续所有指令执行
         e_valid <= d_valid && !jumping;

         /* WRITE */
         if(e_valid) begin
            // 跳转
            if(jumping)
              pc <= e_jump_target;
            // 写寄存器
            if(|e_rd)
              regs[e_rd] <= e_d;
            // 指令计数器+1
            instret <= instret + 1;
         end
      end
   end
endmodule