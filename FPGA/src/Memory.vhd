--------------------------------------------------------------------------------
-- Company:       Digilent RO
-- Engineer:      Kovacs Laszlo - Attila
--
-- Create Date:   12:53:59 01/11/08
-- Module Name:   Memory - Behavioral
-- Project Name:  StreamIO | UMN SimAudio
-- Description:   
--    Implements dualport synchronous memory with separate read and write ports. 
--    Modified for UMN SimAudio project.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.STD_LOGIC_ARITH.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity Memory is
   generic (
        MEMSIZE        : integer := 8192;
        BLOCK_BYTES    : integer := 10 -- Number of bytes that come in at once
   );
   Port ( 
      IFCLK    : in  std_logic;

      RST      : in  std_logic;

	  OVERFLOW : out std_logic;
	  EOF      : out std_logic;
	  
      DOWNBSY  : out std_logic;
      -- DOWNWR   : in  std_logic;
      DOWNACK  : out std_logic;
      -- DOWNDATA : in  std_logic_vector(7 downto 0);
	  
	  DATAID   : in std_logic_vector(7 downto 0);  
	  AUDIO    : in std_logic_vector(23 downto 0); -- Used for single channel tests
	  INPUTBUF : in std_logic_vector(79 downto 0);
	  -- INPUTBUF : in std_logic_vector(119 downto 0);
	  
      UPBSY    : out std_logic;
      UPRD     : in  std_logic;
      UPACK    : out std_logic;
      UPDATA   : out std_logic_vector(7 downto 0));
end Memory;

architecture Behavioral of Memory is

-- Calculate number of bits required to represent all addresses
function num_bits(n: natural) return natural is begin
	if n > 1 then
		return 1 + num_bits(n / 2);
	else 
		return 1;
	end if;
end num_bits;

constant MEMWIDTH     : integer := 8;-- Number of bits for BRAM interface
-- 2^13 = 8192 = Spartan3e100 BRAM max size

signal memOut   : std_logic_vector(MEMWIDTH-1 downto 0);
signal memIn    : std_logic_vector(MEMWIDTH-1 downto 0);
signal memWrite : std_logic := '0';
type MEMType is array (0 to MEMSIZE - 1) of std_logic_vector(MEMWIDTH-1 downto 0);
signal MEMData : MEMType;

signal difference1, difference2, memInAdr, adrUploadPtr, adrUpload, memOutAdr : unsigned(num_bits(MEMSIZE-1)-1 downto 0) := (others => '0');-- range 0 to MEMSIZE - 1;
signal s_available     : std_logic_vector(15 downto 0) := (others => '0'); -- latch for header
signal u_available     : unsigned(15 downto 0)         := (others => '0'); -- current count
signal u_remaining     : unsigned(15 downto 0)         := (others => '0'); -- latches during RST, counts down when reading

signal upCount         : unsigned(7 downto 0) := (others => '0');
signal s_audio_load    : unsigned(3 downto 0) := (others => '0');


