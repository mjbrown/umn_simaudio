`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:34:42 02/27/2012 
// Design Name: 
// Module Name:    I2S_Data
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//   wclk low  = Right channel holds
//   wclk high = Left channel holds
//   Data is latched at positive edge of bclk
//   LSB is latched AFTER wclk changes
//   
// Dependencies: 
//   I2S_Core used to generate clock signals
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module I2S_Data(
	i2s_bclk,
	i2s_wclk,
	din,
	dataL,
	dataR,
	detectL,
	detectR
);
	parameter DATA_W = 24;
	parameter [DATA_W - 1:0] DETECT_SENSITIVITY = 15;
	parameter [DATA_W - 1:0] DETECT_SENSITIVITY_NEG = -DETECT_SENSITIVITY;
	parameter DETECT_W = 4;
	parameter [DETECT_W-1:0] DETECT_MAX = (1 << DETECT_W) - 1;
	
	output reg [DATA_W-1:0] dataL, dataR;
	output reg detectL, detectR;
	input  i2s_bclk;
	input  i2s_wclk;
	input  din;
		
	reg [DETECT_W:0] detectCntL, detectCntR;
	reg wclk_lat;
	reg detectEn;
	
	initial
	begin
		detectEn   = 0;
		detectCntL = 0;
		detectCntR = 0;
		detectL    = 1;
		detectR    = 1;
		dataL      = 0;
		dataR      = -1;
	end
	
	// Latch wclk for required delay
	// Latch detect enable to trigger detection logic
	always @(posedge i2s_bclk)
	begin
		wclk_lat  <= i2s_wclk;
		detectEn  <= i2s_wclk ^ wclk_lat;
	end
	
	// Latch data at positive edge of bit clock
	always @(posedge i2s_bclk)
	begin
		if (wclk_lat == 0) begin
			dataL <= {dataL[DATA_W-2:0], din};
		end else begin
			dataR <= {dataR[DATA_W-2:0], din};
		end
	end
	
	// Signal (microphone) detection
	always @(posedge i2s_bclk)
	begin
		if (detectEn == 1)
		begin
			if (i2s_wclk == 1)
			begin // Detect left channel signal
				if ( (dataL >= DETECT_SENSITIVITY) && (dataL <= DETECT_SENSITIVITY_NEG)) begin
					// Signal detected, reset counter
					detectCntL <= 0;
					detectL <= 1;
				end else if (detectCntL == DETECT_MAX ) begin
					// Signal not detected threshhold reached
					detectL <= 0;
				end else begin
					//Signal within margin of 0 (not detected).
					detectCntL <= detectCntL + 1;
					detectL <= 1;
				end
			end else begin // Detect right channel signal
				if ( (dataR >= DETECT_SENSITIVITY) && (dataR <= DETECT_SENSITIVITY_NEG)) begin
					// Signal detected
					detectCntR <= 0;
					detectR <= 1;
				end else if (detectCntR == DETECT_MAX ) begin
					// Signal not detected threshold reached
					detectR <= 0;
				end else begin
					// Signal within margin of 0 (not detected)
					detectCntR <= detectCntR + 1;
					detectR <= 1;
				end
			end
		end
	end
	
	
	// assign drh = (dataR >= DETECT_SENSITIVITY);
	// assign drl = (dataR <= DETECT_SENSITIVITY_NEG);
endmodule
