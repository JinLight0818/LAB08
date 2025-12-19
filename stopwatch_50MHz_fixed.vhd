library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity stopwatch_50MHz is
    Port (
        clk       : in  std_logic;                     -- 50 MHz system clock
        btn_start : in  std_logic;
        btn_stop  : in  std_logic;
        btn_reset : in  std_logic;
        an        : out std_logic_vector(3 downto 0);  -- digit enables (active low)
        seg       : out std_logic_vector(6 downto 0)   -- segments (active low)
    );
end stopwatch_50MHz;

architecture Behavioral of stopwatch_50MHz is

    -- 50MHz -> 1Hz single-cycle pulse
    constant ONE_SECOND   : natural := 50_000_000;
    signal counter_1s     : natural range 0 to ONE_SECOND-1 := 0;
    signal tick_1hz_pulse : std_logic := '0';

    -- Debounce counters (~20ms)
    constant DEBOUNCE_MAX : natural := 1_000_000;
    signal s_cnt, p_cnt, r_cnt : natural range 0 to DEBOUNCE_MAX := 0;
    signal s_clean, p_clean, r_clean : std_logic := '0';
    signal s_prev,  p_prev,  r_prev  : std_logic := '0';
    signal s_edge,  p_edge,  r_edge  : std_logic := '0';

    -- Stopwatch state and BCD digits (0000..9999, increments each second)
    signal running : std_logic := '0';
    signal ones, tens, hundreds, thousands : natural range 0 to 9 := 0;

    -- Digit multiplex
    signal clkdiv    : unsigned(25 downto 0) := (others=>'0');
    signal digit_sel : unsigned(1 downto 0) := (others=>'0');
    signal current_digit : natural range 0 to 9 := 0;

begin

    --------------------------------------------------------------------
    -- 1 Hz one-clock pulse generator
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if counter_1s = ONE_SECOND-1 then
                counter_1s     <= 0;
                tick_1hz_pulse <= '1';
            else
                counter_1s     <= counter_1s + 1;
                tick_1hz_pulse <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Debounce + rising-edge detect (pressed = '1')
    --------------------------------------------------------------------
   process(clk)
begin
    if rising_edge(clk) then

        -- START button
        if btn_start = '1' then
            if s_cnt < DEBOUNCE_MAX then
                s_cnt <= s_cnt + 1;
            end if;
        else
            s_cnt <= 0;
        end if;

        if s_cnt = DEBOUNCE_MAX then
            s_clean <= '1';
        else
            s_clean <= '0';
        end if;

        s_edge <= s_clean and (not s_prev);
        s_prev <= s_clean;

        -- STOP button
        if btn_stop = '1' then
            if p_cnt < DEBOUNCE_MAX then
                p_cnt <= p_cnt + 1;
            end if;
        else
            p_cnt <= 0;
        end if;

        if p_cnt = DEBOUNCE_MAX then
            p_clean <= '1';
        else
            p_clean <= '0';
        end if;

        p_edge <= p_clean and (not p_prev);
        p_prev <= p_clean;

        -- RESET button
        if btn_reset = '1' then
            if r_cnt < DEBOUNCE_MAX then
                r_cnt <= r_cnt + 1;
            end if;
        else
            r_cnt <= 0;
        end if;

        if r_cnt = DEBOUNCE_MAX then
            r_clean <= '1';
        else
            r_clean <= '0';
        end if;

        r_edge <= r_clean and (not r_prev);
        r_prev <= r_clean;

    end if;
end process;

    --------------------------------------------------------------------
    -- Control + counter update (increments once per second when running)
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            -- Priority: reset > stop > start
            if r_edge='1' then
                running   <= '0';
                ones      <= 0; tens <= 0; hundreds <= 0; thousands <= 0;

            else
                if p_edge='1' then running <= '0'; end if;
                if s_edge='1' then running <= '1'; end if;

                if (tick_1hz_pulse='1') and (running='1') then
                    if ones = 9 then
                        ones <= 0;
                        if tens = 9 then
                            tens <= 0;
                            if hundreds = 9 then
                                hundreds <= 0;
                                if thousands = 9 then
                                    thousands <= 0;
                                else
                                    thousands <= thousands + 1;
                                end if;
                            else
                                hundreds <= hundreds + 1;
                            end if;
                        else
                            tens <= tens + 1;
                        end if;
                    else
                        ones <= ones + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Digit multiplex (~1 kHz-ish overall scan)
    -- 50MHz / 2^16 = 762 Hz for digit changes (ok for 4 digits)
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            clkdiv <= clkdiv + 1;
        end if;
    end process;

    digit_sel <= clkdiv(17 downto 16);

    process(digit_sel, ones, tens, hundreds, thousands)
    begin
        case to_integer(digit_sel) is
            when 0 =>
                an <= "1110"; current_digit <= ones;
            when 1 =>
                an <= "1101"; current_digit <= tens;
            when 2 =>
                an <= "1011"; current_digit <= hundreds;
            when others =>
                an <= "0111"; current_digit <= thousands;
        end case;
    end process;

    --------------------------------------------------------------------
    -- 7-segment encoding (active low) for digits 0..9
    -- seg = a b c d e f g (common convention used by many labs)
    --------------------------------------------------------------------
    process(current_digit)
    begin
        case current_digit is
            when 0 => seg <= "0000001";
            when 1 => seg <= "1001111";
            when 2 => seg <= "0010010";
            when 3 => seg <= "0000110";
            when 4 => seg <= "1001100";
            when 5 => seg <= "0100100";
            when 6 => seg <= "0100000";
            when 7 => seg <= "0001111";
            when 8 => seg <= "0000000";
            when 9 => seg <= "0000100";
            when others => seg <= "1111111";
        end case;
    end process;

end Behavioral;
