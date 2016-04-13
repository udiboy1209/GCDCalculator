library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.StreamComponents.all;

entity GCDScanTest is
  port (
         TDI : in std_logic; -- Test Data In
         TDO : out std_logic; -- Test Data Out
         TMS : in std_logic; -- TAP controller signal
         TCLK : in std_logic; -- Test clock
         TRST : in std_logic; -- Test reset
         LED : out std_logic_vector(5 downto 0)
       );
end GCDScanTest;

architecture Struct of GCDScanTest is
  -- declare Scan-chain component.
  component Scan_Chain is
  generic (
    in_pins : integer; -- Number of input pins
    out_pins : integer -- Number of output pins
  );
  port (
         TDI : in std_logic; -- Test Data In
         TDO : out std_logic; -- Test Data Out
         TMS : in std_logic; -- TAP controller signal
         TCLK : in std_logic; -- Test clock
         TRST : in std_logic; -- Test reset
         dut_in : out std_logic_vector(in_pins-1 downto 0); -- Input for the DUT
         dut_out : in std_logic_vector(out_pins-1 downto 0) -- Output from the DUT
       );
  end component;

  signal clk,reset: std_logic;

  signal scan_chain_parallel_in : std_logic_vector(19 downto 0);
  signal scan_chain_parallel_out: std_logic_vector(17 downto 0);
begin
  dut: StreamCalculator port map (Din => scan_chain_parallel_in(15 downto 0),
                           Avl => scan_chain_parallel_in(16),
                           start => scan_chain_parallel_in(17),
                           clk => clk,
                           reset => reset,
                           Dout => scan_chain_parallel_out(15 downto 0),
                           Send => scan_chain_parallel_out(16),
                           done => scan_chain_parallel_out(17));
  
  scan_instance: Scan_Chain
  generic map(in_pins => 20, out_pins => 18)
  port map (TDI => TDI,
            TDO => TDO,
            TMS => TMS,
            TCLK => TCLK,
            TRST => TRST,
            dut_in => scan_chain_parallel_in,
            dut_out => scan_chain_parallel_out);
				
  clk <= scan_chain_parallel_in(18);
  reset <= scan_chain_parallel_in(19);
end architecture;
