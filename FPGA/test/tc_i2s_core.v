`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:57:45 03/07/2012
// Design Name:   I2S_Core
// Module Name:   D:/Documents/Class/EE 4951W Senior Design/Xilinx/tc_i2s_core.v
// Project Name:  Xilinx
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: I2S_Core
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tc_i2s_core;
	parameter _WIDTH = 24;
	// Inputs
	reg adc_clk;

	// Outputs
	wire i2s_bclk;
	wire i2s_wclk;
	reg [_WIDTH-1:0] adc_acc;
	reg [_WIDTH-1:0] bclk_acc;
	reg wclk_lat;
	reg bclk_lat;
	reg aclk_lat;
	
	// Instantiate the Unit Under Test (UUT)
	I2S_Core uut (
		.adc_clk(adc_clk), 
		.i2s_bclk(i2s_bclk), 
		.i2s_wclk(i2s_wclk)
	);

	initial begin
		// Initialize Inputs
		adc_clk  = 0;
		wclk_lat = 0;
		bclk_lat = 0;
		aclk_lat = 0;
		adc_acc  = 0;
		bclk_acc = 0;
		
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
    
	// 40.6901042 ns
	parameter PERIOD = 40.690;
	always begin
		#(PERIOD/2) adc_clk <= ~adc_clk;
	end
	
	always @(posedge adc_clk) begin
		aclk_lat <= adc_clk;
		bclk_lat <= i2s_bclk;
	end
	
	always @(posedge i2s_bclk) begin
		wclk_lat <= i2s_wclk;
	end
	
	always @(posedge adc_clk) begin
		if (bclk_lat != i2s_bclk && i2s_bclk == 1) begin
			adc_acc <= 0;
		end else begin
			adc_acc <= adc_acc + 1;
		end
	end
	
	always @(posedge i2s_bclk) begin
		if (wclk_lat != i2s_wclk) begin
			bclk_acc <= 0;
		end else begin
			bclk_acc <= bclk_acc + 1;
		end
	end
	
endmodule

