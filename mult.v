module fp16_mult_fraction (out, a, b);
output [19:0] out;
	input  [9:0] a;
	input  [9:0] b;

	assign out = a * b;

endmodule

module fp16_mult_exponent (out, a, b);
output [9:0] out;
	input  [4:0] a;
	input  [4:0] b;

	assign out = a * b;

endmodule
