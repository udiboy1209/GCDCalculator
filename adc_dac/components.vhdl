library std;
library ieee;
use ieee.std_logic_1164.all;
library work;

package RTLComponents is
  component DataRegister is
	generic (data_width:integer);
	port (Din: in std_logic_vector(data_width-1 downto 0);
	      Dout: out std_logic_vector(data_width-1 downto 0);
	      clk, enable: in std_logic);
  end component DataRegister;

  -- produces sum with carry (included in result).
  component Subtractor32 is
        port (A, B: in std_logic_vector(15 downto 0); RESULT: out std_logic_vector(16 downto 0));
  end component Subtractor32;
	
  -- 6-bit decrementer.
  component Decrement5 is
        port (A: in std_logic_vector(4 downto 0); B: out std_logic_vector(4 downto 0));
  end component Decrement5;

  component Increment5 is
        port (A: in std_logic_vector(4 downto 0); B: out std_logic_vector(4 downto 0));
  end component Increment5;
end package;

library ieee;
use ieee.std_logic_1164.all;
entity DataRegister is
	generic (data_width:integer);
	port (Din: in std_logic_vector(data_width-1 downto 0);
	      Dout: out std_logic_vector(data_width-1 downto 0);
	      clk, enable: in std_logic);
end entity;
architecture Behave of DataRegister is
begin
    process(clk)
    begin
       if(clk'event and (clk  = '1')) then
           if(enable = '1') then
               Dout <= Din;
           end if;
       end if;
    end process;
end Behave;

library ieee;
use ieee.std_logic_1164.all;
entity Subtractor32 is
   port (A, B: in std_logic_vector(15 downto 0); RESULT: out std_logic_vector(16 downto 0));
end entity;
architecture Serial of Subtractor32 is
begin
   process(A,B)
     variable carry: std_logic;
   begin
     carry := '1';
     for I in 0 to 15 loop
        RESULT(I) <= (A(I) xor not B(I)) xor carry;
        carry := (carry and (A(I) or not B(I))) or (A(I) and not B(I));
     end loop;
     RESULT(16) <= not carry;
   end process;
end Serial;

library ieee;
use ieee.std_logic_1164.all;
entity Decrement6 is
   port (A: in std_logic_vector(4 downto 0); B: out std_logic_vector(4 downto 0));
end entity Decrement6;

architecture Serial of Decrement6 is
begin
  process(A)
    variable borrow: std_logic;
  begin 
    borrow := '1';
    for I in 0 to 4 loop
       B(I) <= A(I) xor borrow;
       borrow := borrow and (not A(I));
    end loop;
  end process; 
end Serial;

library ieee;
use ieee.std_logic_1164.all;
entity Increment5 is
   port (A: in std_logic_vector(4 downto 0); B: out std_logic_vector(4 downto 0));
end entity Increment5;

architecture Serial of Increment5 is
begin
  process(A)
    variable carry: std_logic;
  begin 
    carry := '1';
    for I in 0 to 4 loop
       B(I) <= A(I) xor carry;
       carry := carry and A(I);
    end loop;
  end process; 
end Serial;

library ieee;
use ieee.std_logic_1164.all;

entity ClockDivider is
    generic (ticks : integer);
    port ( clk_in : in std_logic; clk_out : out std_logic);
end entity;

architecture Count of ClockDivider is
    signal count : integer := 0;
    signal clk_div : std_logic := '0';
begin
    clk_out <= clk_div;

    process(clk_in)
    begin
        if(clk_in'event and clk_in = '1') then
            if (count = ticks) then
                clk_div <= not clk_div;
                count <= 0;
            else
                count <= count + 1;
            end if;
        end if;
    end process;
end Count;
