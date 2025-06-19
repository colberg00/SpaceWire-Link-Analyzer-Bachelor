-- Entitet: DE10_LITE_Empty_Top
-- Beskrivelse: Sammensætning af hele systemet til syntese på DE10 Lite board

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity DE10_LITE_Empty_Top is
    port(
        MAX10_CLK1_50 : in std_logic;
        KEY           : in std_logic_vector(0 downto 0);
        GPIO          : inout std_logic_vector(0 downto 0);
        LEDR          : out std_logic_vector(7 downto 0);
        HEX0          : out std_logic_vector(7 downto 0);
        HEX1          : out std_logic_vector(7 downto 0);
        HEX2          : out std_logic_vector(7 downto 0);
        HEX3          : out std_logic_vector(7 downto 0);
        HEX4          : out std_logic_vector(7 downto 0)
    );
end entity DE10_LITE_Empty_Top;

architecture DE10_LITE_Empty_Top_arch of DE10_LITE_Empty_Top is

-- Data-bit output fra bit-feeder
signal d_out        : std_logic := '0';

-- Strobe-bit output fra bit-feeder
signal s_out        : std_logic := '0'; 

-- Clock genereret via D xor S
signal clk_save     : std_logic := '0';

-- Synkroniseret og stabiliseret clock-signal der har været igennem GPIO
signal clk_stable   : std_logic := '0';

-- Samlet to bit fra data_collect
signal two_bit_out  : std_logic_vector(1 downto 0) := (others => '0');

-- Samlet 8-bit fra sys-col
signal data_done    : std_logic_vector(7 downto 0) := (others => '0');

-- Error end-of-packet flag
signal eep_done     : std_logic := '0';

-- End-of-data flag
signal eop_done     : std_logic := '0';

-- New data char flag
signal nchar_done   : std_logic := '0';

-- Paritetsfejl flag
signal p_err_done   : std_logic := '0';

-- Valid data/kontrol flag 
signal valid_done   : std_logic := '0';

-- Bit_feeder: Danner foruddefineret simuleret SW kommunikationsflow (data + strobe)
component bit_feeder 
    port (
        clk50mhz   : in  std_logic;
        reset      : in  std_logic;
        D          : out std_logic;
        S          : out std_logic
    );
end component;

-- Clock_create: Genererer clock-signal via XOR af data og strobe
component clock_create 
    port(
        D       : in  std_logic;
        S       : in  std_logic;
        Clk_gen : out std_logic
    );
end component;

-- GPIO buffer: Sender den genererede clock igennem I/O for at stabilisere signalet til videre brug
component gpio_lite is
    port (
        dout   : out   std_logic_vector(0 downto 0);
        din    : in    std_logic_vector(0 downto 0) := (others => '0');
        pad_io : inout std_logic_vector(0 downto 0) := (others => '0');
        oe     : in    std_logic_vector(0 downto 0) := (others => '0')
    );
end component;

-- data_collect: Opsamler databits på hhv. rising og falling og sender de to opsamlede databits videre på rising
component data_collect
    port(
        Clk_stable : in  std_logic;
        D          : in  std_logic;
        two_bit_d  : out std_logic_vector(1 downto 0)
    );
end component;

-- Sys_col: Main logic system, der sammensætter SM1 (dataparsing FSM) og SM2 (systemlogik FSM)
component sys_col is
    port(
        Data_in    : in  std_logic_vector(1 downto 0);
        reset_in   : in  std_logic;
        clk50mhz   : in  std_logic;
        clk_stable : in  std_logic;
        data_out   : out std_logic_vector(7 downto 0);
        EEP_out    : out std_logic;
        EOP_out    : out std_logic;
        Nchar_out  : out std_logic;
        p_err_out  : out std_logic;
        valid_out  : out std_logic
    );
end component;

begin

-- Initialisering af ovenstående komponenter

bit_feed : bit_feeder 
    port map(
        clk50mhz   => MAX10_CLK1_50,
        reset      => KEY(0),
        D          => d_out,
        S          => s_out
    );

clock_gen : clock_create
    port map(
        D       => d_out,
        S       => s_out,
        Clk_gen => clk_save
    );

buff1 : gpio_lite
    port map(
        dout(0)   => clk_stable,
        din(0)    => clk_save,
        pad_io(0) => GPIO(0),
        oe(0)     => '1'
    );

data_col : data_collect
    port map(
        Clk_stable  => clk_stable,
        D           => d_out,
        two_bit_d   => two_bit_out
    );

sam_sys : sys_col
    port map(
        Data_in    => two_bit_out,
        reset_in   => KEY(0),
        clk50mhz   => MAX10_CLK1_50,
        clk_stable => clk_stable,
        data_out   => data_done,
        EEP_out    => eep_done,
        EOP_out    => eop_done,
        Nchar_out  => nchar_done,
        p_err_out  => p_err_done,
        valid_out  => valid_done
    );

-- Process til opdatering af LED og 7-segment displays baseret på systemets status
process (MAX10_CLK1_50, KEY(0))
begin
    if KEY(0) = '1' then
        LEDR <= (others => '0');
        HEX0 <= (others => '1');
        HEX1 <= (others => '1');
        HEX2 <= (others => '1');
        HEX3 <= (others => '1');
        HEX4 <= (others => '1');

    elsif rising_edge(MAX10_CLK1_50) then
        LEDR(7 downto 0) <= data_done;

        case eep_done is
            when '0'     => HEX0 <= "01000000"; -- 0
            when '1'     => HEX0 <= "01111001"; -- 1
            when others  => HEX0 <= "01111111";
        end case;

        case eop_done is
            when '0'     => HEX1 <= "01000000";
            when '1'     => HEX1 <= "01111001";
            when others  => HEX1 <= "01111111";
        end case;

        case nchar_done is
            when '0'     => HEX2 <= "01000000";
            when '1'     => HEX2 <= "01111001";
            when others  => HEX2 <= "01111111";
        end case;

        case p_err_done is
            when '0'     => HEX3 <= "01000000";
            when '1'     => HEX3 <= "01111001";
            when others  => HEX3 <= "01111111";
        end case;

        case valid_done is
            when '0'     => HEX4 <= "01000000";
            when '1'     => HEX4 <= "01111001";
            when others  => HEX4 <= "01111111";
        end case;
    end if;
end process;

end architecture;
