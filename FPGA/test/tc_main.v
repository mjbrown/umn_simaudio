`timescale 1ns / 1ps
// require 24 576 000 adc clk


////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:31:00 02/07/2012
// Design Name:   main
// Module Name:   D:/Xilinx/umn_simaudio/tc_main.v
// Project Name:  umn_simaudio
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: main
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tc_main;
	reg LTC6905_out;
	// Outputs
	wire adc_clk;
	
	// Instantiate the Unit Under Test (UUT)
	main uut (
		.mclk_in(LTC6905_out)
	);

	initial begin
		// Initialize Inputs

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
     
	parameter PERIOD = 20;
   always begin
		LTC6905_out = 1'b0;
		#(PERIOD/2) LTC6905_out = 1'b1;
		#(PERIOD/2);
	end 
endmodule

