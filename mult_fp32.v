module mult_fp32(
           input      [31:0] I_a,
           input      [31:0] I_b,
           output reg [31:0] O_result,
           output reg        O_over_flow
       );

reg Sign_a;
reg [7:0] Exp_a;
reg [23:0] Frac_a;

reg Sign_b;
reg [7:0] Exp_b;
reg [23:0] Frac_b;

reg  [8:0] Exp_result;
wire [47:0] Mult_result;
reg [22:0] Frac_result;
reg Sign_result;

integer index;

mult_module
    #(
        .WIDTH(24)
    )
    mult_module_frac
    (
        .I_a(Frac_a),
        .I_b(Frac_b),
        .O_result(Mult_result)
    );

always@(*)
begin
    Sign_a = I_a[31];
    Exp_a = I_a[30:23];
    Frac_a = {1'b1, I_a[22:0]};

    Sign_b = I_b[31];
    Exp_b = I_b[30:23];
    Frac_b = {1'b1, I_b[22:0]};

    Exp_result = Exp_a + Exp_b - 9'b001111111;

    if(Mult_result[47] == 1)
    begin
        Frac_result = Mult_result[46:24];
        Exp_result = Exp_result + 1;
    end
    else
        Frac_result = Mult_result[45:23];

    if(Exp_result[8] == 1)
        O_over_flow = 1;
    else
        O_over_flow = 0;

    Sign_result = Sign_a + Sign_b;

    O_result = {Sign_result, Exp_result[7:0], Frac_result};
end

endmodule
