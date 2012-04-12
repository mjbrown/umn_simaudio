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
   Port ( 
      IFCLK    : in  std_logic;

      RST      : in  std_logic;

	  OVERFLOW : out std_logic;
	  EOF      : out std_logic;
	  
      -- DOWNBSY  : out std_logic;
      -- DOWNWR   : in  std_logic;
      -- DOWNACK  : out std_logic;
      -- DOWNDATA : in  std_logic_vector(7 downto 0);
	  
	  DATAID   : in std_logic_vector(7 downto 0);
	  AUDIO    : in std_logic_vector(23 downto 0);
		
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
 
constant SAMPLE_BYTES : integer := 1;-- Number of bytes in a sample
constant MEMWIDTH     : integer := 8;-- Number of bits for BRAM interface
-- 2^13 = 8192 = Spartan3e100 BRAM max size
-- constant MEMSIZE    : integer := (8192/SAMPLE_BYTES) * SAMPLE_BYTES;
constant MEMSIZE    : integer := (8192);

signal memOut   : std_logic_vector(MEMWIDTH-1 downto 0);
signal memIn    : std_logic_vector(MEMWIDTH-1 downto 0);
signal memWrite : std_logic := '0';

type MEMType is array (0 to MEMSIZE - 1) of std_logic_vector(MEMWIDTH-1 downto 0);
signal MEMData : MEMType;


signal difference1, difference2, memInAdr, adrUploadPtr, adrUpload, memOutAdr : unsigned(num_bits(MEMSIZE-1)-1 downto 0) := (others => '0');-- range 0 to MEMSIZE - 1;
signal s_available     : std_logic_vector(15 downto 0) := (others => '0');
signal u_available     : unsigned(15 downto 0)         := (others => '0');
signal u_remaining     : unsigned(15 downto 0)         := (others => '0');

signal upCount         : unsigned(3 downto 0) := (others => '0');
signal s_audio_load    : unsigned(3 downto 0) := (others => '0');
signal s_send_head     : std_logic_vector(2 downto 0) := (others => '0');

signal s_detect_data   : std_logic := '0';
signal s_lat_dataid    : std_logic_vector(DATAID'length - 1 downto 0)  := (others => '0');
signal s_lat_down_data : std_logic_vector(AUDIO'length + DATAID'length - 1 downto 0)  := (others => '0');

begin
   -- The Busy and Acknowledge signals are not used by this module.
   -- DOWNBSY <= '0';
   -- DOWNACK <= '1';
   UPBSY   <= '0';
   UPACK   <= '1';
   
   memIn <= s_lat_down_data(s_lat_down_data'length-1 downto s_lat_down_data'length-MEMWIDTH);
   
   -- The read port of the synchronous memory is advanced when the read 
   -- signal is active. This way on the next clock cycle will output the 
   -- data from the next address.
   
    -- Memory interface
    memWrite <= '1' when s_detect_data = '1' or (s_audio_load > 0 and s_audio_load < SAMPLE_BYTES) else '0';
    memOutAdr <= adrUpload + 1 when unsigned(s_send_head) >= 1 else adrUpload;
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
				s_lat_down_data <=  AUDIO & DATAID;
			elsif (s_audio_load >= SAMPLE_BYTES) then
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
			-- EOF means no more data is currently available.
			if (u_remaining > 0) then
				EOF <= '0';
			else 
				EOF <= '1';
			end if;
			
			-- RESET or not reading
			if (RST = '0' OR UPRD = '0') then
				-- Overflow (occurs when not reading to keep from moving pointers during upload)
				-- This means that there needs to be some pad space (3 samples should be fine)
				if (u_available >= MEMSIZE - 3*SAMPLE_BYTES) then
					adrUploadPtr <= adrUploadPtr + SAMPLE_BYTES*6;
					OVERFLOW <= '1';
				else
					OVERFLOW <= '0';
				end if;
				s_available(u_available'length-1 downto 0)  <= std_logic_vector(u_available);
			end if;
			
			-- RESET
			if (RST = '0') then
				u_remaining <= u_available;
				adrUpload   <= adrUploadPtr;
				upCount     <= (others => '0');
				s_send_head <= (others => '0');
				UPDATA <= s_available(15 downto 8);
			elsif UPRD = '1' then
				s_send_head <= s_send_head(s_send_head'length - 2 downto 0) & '1';
				
				-- Upload address counter incremented while read signal is active.
				-- Only increment address if data and not the header is being sent.
				if (unsigned(s_send_head) >= 1 and u_remaining > 0) then
					adrUpload <= adrUpload + 1;
					u_remaining <= u_remaining - 1;
					-- Count samples/partial samples
					if (upCount < SAMPLE_BYTES) then
						upCount <= upCount + 1;
					else
						--Only increment pointer when full sample has been uploaded
						adrUploadPtr <= adrUploadPtr + upCount;
						upCount <= (others => '0');
					end if;
				end if;
				-- Set upload data to either memory or header
				if (unsigned(s_send_head) = 0) then
					-- UPDATA <= s_available(15 downto 8);
					-- elsif (unsigned(s_send_head) = 1) then
					UPDATA <= s_available(7 downto 0);
				else
					UPDATA <= memOut;
				end if;				
			end if;
      end if;
   end process;

end Behavioral;
