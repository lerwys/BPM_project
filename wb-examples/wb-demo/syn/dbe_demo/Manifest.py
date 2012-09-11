target = "xilinx"
action = "synthesis"

syn_device = "xc6vlx240t"
syn_grade = "-1"
syn_package = "ff1156"
syn_top = "dbe_demo_top"
syn_project = "dbe_demo_top.xise"

modules = { "local" : [ "../../top/ml_605_dbe/dbe_demo" ] };
