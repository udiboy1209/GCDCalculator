library ieee;
use ieee.std_logic_1164.all;

library std;
use std.textio.all;

library work;
use work.all;

entity TestSRAM is
end entity;

architecture Behave of TestSRAM is
  		signal mc_start, mc_write : std_logic;
  		signal clk : std_logic := '0';
  		signal reset : std_logic := '1';
		signal sram_data1 : std_logic_vector(7 downto 0);
		signal sram_address : std_logic_vector(12 downto 0);
		signal mc_address :  std_logic_vector(12 downto 0);
		signal mc_write_data :  std_logic_vector(7 downto 0) := "00001000";
		signal mc_done , CS, WE, OE:  std_logic;
		signal mc_read_data : std_logic_vector(7 downto 0);

component SRAMInterface is 
	port (
		ADDR: out std_logic_vector(12 downto 0);
		IO: inout std_logic_vector(7 downto 0);
		CS, WE, OE: out std_logic;
		ADDR_DATA: in std_logic_vector(12 downto 0);
		WR_DATA: in std_logic_vector(7 downto 0);
		RD_DATA: out std_logic_vector(7 downto 0);
		start, rd_wr, clk, reset: in std_logic;
		done: out std_logic
	    );
	end component;
	

component DataRegister is
	generic (data_width:integer);
	port (Din: in std_logic_vector(data_width-1 downto 0);
	      Dout: out std_logic_vector(data_width-1 downto 0);
	      clk, enable: in std_logic);
	end component;

	component DataRegister_bit is
	port (Din : in std_logic;
	      Dout: out std_logic;
	      clk, enable: in std_logic);
	end component;
		
	
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
begin

  clk <= not clk after 10 ns; -- assume 10ns clock.

  -- reset process
  	
  process
  begin
     wait until clk = '1';
     reset <= '0';
     wait;
  end process;
  
  

 process 
    variable err_flag : boolean := false;
    File INFILE: text open read_mode is "TraceSRAM.txt";
    FILE OUTFILE: text  open write_mode is "OUTPUTS.txt";

    ---------------------------------------------------
    -- edit the next few lines to customize
    variable A_var: bit_vector ( 12 downto 0);
    variable output_var: bit_vector ( 7 downto 0);
    ----------------------------------------------------
    variable INPUT_LINE: Line;
    variable OUTPUT_LINE: Line;
    variable LINE_COUNT: integer := 0;
    
  begin
	mc_start <= '1';
	mc_write <= '1';
    wait until clk = '1';
    

  
		   
    while not endfile(INFILE) loop 
    	  wait until clk = '0';

          LINE_COUNT := LINE_COUNT + 1;
	
	  readLine (INFILE, INPUT_LINE);
          read (INPUT_LINE, A_var);
	      read (INPUT_LINE, output_var);
		
          --------------------------------------
          -- from input-vector to DUT inputs
	  mc_address <= to_std_logic_vector(A_var);
	  
	  
	  
          --------------------------------------
			 write(OUTPUT_LINE, output_var);
             writeline(OUTFILE, OUTPUT_LINE); 
		   
          -- spin waiting for done
         while (true) loop
            wait until clk = '1';
          mc_start <= '0';
		-- if(WE  = '0') then
		 --	wait for 30 ns;
		 	--sram_data1 <= to_std_logic_vector(output_var);
			
   		 -- end if;
       
         if(mc_done = '1') then
              exit;
          end if;
         end loop;
	  
	  --start <= '1';
          --------------------------------------
	  -- check outputs.
	  if (( sram_data1 /= to_std_logic_vector(output_var))) then
             write(OUTPUT_LINE,to_string("ERROR: in RESULT, line "));
             write(OUTPUT_LINE, LINE_COUNT);
             writeline(OUTFILE, OUTPUT_LINE);
                          
             err_flag := true;
          end if;
          --------------------------------------
    end loop;

    assert (err_flag) report "SUCCESS, all tests passed." severity note;
    assert (not err_flag) report "FAILURE, some tests failed." severity error;

    wait;
  end process;

  dut: SRAMInterface
  port map (
        ADDR => sram_address,
        CS => CS, WE => WE, OE => OE,
        ADDR_DATA => mc_address,
        IO => sram_data1,
        WR_DATA => mc_write_data,
        RD_DATA => mc_read_data,
        start => mc_start, rd_wr => mc_write, clk => clk, reset => reset,
        done => mc_done
    );
			

end Behave;
