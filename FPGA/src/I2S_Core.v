`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:34:42 02/27/2012 
// Design Name:    
// Module Name:    I2S_Core 
// Project Name:   UMN SimAudio
// Target Devices: Spartan3E
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
module I2S_Core(
	input  adc_clk,
	output i2s_bclk,
	output i2s_wclk
);
parameter clk_cnt_W   = 4;//needs to be enough bits to hold integer <bclk_period>/2 - 1
parameter bclk_period = 4;//number of adc cycles in bclk cycle
parameter clk_div = bclk_period >> 1;// bclk = 2*adc/clk_div
parameter wclk_bits   = 32;//number of bclk cycles in a half wclk cycle
parameter bit_cnt_W   = 5;// needs to be enough bits to hold the integer <wclk_bits> - 1

reg [clk_cnt_W - 1:0] clk_cnt = 0;
reg [bit_cnt_W - 1:0] bit_cnt = 0;

reg bclk = 0;
reg wclk = 0;

always @(posedge adc_clk)
begin
	clk_cnt <= clk_cnt + 1;
	if (clk_cnt == clk_div - 1) begin
		bclk <= !bclk;
		clk_cnt <= 0;
		//wclk changes on negative edge of bclk
		// bclk == 1 when starting negedge
		if (bclk == 1) begin
			bit_cnt <= bit_cnt + 1;
			if (bit_cnt == wclk_bits - 1) begin
				wclk <= !wclk;
				bit_cnt <= 0;
			end
		end
	end
end

assign i2s_bclk = bclk;
assign i2s_wclk = wclk;

endmodule
