-- Example Design heavily based on genral-cores top example design
-- from OHWR repositories http://www.ohwr.org/projects/general-cores/wiki

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.gencores_pkg.all;

entity dbe_demo_top_sim is
	port(
		-----------------------------------------
		-- Clocking pins
		-----------------------------------------
		clk100_i 						: in std_logic;
		--sys_clk_p_i					: in std_logic;
		--sys_clk_n_i					: in std_logic;

		-----------------------------------------
		-- Button pins
		-----------------------------------------
		buttons_i						: in std_logic_vector(7 downto 0);
		  
		-----------------------------------------
		-- User LEDs
		-----------------------------------------
		leds_o							: out std_logic_vector(7 downto 0)
	);
end dbe_demo_top_sim;

architecture rtl of dbe_demo_top_sim is

	-- Simple GPIO interface device
	constant c_xwb_gpio32_sdb : t_sdb_device := (
		abi_class     => x"0000", 				-- undocumented device
		abi_ver_major => x"01",
		abi_ver_minor => x"00",
		wbd_endian    => c_sdb_endian_big,
		wbd_width     => x"7", 					-- 8/16/32-bit port granularity
		sdb_component => (
		addr_first    => x"0000000000000000",
		addr_last     => x"0000000000000007", 	-- Two 4 byte registers
		product => (
		vendor_id     => x"0000000000000651", 	-- GSI
		device_id     => x"35aa6b95",
		version       => x"00000001",
		date          => x"20120305",
		name          => "GSI_GPIO_32        ")));

	-- Simple IRQ manager interface device
	constant c_xwb_irqmngr_sdb : t_sdb_device := (
		abi_class     => x"0000", 				-- undocumented device
		abi_ver_major => x"01",
		abi_ver_minor => x"00",
		wbd_endian    => c_sdb_endian_big,
		wbd_width     => x"7", 					-- 8/16/32-bit port granularity
		sdb_component => (
		addr_first    => x"0000000000000000",
		addr_last     => x"0000000000000007", 	-- Two 4 byte registers
		product => (
		vendor_id     => x"0000000000001215", 	-- LNLS
		device_id     => x"35aa6b95",		
		version       => x"00000001",
		date          => x"20120903",			-- YY/MM/DD ??
		name          => "LNLS_IRQMNGR       ")));
    
	-- Top crossbar layout
	constant c_slaves 				: natural := 4;			-- LED, Button and IRQ manager slaves
	constant c_masters 				: natural := 2;			-- LM32 master. Data + Instruction
	constant c_dpram_size 			: natural := 16384; -- in 32-bit words (64KB)

	-- GPIO num pins
	constant c_leds_num_pins 		: natural := 8;
	constant c_buttons_num_pins 	: natural := 8;

	-- WB SDB (Self describing bus) layout
	constant c_layout : t_sdb_record_array(c_slaves-1 downto 0) :=
	(0 => f_sdb_embed_device(f_xwb_dpram(c_dpram_size), 	x"00000000"),		-- 64KB RAM
	1 => f_sdb_embed_device(f_xwb_dpram(c_dpram_size), 		x"10000000"),		-- Second port to the same memory
	2 => f_sdb_embed_device(c_xwb_gpio32_sdb,          		x"20000400"),		-- GPIO LED
	3 => f_sdb_embed_device(c_xwb_gpio32_sdb,             	x"20000500")		-- GPIO Button
	--4 => f_sdb_embed_device(c_xwb_irqmngr_sdb,				x"00100600") 	-- IRQ_MNGR
	);	

	-- Self Describing Bus ROM Address. It is addressed as slave as well.
	constant c_sdb_address 			: t_wishbone_address := x"20000000";

	-- Crossbar master/slave arrays
	signal cbar_slave_i  			: t_wishbone_slave_in_array (c_masters-1 downto 0);
	signal cbar_slave_o  			: t_wishbone_slave_out_array(c_masters-1 downto 0);
	signal cbar_master_i 			: t_wishbone_master_in_array(c_slaves-1 downto 0);
	signal cbar_master_o 			: t_wishbone_master_out_array(c_slaves-1 downto 0);

	-- LM32 signals
	signal clk_sys 					: std_logic;
	signal lm32_interrupt 			: std_logic_vector(31 downto 0);
	signal lm32_rstn 				: std_logic;

	-- Global clock and reset signals
	signal locked 					: std_logic;
	signal clk_sys_rstn 			: std_logic;

	-- Only one clock domain
	signal reset_clks 				: std_logic_vector(0 downto 0);
	signal reset_rstn 				: std_logic_vector(0 downto 0);

	-- Global Clock Single ended
	signal sys_clk_gen				: std_logic;

	-- GPIO LED signals
	signal gpio_slave_led_o 		: t_wishbone_slave_out;
	signal gpio_slave_led_i 		: t_wishbone_slave_in;
	-- signal leds_gpio_dummy_in 		: std_logic_vector(c_leds_num_pins-1 downto 0);

	-- GPIO Button signals
	signal gpio_slave_button_o 		: t_wishbone_slave_out;
	signal gpio_slave_button_i 		: t_wishbone_slave_in;

	-- IRQ manager  signals
	signal gpio_slave_irqmngr_o 	: t_wishbone_slave_out;
	signal gpio_slave_irqmngr_i 	: t_wishbone_slave_in;

	-- LEDS, button and irq manager signals
	--signal r_leds : std_logic_vector(7 downto 0);
	--signal r_reset : std_logic;

	-- Components

	-- Clock generation
	--component clk_gen is
	--port(
	--	sys_clk_p_i					: in std_logic;
	--	sys_clk_n_i					: in std_logic;
	--	sys_clk_o					: out std_logic
	--);
	--end component;

	-- Xilinx Megafunction
  	--component sys_pll is
    --port(
	--	rst_i						: in std_logic  := '0';
	--	clk_i						: in std_logic  := '0';
	--	clk0_o						: out std_logic;
	--	clk1_o						: out std_logic;
	--	locked_o					: out std_logic 
	--);
  	--end component;

	component xwb_irq_mngr is
		generic(
			g_irq_count				: integer := 16;
			g_irq_level 			: std_logic := '1'
			--g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
			--g_address_granularity : t_wishbone_address_granularity := BYTE;
		);
		port(
			-- Global Signals
			clk_sys_i 				: in std_logic;
			rst_n_i   				: in std_logic;
		  
			-- Wishbone interface signals
			slave_i 				: in  t_wishbone_slave_in;
			slave_o 				: out t_wishbone_slave_out;
		
		  -- irq from other IP
		  irq_req_i        			: in  std_logic_vector(g_irq_count-1 downto 0);
		  
		  -- Component external signals
		  irq_req_o           		: out std_logic
		);
	end component;
