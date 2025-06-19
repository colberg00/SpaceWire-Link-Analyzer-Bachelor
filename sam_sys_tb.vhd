-- Entitet: sam_sys_tb
-- Beskrivelse: Testbench-entitet uden porte. Bruges til simulering og verificering
--              af systemet samt generering af outputfil.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

library STD;
use STD.TEXTIO.ALL;

entity sam_sys_tb is
end entity;

architecture Sam_sys_tb_arch of sam_sys_tb is

	-- Reset-signal til DUT sættes i starten af simuleringen
	signal reset_in_tb     : std_logic := '0';

	-- 50 MHz clock
	signal clk50mhz_tb     : std_logic := '0';

	-- 25 MHz clock
	signal clk25mhz_tb     : std_logic := '0';

	-- 8-bit datategn output
	signal data_out_tb     : std_logic_vector(7 downto 0) := (others => '0');

	-- Kontrolflags output
	signal EEP_out_tb      : std_logic := '0';
	signal EOP_out_tb      : std_logic := '0';
	signal Nchar_out_tb    : std_logic := '0';
	signal p_err_out_tb    : std_logic := '0';
	signal valid_out_tb    : std_logic := '0';

	-- Konstant til definition af reset-tid ved sim-start
	constant reset_time    : time := 40 ns;

	-- Sam_sys: Samlet system der skal simuleres
	component sam_sys is
		port (
			reset_in   : in  std_logic;
			clk50mhz   : in  std_logic;
			data_out   : out std_logic_vector(7 downto 0);
			EEP_out    : out std_logic;
			EOP_out    : out std_logic;
			Nchar_out  : out std_logic;
			p_err_out  : out std_logic;
			valid_out  : out std_logic
		);
	end component;

begin

	-- Generering af 50 MHz clk brugt af bitfeeder
	process
	begin 	
		clk50mhz_tb <= '0';
		wait for 10 ns;
		clk50mhz_tb <= '1';
		wait for 10 ns;
	end process;

	-- Generering af 25 MHz clk brugt til udskrivning i outputfil synkront med system
	process
	begin 	
		clk25mhz_tb <= '0';
		wait for 20 ns;
		clk25mhz_tb <= '1';
		wait for 20 ns;
	end process;

	-- Aktiverer reset i starten af simuleringen 
	process
	begin
		reset_in_tb <= '1';
		wait for reset_time;
		reset_in_tb <= '0';
		wait;
	end process;

	-- Instansiering af sam_sys
	DUT : sam_sys
		port map (
			reset_in   => reset_in_tb,
			clk50mhz   => clk50mhz_tb,
			data_out   => data_out_tb,
			EEP_out    => EEP_out_tb,
			EOP_out    => EOP_out_tb,
			Nchar_out  => Nchar_out_tb,
			p_err_out  => p_err_out_tb,
			valid_out  => valid_out_tb
		);

	-- Stimulus-process: Skriver output ud i fil ved rising edge på 25 MHz clock
	-- Outputformat er datategn efterfulgt af udvalgte kontroltegn, som skal bruges til PCAP-generering
	STIMULUS : process(clk25mhz_tb)
		file Fout : TEXT open WRITE_MODE is "output_file.txt";
		variable current_write_line : line;

	begin 
		

		if rising_edge(clk25mhz_tb) then
			write(current_write_line, data_out_tb);
			write(current_write_line, EEP_out_tb);
			write(current_write_line, EOP_out_tb);
			write(current_write_line, Nchar_out_tb);
			write(current_write_line, p_err_out_tb);
			write(current_write_line, valid_out_tb);
			writeline(Fout, current_write_line);
		end if;
	end process;

end architecture Sam_sys_tb_arch;
