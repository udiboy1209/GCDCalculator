library ieee;
use ieee.std_logic_1164.all;

entity ADCInterface is
    port (
        ADC_DATA: in std_logic_vector(7 downto 0);
        CS, WR, RD: out std_logic;
        INTR: in std_logic;
        LED: out std_logic_vector(7 downto 0);
        start, clk, reset: in std_logic;
        done: out std_logic
    );

    type fsm_states is (rst,read,write,output,donestate);
end entity;

architecture FSM of ADCInterface is
    signal fsm_state: fsm_states := rst;
begin
    process(INTR, ADC_DATA, clk, reset, fsm_state)
        variable nstate : fsm_states := fsm_state;
        variable RD_var, WR_var, CS_var, done_var: std_logic;
    begin
        -- Default High
        CS_var := '0';
        RD_var := '1';
        WR_var := '1';
        done_var := '0';

        case fsm_state is
            when rst =>
                CS_var := '1';
                if (start = '0') then
                    CS_var := '0';
                    nstate := write;
                end if;
            when write =>
                WR_var := '0';
                nstate := read;
            when read =>
                if (INTR = '0') then
                    nstate := output;
                end if;
            when output =>
                LED <= ADC_DATA;
                RD_var := '0';
                nstate := donestate;
            when donestate =>
                CS_var := '1';
                done_var := '1';
                nstate := rst;
        end case;

        if(clk'event and clk = '1') then
            RD <= RD_var;
            WR <= WR_var;
            CS <= CS_var;
            done <= done_var;

            if(reset = '1') then
                fsm_state <= rst;
            else
                fsm_state <= nstate;
            end if;
        end if;
    end process;
end FSM;
