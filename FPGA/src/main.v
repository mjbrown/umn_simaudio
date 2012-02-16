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
    //input  XTAL,
    // output ADC_CLK,
   // Connected to Basys2 onBoard 7seg display
   output [7:0] seg,
   output [3:0] an,
 
   // LEDs
   output [7:0] led,
   
   // Switches
   input [7:0] sw,
   
   // Buttons
   input [3:0] btn,
   
   // PS2
   input PS2C,
   input PS2D,
   
   // VGA
   output HSYNC,
   output VSYNC,
   output OutRed,
   output OutGreen,
   output OutBlue,
   
   //PORTS
   output [3:0] JA,
   output [3:0] JB,
   output [3:0] JC,
   output [3:0] JD,
   
   //DPIMREF / EppCtl
   //Connected to Basys2 onBoard USB controller
   inout  [7:0] EppDB,
   input  EppAstb,
   input  EppDstb,
   input  EppWR,
   output EppWait,
   // output [7:0] rgLed,
   // input  [7:0] rgSwt,
   // input  [4:0] rgBtn,
   
   input  mclk
);

wire adc_clk;
wire adc_clk_rst;
wire adc_locked;
wire dpi_btn;
wire dpi_ldg;
wire dpi_led;
wire mclk_bufg;
// reg  [3:0] an_reg = 4b'1111;

assign adc_clk_rst = 0;
assign JA = adc_clk & 3'b000;
assign JB = 4'b0000;
assign JC = 4'b0000;
assign JD = 4'b0000;
assign dpi_btn = 0;

   // IBUFG: Single-ended global clock input buffer
   // IBUFG #(
      // .IBUF_DELAY_VALUE("0"), // Specify the amount of added input delay for 
                                // the buffer: "0"-"12" (Spartan-3E)
      // .IOSTANDARD("DEFAULT")  // Specify the input I/O standard
   // ) IBUFG_inst (
      // .O(mclk_bufg), // Clock buffer output
      // .I(mclk)  // Clock buffer input (connect directly to top-level port)
   // );
					
dpimref dpi(
 // .mclk  (mclk_bufg),
 .mclk  (mclk),
 .pdb   (EppDB),
 .astb  (EppAstb),
 .dstb  (EppDstb),
 .pwr   (EppWR),
 .pwait (EppWait),
 .rgled (led),
 .rgswt (sw),
 .rgbtn (btn),
 .btn   (dpi_btn),
 .ldg   (dpi_ldg),
 .led   (dpi_led)
);

adc_clock_gen adc_clk_gen_inst (
     .U1_CLKIN_IN(mclk),
     .U1_RST_IN(adc_clk_rst),
     .U2_CLKFX_OUT(adc_clk),
	  .U2_LOCKED_OUT(adc_locked)
);
endmodule
