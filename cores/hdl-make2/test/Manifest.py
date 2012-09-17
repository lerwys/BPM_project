action = "simulation"
target = "xilinx"

#files = [ "dbe_demo_top_sim.vhd", "dbe_demo_top_sim_tb.vhd" ];
files = [ "top_module.vhd" ]
modules = { "local" : ["../../../cores/general-cores" ] };
