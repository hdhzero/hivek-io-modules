library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mod_counter is
    generic (
        N_BITS    : integer := 4;
        MOD_VALUE : integer := 10
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        tick  : out std_logic;
        value : out std_logic_vector(N_BITS - 1 downto 0)
    );
end mod_counter;

architecture mod_counter of mod_counter is
    signal counter    : unsigned(N_BITS - 1 downto 0);
    signal nx_counter : unsigned(N_BITS - 1 downto 0);
begin
    value <= std_logic_vector(counter);

    process (clock, reset)
    begin
        if reset = '1' then
            counter <= (others => '0');
        elsif clock'event and clock = '1' then
            counter <= nx_counter;
        end if;
    end process;

    process (counter)
    begin
        if counter = MOD_VALUE - 1 then
            nx_counter <= (others => '0');
            tick <= '1';
        else
            nx_counter <= counter + 1;
            tick <= '0';
        end if;
    end process;
end mod_counter;
