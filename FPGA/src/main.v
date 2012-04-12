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
    input  I2S_DATA0_IN, //JA1
    output I2S_BCLK_OUT, //JA2
    output I2S_WCLK_OUT, //JA3
    output ADC_CLK_OUT,  //JA4
    input  I2S_DATA1_IN, //JB1

    output [7:0] LEDATA,
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
parameter _WIDTH      = 24;

reg lat_i2s_wclk = 0;
reg [DATA_BLOCKS*2-1:0] data_count = 0;
reg [_WIDTH - 1:0] i2s_data_mux = 0;
reg i2s_mux_valid = 0;

reg  [7:0]        data_id    = 0;
reg  [_WIDTH-1:0] audio_data = 0;

reg [10:0] overflow_lat, eof_lat = 0;
reg overflow_LED, eof_LED        = 0;

wire [_WIDTH-1:0] channel0L, channel1L, channel2L, channel3L;
wire [_WIDTH-1:0] channel0R, channel1R, channel2R, channel3R;
wire detect0L, detect0R, detect1L, detect1R;
wire adc_clk;
wire adc_clk_rst;
wire adc_locked;
wire dpi_btn;
wire dpi_ldg;
wire dpi_led;
wire mclk_bufg;
wire i2s_bclk;
wire i2s_wclk;
wire zero;

assign zero = 0;
assign adc_clk_rst  = 0;
assign ADC_CLK_OUT  = adc_clk;
assign I2S_BCLK_OUT = i2s_bclk;
assign I2S_WCLK_OUT = i2s_wclk;

assign LEDATA = {overflow_LED, eof_LED, zero, zero, detect0L, detect0R, detect1L, detect1R};

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
    .AUDIO(audio_data),
    .EOF(eof),
    .OVERFLOW(overflow)
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
    .dataR(channel0R),
    .detectL(detect0L),
    .detectR(detect0R)
 );
 I2S_Data i2s_data_1(
    .i2s_bclk(i2s_bclk),
    .i2s_wclk(i2s_wclk),
    .din(I2S_DATA1_IN),
    .dataL(channel1L),
    .dataR(channel1R),
    .detectL(detect1L),
    .detectR(detect1R)
 );
// I2S_Data i2s_data_2 (
    //.i2s_bclk(i2s_bclk),
    //.i2s_wclk(i2s_wclk),
    //.din(I2S_din2),
    //.dataL(channel2L),
    //.dataR(channel2R)
// );
// I2S_Data i2s_data_3 (
    //.i2s_bclk(i2s_bclk),
    //.i2s_wclk(i2s_wclk),
    //.din(I2S_din3),
    //.dataL(channel3L),
    //.dataR(channel3R)
// );

// I2S MUX
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

assign i2s_dataL_rdy = (lat_i2s_wclk == i2s_wclk) && lat_i2s_wclk == 1;
assign i2s_dataR_rdy = (lat_i2s_wclk == i2s_wclk) && lat_i2s_wclk == 0;
reg [1:0] i2s_dataL_rdy_lat;

//Transfer to USB clock before memory
always @(posedge USBCLK_IN) begin
	i2s_dataL_rdy_lat[0] <= i2s_dataL_rdy;
	i2s_dataL_rdy_lat[1] <= i2s_dataL_rdy_lat[0];
	if (i2s_dataL_rdy_lat[1] == 0 && i2s_dataL_rdy_lat[0] == 1) begin
		data_id    <= data_id + 1;
		audio_data <= channel1L;
	end
end

//Memory LEDS
always @(posedge USBCLK_IN) begin
   if (overflow == 1) begin
      overflow_lat <= 1;
   end else if (overflow_lat != 0) begin
      overflow_lat <= overflow_lat + 1;
   end
   overflow_LED <= (overflow_lat != 0);
   
   if (eof == 1) begin
      eof_lat <= 1;
   end else if (eof_lat != 0) begin
      eof_lat <= eof_lat + 1;
   end
   eof_LED <= (eof_lat != 0);
end

endmodule
