library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity problem1_test is
  Port (
    clk   : in  std_logic;                         -- 50 MHz
    sw    : in  std_logic_vector(3 downto 0);       -- SW0..SW3
    btnE  : in  std_logic;                         -- BTN_EAST  (increment)
    btnS  : in  std_logic;                         -- BTN_SOUTH (reset)
    led   : out std_logic_vector(7 downto 0)        -- LED7..LED0
  );
end problem1_test;

architecture rtl of problem1_test is
  -- debounced/edge-detected button
  signal b1, b2, bprev : std_logic := '0';
  signal brise         : std_logic := '0';

  signal count : unsigned(3 downto 0) := (others => '0');
begin

  -- Sync + rising edge detect for BTN_EAST
  process(clk)
  begin
    if rising_edge(clk) then
      b1    <= btnE;
      b2    <= b1;
      bprev <= b2;
    end if;
  end process;

  brise <= b2 and (not bprev);

  -- Counter: BTN_EAST increments, BTN_SOUTH resets
  process(clk)
  begin
    if rising_edge(clk) then
      if btnS = '1' then
        count <= (others => '0');
      elsif brise = '1' then
        count <= count + 1;
      end if;
    end if;
  end process;

  -- LEDs:
  -- LED7..LED4 show switches
  -- LED3..LED0 show HEX counter
  led <= sw & std_logic_vector(count);

end rtl;
