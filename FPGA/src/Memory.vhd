--------------------------------------------------------------------------------
-- Company:       Digilent RO
-- Engineer:      Kovacs Laszlo - Attila
--
-- Create Date:   12:53:59 01/11/08
-- Module Name:   Memory - Behavioral
-- Project Name:  StreamIO
-- Description:   
--    Implements dualport synchronous memory with separate read and write ports. 
--    
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity Memory is
   Port ( 
      IFCLK    : in  std_logic;

      RST      : in  std_logic;

      DOWNBSY  : out std_logic;
      DOWNWR   : in  std_logic;
      DOWNACK  : out std_logic;
      DOWNDATA : in  std_logic_vector(7 downto 0);

		DATAID   : in std_logic_vector(7 downto 0);
	   AUDIO    : in std_logic_vector(23 downto 0);
		
      UPBSY    : out std_logic;
      UPRD     : in  std_logic;
      UPACK    : out std_logic;
      UPDATA   : out std_logic_vector(7 downto 0));
end Memory;

architecture Behavioral of Memory is

constant MEMSIZE  : integer := 512;

type MEMType is array (0 to MEMSIZE - 1) of std_logic_vector(7 downto 0);
signal MEMData : MEMType;

signal adrDownload, adrUpload, adrUpload2 : integer range 0 to MEMSIZE - 1;
signal s_lat_dataid  : std_logic_vector(7 downto 0);
signal s_detect_data : std_logic;
signal s_audio_load  : integer range 0 to 7;
signal s_lat_audio   : std_logic_vector(31 downto 0);
begin

   -- The Busy and Acknowledge signals are not used by this module.
   DOWNBSY <= '0';
   UPBSY <= '0';
   DOWNACK <= '1';
   UPACK <= '1';
   
   -- The read port of the synchronous memory is advanced when the read 
   -- signal is active. This way on the next clock cycle will output the 
   -- data from the next address.
   adrUpload2 <= adrUpload + 1 when UPRD = '1' else adrUpload;
	
--	s_detect_data <=  '1' when ((s_lat_dataid /= DATAID) or s_detect_data) else '0';
	
   process (IFCLK)
   begin
      if rising_edge(IFCLK) then
			s_lat_dataid <= DATAID;
			if (s_lat_dataid /= DATAID) then
				s_detect_data <= '1';
			else
				s_detect_data <= '0';
			end if;
			if (s_audio_load = 0) then
				s_lat_audio <= DATAID & AUDIO;
			end if;
			
         -- Download address counter incremented while write signal is active.
         if RST = '0' then
            adrDownload <= 0;
--         elsif DOWNWR = '1' then
--            adrDownload <= adrDownload + 1;
			elsif s_detect_data = '1' or s_audio_load > 0 then
				if (s_audio_load <= 3) then
					MEMData(adrDownload) <= s_lat_audio(31 downto 24);
					s_lat_audio <= s_lat_audio(23 downto 0) & x"00";
					adrDownload  <= adrDownload + 1;
					s_audio_load <= s_audio_load + 1;
				else
					s_audio_load <= 0;
				end if;
			end if;
         
         -- Upload address counter incremented while read signal is active.
         if RST = '0' then
            adrUpload <= 0;
         elsif UPRD = '1' then
            adrUpload <= adrUpload + 1;
         end if;
         
         -- When write signal is active write the input data to the download 
         -- address.
--         if DOWNWR = '1' then
--            MEMData(adrDownload) <= DOWNDATA;
--         end if;
			UPDATA <= MEMData(adrUpload2);
      end if;
   end process;

end Behavioral;
