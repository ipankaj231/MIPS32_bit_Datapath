`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.08.2025 19:10:18
// Design Name: 
// Module Name: MIPS32
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MIPS32(
       
       input clk1, clk2,
       output reg[31:0] result_output  //output is just added to get a schematic
    );
       
       reg[31:0] PC, IF_ID_IR, IF_ID_NPC;
       reg[31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
       reg[31:0] EX_MEM_IR, EX_MEM_B, EX_MEM_ALUOUT;
       reg EX_MEM_cond;
       reg[31:0] MEM_WB_IR, MEM_WB_ALUOUT, MEM_WB_LMD;
       
       reg[31:0] reg_file[31:0]; //Register_file
       reg[31:0] memory[1023:0]; //memory for both data memory and instruction memory
       
       reg[2:0] ID_EX_TYPE, EX_MEM_TYPE, MEM_WB_TYPE;
       
       //OPCODES
       parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011, SLT=6'b000100,
                 MUL=6'b000101, HLT=6'b111111, LW=6'b001000, SW=6'b001001, ADDI=6'b001010,
                 SUBI=6'b001011, SLTI=6'b001100, BNEQZ=6'b001101, BEQZ=6'b001110;
       
       parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011, BRANCH=3'b100,
                 HALT=3'b101;
       
       reg halted; //set HLT after instruction is completed(in WB stage)
       reg taken_branch; //reguired to disable instrucions after branch
       
       /*initial begin
        PC = 0;
        halted = 0;
        taken_branch = 0;
        reg_file[0] = 0; // Register 0 is always zero
       end*/
        
       //Stage1: IF(instruction Fetch) : s1
       always@(posedge clk1) begin
           if(halted==0)begin
              if(((EX_MEM_IR[31:26]==BEQZ)&&(EX_MEM_cond==1))||
              ((EX_MEM_IR[31:26]==BNEQZ)&&(EX_MEM_cond==0))) begin
                 
                 IF_ID_IR<=#2 memory[EX_MEM_ALUOUT];
                 taken_branch <= #2 1'b1;
                 IF_ID_NPC <= #2 EX_MEM_ALUOUT+1;
                 PC <= #2 EX_MEM_ALUOUT+1;
              end
              else begin
                 IF_ID_IR <= #2 memory[PC];
                 IF_ID_NPC <=#2 PC+1;
                 PC <=#2 PC+1;
              end
          end
        end
        
        //Stage2: ID: Innstrucion Decoder
        always@(posedge clk2) begin
           if(halted==0) begin
              if(IF_ID_IR[25:21]==5'b00000)
                 ID_EX_A <=0;
              else
                 ID_EX_A <= #2 reg_file[IF_ID_IR[25:21]]; //rs
              
              if(IF_ID_IR[20:16]==5'b00000)
                 ID_EX_B<=0;
               else
                 ID_EX_B<=#2 reg_file[IF_ID_IR[20:16]]; //rt
               
               ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};
               ID_EX_NPC <= #2 IF_ID_NPC;
               ID_EX_IR <= #2 IF_ID_IR;
               
               case(IF_ID_IR[31:26])
                   ADD,SUB,AND,OR,SLT,MUL: 
                         ID_EX_TYPE<= #2 RR_ALU;
                   ADDI,SUBI,SLTI: ID_EX_TYPE<= #2 RM_ALU;
                   LW: ID_EX_TYPE<=#2 LOAD;
                   SW: ID_EX_TYPE<= #2 STORE;
                   BEQZ,BNEQZ: ID_EX_TYPE<= #2 BRANCH;
                   HLT: ID_EX_TYPE <= #2 HALT;
                   default: ID_EX_TYPE <= #2 HALT;
              endcase
           end
      end
      
      //stage3: EX: Execution: s3
      always@(posedge clk1) begin
          if(halted ==0) begin
            EX_MEM_TYPE<= #2 ID_EX_TYPE;
            EX_MEM_IR<= #2 ID_EX_IR;
            taken_branch<= #2 0;
            
            case(ID_EX_TYPE)
              RR_ALU: begin
                case(ID_EX_IR[31:26])
                  ADD: EX_MEM_ALUOUT<= #2 ID_EX_A+ID_EX_B;
                  SUB: EX_MEM_ALUOUT<= #2 ID_EX_A-ID_EX_B;
                  AND: EX_MEM_ALUOUT<= #2 ID_EX_A&ID_EX_B;
                  OR: EX_MEM_ALUOUT<= #2 ID_EX_A|ID_EX_B;
                  SLT: EX_MEM_ALUOUT <= #2 (ID_EX_A < ID_EX_B) ? 32'b1 : 32'b0; // Fixed
                  MUL: EX_MEM_ALUOUT<= #2 ID_EX_A*ID_EX_B;
                  default: EX_MEM_ALUOUT<= #2 32'hxxxxxxxx;
                endcase
              end
              RM_ALU: begin
                case(ID_EX_IR[31:26])
                  ADDI: EX_MEM_ALUOUT <= #2 ID_EX_A+ID_EX_Imm;
                  SUBI: EX_MEM_ALUOUT <= #2 ID_EX_A-ID_EX_Imm;
                  SLTI: EX_MEM_ALUOUT <= #2 (ID_EX_A < ID_EX_Imm) ? 32'b1 : 32'b0;
                  default: EX_MEM_ALUOUT <= #2 32'hxxxxxxxx;
                endcase
              end
              LOAD,STORE: begin
                 EX_MEM_ALUOUT <= #2 ID_EX_A+ID_EX_Imm;
                 EX_MEM_B <= #2 ID_EX_B;
              end
              BRANCH: begin
                 EX_MEM_ALUOUT<= #2 ID_EX_NPC+ID_EX_Imm;
                 EX_MEM_cond<= #2 (ID_EX_A==0);
              end
              default: EX_MEM_ALUOUT <= #2 32'hxxxxxxxx;
         endcase
       end
      end
      //Stage4: MEM stage: s4;
      always@(posedge clk2) begin  
        if(halted==0) begin
           MEM_WB_TYPE<= #2 EX_MEM_TYPE;
           MEM_WB_IR<= #2 EX_MEM_IR;
           
           case(EX_MEM_TYPE)
             RR_ALU,RM_ALU: MEM_WB_ALUOUT<= #2 EX_MEM_ALUOUT;
             
             LOAD: MEM_WB_LMD<= #2 memory[EX_MEM_ALUOUT];
             
             STORE: 
                   if(taken_branch==0)
                       memory[EX_MEM_ALUOUT]<=#2 EX_MEM_B;
           endcase
       end
     end
     
     //stage5: WB: write back to register: s5;
     always@(posedge clk1)begin
        if(taken_branch==0)begin
           case(MEM_WB_TYPE)
              RR_ALU:  begin
                    if (MEM_WB_IR[15:11] != 5'b00000) // Protect register 0
                        reg_file[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOUT; // rd
              end
              RM_ALU: begin
                    if (MEM_WB_IR[20:16] != 5'b00000) // Protect register 0
                        reg_file[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOUT; // rt
                end
                LOAD: begin
                    if (MEM_WB_IR[20:16] != 5'b00000) // Protect register 0
                        reg_file[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD; // rt
                end
              HALT: halted <= #2 1'b1;
              default: ;
           endcase
           //for getting hardware schematic purpose
           case(MEM_WB_TYPE)
                RR_ALU, RM_ALU, LOAD: 
                    result_output <= (MEM_WB_TYPE == LOAD) ? MEM_WB_LMD : MEM_WB_ALUOUT;
                default: result_output <= result_output; // Keep previous value
           endcase
        end
    end
                 
endmodule
