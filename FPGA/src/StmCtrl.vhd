--------------------------------------------------------------------------------
-- Company:       Digilent RO
-- Engineer:      Kovacs Laszlo - Attila
--
-- Create Date:   12:53:59 01/11/08
-- Module Name:   StmCtrl - Behavioral
-- Project Name:  StreamIOEx
-- Description:   
--    Digilent Stream Data Transfer protocol interface for DstmIOEx API.
--    Provides separate download and upload ports to be connected to different 
--    design components. 
--    The busy signal stop the data transfer burst in the respective direction, 
--    but not the entire transfer process. 
--    The acknowledge signal activation enables the transfer of the current data 
--    byte, or pauses the transfer. While the acknowledge signal is not activated 
--    the download write or upload read signals will be held active. 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity StmCtrl is
    Port ( 
      IFCLK    : in  std_logic;
      STMEN    : in  std_logic;
      
      FLAGA    : in  std_logic;
      FLAGB    : in  std_logic;
      SLRD     : out std_logic;
      SLWR     : out std_logic;
      SLOE     : out std_logic;
      FIFOADR  : out std_logic_vector(1 downto 0);
      PKTEND   : out std_logic;

      USBDB       : inout std_logic_vector(7 downto 0);
            
      -- stop the download transfer burst
      DOWNBSY  : in  std_logic;
      DOWNWR   : out std_logic;
      -- pause the download transfer 
      DOWNACK  : in  std_logic;
      DOWNDATA : out std_logic_vector(7 downto 0);

      -- stop the upload transfer burst
      UPBSY    : in  std_logic;
      UPRD     : out std_logic;
      -- pause the upload transfer
      UPACK    : in  std_logic;
      UPDATA   : in  std_logic_vector(7 downto 0));
end StmCtrl;

architecture Behavioral of StmCtrl is

type stateType is (stIdle, stWait, stDownload, stUpload, stPktEnd);

signal stCur, stNext : stateType := stIdle;

-- Active low FIFO cotnrol signals
signal nSLRD, nSLWR : std_logic;

begin
   
   
   -- Drive the FIFO control signals according the state machine output 
   -- signals while Stream mode is enabled.

   SLRD  <= 'Z' when STMEN = '0' else nSLRD;

   SLWR  <= 'Z' when STMEN = '0' else nSLWR;
   
   PKTEND <= 'Z' when STMEN = '0' else '1';

   SLOE  <= 'Z' when STMEN = '0' else nSLRD;

   -- Tristate the FIFO address signals while stream mode is not enabled.
   -- When the nSLRD signal is active select download otherwise the upload FIFO.
   FIFOADR <= "ZZ" when STMEN = '0' else "00" when nSLRD = '0' else "10";

   -- Drive the data bus only when the nSLWR signal is active.
   USBDB    <= UPDATA when nSLWR = '0' and STMEN = '1' else (others => 'Z');


   -- The download data is the USB Data Bus input.
   DOWNDATA <= USBDB;
   
   -- Synchronization process of the state machine.
   SynchronizationProcess: process(IFCLK)
   begin
      if rising_edge(IFCLK) then
         if STMEN = '0' then
            stCur <= stIdle;
         else
            stCur <= stNext;
         end if;
      end if;
   end process;

   -- Decoding the outputs of state machine accoring the state and flags.
   OutputDecode: process(stCur, FLAGA, FLAGB, DOWNACK, UPACK)
   begin
      
      -- Default states of the control signals.
      nSLRD    <= '1';
      nSLWR    <= '1';
      DOWNWR   <= '0';
      UPRD     <= '0';
      
      case(stCur) is

         -- In Download state the DOWNWR signal is activated while the download 
         -- FIFO is not empty.
         -- When the DOWNWR signals is acknowledged with DOWNACK signal the nSLRD 
         -- signal is activated to read data from USB download FIFO.
         when stDownload =>
            if FLAGA = '0' then
               DOWNWR   <= '1';
               if DOWNACK = '1' then
                  nSLRD  <= '0';
               end if;
            end if;
               
         -- In Upload state the UPRD signal is activated while the upload FIFO 
         -- is not full and the transfer counter is not expired.
         -- When the UPRD signals is acknowledged with UPACK signal the nSLWR 
         -- signal is activated to write data to the USB FIFO.
         when stUpload  =>
            if FLAGB = '0' then
               UPRD   <= '1';
               if UPACK = '1' then
                  nSLWR   <= '0';
               end if;
            end if;       

         when others =>

      end case;
   end process;

   -- Decide the next state accring the current state and the input signals.
   NEXT_STATE_DECODE: process(stCur, STMEN, FLAGA, FLAGB, DOWNBSY, UPBSY)
   begin
      
      -- Stay in current state if not given otherwise in the following.
      stNext <= stCur;
      
      case stCur is
         
         -- From Idle state go to download when the download FIFO is not empty 
         -- and the DOWNBSY signal is not active or to upload state when the 
         -- upload FIFO is not full, the UPBSY signal is not active and the 
         -- transfer counter is not expired.
         when stIdle  =>
            if FLAGA = '0' and DOWNBSY = '0' then
               stNext <= stDownload;
            elsif FLAGB = '0' and UPBSY = '0' then
               stNext <= stUpload;
            end if;
         
         -- From download state go back to the Idle state when the download 
         -- FIFO becomes empty or the DOWNBSY signal is activated.
         when stDownload   =>
            if FLAGA = '1' or DOWNBSY = '1' then
               stNext <= stIdle;
            end if;
         
         -- From upload state go to the PKTEND state when the transfer counter 
         -- expires or go back to the Idle state when the upload FIFO
         -- becomes full or the UPBSY signal is activated.
         when stUpload   =>
            if FLAGB = '1' or UPBSY = '1' then
               stNext <= stIdle;
            end if;

         when others  => 
            stNext <= stIdle;

      end case;

   end process;


end Behavioral;
