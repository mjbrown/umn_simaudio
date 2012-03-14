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
	integer file;
	parameter _WIDTH = 24;
	reg LTC6905_out;
	reg din0;
	reg dout;
	
	wire adc_clk;
	// wire wclk;
	// wire bclk;
	reg lat_wclk;
	
	reg [_WIDTH-1:0] squarewave;
	reg [_WIDTH-1:0] impulse;
	reg [_WIDTH-1:0] sawtooth;
	reg [_WIDTH-1:0] sawtoothN;
	
	// Instantiate the Unit Under Test (UUT)
	main uut (
		.MCLK_IN(LTC6905_out),
		.ADC_CLK_OUT(adc_clk),
		.I2S_WCLK_OUT(wclk),
		.I2S_BCLK_OUT(bclk),
		.I2S_din0(din0),
		.dout(dout)
	);
	
	
	
	initial begin
		// Initialize Inputs
		LTC6905_out = 0;
		squarewave <= 24'h000000;
		sawtooth   <= 24'h000000;
		sawtoothN  <= sawtooth + 1;
		file = $fopen("simaudio_testcase.txt","w");
		$fclose(file);
		
		// Wait 100 ns for global reset to finish
		#100;
		
		// Add stimulus here
		
	end
     
	parameter PERIOD = 20;//nanoseconds
    always begin
		#(PERIOD/2) LTC6905_out = ~LTC6905_out;
	end
	
	// I2S wclk latches at positive edge of bclk
	always @(posedge bclk)
	begin
		lat_wclk <= wclk;
	end
	
	
	// Square wave active during lat_wclk = 1;
	// load next sawtooth
	always @(posedge lat_wclk)
	begin
		sawtoothN <= sawtoothN + 2;
		file = $fopen("simaudio_testcase.txt","a");
		$fwrite(file,"%h/n",dout);
		$fclose(file);
	end
	
	// Sawtooth active during lat_wclk = 0;
	// load next square wave
	always @(negedge lat_wclk)
	begin
		file = $fopen("simaudio_testcase.txt","a");
		$fwrite(file,"%h/n",dout);
		$fclose(file);
	end
	
	always @(negedge bclk)
	begin
		if (lat_wclk == 1) begin
			din0 <= squarewave[0];
			squarewave <= {~squarewave[0],squarewave[_WIDTH-1:1]};
		end else begin
			din0 <= 0;
		end
	end
	
	
endmodule

