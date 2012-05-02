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
parameter MEMBUFLEFT  = 79;
// parameter MEMBUFLEFT  = 119;

reg [MEMBUFLEFT:0] inputbuf     = 0;
reg                lat_i2s_wclk = 0;
reg [7:0]          data_id      = 0;
reg [_WIDTH-1:0]   audio_data   = 0;
reg [10:0]         overflow_lat = 0;
reg [0:0]          eof_lat      = 0;
reg [0:0]          stmen_lat    = 0;
reg [10:0]         flagb_lat    = 0;
reg                overflow_LED = 0;
reg                eof_LED      = 0;
reg                stmen_LED    = 0;
reg                flagb_LED    = 0;

wire [_WIDTH-1:0] channel0L, channel1L, channel2L, channel3L;
wire [_WIDTH-1:0] channel0R, channel1R, channel2R, channel3R;
wire detect0L, detect0R, detect1L, detect1R;
wire adc_clk;
wire adc_clk_rst;
wire adc_locked;
wire mclk_bufg;
wire i2s_bclk;
wire i2s_wclk;
wire zero;
wire eof;

assign zero = 0;
assign adc_clk_rst  = 0;
assign ADC_CLK_OUT  = adc_clk;
assign I2S_BCLK_OUT = i2s_bclk;
assign I2S_WCLK_OUT = i2s_wclk;

assign LEDATA = {STMEN, eof, overflow_LED, flagb_LED, detect0L, detect0R, detect1L, detect1R};

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
    .OVERFLOW(overflow),
	.INPUTBUF(inputbuf)
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

always @(posedge i2s_bclk) begin
	lat_i2s_wclk <= i2s_wclk;
end

// assign i2s_dataL_rdy = (lat_i2s_wclk == i2s_wclk) && lat_i2s_wclk == 1;
// assign i2s_dataR_rdy = (lat_i2s_wclk == i2s_wclk) && lat_i2s_wclk == 0;
reg [2:0] i2s_dataL_rdy_lat;
reg [2:0] i2s_dataR_rdy_lat;

reg [2:0] latch_wclk = 0;
reg [2:0] latch_bclk = 0;
reg [3:0] latch_chL = 0;
reg [3:0] latch_chR = 0;
assign i2s_dataL_rdy = latch_chL[3]==1 || latch_chL[2]==1 || latch_chL[1]==1;
assign i2s_dataR_rdy = latch_chR[3]==1 || latch_chR[2]==1 || latch_chR[1]==1;
always @(posedge mclk_bufg) begin
	latch_wclk[0] <= i2s_wclk;
	latch_wclk[1] <= latch_wclk[0];
	latch_wclk[2] <= latch_wclk[1];
	latch_bclk[0] <= i2s_bclk;
	latch_bclk[1] <= latch_bclk[0];
	latch_bclk[2] <= latch_bclk[1];
	if (latch_wclk == 3'b011) begin // WCLK rising edge
		latch_chL[0] <= 1;
	end else if (latch_wclk == 3'b100) begin
		latch_chR[0] <= 1;
	end
	if (latch_bclk == 3'b011) begin // BCLK rising edge
		latch_chL[0] <= 0;
		latch_chL[1] <= latch_chL[0];
		latch_chL[2] <= latch_chL[1];
		latch_chL[3] <= latch_chL[2];
		latch_chR[0] <= 0;
		latch_chR[1] <= latch_chR[0];
		latch_chR[2] <= latch_chR[1];
		latch_chR[3] <= latch_chR[2];
	end
end

//Transfer to USB clock before memory
reg [7 :0] buftest  = 8'h00;
reg [15:0] buftest1 = 16'h8000; // low
reg [15:0] buftest2 = 16'hF000; // mid-low
reg [15:0] buftest3 = 16'h0000; // mid-high
reg [15:0] buftest4 = 16'h7000; // high
reg [31:0] Rbuffer  = 0;//16bit
// reg [47:0] Rbuffer  = 0;//24bit
always @(posedge USBCLK_IN) begin
	i2s_dataL_rdy_lat[0] <= i2s_dataL_rdy;
	i2s_dataL_rdy_lat[1] <= i2s_dataL_rdy_lat[0];
	i2s_dataL_rdy_lat[2] <= i2s_dataL_rdy_lat[1];
	i2s_dataR_rdy_lat[0] <= i2s_dataR_rdy;
	i2s_dataR_rdy_lat[1] <= i2s_dataR_rdy_lat[0];
	i2s_dataR_rdy_lat[2] <= i2s_dataR_rdy_lat[1];
	// if (i2s_dataL_rdy_lat == 3'b011 || i2s_dataR_rdy_lat == 3'b011) begin//L & R channels
	if (i2s_dataL_rdy_lat == 3'b011)begin // L channels only
		data_id[0]    <= ~data_id[0];
		// buftest1[11:0] <= buftest1[11:0]+1;
		// buftest2[11:0] <= buftest2[11:0]+1;
		// buftest3[11:0] <= buftest3[11:0]+1;
		// buftest4[11:0] <= buftest4[11:0]+1;
	end else if (i2s_dataL_rdy_lat[1:0] == 2'b01) begin
		// audio_data <= channel1L;
		// inputbuf[MEMBUFLEFT:MEMBUFLEFT-15]    <= channel0L[23:8];
		// inputbuf[MEMBUFLEFT-16:MEMBUFLEFT-31] <= channel1L[23:8];
		// inputbuf    <= {16'h0000, buftest1, buftest2, inputbuf[MEMBUFLEFT : 48]};
		inputbuf    <= {16'h0000, channel0L[23:8], channel1L[23:8], Rbuffer};//16bit audio
		// inputbuf    <= {24'h000000, channel0L, channel1L, Rbuffer};//24bit audio
	end else if (i2s_dataR_rdy_lat[1:0] == 2'b01) begin
		// audio_data <= channel1R;
		// inputbuf[MEMBUFLEFT:MEMBUFLEFT-16]    <= channel0R[23:8];
		// inputbuf[MEMBUFLEFT-17:MEMBUFLEFT-32] <= channel1R[23:8];
		// Rbuffer    <= {buftest3, buftest4};
		Rbuffer    <= {channel0R[23:8], channel1R[23:8]}; //16bit audio
		// Rbuffer    <= {channel0R, channel1R}; //24bit audio
		// inputbuf[MEMBUFLEFT:MEMBUFLEFT-15]    <= buftest3;
		// inputbuf[MEMBUFLEFT-16:MEMBUFLEFT-31] <= buftest4;
	end
end

//Memory LEDS
always @(posedge USBCLK_IN) begin
   if (overflow == 1 && STMEN == 0) begin
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
   
   if (STMEN == 1) begin
      stmen_lat <= 1;
   end else if (stmen_lat != 0) begin
      stmen_lat <= stmen_lat + 1;
   end
   stmen_LED <= (stmen_lat != 0);
   
   if (overflow == 1 && STMEN == 1) begin
      flagb_lat <= 1;
   end else if (flagb_lat != 0) begin
      flagb_lat <= flagb_lat + 1;
   end
   flagb_LED <= (flagb_lat != 0);
end

endmodule
