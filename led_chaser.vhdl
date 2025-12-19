library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity led_chaser is
    Port (
        clk    : in  std_logic;       -- 50 MHz system clock
        reset  : in  std_logic;       -- synchronous reset (active-high)
        sw     : in  std_logic;       -- direction switch
        led    : out std_logic_vector(7 downto 0)  -- 8 LEDs
    );
end led_chaser;

architecture Behavioral of led_chaser is
    -- Clock divider: 50 MHz -> ~0.5 sec tick
    signal clk_counter : unsigned(22 downto 0) := (others => '0');
    signal tick        : std_logic := '0';

    signal index : integer range 0 to 7 := 0;
    signal led_reg : std_logic_vector(7 downto 0) := (others => '0');
begin

    -- Clock divider
    process(clk)
    begin
        if rising_edge(clk) then
            if clk_counter = 4_999_999 then
                clk_counter <= (others => '0');
                tick <= '1';
            else
                clk_counter <= clk_counter + 1;
                tick <= '0';
            end if;
        end if;
    end process;

    -- LED chaser logic
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                index   <= 0;
                led_reg <= (others => '0');
            elsif tick = '1' then
                -- Direction control
                if sw = '0' then
                    -- ?????? ????
                    if index = 7 then
                        index <= 0;
                    else
                        index <= index + 1;
                    end if;
                else
                    -- ???? ????
                    if index = 0 then
                        index <= 7;
                    else
                        index <= index - 1;
                    end if;
                end if;

                -- LED update
                led_reg <= (others => '0');
                led_reg(index) <= '1';
            end if;
        end if;
    end process;

    led <= led_reg;

end Behavioral;
