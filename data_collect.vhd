-- Entitet: data_collect
-- Beskrivelse: Opsamler to bit fra data input signalet
-- over rising og falling edge og outputter de to bit 
-- på rising edge.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity data_collect is
    Port (
        Clk_stable : in  std_logic;
        D          : in  std_logic;
        two_bit_d  : out std_logic_vector(1 downto 0)
    );
end entity data_collect;

-- Main process: Output datavektor genereres ud fra de to opsamlede databits.
architecture data_collect_arch of data_collect is
    signal bit0, bit1 : std_logic;
begin

    -- Fanger bit0 på rising edge og genererer output
    process(Clk_stable )
    begin
        if rising_edge(Clk_stable ) then
            bit0 <= D;
            two_bit_d <= bit0 & bit1;
        end if;
    end process;

    -- Fanger bit1 på falling edge
    process(Clk_stable )
    begin
        if falling_edge(Clk_stable ) then
            bit1 <= D;
        end if;
    end process;

end architecture data_collect_arch;
