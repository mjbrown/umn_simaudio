`timescale 1ns / 1ps
//XTAL_FREQ = 8 MHZ
//4000 samples
//XTAL_PER  = 125.02 ns
//low         117.55 ns
//high        132.66 ns
//sigma       0.86

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:12:20 02/04/2012 
// Design Name: 
// Module Name:    main 
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
module main(
   input  mclk_in ,
   input  astb ,
   input  dstb ,
   input  pwr  ,
   inout  [7:0] pdb  ,
   output [7:0] rgLed,
   input  [7:0] rgSwt,
   input  [3:0] rgBtn,   
   output  pwait,
   output I2S_bclk_out,
   output I2S_wclk_out,
   output adc_clk_out,
   input  I2S_din0,
   input  I2S_din1,
   input  I2S_din2,
   input  I2S_din3
);

wire adc_clk;
wire adc_clk_rst;
wire adc_locked;
wire dpi_btn;
wire dpi_ldg;
wire dpi_led;
wire mclk_bufg;
wire i2s_bclk;
wire i2s_wclk;
wire ja0;
wire ja1;
wire channel0;
wire channel1;

assign adc_clk_rst  = 0;
assign adc_clk_out  = adc_clk;
assign I2S_bclk_out = i2s_bclk;
assign I2S_wclk_out = i2s_wclk;

dpimref dpi(
 .mclk  (mclk),
 .pdb   (pdb),
 .astb  (astb),
 .dstb  (dstb),
 .pwr   (pwr),
 .pwait (pwait),
 .rgled (rgLed),
 .rgswt (rgSwt),
 .rgbtn (rgBtn),
 .btn   (dpi_btn),
 .ldg   (dpi_ldg),
 .led   (dpi_led)
);

adc_clock_gen adc_clk_gen_inst (
     .U1_CLKIN_IN(mclk_in),
	 .U1_CLKIN_IBUFG_OUT (mclk),
     .U1_RST_IN(adc_clk_rst),
     .U2_CLKFX_OUT(adc_clk),
	  .U2_LOCKED_OUT(adc_locked)
);

I2S_Core i2s_core_inst (
	.adc_clk(adc_clk),
	.i2s_bclk(i2s_bclk),
	.i2s_wclk(i2s_wclk)
);

I2S_Data i2s_data_0 (
	.i2s_bclk(i2s_bclk),
	.i2s_wclk(i2s_wclk),
	.din(I2S_din0),
	.dataL(channel0),
	.dataR(channel1)
);
I2S_Data i2s_data_1(
	.i2s_bclk(i2s_bclk),
	.i2s_wclk(i2s_wclk),
	.din(I2S_din1),
	.dataL(channel2),
	.dataR(channel3)
);
I2S_Data i2s_data_2 (
	.i2s_bclk(i2s_bclk),
	.i2s_wclk(i2s_wclk),
	.din(I2S_din2),
	.dataL(channel4),
	.dataR(channel5)
);
I2S_Data i2s_data_3 (
	.i2s_bclk(i2s_bclk),
	.i2s_wclk(i2s_wclk),
	.din(I2S_din3),
	.dataL(channel6),
	.dataR(channel7)
);


endmodule
