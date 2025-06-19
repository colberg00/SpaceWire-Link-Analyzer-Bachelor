-- Entitet: clock_domain_shift
-- Beskrivelse: Overfører et enkelt pulssignal fra clk_in-domænet til clk_out-domænet.
-- Dette gøres ved hjælp af handshake-protokol og synkronisering.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clock_domain_shift is
    port (
        clk_in     : in  std_logic;
        clk_out    : in  std_logic;
        signal_in  : in  std_logic;
        reset      : in  std_logic;
        signal_out : out std_logic
    );
end clock_domain_shift;

architecture clock_domain_shift_arch of clock_domain_shift is

    -- FSM states for clk_in-domænet
    type state_type is (IDLE, WAIT_ACK);
    signal state : state_type := IDLE;

    -- Registrerer tidligere værdi af signal_in for at detektere en puls
    signal signal_in_prev  : std_logic;
    signal signal_in_pulse : std_logic;

    -- Holder signalet aktivt indtil ack modtages
    signal signal_hold     : std_logic;

    -- Synkroniseringsregistre fra signal_hold og clk_out-domænet
    signal reg1, reg2      : std_logic;

    -- Ack-signal genereret i clk_out-domænet
    signal ack             : std_logic;

    -- Synkronisering af ack tilbage til clk_in-domænet
    signal a_reg1, a_reg2  : std_logic;

begin

    -- FSM: Genererer signal_hold-puls ved detektion af puls og afventer herefter ACK
    process(clk_in, reset)
    begin
        if reset = '1' then
            signal_hold <= '0';
            state <= IDLE;

        elsif rising_edge(clk_in) then
            case state is
                when IDLE =>
                    if signal_in_pulse = '1' then
                        signal_hold <= '1';
                        state <= WAIT_ACK;
                    end if;

                when WAIT_ACK =>
                    if a_reg2 = '1' then
                        signal_hold <= '0';
                        state <= IDLE;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    -- Detekterer en rising edge-puls på input-signalet
    process(clk_in, reset)
    begin
        if reset = '1' then
            signal_in_pulse <= '0';
        elsif rising_edge(clk_in) then
            signal_in_prev <= signal_in;
            if (signal_in = '1' and signal_in_prev = '0') then
                signal_in_pulse <= '1';
            else
                signal_in_pulse <= '0';
            end if;
        end if;
    end process;

    -- Synkronisering af signal_hold til clk_out-domænet
    process(clk_out, reset)
    begin
        if reset = '1' then
            reg1 <= '0';
            reg2 <= '0';
        elsif rising_edge(clk_out) then
            reg1 <= signal_hold;
            reg2 <= reg1;
        end if;
    end process;

    -- Synkronisering af ack tilbage til clk_in-domænet
    process(clk_in, reset)
    begin
        if reset = '1' then
            a_reg1 <= '0';
            a_reg2 <= '0';
        elsif rising_edge(clk_in) then
            a_reg1 <= ack;
            a_reg2 <= a_reg1;
        end if;
    end process;

    -- Genererer en enkelt puls til signal_out når reg2 er højt
    process(clk_out, reset)
    begin
        if reset = '1' then
            signal_out <= '0';
        elsif rising_edge(clk_out) then
            signal_out <= reg2 AND NOT reg1;
        end if;
    end process;

    -- Genererer ack-signal i clk_out-domænet baseret på reg2
    process(clk_out, reset)
    begin
        if reset = '1' then
            ack <= '0';
        elsif rising_edge(clk_out) then
            ack <= reg2;
        end if;
    end process;

end architecture clock_domain_shift_arch;
