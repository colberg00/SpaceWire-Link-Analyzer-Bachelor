-- Entitet: sys_col
-- Beskrivelse: Samling af SM1 og SM2 med koordinering af signalerne mellem dem via domain_shift. 
--              SM1 samler to input-bit og genererer bl.a. kontrolsignaler. Disse synkroniseres til
--              SM2’s clock-domæne, før de behandles i SM2. SM2 genererer reset_out-signalet, der 
--              bruges til styring af SM1.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sys_col is
port(
	Data_in     : in std_logic_vector(1 downto 0);
	reset_in    : in std_logic;
	clk50mhz    : in std_logic;
	clk_stable     : in std_logic;

	data_out    : out std_logic_vector(7 downto 0);
	EEP_out     : out std_logic;
	EOP_out     : out std_logic;
	Nchar_out   : out std_logic;
	p_err_out   : out std_logic;
	valid_out   : out std_logic
	);
end entity;

architecture sys_col_arch of sys_col is

-- Interne kontrolsignaler fra SM1
signal fct_sig1     : std_logic := '0';
signal nul_sig1     : std_logic := '0';
signal ts_sig1      : std_logic := '0';
signal nchar_sig1   : std_logic := '0';
signal eep_sig1     : std_logic := '0';
signal eop_sig1     : std_logic := '0';
signal p_err_sig1   : std_logic := '0';

-- Reset-signal genereret af SM2 til kontrol af SM1
signal reset_sig1   : std_logic := '0';

-- Synkroniserede signaler i SM2’s clock-domæne
signal fct_sig2     : std_logic := '0';
signal nul_sig2     : std_logic := '0';
signal ts_sig2      : std_logic := '0';
signal nchar_sig2   : std_logic := '0';
signal eep_sig2     : std_logic := '0';
signal eop_sig2     : std_logic := '0';
signal p_err_sig2   : std_logic := '0';

-- Komponentdeklaration for SM1 (dataparsing FSM)
component SM1 
Port(
	Clk_stable : in std_logic;
	reset      : in std_logic;
	Data_in    : in std_logic_vector(1 downto 0);

	FCT        : out std_logic;
	NUL        : out std_logic;
	TS         : out std_logic;
	Nchar      : out std_logic;
	EEP        : out std_logic;
	EOP        : out std_logic;
	p_err      : out std_logic;
	Valid      : out std_logic;
	Data_out   : out std_logic_vector(7 downto 0)
);
end component;

-- Komponentdeklaration for SM2 (systemlogik FSM)
component SM2 is
port (
	clk50mhz   : in std_logic;
	reset      : in std_logic;

	FCT        : in std_logic;
	NUL        : in std_logic;
	TS         : in std_logic;
	Nchar      : in std_logic;
	EEP        : in std_logic;
	EOP        : in std_logic;
	p_err      : in std_logic;
	reset_out  : out std_logic
);
end component;

-- Komponent til håndtering af clock-domain crossing
component clock_domain_shift is
	port (
	clk_in     : in std_logic;
	clk_out    : in std_logic;
	signal_in  : in std_logic;
	reset      : in std_logic;
	signal_out : out std_logic
	);
end component;

begin

-- Instansiering af SM1
sm1_comp : SM1
	port map (
		Clk_stable  => clk_stable,
		reset       => reset_sig1,
		Data_in     => Data_in,
		FCT         => fct_sig1,
		NUL         => nul_sig1,
		TS          => ts_sig1,
		Nchar       => nchar_sig1,
		EEP         => eep_sig1,
		EOP         => eop_sig1,
		p_err       => p_err_sig1,
		Valid       => valid_out,
		Data_out    => data_out
	);

-- Instansiering af clock-domæne shiftere
FCT_shift : clock_domain_shift
	port map (
	clk_in     => clk_stable,
	clk_out    => clk50mhz,
	signal_in  => fct_sig1,
	reset      => reset_in,
	signal_out => fct_sig2
	);

NULL_shift : clock_domain_shift
	port map (
	clk_in     => clk_stable,
	clk_out    => clk50mhz,
	signal_in  => nul_sig1,
	reset      => reset_in,
	signal_out => nul_sig2
	);

TS_shift : clock_domain_shift
	port map (
	clk_in     => clk_stable,
	clk_out    => clk50mhz,
	signal_in  => ts_sig1,
	reset      => reset_in,
	signal_out => ts_sig2
	);

Nchar_shift : clock_domain_shift
	port map (
	clk_in     => clk_stable,
	clk_out    => clk50mhz,
	signal_in  => nchar_sig1,
	reset      => reset_in,
	signal_out => nchar_sig2
	);

EEp_shift : clock_domain_shift
	port map (
	clk_in     => clk_stable,
	clk_out    => clk50mhz,
	signal_in  => eep_sig1,
	reset      => reset_in,
	signal_out => eep_sig2
	);

EOD_shift : clock_domain_shift
	port map (
	clk_in     => clk_stable,
	clk_out    => clk50mhz,
	signal_in  => eop_sig1,
	reset      => reset_in,
	signal_out => eop_sig2
	);

Perr_shift : clock_domain_shift
	port map (
	clk_in     => clk_stable,
	clk_out    => clk50mhz,
	signal_in  => p_err_sig1,
	reset      => reset_in,
	signal_out => p_err_sig2
	);

-- Instansiering af SM2
sm2_comp : SM2
	port map (
		clk50mhz  => clk50mhz,
		reset     => reset_in,
		FCT       => fct_sig2,
		NUL       => nul_sig2,
		TS        => ts_sig2,
		Nchar     => nchar_sig2,
		EEP       => eep_sig2,
		EOP       => eop_sig2,
		p_err     => p_err_sig2,
		reset_out => reset_sig1
		);

-- Outputlogik til generering af signaler til videre brug
process(clk_stable, reset_in)
begin 
	if reset_in = '1' then
		EEP_out    <= '0';
		EOP_out    <= '0';
		p_err_out  <= '0';
		Nchar_out  <= '0';
	elsif rising_edge(clk_stable) then
		EEP_out    <= eep_sig1;
		EOP_out    <= eop_sig1;
		p_err_out  <= p_err_sig1;
		Nchar_out  <= nchar_sig1;
	end if;
end process;

end architecture;
