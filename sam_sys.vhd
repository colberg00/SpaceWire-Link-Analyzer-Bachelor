-- Entitet: sam_sys
-- Beskrivelse: Top-level entitet til test og simulering af samlet system,
--              her med simuleret IO-buffer.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sam_sys is
    port (
        reset_in    : in std_logic;
        clk50mhz    : in std_logic;

        data_out    : out std_logic_vector(7 downto 0);
        EEP_out     : out std_logic;
        EOP_out     : out std_logic;
        Nchar_out   : out std_logic;
        p_err_out   : out std_logic;
        valid_out   : out std_logic
    );
end entity sam_sys;

architecture sam_sys_arch of sam_sys is

    -- Data-bit fra bit-feeder
    signal d_out : std_logic := '0';

    -- Strobe-bit fra bit-feeder
    signal s_out : std_logic := '0';

    -- Clock genereret af clock_create som D xor S
    signal clk_save : std_logic := '0';

    -- Output-clock fra simuleret IO-buffer
    signal clk_stable : std_logic := '0';

    -- To-bit samler fra data_collect
    signal two_bit_out : std_logic_vector(1 downto 0) := "00";
	 

    -- Bit_feeder: Danner foruddefineret simuleret SW-kommunikationsflow (data + strobe)
    component bit_feeder 
        port (
            clk50mhz        : in  std_logic;
            reset      : in  std_logic;
            D    : out std_logic;
            S : out std_logic
        );
    end component;

    -- Clock_create: Genererer clock-signal via XOR af data og strobe
    component clock_create 
        port (
            D       : in std_logic;
            S       : in std_logic;
            Clk_gen : out std_logic
        );
    end component;

    -- data_collect: Opsamler databits på hhv. rising og falling og sender de to opsamlede databits videre på rising
    component data_collect
        port (
            Clk_stable : in std_logic;
            D          : in std_logic;
            two_bit_d  : out std_logic_vector(1 downto 0)
        );
    end component;
	 

    -- Sys_col: Main logic system, der sammensætter SM1 (dataparsing FSM) og SM2 (systemlogik FSM)
    component sys_col is
        port (
            Data_in    : in std_logic_vector(1 downto 0);
            reset_in   : in std_logic;
            clk50mhz   : in std_logic;
            clk_stable : in std_logic;

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
        port map (
            clk50mhz   => clk50mhz,
            reset      => reset_in,
            D          => d_out,
            S          => s_out
        );

    clock_gen : clock_create
        port map (
            D       => d_out,
            S       => s_out,
            Clk_gen => clk_save
        );

    data_col : data_collect
        port map (
            Clk_stable => clk_stable,
            D          => d_out,
            two_bit_d  => two_bit_out
        );
	

    sam_sys : sys_col
        port map (
            Data_in    => two_bit_out,
            reset_in   => reset_in,
            clk50mhz   => clk50mhz,
            clk_stable => clk_stable,
            data_out   => data_out,
            EEP_out    => EEP_out,
            EOP_out    => EOP_out,
            Nchar_out  => Nchar_out,
            p_err_out  => p_err_out,
            valid_out  => valid_out
        );

    -- I/O buf simulering
    clk_stable <= clk_save;

end architecture;
