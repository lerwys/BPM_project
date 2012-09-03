
--  MMCM_BASE  : In order to incorporate this function into the design,
--    VHDL     : the following instance declaration needs to be placed
--  instance   : in the body of the design code.  The instance name
-- declaration : (MMCM_BASE_inst) and/or the port declarations after the
--    code     : "=>" declaration maybe changed to properly reference and
--             : connect this function to the design.  All inputs and outputs
--             : must be connected.

--   Library   : In addition to adding the instance declaration, a use
-- declaration : statement for the UNISIM.vcomponents library needs to be
--     for     : added before the entity declaration.  This library
--   Xilinx    : contains the component declarations for all Xilinx
-- primitives  : primitives and points to the models that will be used
--             : for simulation.

--  Copy the following two statements and paste them before the
--  Entity declaration, unless they already exist.



Library UNISIM;
use UNISIM.vcomponents.all;

entity sys_pll is
	port
	(
		areset			: in std_logic  := '0';
		inclk0			: in std_logic  := '0';
		c0				: out std_logic ;
		c1				: out std_logic ;
		mmcm_locked		: out std_logic 
	);
end sys_pll;

architecture syn of sys_pll is

	signal mmcm_fbin 		: std_logic;
	signal mmcm_fbout		: std_logic;

   	-- MMCM_BASE: Base Mixed Mode Clock Manager
   	--            Virtex-6
   	-- Xilinx HDL Language Template, version 13.4

   	-- ADC Clock PLL
    cmp_mmcm_adc : MMCM_ADV
    generic map
    (
        BANDWIDTH            => "OPTIMIZED",
        CLKOUT4_CASCADE      => FALSE,
        CLOCK_HOLD           => FALSE,
        COMPENSATION         => "ZHOLD",
        STARTUP_WAIT         => FALSE,
        DIVCLK_DIVIDE        => 1,
        CLKFBOUT_MULT_F      => 16.000,
        CLKFBOUT_PHASE       => 0.000,
        CLKFBOUT_USE_FINE_PS => FALSE,
        CLKOUT0_DIVIDE_F     => 16.000,
        CLKOUT0_PHASE        => 0.000,
        CLKOUT0_DUTY_CYCLE   => 0.500,
        CLKOUT0_USE_FINE_PS  => FALSE,
        CLKOUT1_DIVIDE       => 8,
        CLKOUT1_PHASE        => 0.000,
        CLKOUT1_DUTY_CYCLE   => 0.500,
        CLKOUT1_USE_FINE_PS  => FALSE,
		-- 100 MHz input clock
        CLKIN1_PERIOD        => 10.000,
        REF_JITTER1          => 0.010
    )
    port map
    (
        -- Output clocks
        CLKFBOUT            => mmcm_fbout,
        CLKFBOUTB           => open,
        CLKOUT0             => c0,
        CLKOUT0B            => open,
        CLKOUT1             => c1,
        CLKOUT1B            => open,
        CLKOUT2             => open,
        CLKOUT2B            => open,
        CLKOUT3             => open,
        CLKOUT3B            => open,
        CLKOUT4             => open,
        CLKOUT5             => open,
        CLKOUT6             => open,
        -- Input clock control
        CLKFBIN             => mmcm_fbin,
        CLKIN1              => inclk0,
        CLKIN2              => '0',
        -- Tied to always select the primary input clock
        CLKINSEL            => '1',
        -- Ports for dynamic reconfiguration
        DADDR               => (others => '0'),
        DCLK                => '0',
        DEN                 => '0',
        DI                  => (others => '0'),
        DO                  => open,
        DRDY                => open,
        DWE                 => '0',
        -- Ports for dynamic phase shift
        PSCLK               => '0',
        PSEN                => '0',
        PSINCDEC            => '0',
        PSDONE              => open,
        -- Other control and status signals
        LOCKED              => mmcm_locked,
        CLKINSTOPPED        => open,
        CLKFBSTOPPED        => open,
        PWRDWN              => '0',
        RST                 => areset
    );
   	-- End of MMCM_BASE_inst instantiation

   -- Global clock buffers for "cmp_mmcm_adc" instance
    cmp_clkf_bufg : BUFG
    port map
    (
        O => mmcm_fbin,
        I => mmcm_fbout
    );
				
