mult: mult.v mult_tb.v
	# To install iStyle, please visit https://github.com/thomasrussellmurphy/istyle-verilog-formatter
	iStyle mult.v
	rm mult.v.orig
	iStyle mult_tb.v
	rm mult_tb.v.orig
	iStyle mult_fp32.v
	rm mult_fp32.v.orig
	iStyle mult_fp64.v
	rm mult_fp64.v.orig
	iverilog -o mult_test mult.v mult_fp32.v mult_fp64.v mult_tb.v
	vvp mult_test -lxt2
	gtkwave mult.vcd
rv: rv32i.v cache.v tb.v
	iverilog -o rv_test -g2012 rv32i.v cache.v tb.v
	vvp rv_test -lxt2