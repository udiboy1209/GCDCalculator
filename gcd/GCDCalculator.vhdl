library std;
library ieee;
use ieee.std_logic_1164.all;

library work;
package GCDComponents is
  component GCDCalculator is
    port(A,B: in std_logic_vector(15 downto 0);
       RESULT: out std_logic_vector(15 downto 0);
       start: in std_logic;
       done: out std_logic;
       clk, reset: in std_logic);
  end component GCDCalculator;

  component GCDControlPath is
	port (
		T0,T1,T2,T3,T4,T5,T6: out std_logic;
		S1, S2: in std_logic;
		start: in std_logic;
		done : out std_logic;
		clk, reset: in std_logic
	     );
  end component;

  component GCDDataPath is
	port (
		T0,T1,T2,T3,T4,T5,T6: in std_logic;
		S1, S2: out std_logic;
		A,B: in std_logic_vector(15 downto 0);
		RESULT:  out std_logic_vector(15 downto 0);
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
use work.GCDComponents.all;

entity GCDCalculator is
  port(A,B: in std_logic_vector(15 downto 0);
       RESULT: out std_logic_vector(15 downto 0);
       start: in std_logic;
       done: out std_logic;
       clk, reset: in std_logic);
end entity GCDCalculator;

architecture Struct of GCDCalculator is
   signal T0,T1,T2,T3,T4,T5,T6, S1, S2: std_logic;
begin

    CP: GCDControlPath 
	     port map(T0 => T0,
			T1 => T1, 
			T2 => T2,
			T3 => T3,
			T4 => T4,
			T5 => T5,
			T6 => T6,
			S1 => S1,
			S2 => S2,
			start => start,
			done => done,
			reset => reset,
			clk => clk);

    DP: GCDDataPath
	     port map (A => A, B => B,
            RESULT => RESULT,
            T0 => T0,
			T1 => T1, 
			T2 => T2,
			T3 => T3,
			T4 => T4,
			T5 => T5,
			T6 => T6,
			S1 => S1,
            S2 => S2,
			reset => reset,
			clk => clk);
end Struct;

library ieee;
use ieee.std_logic_1164.all;
entity GCDControlPath is
	port (
		T0,T1,T2,T3,T4,T5,T6: out std_logic;
		S1, S2: in std_logic;
		start: in std_logic;
		done : out std_logic;
		clk, reset: in std_logic
	     );
end entity;

architecture Behave of GCDControlPath is
   type FsmState is (rst, divide, update, donestate);
   signal fsm_state : FsmState;
begin

   process(fsm_state, start, S1, S2, clk, reset)
      variable next_state: FsmState;
      variable Tvar: std_logic_vector(0 to 9);
      variable done_var: std_logic;
   begin
       -- defaults
       Tvar := (others => '0');
       done_var := '0';
       next_state := fsm_state;

       case fsm_state is 
          when rst =>
            if(start = '1') then
               Tvar(0) := '1';
               Tvar(1) := '1';
               Tvar(5) := '1';
               next_state := divide;
            end if;
          when divide =>
               Tvar(6) := '1';
               if(S2 = '1') then
                   next_state := update;
               end if;
          when update =>
              Tvar(2) := '1';
              Tvar(3) := '1';
              if(S1 = '1') then
                  next_state := donestate;
                  Tvar(4) := '1';
              else
                  next_state := divide;
                  Tvar(5) := '1';
              end if;
          when donestate =>
               done_var := '1';
               next_state := rst;
     end case;

     T0 <= Tvar(0); T1 <= Tvar(1); T2 <= Tvar(2); T3 <= Tvar(3); T4 <= Tvar(4); T5 <= Tvar(5); T6 <= Tvar(6);
     done <= done_var;

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
use work.GCDComponents.all;
use work.LongDividerComponents.LongDivider;

entity GCDDataPath is
	port (
		T0,T1,T2,T3,T4,T5,T6: in std_logic;
		S1, S2: out std_logic;
		A,B: in std_logic_vector(15 downto 0);
		RESULT: out std_logic_vector(15 downto 0);
		clk, reset: in std_logic
	     );
end entity;

architecture Mixed of GCDDataPath is
    signal AREG: std_logic_vector(15 downto 0);
    signal BREG: std_logic_vector(15 downto 0);
    signal START: std_logic_vector(0 downto 0);

    signal AREG_in, BREG_in, RESULT_in: std_logic_vector(15 downto 0);
    signal START_in: std_logic_vector(0 downto 0);
   
    signal divA, divB, divRem: std_logic_vector(15 downto 0);
    signal divDone: std_logic;

    constant C16 : std_logic_vector(15 downto 0) := (others => '0');

    signal count_enable, areg_enable, breg_enable, tdiff_enable, remainder_enable, quotient_enable, result_enable, start_enable: std_logic;

begin
    divider: LongDivider port map (A => AREG, B => BREG, RESULT_REMAINDER => divRem, start => START(0), clk => clk, reset => reset, done => S2);

    -- predicate
    S1 <= '1' when (divRem = C16) else '0';

    ------------------------------------------------
    -- START logic
    ------------------------------------------------
    START_in(0) <= '1' when T5 = '1' else '0' when T6 = '1';

    start_enable <= T5 or T6;
    sr: DataRegister generic map(data_width => 1)
			port map (Din => START_in, Dout => START, Enable => start_enable, clk => clk);

    -------------------------------------------------
    -- BREG related logic..
    -------------------------------------------------
    AREG_in <= A when T0 = '1' else BREG when T2 = '1';  -- not really needed, just being consistent.

    areg_enable <= T0 or T2;
    ar: DataRegister generic map(data_width => 16)
			port map (Din => AREG_in, Dout => AREG, Enable => areg_enable, clk => clk);

    -------------------------------------------------
    -- BREG related logic..
    -------------------------------------------------
    BREG_in <= B when T1 ='1' else divRem when T3 = '1';  -- not really needed, just being consistent.

    breg_enable <= T1 or T3;
    br: DataRegister generic map(data_width => 16)
			port map (Din => BREG_in, Dout => BREG, Enable => breg_enable, clk => clk);
   
    -------------------------------------------------
    -- RESULT related logic
    -------------------------------------------------
    RESULT_in <= BREG;
    result_enable <= T4;
    rqr: DataRegister generic map(data_width => 16)
			port map(Din => RESULT_in, Dout => RESULT, Enable => result_enable, clk => clk);

end Mixed;
