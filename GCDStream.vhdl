--   states:
--     rst:
-- T0    AREG = 0
-- T0    BREG = 0
-- T0    COUNT = 8
--       goto take_input
--     take_input:
--       send_input = 1
-- S0    if(input_available = 1)
-- T2      BREG = Din
-- S1      if (AREG = 0)
-- T3        AREG = Din
--         else 
--           send_input = 0
-- T4        start_div = 1
--           goto process
--     process:
-- T5    start_div = 0
--       GCD(AREG,BREG)
-- S2    if (gcddone = 1)
--         goto update
--     update:
-- T6    AREG = GCDout
-- T6    BREG = 0
-- T6    COUNT --
--       goto take_input
-- S3    if (COUNT = 1)
-- T7      Dout = GCDout
--         goto donestate


library std;
library ieee;
use ieee.std_logic_1164.all;

library work;
package StreamComponents is
  component StreamCalculator is
    port(Din: in std_logic_vector(15 downto 0);
       Dout: out std_logic_vector(15 downto 0);
       Avl: in std_logic;
       Send: out std_logic;
       start: in std_logic;
       done: out std_logic;
       clk, reset: in std_logic);
  end component StreamCalculator;

  component StreamControlPath is
	port (
		T: out std_logic_vector(7 downto 0);
		S: in std_logic_vector(3 downto 0);
		start: in std_logic;
		Send : out std_logic;
		done : out std_logic;
		clk, reset: in std_logic
	     );
  end component;

  component StreamDataPath is
	port (
		T: in std_logic_vector(7 downto 0);
		S: out std_logic_vector(3 downto 0);
        Din: in std_logic_vector(15 downto 0);
        Dout: out std_logic_vector(15 downto 0);
        Avl: in std_logic;
		clk, reset: in std_logic
	     );
  end component;
end package;

library std;
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.RTLComponents.all;
use work.LongDividerComponents.LongDivider;
use work.StreamComponents.all;

entity StreamCalculator is
  port(Din: in std_logic_vector(15 downto 0);
       Dout: out std_logic_vector(15 downto 0);
       Avl: in std_logic;
       Send: out std_logic;
       start: in std_logic;
       done: out std_logic;
       clk, reset: in std_logic);
end entity StreamCalculator;

architecture Struct of StreamCalculator is
    signal T: std_logic_vector(7 downto 0);
    signal S: std_logic_vector(3 downto 0);
begin

    CP: StreamControlPath 
	     port map(T => T,
			S => S,
			start => start,
            Send => Send,
			done => done,
			reset => reset,
			clk => clk);

    DP: StreamDataPath
	     port map (Din => Din,
                   Dout => Dout,
                   Avl => Avl,
                   T => T,
                   S => S,
                   reset => reset,
                   clk => clk);
end Struct;

library ieee;
use ieee.std_logic_1164.all;
entity StreamControlPath is
	port (
		T: out std_logic_vector(7 downto 0);
		S: in std_logic_vector(3 downto 0);
		start: in std_logic;
		Send : out std_logic;
		done : out std_logic;
		clk, reset: in std_logic
	     );
end entity;

architecture Behave of StreamControlPath is
   type FsmState is (rst, take_input, procs, update, donestate);
   signal fsm_state : FsmState;
