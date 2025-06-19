-- Entitet: SM1 
-- Beskrivelse: Finite State Machine, der processerer 2-bit input og samler
--              dem til enten kontrol- eller data-tegn. Her håndteres de indsamlede
--              tegn og udføres paritetstjek.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_std.all;

entity SM1 is
    Port(
        clk_stable : in std_logic;
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
end entity SM1;

architecture sm1_arch of SM1 is

    -- FSM-tilstande til fortolkning af de to input-bit
    type state_type is (
        start, control, esc, data1, data2, data3, data4,
        escfct, t1, t2, t3, t4, standby, standby_transition
    );

    -- Current og next state signaler
    signal current_state   : state_type := standby;
    signal next_state      : state_type;

    -- 8-bit register til opsamling af 4x2-bit input
    signal data_hold       : std_logic_vector(7 downto 0) := (others => '0');

    -- Akkumuleret XOR paritets tjek
    signal parity_accum    : std_logic;

    -- Flag til indikation af om tidligere state var standby
    signal standby_before  : std_logic;

    -- Flag til indikation af om data karakteren er klar
    signal data_ready      : std_logic;


begin

    -- FSM State Register: Opdaterer current_state ved rising_edge
    process(clk_stable, reset)
    begin 
        if reset = '1' then
            current_state <= standby;
        elsif rising_edge(clk_stable) then 
            current_state <= next_state;
        end if;
    end process;

    -- Next-State logic: Bestemmer FSM-transitions baseret på input
    process(current_state, data_in)
    begin
		
        case current_state is

            when standby =>
                next_state <= standby_transition;
				
				when standby_transition =>
					next_state <= start;

            when start =>
                if data_in(0) = '1' then
                    next_state <= control;
                elsif data_in(0) = '0' then
                    next_state <= data1;
					 else 
					  next_state <= start;
					end if;

            when control =>
                if data_in = "10" or data_in = "01" or data_in = "00" then
                    next_state <= start;
                elsif data_in = "11" then
                    next_state <= esc;
					 else 
						  next_state <= start;
                end if;

            when esc =>
                if data_in(0) = '1' then 
                    next_state <= escfct;
                elsif data_in(0) = '0' then
                    next_state <= t1;
					 else
						next_state <= escfct;
                end if;

            when escfct =>
                next_state <= start;

            when data1 =>
                next_state <= data2;

            when data2 =>
                next_state <= data3;

            when data3 =>
                next_state <= data4;

            when data4 =>
                next_state <= start;

            when t1 =>
                next_state <= t2;

            when t2 =>
                next_state <= t3;

            when t3 =>
                next_state <= t4;

            when t4 =>
                next_state <= start;

            when others =>
                next_state <= start;

        end case;
    end process;

    -- Data Assembler: Indhenter 2-bit input i 8-bit register
    process(clk_stable)
    begin
        if rising_edge(clk_stable) then
		   if  reset = '1' then 
            data_hold   <= (others => '0');
            data_ready  <= '0';
			else
            case current_state is
                when data1 =>
                    data_hold(7 downto 6) <= data_in;
                    data_ready <= '0';

                when data2 =>
                    data_hold(5 downto 4) <= data_in;
                    data_ready <= '0';

                when data3 =>
                    data_hold(3 downto 2) <= data_in;
                    data_ready <= '0';

                when data4 =>
                    data_hold(1 downto 0) <= data_in;
                    data_ready <= '1';

                when others => 
                    data_hold  <= (others => '0');
                    data_ready <= '0';
            end case;
			end if;
        end if;
    end process;

    process(clk_stable, reset)
    begin
        if rising_edge(clk_stable) then
			if reset = '1' then
            parity_accum <= '0';
         else 
            case current_state is 
                when standby =>
                    parity_accum    <= '0';
					
					 when standby_transition =>
						  parity_accum    <= '0';
                    standby_before  <= '1';

                when start =>
                    if standby_before = '1' then
								standby_before <= '0';
                        parity_accum   <= '1';
                    else
                        parity_accum <= parity_accum xor data_in(1) xor data_in(0);
                    end if;

                when esc | data2 | data3 | data4 | escfct | t1 | t2 | t3 | t4 =>
                    parity_accum <= parity_accum xor data_in(1) xor data_in(0);

                when control | data1 =>
                    parity_accum <= data_in(1) xor data_in(0);

                when others => 
                    null;
            end case;
			end if;
        end if;
    end process;

    -- Output Logic: Sætter protokol-signaler og data-output samt udregner paritet
    process(current_state, data_in, data_hold, parity_accum, data_ready)
    begin
        FCT      <= '0';
        NUL      <= '0';
        TS       <= '0';
        Nchar    <= '0';
        EEP      <= '0';
        EOP		  <= '0';
        p_err    <= '0';
        Valid    <= '0';
        Data_out <= (others => '0');

        case current_state is

            when control =>
                if parity_accum = '1' then
                    p_err <= '0';
                    Valid <= '1';
                else
                    p_err <= '1';
                    Valid <= '0';
                end if;

                case data_in is
                    when "00" => FCT <= '1';
                    when "01" => EOP <= '1';
                    when "10" => EEP <= '1';
                    when others => null;
                end case;

            when esc =>
                if data_in(0) = '1' then 
                    NUL <= '1';
                else 
                    TS  <= '1';
                end if;

            when data4 =>
                Nchar <= '1';

            when data1 =>
                if parity_accum = '1' then
                    p_err <= '0';
                    Valid <= '1';
                else
                    p_err <= '1';
                    Valid <= '0';
                end if;

            when start =>
                if data_ready = '1' then
                    Data_out <= data_hold;
                end if;

            when others =>
                null;
        end case;
    end process;

end architecture sm1_arch;