signal lat_eof         : std_logic := '0';
signal lat_rst         : std_logic := '0';
signal s_detect_data   : std_logic := '0';
signal s_lat_dataid    : std_logic_vector(DATAID'length - 1 downto 0)  := (others => '0');
signal s_lat_down_data : std_logic_vector(INPUTBUF'length - 1 downto 0)  := (others => '0');
signal s_memAdrHeader  : std_logic_vector(15 downto 0);

signal   s_send_state   : unsigned(3 downto 0) := (others => '0');
constant SEND_HEAD      : unsigned(s_send_state'range) := TO_UNSIGNED( 0,s_send_state'length);
constant SEND_AVAILABLE : unsigned(s_send_state'range) := TO_UNSIGNED( 1,s_send_state'length);
constant SEND_DATA      : unsigned(s_send_state'range) := TO_UNSIGNED( 2,s_send_state'length);
constant SEND_EOF       : unsigned(s_send_state'range) := TO_UNSIGNED( 3,s_send_state'length);


signal memDbg   : unsigned(memOutAdr'length - 1 downto 0) := (others => '0');

begin
   -- Do not acknowledge downstream, it is always busy/disabled
   DOWNBSY <= '1';
   DOWNACK <= '0';
   -- Acknowledge upstream
   UPBSY   <= '0';
   UPACK   <= '1';
   
   memIn <= s_lat_down_data(s_lat_down_data'length-1 downto s_lat_down_data'length-MEMWIDTH);
   
   -- The read port of the synchronous memory is advanced when the read 
   -- signal is active. This way on the next clock cycle will output the 
   -- data from the next address.
   
    -- Memory interface
    memWrite <= '1' when s_detect_data = '1' or (s_audio_load > 0 and s_audio_load < BLOCK_BYTES) else '0';
    memOutAdr <= adrUpload + 1 when s_send_state = SEND_DATA else adrUpload;
	-- memOutAdr <= adrUpload;
	--MEMORY OUTPUT // latched into UPDATA so don't need to latch here.
	
    process (IFCLK) begin
		if rising_edge(IFCLK) then
			-- Latched?
			memOut <= MEMData(TO_INTEGER(memOutAdr));
			-- Download address counter incremented while write signal is active.
			-- MEMORY INPUT
			if s_detect_data = '1' or s_audio_load > 0 then
				if (memWrite = '1') then
					MEMData(TO_INTEGER(memInAdr)) <= memIn;
					memInAdr  <= memInAdr + 1;
				end if;
			end if;
			if s_detect_data = '1' or s_audio_load > 0 then
				if (memWrite = '1') then
					memDbg  <= memInAdr;
				end if;
			end if;
		end if;
    end process;
   
    -- Detect data and writing
    process (IFCLK) begin
        if rising_edge(IFCLK) then
			-- Detect data
			s_lat_dataid <= DATAID;
			if (s_lat_dataid /= DATAID) then
				s_detect_data <= '1';
			else
				s_detect_data <= '0';
			end if;
			
			if (s_audio_load = 0 and s_detect_data = '0') then
				-- s_lat_down_data <= AUDIO & DATAID & x"00";
				s_lat_down_data <= INPUTBUF(INPUTBUF'length - 1 downto INPUTBUF'length - s_lat_down_data'length);
				-- s_lat_down_data <= std_logic_vector(resize(memInAdr,24)) & std_logic_vector(resize(memInAdr + 3,24));   -- 24 BIT MEMORY TEST
				-- s_lat_down_data <= std_logic_vector(TO_UNSIGNED(      0,16))
				-- s_lat_down_data <= std_logic_vector(resize(memInAdr    ,16))
				                 -- & std_logic_vector(resize(memDbg + 2,16))
								 -- & std_logic_vector(resize(memDbg + 4,16))
								 -- & std_logic_vector(resize(memDbg + 6,16))
								 -- & std_logic_vector(resize(memDbg + 8,16)); -- 16 BIT MEMORY TEST
				-- s_lat_down_data <=  std_logic_vector(memInAdr(7 downto 0)) & x"00" & x"0000" & x"0000"; -- LSB MEMORY TEST
				-- s_lat_down_data <=  std_logic_vector(memInAdr(memInAdr'length-1 downto memInAdr'length-8)) & x"000000"; -- MSB MEMORY TEST
			elsif (s_audio_load >= BLOCK_BYTES) then
				s_audio_load <= (others => '0');
			elsif (s_detect_data = '1' or s_audio_load > 0) then
				s_lat_down_data <= s_lat_down_data(s_lat_down_data'length - 9 downto 0) & x"00"; --shift
				s_audio_load <= s_audio_load + 1;
			end if;
		end if;
	end process;
	
	-- Output
    difference1 <= memInAdr - memOutAdr;
    difference2 <= memInAdr + TO_UNSIGNED(MEMSIZE-1, difference2'length) - 1 - memOutAdr;
    u_available(difference1'length-1 downto 0)  <= difference1 when (memInAdr >= memOutAdr) else difference2;
	process (IFCLK) begin
        if rising_edge(IFCLK) then
			lat_rst <= RST;
			-- EOF means no more data is currently available.
			if (RST = '0') then
				lat_eof <= '0';
			elsif (u_remaining > 0) then
				lat_eof <= '0';
			else
				lat_eof <= '1';
			end if;
			EOF <= lat_eof;
			
			-- RESET or not reading
			if (RST = '0') then
				-- Overflow (occurs when not reading to keep from moving pointers during upload)
				-- This means that there needs to be some pad space (3 samples should be fine)
				if (u_available >= MEMSIZE - 1   -  5*BLOCK_BYTES) then
					adrUploadPtr <= adrUploadPtr + 10*BLOCK_BYTES;
					adrUpload    <= adrUpload    + 10*BLOCK_BYTES;
					OVERFLOW <= '1';
				else
					adrUpload <= adrUploadPtr;
					OVERFLOW <= '0';
				end if;
			else -- STMIO is active
				if (u_available >= MEMSIZE - 1 - BLOCK_BYTES) then
					OVERFLOW <= '1';
				else
					OVERFLOW <= '0';
				end if;
			end if;
			
			-- RESET
			if (RST = '0') then
				if (lat_rst = '1') then
					-- adrUploadPtr <= adrUploadPtr - 3*BLOCK_BYTES;
				end if;
				upCount        <= TO_UNSIGNED(1,upCount'length);
				s_send_state   <= SEND_HEAD;
				s_memAdrHeader <= std_logic_vector(memOutAdr);
				u_remaining    <= u_available;
				s_available    <= std_logic_vector(u_available);
				UPDATA         <= std_logic_vector(u_available(15 downto 8));
			elsif UPRD = '1' then				
				-- Upload address counter incremented while read signal is active.
				-- Only increment address if data and not the header is being sent.
				if (s_send_state = SEND_DATA and u_remaining > 0) then
					adrUpload <= adrUpload + 1;
					u_remaining <= u_remaining - 1;
					
					-- Count samples/partial samples
					if (upCount < BLOCK_BYTES) then
						upCount <= upCount + 1;
					else
						--Only increment pointer when full sample has been uploaded
						adrUploadPtr <= adrUploadPtr + upCount;
						upCount <= TO_UNSIGNED(1,upCount'length);
					end if;
				end if;
				
				-- Set upload data to either memory or header
				if (s_send_state = SEND_HEAD) then
					s_send_state <= SEND_DATA;
					-- UPDATA <= s_available(15 downto 8);
					-- elsif (unsigned(s_send_state) = 1) then
					UPDATA <= s_available(7 downto 0);
				-- elsif (unsigned(s_send_state) = 1) then
					-- UPDATA <= s_memAdrHeader(15 downto 8);
				-- elsif (unsigned(s_send_state) = 3) then
					-- UPDATA <= s_memAdrHeader(7 downto 0);
				elsif (lat_eof = '1') then
					UPDATA <= (others => '0');
				else
					UPDATA <= memOut;
					-- UPDATA <= std_logic_vector(memOutAdr(7 downto 0));
				end if;				
			end if;
      end if;
   end process;

end Behavioral;
