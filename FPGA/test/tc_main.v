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
	
	reg STMEN = 0;
	reg FLAGA = 0;
	reg FLAGB = 0;
	wire [7:0] USBDB;
	
	reg SYS_CLK = 0;
	reg USB_CLK = 0;
	reg din0    = 0;
	reg din1    = 1;
	wire dout;
	
	wire adc_clk;
	wire i2s_wclk;
	wire i2s_bclk;
	wire [7:0] leds;
	wire [1:0] FIFOADR;
	
	reg lat_wclk = 0;
	reg start    = 0;
	reg dataRdy  = 0;
	
	reg [_WIDTH-1:0] squarewave = 0;
	reg [_WIDTH-1:0] sawtooth   = 0;
	reg [_WIDTH-1:0] sawtoothN  = 1;
	
	// Instantiate the Unit Under Test (UUT)
	main uut (
		.MCLK_IN(SYS_CLK),
		.USBCLK_IN(USB_CLK),
		.ADC_CLK_OUT(adc_clk),
		.I2S_WCLK_OUT(i2s_wclk),
		.I2S_BCLK_OUT(i2s_bclk),
		.I2S_DATA0_IN(din0),
		.I2S_DATA1_IN(din1),
		.LEDATA(leds),
		.STMEN  (STMEN),
		.FLAGA  (FLAGA),
		.FLAGB  (FLAGB),
		.SLRD   (SLRD),
		.SLWR   (SLWR),
		.SLOE   (SLOE),
		.PKTEND (PKTEND),
		.FIFOADR(FIFOADR),
		.USBDB  (USBDB)
	);
	
	initial begin
		// Wait 100 ns for global reset to finish
		#100;
		
		// Add stimulus here
	end
     
	parameter PERIOD = 20;//nanoseconds
    always begin
		#(PERIOD/2) SYS_CLK = ~SYS_CLK;
	end
	
	parameter USB_PERIOD = 20.83;
	always begin
		#(USB_PERIOD/2) USB_CLK = ~USB_CLK;
	end
	
	// I2S i2s_wclk latches at positive edge of i2s_bclk
	always @(posedge i2s_bclk) begin
		lat_wclk <= i2s_wclk;
		dataRdy  <= i2s_wclk ^ lat_wclk;
		start    <= (i2s_wclk ^ lat_wclk) | start;
	end
	
	// Square wave active during lat_wclk = 1;
	// load next sawtooth
	always @(posedge lat_wclk) begin
		sawtoothN <= sawtoothN + 2;
	end
	
	// Sawtooth active during lat_wclk = 0;
	// load next square wave
	always @(negedge i2s_bclk) begin
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

