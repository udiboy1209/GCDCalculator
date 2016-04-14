library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity CCU is
    port (
        start, capture, display, clk_in, reset: in std_logic;
        done: out std_logic;
        DAC_OUT: out std_logic_vector(7 downto 0);

        -- adcc pins
        ADC_DATA: in std_logic_vector(7 downto 0);
        CS_ADC, WR, RD: out std_logic;
        INTR: in std_logic;

        -- smc pins
        ADDR: out std_logic_vector(12 downto 0);
        IO: inout std_logic_vector(7 downto 0);
        CS_SRAM, WE, OE: out std_logic
    );

    type fsm_states is (rst,capturestate,sramstore,displaystate,donestate);
end entity;

architecture FSM of CCU is
    signal clk, khz_clk : std_logic;

    signal fsm_state: fsm_states := rst;
    signal clock_count: integer;

    signal adc_convert, adc_ready: std_logic;
    signal adc_out : std_logic_vector(7 downto 0);

    signal sram_start, sram_write, sram_ready: std_logic;
    signal sram_addr : std_logic_vector(12 downto 0);
    signal sram_write_data, sram_read_data : std_logic_vector(7 downto 0);

    component SRAMInterface
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
    end component;

    component ADCInterface
        port (
            ADC_DATA: in std_logic_vector(7 downto 0);
            CS, WR, RD: out std_logic;
            INTR: in std_logic;
            LED: out std_logic_vector(7 downto 0);
            start, clk, reset: in std_logic;
            done: out std_logic
        );
    end component;

    component ClockDivider
        generic (ticks : integer);
        port ( clk_in : in std_logic; clk_out : out std_logic);
    end component;
begin
    adcc : ADCInterface port map (ADC_DATA => ADC_DATA, CS => CS_ADC, WR => WR, RD => RD, INTR => INTR, LED => adc_out, start => adc_convert, done => adc_ready, clk => clk, reset => reset);

    smc : SRAMInterface port map (ADDR => ADDR, CS => CS_SRAM, WE => WE, OE => OE, ADDR_DATA => sram_addr, WR_DATA => sram_write_data, RD_DATA => sram_read_data, start => sram_start, done => sram_ready, write => sram_write, reset => reset, clk => clk);

    clk_divider : ClockDivider generic map ( ticks => 100) port map ( clk_in => clk_in, clk_out => clk);

    khz_divider : ClockDivider generic map ( ticks => 500000) port map ( clk_in => clk, clk_out => khz_clk);

    sram_write_data <= adc_out;

    process(start, reset, capture, display) is
        variable nstate : fsm_states := fsm_state;
        variable done_var, adc_convert_var, sram_start_var, sram_write_var: std_logic;
        variable DAC_var: std_logic_vector(7 downto 0);
        variable sram_write_data_var: std_logic_vector(7 downto 0);
        variable clock_count_in : integer := clock_count;

        variable addr_count_in : integer := to_integer(unsigned(sram_addr));
    begin
        -- Default High
        done_var := '0';
        adc_convert_var := '0';
        sram_start_var := '0';
        sram_write_var := '0';

        case fsm_state is
            when rst =>
                if(khz_clk'event and khz_clk = '1') then
                    if (capture = '1') then
                        addr_count_in := addr_count_in + 1;
                        nstate := capturestate;
                        adc_convert_var := '1';
                    else
                        if (display = '1') then
                            addr_count_in := addr_count_in + 1;
                            sram_write_var := '0';
                            sram_start_var := '1';
                            nstate := displaystate;
                        else
                        end if;
                    end if;
                end if;
            when capturestate =>
                if (adc_ready = '1') then
                    nstate := sramstore;
                    sram_write_var := '1';
                    sram_start_var := '1';
                end if;
            when sramstore =>
                if(sram_ready = '1') then
                    nstate := donestate;
                end if;
            when displaystate =>
                if(sram_ready = '1') then
                    DAC_var := sram_read_data;
                    nstate := rst;
                end if;
            when donestate =>
                done_var := '1';
                nstate := donestate;
        end case;

        if(clk'event and clk = '1') then
            done <= done_var;
            DAC_OUT <= DAC_var;
            adc_convert <= adc_convert_var;

            sram_addr <= std_logic_vector(to_unsigned(addr_count_in, sram_addr'length));
            sram_write <= sram_write_var;
            sram_start <= sram_start_var;

            if(reset = '1') then
                fsm_state <= rst;
            else
                fsm_state <= nstate;
            end if;
        end if;
    end process;
end FSM;
