library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.wishbone_pkg.all;
use work.gencores_pkg.all;

entity dbe_demo_top_sim_tb is				-- entity declaration
end dbe_demo_top_sim_tb;

architecture rtl of dbe_demo_top_sim_tb is

	-- 100.00 MHz clock
	constant c_clk_period					: time := 10.00 ns;
	constant c_sim_time						: time := 1000.00 ns;
	constant g_num_pins						: natural := 8;
	constant c_ip_width						: natural := 10;
	
	signal g_end_simulation          		: boolean   := false; -- Set to true to halt the simulation


	signal clk100						: std_logic := '0';
	signal buttons_dummy_value				: std_logic_vector(g_num_pins-1 downto 0) := x"00";
	signal leds_value						: std_logic_vector(g_num_pins-1 downto 0);


	component dbe_demo_top_sim is
	port(
		-----------------------------------------
		-- Clocking pins
		-----------------------------------------
		clk100_i 							: in std_logic;
		--sys_clk_p_i						: in std_logic;
		--sys_clk_n_i						: in std_logic;

		-----------------------------------------
		-- Button pins
		-----------------------------------------
		buttons_i							: in std_logic_vector(g_num_pins-1 downto 0);
		  
		-----------------------------------------
		-- User LEDs
		-----------------------------------------
		leds_o								: out std_logic_vector(g_num_pins-1 downto 0)
	);
	end component;
	
	-- Functions
	--function calculate_next_input_sample(sample_number : in integer) return std_logic_vector is
   -- variable A      : real  := 1.0;   -- Amplitude for wave
   -- variable F      : real  := 100.0;   -- Frequency for wave
   -- variable P      : real  := 0.0;   -- Phase for wave
   -- variable theta  : real;

   -- variable y      : real;     -- The calculated value as a real
   -- variable y_int  : integer;  -- The calculated value as an integer
   -- variable result : std_logic_vector(c_ip_width-1 downto 0);
       
   -- variable number_of_samples : real := 100.0 * real(47);

  --begin
   -- theta  := (2.0 * MATH_PI * F * real(sample_number mod integer(number_of_samples))) / number_of_samples;
 
    --y      := A * sin(theta + P);
    --y_int  := integer(round(y * real(2**(c_ip_width-2))));
    --result := std_logic_vector(to_signed(y_int, c_ip_width));

    --return result;
  --end function calculate_next_input_sample;
	
begin

--	cmp_dbe_demo_top: dbe_demo_top_sim
--	port map
--	(
--		clk100_i 						=> clk100,
--		--sys_clk_p_i					: in std_logic;
--		--sys_clk_n_i					: in std_logic;
--
--		-----------------------------------------
--		-- Button pins
--		-----------------------------------------
--		buttons_i						=> buttons_dummy_value,
--		  
--		-----------------------------------------
--		-- User LEDs
--		-----------------------------------------
--		leds_o							=> leds_value
--	);
	
	p_clk_gen : process is
	begin
		while g_end_simulation = false loop
			wait for c_clk_period/2;
			clk100 <= not clk100;
			wait for c_clk_period/2;
			clk100 <= not clk100;	
		end loop;
		wait;  -- simulation stops here
	end process p_clk_gen;
	
	p_main_simulation : process is
	begin
		wait for c_sim_time;
		g_end_simulation <= true;
		wait;
	end process p_main_simulation;

end rtl;
