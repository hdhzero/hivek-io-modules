library ieee;
use ieee.std_logic_1164.all;

entity hex_disp is
    port (
        v : in std_logic_vector(3 downto 0);
        s : out std_logic_vector(6 downto 0)
    );
end hex_disp;

architecture hex_disp_arch of hex_disp is
    signal t : std_logic_vector(6 downto 0);
begin
    s(6) <= t(0);
    s(5) <= t(1);
    s(4) <= t(2);
    s(3) <= t(3);
    s(2) <= t(4);
    s(1) <= t(5);
    s(0) <= t(6);

    with v select
        t <= "1111110" when "0000",
             "0110000" when "0001",
             "1101101" when "0010",
             "1111001" when "0011",
             "0110011" when "0100",
             "1011011" when "0101",
             "1011111" when "0110",
             "1110000" when "0111",
             "1111111" when "1000",
             "1111011" when "1001",
             "1110111" when "1010",
             "0011111" when "1011",
             "1001110" when "1100",
             "0111101" when "1101",
             "1001111" when "1110",
             "1000111" when others;
end hex_disp_arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_uart_controller is
    port (
        clock_50mhz : in std_logic;
        GPIO0_D     : in std_logic_vector(31 downto 0);
        SW          : in std_logic_vector(3 downto 0);
        KEY         : in std_logic_vector(11 downto 0);
        DISP0_D     : out std_logic_vector(7 downto 0);
        DISP1_D     : out std_logic_vector(7 downto 0);
        UART_RXD    : in std_logic;
        UART_TXD    : out std_logic
    );
end top_uart_controller;

architecture top_uart_controller of top_uart_controller is
    signal clock : std_logic;
    signal reset : std_logic;

        -- receiver interface
    signal rx_data  : std_logic_vector(7 downto 0);
    signal rx_empty : std_logic;
    signal rx_read  : std_logic;

        -- transmiter interface
    signal tx_data  : std_logic_vector(7 downto 0);
    signal tx_write : std_logic;
    signal tx_busy  : std_logic;

        -- rs232
    signal rx : std_logic;
    signal tx : std_logic;

    signal tx_writeA : std_logic;
    signal tx_writeB : std_logic;
begin
    clock <= clock_50mhz;
    reset <= sw(0);
--    tx_data <= GPIO0_D(7 downto 0);
    DISP0_D(7) <= tx_busy;
    DISP1_D(7) <= rx_empty;
--    rx <= UART_RXD;
    UART_TXD <= tx;
    rx <= tx;

    process (clock, reset)
    begin
        if reset = '1' then
            tx_data <= (others => '0');
        elsif clock'event and clock = '1' then
            if tx_write = '1' then
                tx_data <= std_logic_vector(unsigned(tx_data) + 1);
            end if;
        end if;
    end process;

    B0 : entity work.bit_button_module 
    port map (clock, reset, key(9), rx_read);

    B1 : entity work.bit_button_module
    generic map (TICK => 0)
    port map (clock, reset, key(10), tx_writeA);

    B2 : entity work.bit_button_module
    generic map (TICK => 1)
    port map (clock, reset, key(11), tx_writeB);

    tx_write <= tx_writeA or tx_writeB;

    H0 : entity work.hex_disp
    port map (rx_data(3 downto 0), DISP0_D(6 downto 0));

    H1 : entity work.hex_disp
    port map (rx_data(7 downto 4), DISP1_D(6 downto 0));

    C0 : entity work.uart_controller
    port map (
        clock, reset, rx_data, rx_empty, rx_read, tx_data, tx_write, 
        tx_busy, rx, tx
    );
end top_uart_controller;
