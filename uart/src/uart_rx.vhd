library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port (
        clock : in std_logic;
        reset : in std_logic;
        tick  : in std_logic;
        rx    : in std_logic;
        done  : out std_logic;
        data  : out std_logic_vector(7 downto 0)
    );
end uart_rx;

architecture uart_rx of uart_rx is
    type state_t is (
        wait_transmission,
        data_bits
    );

    signal current_state : state_t;
    signal next_state    : state_t;

    signal tick_counter      : unsigned(3 downto 0);
    signal tick_counter_next : unsigned(3 downto 0);

    signal num_bits      : unsigned(3 downto 0);
    signal num_bits_next : unsigned(3 downto 0);

    signal data_rx      : std_logic_vector(9 downto 0);
    signal data_rx_next : std_logic_vector(9 downto 0);
begin

    data <= data_rx(8 downto 1);

    process (clock, reset)
    begin
        if reset = '1' then
            current_state <= wait_transmission;
            tick_counter  <= "0000";
            num_bits      <= "0000";
            data_rx       <= "0000000000";
        elsif clock'event and clock = '1' then
            current_state <= next_state;
            tick_counter  <= tick_counter_next;
            num_bits      <= num_bits_next;
            data_rx       <= data_rx_next;
        end if;
    end process;

    process (current_state, tick_counter, num_bits, rx, tick, data_rx)
    begin
        next_state        <= current_state;
        tick_counter_next <= tick_counter;
        num_bits_next     <= num_bits;
        data_rx_next      <= data_rx;
        done <= '0';

        case current_state is
            when wait_transmission =>
                tick_counter_next <= "0000";
                num_bits_next     <= "0000";

                if rx = '0' then
                    next_state <= data_bits;
                end if;

            when data_bits =>
                if tick = '1' then
                    if tick_counter = 7 then
                        tick_counter_next <= "1000";
                        data_rx_next <= rx & data_rx(9 downto 1);

                        if num_bits = 9 then
                            next_state <= wait_transmission;
                            done <= '1';
                        else
                            num_bits_next <= num_bits + 1;
                        end if;
                    else
                        tick_counter_next <= tick_counter + 1;
                    end if;
                end if;
        end case;
    end process;
end uart_rx;
