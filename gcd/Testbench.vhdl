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

  function to_bit_vector(x: std_logic_vector) return bit_vector is
    alias lx: std_logic_vector(1 to x'length) is x;
    variable ret_var : bit_vector(1 to x'length);
  begin
     for I in 1 to x'length loop
        if(lx(I) = '1') then
           ret_var(I) :=  '1';
        else
           ret_var(I) :=  '0';
	end if;
     end loop;
     return(ret_var);
  end to_bit_vector;

function to_hstring (value     : STD_LOGIC_VECTOR) return STRING is
    constant ne     : INTEGER := (value'length+3)/4;
    variable pad    : STD_LOGIC_VECTOR(0 to (ne*4 - value'length) - 1);
    variable ivalue : STD_LOGIC_VECTOR(0 to ne*4 - 1);
    variable result : STRING(1 to ne);
    variable quad   : STD_LOGIC_VECTOR(0 to 3);
  begin
    if value'length < 1 then
      return "0";
    else
      if value (value'left) = 'Z' then
        pad := (others => 'Z');
      else
        pad := (others => '0');
      end if;
      ivalue := pad & value;
      for i in 0 to ne-1 loop
        quad := To_X01Z(ivalue(4*i to 4*i+3));
        case quad is
          when x"0"   => result(i+1) := '0';
          when x"1"   => result(i+1) := '1';
          when x"2"   => result(i+1) := '2';
          when x"3"   => result(i+1) := '3';
          when x"4"   => result(i+1) := '4';
          when x"5"   => result(i+1) := '5';
          when x"6"   => result(i+1) := '6';
          when x"7"   => result(i+1) := '7';
          when x"8"   => result(i+1) := '8';
          when x"9"   => result(i+1) := '9';
          when x"A"   => result(i+1) := 'A';
          when x"B"   => result(i+1) := 'B';
          when x"C"   => result(i+1) := 'C';
          when x"D"   => result(i+1) := 'D';
          when x"E"   => result(i+1) := 'E';
          when x"F"   => result(i+1) := 'F';
          when "ZZZZ" => result(i+1) := 'Z';
          when others => result(i+1) := '0';
        end case;
      end loop;
      return result;
    end if;
  end function to_hstring;

  function write_scan_in(din,dout : std_logic_vector; send, avl, start, done, clk, reset : std_logic) return string is
      variable result: string(1 to 43);
      variable scan_pll_in: std_logic_vector(19 downto 0) := (others => '0');
      variable scan_pll_out: std_logic_vector(17 downto 0) := (others => '0');
      variable mask: std_logic_vector(17 downto 0) := (others => '0');
  begin
       scan_pll_in(15 downto 0) := Din;
       scan_pll_in(16) := Avl;
       scan_pll_in(17) := start;
       scan_pll_in(18) := clk;
       scan_pll_in(19) := reset;
       scan_pll_out(15 downto 0) := Dout;
       scan_pll_out(16) := Send;
       scan_pll_out(17) := done;

       if(done = '1') then
           mask := (others => '1');
       end if;
       if(send = '1') then
           mask(16) := '1';
       end if;

       result := "SDR 20 TDI(" & to_hstring(scan_pll_in) & ") 18 TDO(" & to_hstring(scan_pll_out) & ") MASK(" & to_hstring(mask) & ")";
       return result;
  end function write_scan_in;
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
    FILE SCAN_INPUT: text  open write_mode is "scan_input.txt";

    ---------------------------------------------------
    -- edit the next few lines to customize
    variable A_var: bit_vector ( 15 downto 0);
    variable Result_var: bit_vector (15 downto 0);
    ----------------------------------------------------
    variable INPUT_LINE: Line;
    variable OUTPUT_LINE: Line;
    variable SCAN_INPUT_LINE: Line;
    variable LINE_COUNT: integer := 0;

    variable stream_end: std_logic := '1';
    
  begin

    wait until clk = '1';

   
    while not endfile(INFILE) loop 
    	  wait until clk = '0';

	
          --------------------------------------
          -- from input-vector to DUT inputs
          --------------------------------------

          -- set start
          if(stream_end = '1') then
              LINE_COUNT := LINE_COUNT + 1;
              readLine (INFILE, INPUT_LINE);
              start <= '1';
              stream_end := '0';
          end if;

          write(SCAN_INPUT_LINE, write_scan_in(A,RESULT,send,avl,start,done,clk,reset));
          writeline(SCAN_INPUT, SCAN_INPUT_LINE);
          write(SCAN_INPUT_LINE, to_string("RUNTEST 1 MSEC"));
          writeline(SCAN_INPUT, SCAN_INPUT_LINE);

          -- spin waiting for done
          while (true) loop
             wait until clk'event;
             if clk = '1' then 
                 start <= '0';
                 if(Send = '1' or done = '1') then
                    Avl <= '0';
                    exit;
                 end if;
             end if;
              write(SCAN_INPUT_LINE, write_scan_in(A,RESULT,send,avl,start,done,clk,reset));
              writeline(SCAN_INPUT, SCAN_INPUT_LINE);
              write(SCAN_INPUT_LINE, to_string("RUNTEST 1 MSEC"));
              writeline(SCAN_INPUT, SCAN_INPUT_LINE);
          end loop;

          write(SCAN_INPUT_LINE, write_scan_in(A,RESULT,send,avl,start,done,clk,reset));
          writeline(SCAN_INPUT, SCAN_INPUT_LINE);
          write(SCAN_INPUT_LINE, to_string("RUNTEST 1 MSEC"));
          writeline(SCAN_INPUT, SCAN_INPUT_LINE);


          --------------------------------------
	  -- check outputs.
          if (done = '1') then
              read (INPUT_LINE, Result_var);
              if (RESULT /= to_std_logic_vector(Result_var)) then
                 write(OUTPUT_LINE,to_string("ERROR: in RESULT, line "));
                 write(OUTPUT_LINE, LINE_COUNT);
                 write(OUTPUT_LINE, to_string(" RES: "));
                 write(OUTPUT_LINE, to_bit_vector(RESULT));
                 write(OUTPUT_LINE, to_string(" EXP: "));
                 write(OUTPUT_LINE, Result_var);
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

