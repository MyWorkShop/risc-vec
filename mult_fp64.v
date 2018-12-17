module mult_fp64(
           input      [63:0] I_a,
           input      [63:0] I_b,
           output reg [63:0] O_result,
           output reg        O_over_flow
       );

reg Sign_a;
reg [10:0] Exp_a;
reg [52:0] Frac_a;

reg Sign_b;
reg [10:0] Exp_b;
reg [52:0] Frac_b;

reg  [11:0] Exp_result;
wire [105:0] Mult_result;
reg [51:0] Frac_result;
reg Sign_result;

integer index;

mult_module
    #(
        .WIDTH(53)
    )
    mult_module_frac
    (
        .I_a(Frac_a),
        .I_b(Frac_b),
        .O_result(Mult_result)
    );

always@(*)
begin
    Sign_a = I_a[63];
    Exp_a = I_a[62:52];
    Frac_a = {1'b1, I_a[51:0]};

    Sign_b = I_b[63];
    Exp_b = I_b[62:52];
    Frac_b = {1'b1, I_b[51:0]};

    Exp_result = (Exp_a + Exp_b) - 12'b001111111111;

    if(Mult_result[105] == 1)
    begin
        Frac_result = Mult_result[104:53];
        Exp_result = Exp_result + 1;
    end
    else
        Frac_result = Mult_result[103:52];

    if(Exp_result[11] == 1)
        O_over_flow = 1;
    else
        O_over_flow = 0;

    Sign_result = Sign_a + Sign_b;

    O_result = {Sign_result, Exp_result[10:0], Frac_result};
end

endmodule
