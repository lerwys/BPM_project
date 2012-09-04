-- Simple IRQ Manager
-- Based on the original design by:
--	
-- Fabrice Mousset (fabrice.mousset@laposte.net)
-- Project       :  Wishbone Interruption Manager (ARMadeus wishbone example)

-- See: http://www.armadeus.com/wiki/index.php?title=A_simple_design_with_Wishbone_bus

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.wishbone_pkg.all;
use work.gencores_pkg.all;

entity xwb_irq_mngr is
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
end entity;
    
architecture rtl of xwb_irq_mngr is

	-- Read addresses regs
	constant c_IRQ_MASK 			: std_logic_vector(1 downto 0) := "00";  -- *reg* IRQ mask
	constant c_IRQ_PEND 			: std_logic_vector(1 downto 0) := "01";  -- *reg* IRQ pending

	-- Write addresses regs
	--constant c_IRQ_MASK 			: std_logic_vector(1 downto 0) := "00";  -- *reg* IRQ mask
	constant c_IRQ_ACK 				: std_logic_vector(1 downto 0) := "01";  -- *reg* IRQ acknowledge from master

	signal irq_r    				: std_logic_vector(g_irq_count-1 downto 0);
	signal irq_old  				: std_logic_vector(g_irq_count-1 downto 0);

	signal irq_pend 				: std_logic_vector(g_irq_count-1 downto 0);
	signal irq_ack  				: std_logic_vector(g_irq_count-1 downto 0);

	signal irq_mask 				: std_logic_vector(g_irq_count-1 downto 0);

	signal readdata 				: std_logic_vector(15 downto 0);
	signal rd_ack 					: std_logic;
	signal wr_ack 					: std_logic;

	signal sel						: std_logic;

begin

-- ----------------------------------------------------------------------------
--  External signals synchronization process
-- ----------------------------------------------------------------------------

	gen_sync_ff : for i in 0 to g_irq_count-1 generate
		cmp_input_sync : gc_sync_ffs
		generic map (
			g_sync_edge => "positive")
		port map (
			rst_n_i  			=> rst_n_i,
		    clk_i    			=> clk_sys_i,
		    data_i   			=> irq_req_i(i),
		    synced_o 			=> irq_old(i),
		    ppulse_o 			=> irq_r(i));
	end generate gen_sync_ff;

--process(gls_clk, gls_reset)
--begin
--  if(gls_reset='1') then
--    irq_r <= (others => '0');
--    irq_old <= (others => '0');
--  elsif(rising_edge(gls_clk)) then
--    irq_r <= irqport;
--    irq_old <= irq_r;
--  end if;
--end process;

	-- Simple sel bus aggregate
	sel 						<= '1' when (unsigned(not slave_i.sel) = 0) else '0';

----------------------------------------------------------------------------
--  Interruption requests latching process on rising edge
----------------------------------------------------------------------------
	p_int_req : process(clk_sys_i, rst_n_i)
	begin
		if(rst_n_i = '0') then
			irq_pend 			<= (others => '0');
	  	elsif rising_edge(clk_sys_i) then
			irq_pend 			<= (irq_pend or (irq_r and irq_mask)) and (not irq_ack);
	  	end if;
	end process p_int_req;

----------------------------------------------------------------------------
--  Register reading process
----------------------------------------------------------------------------
	p_read_reg : process(clk_sys_i, rst_n_i)
	begin
		if(rst_n_i = '0') then
			rd_ack    			<= '0';
			readdata 			<= (others => '0');
		elsif rising_edge(clk_sys_i) then
			rd_ack  			<= '0';
			-- WB READ classic cycle
			if(slave_i.stb = '1' and slave_i.we = '0' and slave_i.cyc = '1') then
				rd_ack  		<= '1';

			-- Decode address (partial decoding only)
		  	if(slave_i.adr = c_IRQ_MASK) then
				readdata(g_irq_count-1 downto 0)	<= irq_mask;
		  	elsif(slave_i.adr = c_IRQ_PEND) then
				readdata(g_irq_count-1 downto 0) 	<= irq_pend;
		  	--elsif(wbs_s1_address="10") then
				--readdata <= std_logic_vector(to_unsigned(id,16));
		  	else
				readdata 		<= (others => '0');
		  end if;
		end if;
	  end if;
	end process p_read_reg;

----------------------------------------------------------------------------
--  Register update process
----------------------------------------------------------------------------
	p_update_reg : process(clk_sys_i, rst_n_i)
	begin
		if(rst_n_i = '0') then
			irq_ack				<= (others => '0');
			wr_ack  			<= '0';
			irq_mask 			<= (others => '0');
		elsif rising_edge(clk_sys_i) then
			irq_ack 			<= (others => '0');
			wr_ack  			<= '0';

		-- WB WRITE classic cycle
			if(slave_i.stb = '1' and slave_i.we = '0' and slave_i.cyc = '1' and sel = '1') then
      			wr_ack  		<= '1';
		  		if(slave_i.adr = c_IRQ_MASK) then
		    		irq_mask 		<= slave_i.dat(g_irq_count-1 downto 0);
		  		elsif(slave_i.adr = c_IRQ_ACK) then
		    		irq_ack 		<= slave_i.dat(g_irq_count-1 downto 0);
				end if;
			end if;
  		end if;
	end process;

	irq_req_o 							<= g_irq_level when(unsigned(irq_pend) /= 0 and rst_n_i = '1') else
		       								not g_irq_level;

	slave_o.ack 						<= rd_ack or wr_ack;
	slave_o.dat  						<= readdata when (slave_i.stb = '1' and slave_i.we = '0' and slave_i.cyc = '1') else (others => '0');

	slave_o.err   						<= '0';
	slave_o.int   						<= '0';
	slave_o.rty   						<= '0';
	slave_o.stall 						<= '0';

end architecture rtl;
