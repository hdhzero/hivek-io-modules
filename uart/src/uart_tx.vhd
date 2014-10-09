library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    port (
        clock : in std_logic;
        reset : in std_logic;
        tick  : in std_logic;
        start : in std_logic;
        data  : in std_logic_vector(7 downto 0);
        done  : out std_logic;
        tx    : out std_logic
    );
end uart_tx;

architecture uart_tx of uart_tx is
    type state_t is (
        wait_transmission,
        data_bits
    );

    signal current_state : state_t;
    signal next_state    : state_t;

    signal tx_reg  : std_logic;
    signal tx_next : std_logic;

    signal tick_counter      : unsigned(3 downto 0);
    signal tick_counter_next : unsigned(3 downto 0);

    signal num_bits      : unsigned(3 downto 0);
    signal num_bits_next : unsigned(3 downto 0);

    signal data_tx      : std_logic_vector(9 downto 0);
    signal data_tx_next : std_logic_vector(9 downto 0);
begin
    tx <= tx_reg;

    process (clock, reset)
    begin
        if reset = '1' then
            current_state <= wait_transmission;
            tx_reg        <= '1';
            num_bits      <= "0000";
            tick_counter  <= "0000";
            data_tx       <= "0000000000";
        elsif clock'event and clock = '1' then
            current_state <= next_state;
            tx_reg        <= tx_next;
            num_bits      <= num_bits_next;
            tick_counter  <= tick_counter_next;
            data_tx       <= data_tx_next;
        end if;
    end process;

    process (current_state, tx_reg, num_bits, tick_counter, data_tx, tick, start)
    begin
        next_state        <= current_state;
        tx_next           <= tx_reg;
        num_bits_next     <= num_bits;
        tick_counter_next <= tick_counter;
        data_tx_next      <= data_tx;
        done <= '0';

        case current_state is
            when wait_transmission =>
                tx_next <= '1';
                num_bits_next     <= "0000";
                tick_counter_next <= "0000";
                data_tx_next      <= '1' & data & '0';

                if start = '1' then
                    next_state <= data_bits;
                end if;

            when data_bits =>
                tx_next <= data_tx(0);

                if tick = '1' then
                    if tick_counter = 15 then
                        tick_counter_next <= "0000";
                        data_tx_next <= '0' & data_tx(9 downto 1);

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
end uart_tx;