begin

   process(fsm_state, start, S, clk, reset)
      variable next_state: FsmState;
      variable Tvar: std_logic_vector(7 downto 0);
      variable done_var, Send_var: std_logic;
   begin
       -- defaults
       Tvar := (others => '0');
       done_var := '0';
       Send_var := '0';
       next_state := fsm_state;

       case fsm_state is 
          when rst =>
            if(start = '1') then
               Tvar(0) := '1';
               next_state := take_input;
               Send_var := '1';
            end if;
          when take_input =>
              if (S(0) = '1') then
                  Tvar(2) := '1';
                  if( S(1) = '1') then
                      Tvar(3) := '1';
                  else
                      Tvar(4) := '1';
                      next_state := procs;
                  end if;
              end if; 
          when procs =>
              Tvar(5) := '1';
              if( S(2) = '1') then
                  next_state := update;
                  Tvar(5) := '0';
              end if;
          when update =>
              Tvar(6) := '1';
              if( S(3) = '1') then
                  Tvar(7) := '1';
                  next_state := donestate;
              else
                  next_state := take_input;
                  Send_var := '1';
              end if;
          when donestate =>
              done_var := '1';
              next_state := rst;
     end case;

     T <= Tvar;
     done <= done_var;
     Send <= Send_var;

     if(clk'event and (clk = '1')) then
        if(reset = '1') then
             fsm_state <= rst;
        else
             fsm_state <= next_state;
        end if;
     end if;
   end process;
end Behave;


library ieee;
use ieee.std_logic_1164.all;
library work;
use work.RTLComponents.all;
use work.StreamComponents.all;
use work.GCDComponents.GCDCalculator;

entity StreamDataPath is
	port (
		T: in std_logic_vector(7 downto 0);
		S: out std_logic_vector(3 downto 0);
        Din: in std_logic_vector (15 downto 0);
        Avl: in std_logic;
        Dout: out std_logic_vector (15 downto 0);
		clk, reset: in std_logic
	     );
end entity;

architecture Mixed of StreamDataPath is
    signal AREG: std_logic_vector(15 downto 0);
    signal BREG: std_logic_vector(15 downto 0);
    signal START: std_logic_vector(0 downto 0);
    signal COUNT: std_logic_vector(4 downto 0);

    signal AREG_in, BREG_in, RESULT_in: std_logic_vector(15 downto 0);
    signal START_in: std_logic_vector(0 downto 0);
    signal COUNT_in: std_logic_vector(4 downto 0);
   
    signal GCDA, GCDB, GCDOut: std_logic_vector(15 downto 0);
    signal GCDDone: std_logic;

    signal decrOut: std_logic_vector(4 downto 0);
    constant C8 : std_logic_vector(4 downto 0) := "01000";
    constant C16 : std_logic_vector(15 downto 0) := (others => '0');
    constant C1 : std_logic_vector(4 downto 0) := "00001";

    signal count_enable, areg_enable, breg_enable, tdiff_enable, remainder_enable, quotient_enable, result_enable, start_enable: std_logic;

begin
    gcd: GCDCalculator port map (A => AREG, B => BREG, start => START(0), clk => clk, reset => reset, done => S(2), RESULT => GCDOut);

    S(0) <= Avl;
    S(1) <= '1' when AREG = C16 else '0';
    -- predicate
    S(3) <= '1' when (COUNT = C1) else '0';

    --------------------------------------------------------
    --  count-related logic
    --------------------------------------------------------
    -- decrementer
    decr: Decrement6  port map (A => COUNT, B => decrOut);

    -- count register.
    count_enable <=  (T(0) or T(6));
    COUNT_in <= decrOut when T(6) = '1' else C8;
    count_reg: DataRegister 
                   generic map (data_width => 5)
                   port map (Din => COUNT_in,
                             Dout => COUNT,
                             Enable => count_enable,
                             clk => clk);

    ------------------------------------------------
    -- START logic
    ------------------------------------------------
    START_in(0) <= '1' when T(4) = '1' else '0' when T(5) = '1';

    start_enable <= T(4) or T(5);
    sr: DataRegister generic map(data_width => 1)
			port map (Din => START_in, Dout => START, Enable => start_enable, clk => clk);

    -------------------------------------------------
    -- AREG related logic..
    -------------------------------------------------
    AREG_in <= C16 when T(0) = '1' else Din when T(3) = '1' else GCDOut when T(6) = '1';
    areg_enable <= T(0) or T(3) or T(6);
    ar: DataRegister generic map(data_width => 16)
			port map (Din => AREG_in, Dout => AREG, Enable => areg_enable, clk => clk);

    -------------------------------------------------
    -- BREG related logic..
    -------------------------------------------------
    BREG_in <= C16 when T(0) = '1' else Din when T(2) = '1' else C16 when T(6) = '1';

    breg_enable <= T(0) or T(2) or T(6);
    br: DataRegister generic map(data_width => 16)
			port map (Din => BREG_in, Dout => BREG, Enable => breg_enable, clk => clk);
   
    -------------------------------------------------
    -- RESULT related logic
    -------------------------------------------------
    RESULT_in <= GCDOut;
    result_enable <= T(7);
    rqr: DataRegister generic map(data_width => 16)
			port map(Din => RESULT_in, Dout => Dout, Enable => result_enable, clk => clk);


end Mixed;

