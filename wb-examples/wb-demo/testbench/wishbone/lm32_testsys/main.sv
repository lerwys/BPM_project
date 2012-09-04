`timescale 1ns/1ps

module main;

	reg clk_sys  = 0;
	reg rst_n    = 0;

	always #5 clk_sys <= ~clk_sys;
   
	deb_demo_top
	DUT (
		.clk100_i (clk_sys),
		.buttons_i (),
		.leds_o ()
	);                           

endmodule // main


