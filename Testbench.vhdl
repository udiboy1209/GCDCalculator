library ieee;
use ieee.std_logic_1164.all;
library std;
use std.textio.all;
library work;
use work.StreamComponents.all;

entity Testbench is
end entity;
architecture Behave of Testbench is
  signal A, RESULT: std_logic_vector(15 downto 0);
  signal start, done: std_logic;
  signal clk: std_logic := '0';
  signal reset: std_logic := '1';
  signal Send: std_logic;
  signal Avl: std_logic := '0';

  function to_string(x: string) return string is
      variable ret_val: string(1 to x'length);
      alias lx : string (1 to x'length) is x;
  begin  
      ret_val := lx;
      return(ret_val);
  end to_string;

  function to_std_logic_vector(x: bit_vector) return std_logic_vector is
    alias lx: bit_vector(1 to x'length) is x;
    variable ret_var : std_logic_vector(1 to x'length);
  begin
     for I in 1 to x'length loop
        if(lx(I) = '1') then
           ret_var(I) :=  '1';
        else 
           ret_var(I) :=  '0';
	end if;
     end loop;
     return(ret_var);
  end to_std_logic_vector;

begin
  clk <= not clk after 5 ns; -- assume 10ns clock.

  -- reset process
  process
  begin
     wait until clk = '1';
     reset <= '0';
     wait;
  end process;

  process 
    variable err_flag : boolean := false;
    File INFILE: text open read_mode is "TRACEFILE.txt";
    FILE OUTFILE: text  open write_mode is "OUTPUTS.txt";

    ---------------------------------------------------
    -- edit the next few lines to customize
    variable A_var: bit_vector ( 15 downto 0);
    variable Result_var: bit_vector (15 downto 0);
    ----------------------------------------------------
    variable INPUT_LINE: Line;
    variable OUTPUT_LINE: Line;
    variable LINE_COUNT: integer := 0;

    variable stream_end: std_logic := '1';
    
  begin

    wait until clk = '1';

   
    while not endfile(INFILE) loop 
    	  wait until clk = '0';

          LINE_COUNT := LINE_COUNT + 1;
	

          --------------------------------------
          -- from input-vector to DUT inputs
          --------------------------------------

          -- set start
          if(stream_end = '1') then
              readLine (INFILE, INPUT_LINE);
              start <= '1';
              stream_end := '0';
          end if;

          -- spin waiting for done
          while (true) loop
             wait until clk = '1';
             start <= '0';
             if(Send = '1' or done = '1') then
                Avl <= '0';
                exit;
             end if;
          end loop;

          --------------------------------------
	  -- check outputs.
          if (done = '1') then
              read (INPUT_LINE, Result_var);
              if (RESULT /= to_std_logic_vector(Result_var)) then
                 write(OUTPUT_LINE,to_string("ERROR: in RESULT, line "));
                 write(OUTPUT_LINE, LINE_COUNT);
                 -- write(OUTPUT_LINE, to_string(" QUO: "));
                 -- write(OUTPUT_LINE, RESULT_QUOTIENT);
                 -- write(OUTPUT_LINE, to_string(" REM: "));
                 -- write(OUTPUT_LINE, RESULT_REMAINDER);
                 writeline(OUTFILE, OUTPUT_LINE);
                 err_flag := true;
              end if;
              stream_end := '1';
          else
              read (INPUT_LINE, A_var);
              A <= to_std_logic_vector(A_var);
              Avl <= '1';
          end if;
          --------------------------------------
    end loop;

    assert (err_flag) report "SUCCESS, all tests passed." severity note;
    assert (not err_flag) report "FAILURE, some tests failed." severity error;

    wait;
  end process;

  dut: StreamCalculator
     port map(Din => A,
              Dout => RESULT,
              Send => Send,
              Avl => Avl,
              clk => clk,
              reset => reset,
              start => start, done => done);

end Behave;

