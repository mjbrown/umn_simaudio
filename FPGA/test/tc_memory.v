`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   05:08:05 04/18/2012
// Design Name:   Memory
// Module Name:   D:/Documents/Class/EE 4951W Senior Design/Xilinx/tc_memory.v
// Project Name:  Xilinx
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Memory
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tc_memory;
	parameter MEMBUFLEFT  = 79;
	parameter testbufleft = 79;
	
	reg        dclk         = 0;
	reg [31:0] TC_READCOUNT = 0;
	reg [15:0] TC_AVAILABLE = 0;
	reg [15:0] TC_REMAINING = 0;
	reg [15:0] TC_DATA0 = 0;
	reg [15:0] TC_DATAN = 0;
	reg [15:0] buftest1 = 16'h1000;
	reg [15:0] buftest2 = 16'h2000;
	reg [15:0] buftest3 = 16'h3000;
	reg [15:0] buftest4 = 16'h4000;
	reg [testbufleft:0] buffer = 0;
	
	// Inputs
	reg IFCLK = 0;
	reg RST = 0;
	reg [7:0] DATAID = 0;
	reg [23:0] AUDIO = 24'h010203;
	reg UPRD = 0;
	reg [MEMBUFLEFT:0] INPUTBUF = 0;
	
	// Outputs
	wire OVERFLOW;
	wire EOF;
	wire UPBSY;
	wire UPACK;
	wire [7:0] UPDATA;

	// Instantiate the Unit Under Test (UUT)
	Memory #(.MEMSIZE(512)) uut (
		.IFCLK(IFCLK), 
		.RST(RST), 
		.OVERFLOW(OVERFLOW), 
		.EOF(EOF), 
		.DATAID(DATAID), 
		.AUDIO(AUDIO), 
		.UPBSY(UPBSY), 
		.UPRD(UPRD), 
		.UPACK(UPACK), 
		.UPDATA(UPDATA),
		.INPUTBUF(INPUTBUF)
	);

	
	initial begin
		#100
		// INPUTBUF = 0;
		
		//read before overflow
		#1000;
		RST <= 1;
		#1000;
		UPRD <= 1;
		wait(EOF == 1);
		#100;
		#100;
		
		//wait for full buffer
		UPRD <= 0;
		wait(OVERFLOW == 1);
		RST <= 0;
		#100;
		
		//alignment test
		RST <= 1;
		#100;
		UPRD <= 1;
		wait(TC_READCOUNT > 0 && UPDATA == 8'h01);
		UPRD <= 0;
		RST  <= 0;
		#100
		UPRD <= 1;
		RST  <= 1;
		wait(UPDATA == 8'h02);
		UPRD <= 0;
		RST  <= 0;
		#100
		UPRD <= 1;
		RST  <= 1;
		wait(UPDATA == 8'h03);
		UPRD <= 0;
		RST  <= 0;
		#100
		UPRD <= 1;
		RST  <= 1;
		wait(UPDATA == 8'h04);
		UPRD <= 0;
		RST  <= 0;
		#100
		UPRD <= 1;
		RST  <= 1;
		wait(UPDATA == 8'h05);
		UPRD <= 0;
		RST  <= 0;
		#100
		UPRD <= 1;
		RST  <= 1;
		wait(UPDATA == 8'h06);
		UPRD <= 0;
		RST  <= 0;
		#100
		UPRD <= 1;
		RST  <= 1;
		wait(UPDATA == 8'h07);
		UPRD <= 0;
		RST  <= 0;
		#100
		
		//complete read
		#1000;
		UPRD <= 0;
		#10
		RST  <= 0;
		wait(OVERFLOW == 1);
		RST <= 1;
		UPRD <= 1;
		wait(EOF == 1);
		#105;
		RST <= 0;
		UPRD <= 0;
		
		#1000
		#1000
		#1000
		#1000
		RST <= 1;
		UPRD <= 1;
		wait(EOF == 1);
		#114;
		RST <= 0;
		UPRD <= 0;
		#1000
		#1000
		#1000
		#1043
		RST <= 1;
		UPRD <= 1;
		wait(EOF == 1);
		#134;
		RST <= 0;
		UPRD <= 0;
		#1000
		#1000
		#1000
		#534
		RST <= 1;
		UPRD <= 1;
		wait(EOF == 1);
		#93;
		RST <= 0;
		UPRD <= 0;
		#1000
		#1000
		#1000
		#3312
		RST <= 1;
		UPRD <= 1;
		wait(EOF == 1);
		#164;
		RST <= 0;
		UPRD <= 0;
		#1000
		#1000
		#1000
		#2421
		RST <= 1;
		UPRD <= 1;
		wait(EOF == 1);
		#127;
		RST <= 0;
		UPRD <= 0;
		//loop read
		
		
		
		// Add stimulus here

	end
    
	parameter PERIOD = 20.833;
	always begin
		#(PERIOD/2) IFCLK = ~IFCLK;
	end
	
	always begin
		#(PERIOD*24/2) dclk = ~dclk;
	end
	
	reg [2:0] dataRdy = 0;
	always @(posedge dclk) begin
		AUDIO  <= AUDIO + 24'h010101;
		dataRdy[0]    <= 1;
		buftest1[11:0] <= buftest1[11:0]+1;
		buftest2[11:0] <= buftest2[11:0]+1;
		buftest3[11:0] <= buftest3[11:0]+1;
		buftest4[11:0] <= buftest4[11:0]+1;
		// INPUTBUF   <= {16'h0000, 16'h1111, 16'h2222,  buffer[testbufleft : 48]};
		INPUTBUF <= {16'h0000, 16'h1111, 16'h2222, INPUTBUF[MEMBUFLEFT : 48]};
	end
	
	always @(negedge dclk) begin
		// buffer   <= {16'h3333, 16'h4444,   buffer[testbufleft : 32]};
		INPUTBUF <= {16'h3333, 16'h4444,  INPUTBUF[MEMBUFLEFT  : 32]};
	end
	
	always @(posedge IFCLK) begin
		dataRdy[0] <= 0;
		dataRdy[1] <= dataRdy[0];
		dataRdy[2] <= dataRdy[1];
		if (dataRdy[2:1] == 2'b01) begin
			DATAID <= DATAID + 1;
		end
	end
	
	
	always @(posedge IFCLK) begin
		if (UPRD == 1) begin
			TC_READCOUNT <= TC_READCOUNT + 1;
			if (TC_READCOUNT <= 1) begin
				TC_AVAILABLE <= {TC_AVAILABLE[7:0], UPDATA};
				TC_REMAINING <= {TC_REMAINING[7:0], UPDATA};
			// end else if (TC_READCOUNT <= 3) begin
				// address <= {address[7:0], UPDATA};
			end else begin
				TC_REMAINING <= TC_REMAINING - 1;
			end
			if (TC_READCOUNT <= 3) begin
				TC_DATA0 <= {TC_DATA0[7:0], UPDATA};
			end
		end else if (RST == 0) begin
			TC_READCOUNT <= 0;
		end
	end
endmodule

