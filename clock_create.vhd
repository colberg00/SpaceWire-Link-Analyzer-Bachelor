-- Entitet: clock_create
-- Beskrivelse: Logik til generering af clocksignal ved XOR af inputsignaler
--              data og strobe som defineret i SW-protokollen

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clock_create is
    port(
        D       : in  std_logic;
        S       : in  std_logic;
        Clk_gen : out std_logic
    );
end entity clock_create;

-- Main process: Output clock genereres ud fra inputsignaler
architecture clock_create_arch of clock_create is
begin

    Clk_gen <= D xor S;

end architecture clock_create_arch;
