library ieee;
use ieee.std_logic_1164.all;
use work.RTLComponents.all;

entity SRAMInterface is
    port (
        ADDR: out std_logic_vector(12 downto 0);
        IO: inout std_logic_vector(7 downto 0);
        CS, WE, OE: out std_logic;
        ADDR_DATA: in std_logic_vector(12 downto 0);
        WR_DATA: in std_logic_vector(7 downto 0);
        RD_DATA: out std_logic_vector(7 downto 0);
        start, write, clk, reset: in std_logic;
        done: out std_logic
    );

    type fsm_states is (rst,writestate,readstate,output,donestate);
end entity;

architecture FSM of SRAMInterface is
    signal fsm_state: fsm_states := rst;
    signal write_wait_count, read_wait_count : integer;
begin
    process(IO, start, clk, reset, WR_DATA, IO, ADDR_DATA) is
        variable nstate : fsm_states := fsm_state;
        variable CS_var, WE_var, OE_var, done_var: std_logic;
        variable ADDR_var: std_logic_vector(12 downto 0);
        variable IO_var: std_logic_vector(7 downto 0);
        variable write_wait_count_in : integer := write_wait_count;
        variable read_wait_count_in : integer := read_wait_count;
    begin
        -- Default High
        CS_var := '0';
        WE_var := '1';
        OE_var := '1';
        done_var := '0';

        case fsm_state is
            when rst =>
                CS_var := '1';
                if (start = '1') then
                    ADDR_var := ADDR_DATA;
                    CS_var := '0';
                    if (write = '1') then
                        nstate := writestate;
                        write_wait_count_in := 4;
                    else
                        nstate := readstate;
                    end if;
                end if;
            when writestate =>
                WE_var := '0';
                if (write_wait_count_in = 0) then
                    IO_var := WR_DATA;
                    nstate := donestate;
                else
                    write_wait_count_in := write_wait_count_in - 1;
                end if;
            when readstate =>
                OE_var := '0';
                if (read_wait_count_in = 0) then
                    RD_DATA <= IO;
                    nstate := donestate;
                else
                    read_wait_count_in := read_wait_count_in - 1;
                end if;
            when output =>
            when donestate =>
                done_var := '1';
                nstate := rst;
        end case;

        if(clk'event and clk = '1') then
            CS <= CS_var;
            WE <= WE_var;
            OE <= OE_var;
            done <= done_var;

            ADDR <= ADDR_var;
            IO <= IO_var;

            write_wait_count <= write_wait_count_in;

            if(reset = '1') then
                fsm_state <= rst;
            else
                fsm_state <= nstate;
            end if;
        end if;
    end process;
end FSM;