begin

	-- Clock generation
	--cmp_clk_gen : clk_gen
	--port map (
	--	sys_clk_p_i				=> sys_clk_p_i,
	--	sys_clk_n_i				=> sys_clk_n_i,
	--	sys_clk_o				=> sys_clk_gen
	--);

	-- Obtain core locking. Replace with Xilinx function!
	--cmp_sys_pll_inst : sys_pll
	--port map (
	--	rst_i					=> '0',
	--	clk_i					=> sys_clk_gen,
	--	clk0_o					=> open,     	-- 200Mhz locked clock
	--	clk1_o					=> clk_sys,     -- 100MHz locked clock
	--	locked_o				=> locked		-- '1' when the PLL has locked
	--);
  
	-- Reset synchronization
	cmp_reset : gc_reset
	port map(
		free_clk_i 			=> sys_clk_gen,
		locked_i   			=> locked,
		clks_i     			=> reset_clks,
		rstn_o     			=> reset_rstn
	);

	-- simulation only!
	locked	<= '1';
	clk_sys		<= clk100_i;
	sys_clk_gen <= clk100_i;
	-- End of simulation only!
	reset_clks(0) <= clk_sys;
	clk_sys_rstn <= reset_rstn(0);
  
  -- The top-most Wishbone B.4 crossbar
	cmp_interconnect : xwb_sdb_crossbar
	generic map(
		g_num_masters => c_masters,
		g_num_slaves  => c_slaves,
		g_registered  => true,
		g_wraparound  => false, -- Should be true for nested buses
		g_layout      => c_layout,
		g_sdb_addr    => c_sdb_address
	)
	port map(
		clk_sys_i     => clk_sys,
		rst_n_i       => clk_sys_rstn,
		-- Master connections (INTERCON is a slave)
		slave_i       => cbar_slave_i,
		slave_o       => cbar_slave_o,
		-- Slave connections (INTERCON is a master)
		master_i      => cbar_master_i,
		master_o      => cbar_master_o
	);
  
	-- The LM32 is master 1+2
	lm32_rstn <= clk_sys_rstn; --and not r_reset;

	cmp_lm32 : xwb_lm32
	generic map(
		g_profile => "medium_icache_debug") -- Including JTAG and I-cache (no divide)
	port map(
		clk_sys_i => clk_sys,
		rst_n_i   => lm32_rstn,
		irq_i     => lm32_interrupt,
		dwb_o     => cbar_slave_i(0), -- Data bus
		dwb_i     => cbar_slave_o(0),
		iwb_o     => cbar_slave_i(1), -- Instruction bus
		iwb_i     => cbar_slave_o(1)
	);
  
	-- Interrupts disabled for now
	lm32_interrupt(31 downto 0) <= (others => '0');
  
  	-- Slave 1+2 is the RAM. Load a input file containing a simple led blink program!
	cmp_ram : xwb_dpram
	generic map(
		g_size                  => c_dpram_size, -- must agree with sw/target/lm32/ram.ld:LENGTH / 4
		g_init_file             => "sw/main.ram",
		g_must_have_init_file   => true,
		g_slave1_interface_mode => PIPELINED,
		g_slave2_interface_mode => PIPELINED,
		g_slave1_granularity    => BYTE,
		g_slave2_granularity    => BYTE)
	port map(
		clk_sys_i 				=> clk_sys,
		rst_n_i   				=> clk_sys_rstn,
		-- First port connected to the crossbar
		slave1_i  				=> cbar_master_o(0),
		slave1_o  				=> cbar_master_i(0),
		-- Second port connected to the crossbar
		slave2_i  				=> cbar_master_o(1),
		slave2_o  				=> cbar_master_i(1)
	);

	-- Slave 1 is the example LED driver
	cmp_leds : xwb_gpio_port
	generic map(
		--g_interface_mode         => CLASSIC;
		--g_address_granularity    => WORD;
		g_num_pins => c_leds_num_pins,
		g_with_builtin_tristates => false
	)
	port map(
		clk_sys_i 				=> clk_sys,
		rst_n_i   				=> clk_sys_rstn,

		-- Wishbone
		slave_i 				=> cbar_master_o(2),
		slave_o 				=> cbar_master_i(2),
		desc_o  				=> open,	-- Not implemented

		--gpio_b : inout std_logic_vector(g_num_pins-1 downto 0);

		gpio_out_o 				=> leds_o,
		gpio_in_i 				=> x"00",
		gpio_oen_o 				=> open
    );

  	-- Slave 2 is the example Button driver
	cmp_buttons : xwb_gpio_port
	generic map(
		--g_interface_mode         => CLASSIC;
		--g_address_granularity    => WORD;
		g_num_pins => c_buttons_num_pins,
		g_with_builtin_tristates => false
	)
	port map(
		clk_sys_i 				=> clk_sys,
		rst_n_i   				=> clk_sys_rstn,

		-- Wishbone
		slave_i 				=> cbar_master_o(3),
		slave_o 				=> cbar_master_i(3),
		desc_o  				=> open,	-- Not implemented

		--gpio_b : inout std_logic_vector(g_num_pins-1 downto 0);

		gpio_out_o 				=> open,
		gpio_in_i 				=> buttons_i,
		gpio_oen_o 				=> open
    );

  	-- Slave 3 is the example IRQ Manager driver
	--component xwb_irq_mngr is
	--port map(
		-- Global Signals
	--	clk_sys_i 				=> clk_sys,
	--	rst_n_i   				=> clk_sys_rstn,
	  
		-- Wishbone interface signals
	--	slave_i 				=> cbar_master_i(3),
	--	slave_o 				=> cbar_master_o(3),
	
	  	-- irq from other IP
	 -- 	irq_req_i        		=> std_logic_vector(g_irq_count-1 downto 0),
	  
	  	-- Component external signals
	 -- 	irq_req_o           	=> lm32_interrupt(0)
	--);
end rtl;
