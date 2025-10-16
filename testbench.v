`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.08.2025 22:45:47
// Design Name: 
// Module Name: testbench
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


module MIPS32_tb;
    reg clk1, clk2;
    //wire [31:0] result_output;
    
    // Instantiate the MIPS32 processor
    MIPS32 dut(.clk1(clk1), .clk2(clk2));
    
    // Clock generation
    always #5 clk1 = ~clk1;  // 100MHz clock
    always #10 clk2 = ~clk2; // 50MHz clock (half frequency of clk1)
    
    // Test sequence
    initial begin
        // Initialize clocks
        clk1 = 0;
        clk2 = 0;
        
        // Initialize memory with test program
        // Program: ADDI R1, R0, 5  (R1 = 5)
        dut.memory[0] = {6'b001010, 5'b00000, 5'b00001, 16'd5};
        
        // Program: ADDI R2, R0, 3  (R2 = 3)
        dut.memory[1] = {6'b001010, 5'b00000, 5'b00010, 16'd3};
        
        // Program: ADD R3, R1, R2  (R3 = R1 + R2 = 8)
        dut.memory[2] = {6'b000000, 5'b00001, 5'b00010, 5'b00011, 11'b0};
        
        // Program: SW R3, 100(R0)  (Store R3 at memory address 100)
        dut.memory[3] = {6'b001001, 5'b00000, 5'b00011, 16'd100};
        
        // Program: LW R4, 100(R0)  (Load from address 100 to R4)
        dut.memory[4] = {6'b001000, 5'b00000, 5'b00100, 16'd100};
        
        // Program: HLT (Halt)
        dut.memory[5] = {6'b111111, 26'b0};
        
        // Initialize register file
        dut.reg_file[0] = 0;  // R0 is always zero
        
        // Initialize PC and control signals
        dut.PC = 0;
        dut.halted = 0;
        dut.taken_branch = 0;
        
        // Monitor progress
        $display("Time\tPC\tR1\tR2\tR3\tR4\tMemory[100]");
        $monitor("%0t\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d", 
                $time, dut.PC, dut.reg_file[1], dut.reg_file[2], 
                dut.reg_file[3], dut.reg_file[4], dut.memory[100]);
        
        // Run for enough cycles to complete the program
        #200;
        
        // Verify results
        if (dut.reg_file[1] == 5 && 
            dut.reg_file[2] == 3 && 
            dut.reg_file[3] == 8 && 
            dut.reg_file[4] == 8 && 
            dut.memory[100] == 8) begin
            $display("TEST PASSED: All operations completed correctly");
        end else begin
            $display("TEST FAILED: Incorrect results");
            $display("Expected: R1=5, R2=3, R3=8, R4=8, Mem[100]=8");
            $display("Got: R1=%0d, R2=%0d, R3=%0d, R4=%0d, Mem[100]=%0d",
                    dut.reg_file[1], dut.reg_file[2], 
                    dut.reg_file[3], dut.reg_file[4], dut.memory[100]);
        end
        
        $finish;
    end
    
    // Dump waves for debugging (optional)
    initial begin
        $dumpfile("mips32.vcd");
        $dumpvars(0, MIPS32_tb);
    end
endmodule
