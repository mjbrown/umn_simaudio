`timescale 1ns / 1ps

module tc_i2s_data;
	// integer file;
	parameter _WIDTH = 24;
		
	reg i2s_bclk;
	reg i2s_wclk;
	reg lat_wclk;
	reg din0,din1,din2;
	wire [_WIDTH-1:0]  dataR0,dataR1,dataR2;
	wire [_WIDTH-1:0]  dataL0,dataL1,dataL2;
	wire detectL0,detectL1,detectL2;
	wire detectR0,detectR1,detectR2;
	
	reg [_WIDTH-1:0] squarewave;
	reg [_WIDTH-1:0] sawtooth;
	reg [_WIDTH-1:0] sawtoothN;
	reg [_WIDTH-1:0] clkDiv;
	reg dataRdy;
	reg start;
	
	I2S_Data uut0 (
		.i2s_bclk(i2s_bclk),
	    .i2s_wclk(i2s_wclk),
	    .din     (din0),
	    .dataL   (dataL0),
	    .dataR   (dataR0),
	    .detectL (detectL0),
	    .detectR (detectR0)
	);
	
	I2S_Data uut1 (
		.i2s_bclk(i2s_bclk),
	    .i2s_wclk(i2s_wclk),
	    .din     (din1),
	    .dataL   (dataL1),
	    .dataR   (dataR1),
	    .detectL (detectL1),
	    .detectR (detectR1)
	);
	
	I2S_Data uut2 (
		.i2s_bclk(i2s_bclk),
	    .i2s_wclk(i2s_wclk),
	    .din     (din2),
	    .dataL   (dataL2),
	    .dataR   (dataR2),
	    .detectL (detectL2),
	    .detectR (detectR2)
	);
	
	initial begin
		i2s_bclk = 0;
		i2s_wclk = 0;
		lat_wclk = 0;
		din0     = 0;
		din1     = 0;
		din2     = 0;
		start    = 0;
		squarewave = 0;
		sawtooth   = 0;
		sawtoothN  = sawtooth + 1;
		#100;
	end
	
	parameter PERIOD = 20;
	always begin
		#(PERIOD/2) i2s_bclk = ~i2s_bclk;
	end
	
	// I2S wclk latches at positive edge of bclk
	always @(posedge i2s_bclk)
	begin
		lat_wclk <= i2s_wclk;
		dataRdy  <= i2s_wclk ^ lat_wclk;
		start    <= (i2s_wclk ^ lat_wclk) | start;
	end
	
	//Set clock div for wclk
	always @(posedge i2s_bclk) begin
		if (clkDiv <= _WIDTH-2) begin
			clkDiv <= clkDiv + 1;
		end else begin
			clkDiv <= 0;
		end
	end
	
	//Generate wclk din1 and din2
	always @(negedge i2s_bclk) begin
		if (clkDiv == 0) begin
			i2s_wclk <= ~i2s_wclk;
		end
		din1 <= ~i2s_wclk;
		din2 <= ~din2;
	end
	
	always @(negedge i2s_bclk)
	begin
		if (lat_wclk == 1)
		begin
			din0 <= squarewave[0];
			squarewave <= {~squarewave[0],squarewave[_WIDTH-1:1]};
		end else if (start) begin
			din0 <= sawtooth[_WIDTH-1];
			sawtooth  <= {sawtooth[_WIDTH-2:0], sawtooth[_WIDTH-1]};
			// sawtoothN <= {sawtooth[0] ,sawtoothN[_WIDTH-1:1]};
		end
		if (start && lat_wclk == 1 && dataRdy == 1) begin
			sawtooth  <= sawtooth  + 1;
			// sawtoothN <= sawtoothN + 2;
		end
	end
endmodule

