library std;
library ieee;
use ieee.std_logic_1164.all;
use work.RTLComponents.all;

package LongDividerComponents is
  component LongDivider is
    port(A,B: in std_logic_vector(15 downto 0);
       RESULT_QUOTIENT: out std_logic_vector(15 downto 0);
       RESULT_REMAINDER: out std_logic_vector(15 downto 0);
       start: in std_logic;
       done: out std_logic;
       clk, reset: in std_logic);
  end component  LongDivider;

  component DividerControlPath is
	port (
		T0,T1,T2,T3,T4,T5,T6,T7,T8,T9: out std_logic;
		S: in std_logic;
		start: in std_logic;
		done : out std_logic;
		clk, reset: in std_logic
	     );
  end component;

  component DividerDataPath is
	port (
		T0,T1,T2,T3,T4,T5,T6,T7,T8,T9: in std_logic;
		S: out std_logic;
		A,B: in std_logic_vector(15 downto 0);
		RESULT_REMAINDER, RESULT_QUOTIENT:  out std_logic_vector(15 downto 0);
		clk, reset: in std_logic
	     );
  end component;
end package;

library work;
library ieee;
use work.LongDividerComponents.all;
use ieee.std_logic_1164.all;
entity LongDivider is
  port(A,B: in std_logic_vector(15 downto 0);
       RESULT_QUOTIENT: out std_logic_vector(15 downto 0);
       RESULT_REMAINDER: out std_logic_vector(15 downto 0);
       start: in std_logic;
       done: out std_logic;
       clk, reset: in std_logic);
end entity LongDivider;


architecture Struct of LongDivider is
   signal T0,T1,T2,T3,T4,T5,T6,T7,T8,T9, S: std_logic;
begin

    CP: DividerControlPath 
	     port map(T0 => T0,
			T1 => T1, 
			T2 => T2,
			T3 => T3,
			T4 => T4,
 			T5 => T5,
			T6 => T6,
			T7 => T7,
			T8 => T8,
			T9 => T9,
			S => S,
			start => start,
			done => done,
			reset => reset,
			clk => clk);

    DP: DividerDataPath
	     port map (A => A, B => B,
            RESULT_QUOTIENT => RESULT_QUOTIENT,
            RESULT_REMAINDER => RESULT_REMAINDER,
            T0 => T0,
			T1 => T1, 
			T2 => T2,
			T3 => T3,
			T4 => T4,
 			T5 => T5,
			T6 => T6,
			T7 => T7,
			T8 => T8,
			T9 => T9,
			S => S,
			reset => reset,
			clk => clk);
end Struct;

library ieee;
use ieee.std_logic_1164.all;
entity DividerControlPath is
	port (
		T0,T1,T2,T3,T4,T5,T6,T7,T8,T9: out std_logic;
		S: in std_logic;
		start: in std_logic;
		done : out std_logic;
		clk, reset: in std_logic
	     );
end entity;

architecture Behave of DividerControlPath is
   type FsmState is (rst, subtract, update, donestate);
   signal fsm_state : FsmState;
begin

   process(fsm_state, start, S, clk, reset)
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
               Tvar(2) := '1';
               Tvar(3) := '1';
               Tvar(4) := '1';
               next_state := subtract;
            end if;
          when subtract =>
               Tvar(5) := '1';
               Tvar(6) := '1';
               next_state := update;
          when update =>
               Tvar(7) := '1';
               Tvar(8) := '1';
               if(S = '1') then
                  Tvar(9) := '1';
                  next_state := donestate;
               else
                  next_state := subtract;
               end if;
          when donestate =>
               done_var := '1';
               next_state := rst;
     end case;

     T0 <= Tvar(0); T1 <= Tvar(1); T2 <= Tvar(2); T3 <= Tvar(3); T4 <= Tvar(4);
     T5 <= Tvar(5); T6 <= Tvar(6); T7 <= Tvar(7); T8 <= Tvar(8); T9 <= Tvar(9);
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
use work.LongDividerComponents.all;
use work.RTLComponents.all;

entity DividerDataPath is
	port (
		T0,T1,T2,T3,T4,T5,T6,T7,T8,T9: in std_logic;
		S: out std_logic;
		A,B: in std_logic_vector(15 downto 0);
		RESULT_QUOTIENT: out std_logic_vector(15 downto 0);
		RESULT_REMAINDER: out std_logic_vector(15 downto 0);
		clk, reset: in std_logic
	     );
end entity;

