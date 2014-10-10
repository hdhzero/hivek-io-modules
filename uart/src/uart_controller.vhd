library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- In linux, one can use GtkTerm

-- This uart_controller module uses:
--     - 8 bits (data)
--     - no parity bit
--     - 1 stop bit

entity uart_controller is
    generic (
        CLK_FREQ  : integer := 50000000; -- in hertz
        BAUD_RATE : integer := 19200
    );
    port (
        clock : in std_logic;
        reset : in std_logic;

        -- receiver interface
        rx_data  : out std_logic_vector(7 downto 0);
        rx_empty : out std_logic;
        rx_read  : in std_logic;

        -- transmiter interface
        tx_data  : in std_logic_vector(7 downto 0);
        tx_write : in std_logic;
        tx_busy  : out std_logic;

        -- rs232
        rx : in std_logic;
        tx : out std_logic
    );
end uart_controller;

architecture uart_controller of uart_controller is
    constant SAMPLING_RATE : integer := BAUD_RATE * 16;
    constant ROUND : integer := CLK_FREQ + SAMPLING_RATE - 1;
    constant MOD_VALUE : integer := ROUND / SAMPLING_RATE;

    signal rx_done   : std_logic;
    signal tx_done   : std_logic;
    signal baud_tick : std_logic;

    signal rx_data_tmp : std_logic_vector(7 downto 0);
begin
    process (clock, reset)
    begin
        if reset = '1' then
            rx_data  <= (others => '0');
            rx_empty <= '1';
            tx_busy  <= '0';
        elsif clock'event and clock = '1' then
            if rx_done = '1' then
                rx_data <= rx_data_tmp;
            end if;

            if rx_done = '1' then
                rx_empty <= '0';
            elsif rx_read = '1' then
                rx_empty <= '1';
            end if;

            if tx_done = '1' then
                tx_busy <= '0';
            elsif tx_write = '1' then
                tx_busy <= '1';
            end if;
        end if;
    end process;

    mod_counter_c : entity work.mod_counter
    generic map (
        N_BITS => 15, -- large enough, I hope
        MOD_VALUE => MOD_VALUE
    )
    port map (
        clock => clock,
        reset => reset,
        tick  => baud_tick,
        value => open
    );

    uart_receiver : entity work.uart_rx
    port map (
        clock => clock,
        reset => reset,
        tick  => baud_tick,
        done  => rx_done,
        data  => rx_data_tmp,
        rx    => rx
    );

    uart_transmitter : entity work.uart_tx
    port map (
        clock => clock,
        reset => reset,
        tick  => baud_tick,
        start => tx_write,
        done  => tx_done,
        data  => tx_data,
        tx    => tx
    );
end uart_controller;
