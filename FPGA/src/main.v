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
//   input  astb ,
//   input  dstb ,
//   input  pwr  ,
//   inout  [7:0] pdb  ,
//   output [7:0] rgLed,
//   input  [7:0] rgSwt,
//   input  [3:0] rgBtn,   
//   output  pwait,
	input  I2S_DATA0_IN, //JA1
	output I2S_BCLK_OUT, //JA2
   output I2S_WCLK_OUT, //JA3
   output ADC_CLK_OUT,  //JA4
	
	input  I2S_DATA1_IN, //JB1
	// output MCLK_OUT,
   input  I2S_din0,
   input  I2S_din1,
   input  I2S_din2,
   input  I2S_din3,
   output dout,
	
	output LEDATA,
	input  MCLK_IN,
	
	input  USBCLK_IN,
	input  STMEN,
	input  FLAGA,
	input  FLAGB,
	output SLRD,
	output SLWR,
	output SLOE,
	output PKTEND,
	output [1:0] FIFOADR,
	inout  [7:0] USBDB
);
parameter DATA_BLOCKS = 4;
parameter _WIDTH = 24;

reg lat_i2s_wclk;
reg [DATA_BLOCKS*2-1:0] data_count;
reg [_WIDTH - 1:0] i2s_data_mux;
reg i2s_mux_valid;

wire adc_clk;
wire adc_clk_rst;
wire adc_locked;
wire dpi_btn;
wire dpi_ldg;
wire dpi_led;
wire mclk_bufg;
wire i2s_bclk;
wire i2s_wclk;

reg  [7:0] data_id;
reg  [_WIDTH-1:0] audio_data;
wire [_WIDTH-1:0] channel0L, channel1L, channel2L, channel3L;
wire [_WIDTH-1:0] channel0R, channel1R, channel2R, channel3R;

// wire fir_rdy;
// wire fir_rfd;
// wire fir_chan_in;
// wire fir_chan_out;
// wire fir_din;
// wire fir_dout;
// wire i2s_dataL_rdy;
// wire i2s_dataR_rdy;


assign adc_clk_rst = 0;

assign ADC_CLK_OUT  = adc_clk;
assign I2S_BCLK_OUT = i2s_bclk;
assign I2S_WCLK_OUT = i2s_wclk;
// assign MCLK_OUT = mclk_bufg;

initial begin
	data_id = 0;
end

// dpimref dpi(
 // .mclk  (mclk),
 // .pdb   (pdb),
 // .astb  (astb),
 // .dstb  (dstb),
 // .pwr   (pwr),
 // .pwait (pwait),
 // .rgled (rgLed),
 // .rgswt (rgSwt),
 // .rgbtn (rgBtn),
 // .btn   (dpi_btn),
 // .ldg   (dpi_ldg),
 // .led   (dpi_led)
// );

StreamIOvhd streamIO (
	.IFCLK(USBCLK_IN),  
	.STMEN(STMEN),  
	.FLAGA(FLAGA),
	.FLAGB(FLAGB),  
	.SLRD(SLRD),   
	.SLWR(SLWR),   
	.SLOE(SLOE),   
	.PKTEND(PKTEND), 
	.FIFOADR(FIFOADR),
	.USBDB(USBDB),  
	.DATAID(data_id), 
	.AUDIO(audio_data)  
);

adc_clock_gen adc_clk_gen_inst (
     .U1_CLKIN_IN(MCLK_IN),
	  .U1_CLKIN_IBUFG_OUT(mclk_bufg),
     .U1_RST_IN(adc_clk_rst),
     .U2_CLKFX_OUT(adc_clk),
	  .U1_CLKDV_OUT(),
	  .U1_CLK0_OUT(),
	  .U1_STATUS_OUT(),
	  .U2_CLK0_OUT(),
	  .U2_STATUS_OUT(),
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
	 .din(I2S_DATA0_IN),
	 .dataL(channel0L),
	 .dataR(channel0R)
 );
 I2S_Data i2s_data_1(
	 .i2s_bclk(i2s_bclk),
	 .i2s_wclk(i2s_wclk),
	 .din(I2S_DATA1_IN),
	 .dataL(channel1L),
	 .dataR(channel1R)
 );
// I2S_Data i2s_data_2 (
	// .i2s_bclk(i2s_bclk),
	// .i2s_wclk(i2s_wclk),
	// .din(I2S_din2),
	// .dataL(channel2L),
	// .dataR(channel2R)
// );
// I2S_Data i2s_data_3 (
	// .i2s_bclk(i2s_bclk),
	// .i2s_wclk(i2s_wclk),
	// .din(I2S_din3),
	// .dataL(channel3L),
	// .dataR(channel3R)
// );

// FIR FIR_inst (
	// .clk(mclk_bufg), // input clk
	// .rfd(fir_rfd), // output rfd
	// .rdy(fir_rdy), // output rdy
	// .chan_in(fir_chan_in), // output [2 : 0] chan_in
	// .chan_out(fir_chan_out), // output [2 : 0] chan_out
	// .din(fir_din), // input [23 : 0] din
	// .dout(fir_dout)
// ); // output [44 : 0] dout


// I2S MUX
assign i2s_dataL_rdy = (lat_i2s_wclk == i2s_wclk) && lat_i2s_wclk == 1;
assign i2s_dataR_rdy = (lat_i2s_wclk == i2s_wclk) && lat_i2s_wclk == 0;

// always @(posedge mclk_bufg)
// begin
	// if (data_count == 0) begin
		// i2s_mux_valid <= 1;
	// end
	// if (i2s_dataL_rdy) begin
		// data_count <= data_count + 1;
		// case (data_count) 
	      // 0 : i2s_data_mux = channel0L; 
	      // 1 : i2s_data_mux = channel1L; 
	      // 2 : i2s_data_mux = channel2L; 
	      // 3 : i2s_data_mux = channel3L; 
	      // default : i2s_mux_valid = 0; 
	    // endcase 
	// end else if (i2s_dataR_rdy) begin
		// data_count <= data_count + 1;
		// case (data_count) 
	      // 0 : i2s_data_mux = channel0R; 
	      // 1 : i2s_data_mux = channel1R; 
	      // 2 : i2s_data_mux = channel2R; 
	      // 3 : i2s_data_mux = channel3R; 
	      // default : i2s_mux_valid = 0; 
	    // endcase 
	// end else begin
		// // transition between L/R
		// data_count <= 0;
	// end
// end

always @(posedge i2s_bclk) begin
	lat_i2s_wclk <= i2s_wclk;
end

//reg drdy;
//wire drdy_pulse = i2s_dataL_rdy ^ drdy;
//wire incrID = drdy_pulse == 1 && i2s_dataL_rdy == 1;
//always @(posedge i2s_bclk) begin
//	drdy <= i2s_dataL_rdy;
//	if (incrID == 1) begin
//		
//	end
//	if (i2s_dataL_rdy == 1) begin
//		
//	end
//end

reg [1:0] i2s_dataL_rdy_lat;
always @(posedge USBCLK_IN) begin
	i2s_dataL_rdy_lat[0] <= i2s_dataL_rdy;
	i2s_dataL_rdy_lat[1] <= i2s_dataL_rdy_lat[0];
	if (i2s_dataL_rdy_lat[1] ^ i2s_dataL_rdy_lat[0]) begin
		data_id <= data_id + 1;
		audio_data <= channel1L;
	end
end


endmodule
