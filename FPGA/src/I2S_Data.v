`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:34:42 02/27/2012 
// Design Name: 
// Module Name:    I2S_Core 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
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
	parameter DETECT_SENSITIVITY = 15;
	parameter DETECT_W = 4;
	parameter DETECT_MAX = (1 << DETECT_W) - 1;
	
	output [DATA_W-1:0] dataL, dataR;
	output detectL, detectR;
	input  i2s_bclk;
	input  i2s_wclk;
	input  din;
	
	reg [DATA_W:0] dataregL,dataregR;
	reg detectregL, detectregR;
	reg [DETECT_W:0] detectcntL, detectcntR;
	always @(posedge i2s_bclk)
	begin
		if (i2s_wclk == 0) begin
			dataregL <= {dataregL[22:0], din};
		end else begin
			dataregR <= {dataregR[22:0], din};
		end
	end
	
	always @(posedge i2s_wclk)
	begin
		if ( (dataregL > DETECT_SENSITIVITY) || (dataregL < 0-DETECT_SENSITIVITY)) begin
			detectcntL <= 0;
			detectregL <= 1;
		end else if (detectcntL == DETECT_MAX ) begin
			detectregL <= 0;
		end else begin
			detectcntL <= detectcntL + 1;
			detectregL <= 1;
		end
	end

endmodule
