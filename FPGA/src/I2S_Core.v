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
module I2S_Core(
	input  adc_clk,
	output i2s_bclk,
	output i2s_wclk
);
parameter clk_cnt_W   = 8;
parameter bclk_period = 4;
parameter clk_div = bclk_period >> 1;// bclk = 2*adc/clk_div
parameter sample_size = 24;
parameter wclk_bits   = 32;
parameter bit_cnt_W   = 5;

reg [clk_cnt_W - 1:0] clk_cnt = 0;
reg [bit_cnt_W - 1:0] bit_cnt = 0;

reg bclk = 0;
reg wclk = 0;
wire s1_bflip;
wire s2_bflip;

//assign s1_bflip = (clk_cnt == clk_div - 1);
//assign s2_bflip = (clk_cnt == clk_div);
//assign s0_bflip = ((s2_bflip == 1) || ((bclk == 1) && (s1_bflip == 1) && (bit_cnt >= 8)));

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
