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
	reg USB_CLK;
	reg din0;
	reg din1;
	wire dout;
	
	wire adc_clk;
	// wire i2s_wclk;
	// wire i2s_bclk;
	reg lat_wclk;
	reg start;
	reg dataRdy;
	
	reg [_WIDTH-1:0] squarewave;
	reg [_WIDTH-1:0] impulse;
	reg [_WIDTH-1:0] sawtooth;
	reg [_WIDTH-1:0] sawtoothN;
	
	// Instantiate the Unit Under Test (UUT)
	main uut (
		.MCLK_IN(LTC6905_out),
		.USBCLK_IN(USB_CLK),
		.ADC_CLK_OUT(adc_clk),
		.I2S_WCLK_OUT(i2s_wclk),
		.I2S_BCLK_OUT(i2s_bclk),
		.I2S_din0(din0),
		.I2S_din1(din1),
		.dout(dout)
	);
	
	
	
	initial begin
		// Initialize Inputs
		LTC6905_out = 0;
		USB_CLK = 0;
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
	
	parameter USB_PERIOD = 20.83;
	always begin
		#(USB_PERIOD/2) USB_CLK = ~USB_CLK;
	end
	
	// I2S i2s_wclk latches at positive edge of i2s_bclk
	always @(posedge i2s_bclk)
	begin
		lat_wclk <= i2s_wclk;
		dataRdy  <= i2s_wclk ^ lat_wclk;
		start    <= (i2s_wclk ^ lat_wclk) | start;
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
	
	always @(negedge i2s_bclk)
	begin
		if (lat_wclk == 1)
		begin
			din0 <= squarewave[0];
			din1 <= squarewave[0];
			squarewave <= {~squarewave[0],squarewave[_WIDTH-1:1]};
		end else if (start) begin
			din0 <= sawtooth[_WIDTH-1];
			din1 <= sawtooth[_WIDTH-1];
			sawtooth  <= {sawtooth[_WIDTH-2:0], sawtooth[_WIDTH-1]};
			// sawtoothN <= {sawtooth[0] ,sawtoothN[_WIDTH-1:1]};
		end
		if (start && lat_wclk == 1 && dataRdy == 1) begin
			sawtooth  <= sawtooth  + 1;
			// sawtoothN <= sawtoothN + 2;
		end
	end
	
endmodule