architecture Mixed of DividerDataPath is
    signal BREG: std_logic_vector(15 downto 0);
    signal COUNT: std_logic_vector(4 downto 0);
    signal TDIFF: std_logic_vector(16 downto 0);
    signal REMAINDER: std_logic_vector(32 downto 0);
    signal QUOTIENT: std_logic_vector(15 downto 0);

    signal BREG_in, RESULT_QUOTIENT_in, RESULT_REMAINDER_in: std_logic_vector(15 downto 0);
    signal COUNT_in: std_logic_vector(4 downto 0);
    signal TDIFF_in: std_logic_vector(16 downto 0);
    signal REMAINDER_in: std_logic_vector(32 downto 0);
    signal QUOTIENT_in: std_logic_vector(15 downto 0);
   
    signal subA,subB: std_logic_vector(15 downto 0);
    signal subResult: std_logic_vector(16 downto 0);

    signal decrOut, count_reg_in: std_logic_vector(4 downto 0);
    constant C33 : std_logic_vector(4 downto 0) := "10001";
    constant C0 : std_logic_vector(0 downto 0) := "0";
    constant C6 : std_logic_vector(4 downto 0) := "00000";
    constant C32 : std_logic_vector(15 downto 0) := (others => '0');
    constant C31 : std_logic_vector(14 downto 0) := (others => '0');
    constant C64 : std_logic_vector(31 downto 0) := (others => '0');

    signal count_enable, areg_enable, breg_enable, tdiff_enable, remainder_enable, quotient_enable, result_enable: std_logic;

begin
    -- predicate
    S <= '1' when (COUNT = C6) else '0';

    --------------------------------------------------------
    --  count-related logic
    --------------------------------------------------------
    -- decrementer
    decr: Decrement6  port map (A => COUNT, B => decrOut);

    -- count register.
    count_enable <=  (T0 or T6);
    COUNT_in <= decrOut when T6 = '1' else C33;
    count_reg: DataRegister 
                   generic map (data_width => 5)
                   port map (Din => COUNT_in,
                             Dout => COUNT,
                             Enable => count_enable,
                             clk => clk);

    -------------------------------------------------
    -- BREG related logic..
    -------------------------------------------------
    BREG_in <= B;  -- not really needed, just being consistent.

    breg_enable <= T1;
    br: DataRegister generic map(data_width => 16)
			port map (Din => BREG_in, Dout => BREG, Enable => breg_enable, clk => clk);
   
    -------------------------------------------------
    -- TDIFF related logic
    -------------------------------------------------
    TDIFF_in <= subResult when T6 = '1' 
                else C32 & '0';
    subA <= REMAINDER(31 downto 16);
    subB <= BREG;
    sub: Subtractor32 port map(A => subA, B => subB, RESULT => subResult);

    tdiff_enable <= T3 or T6;
    tr: DataRegister generic map(data_width => 17)
			port map(Din => TDIFF_in, Dout => TDIFF, Enable => tdiff_enable, clk => clk);

    -------------------------------------------------
    -- REMANIDER related logic
    -------------------------------------------------
    REMAINDER_in <= TDIFF(15 downto 0) & REMAINDER(15 downto 0) & '0' when TDIFF(16) = '0' and T8 = '1'
                    else REMAINDER(31 downto 0) & '0' when T8 = '1'
                    else C32 & A & '0';

    remainder_enable <= T4 or T8;
    rr: DataRegister generic map(data_width => 33)
                     port map(Din => REMAINDER_in, Dout => REMAINDER, Enable => remainder_enable, clk => clk);

    -------------------------------------------------
    -- QUOTIENT related logic
    -------------------------------------------------
    QUOTIENT_in <= QUOTIENT(14 downto 0) & not TDIFF(16) when T7 = '1'
                   else C32;

    quotient_enable <= T2 or T7;
    qr: DataRegister generic map(data_width => 16)
                     port map(Din => QUOTIENT_in, Dout => QUOTIENT, Enable => quotient_enable, clk => clk);

    -------------------------------------------------
    -- RESULT related logic
    -------------------------------------------------
    RESULT_QUOTIENT_in <= QUOTIENT;
    result_enable <= T9;
    rqr: DataRegister generic map(data_width => 16)
			port map(Din => RESULT_QUOTIENT_in, Dout => RESULT_QUOTIENT, Enable => result_enable, clk => clk);

    RESULT_REMAINDER_in <= REMAINDER(32 downto 17);
    rrr: DataRegister generic map(data_width => 16)
			port map(Din => RESULT_REMAINDER_in, Dout => RESULT_REMAINDER, Enable => result_enable, clk => clk);

end Mixed;


