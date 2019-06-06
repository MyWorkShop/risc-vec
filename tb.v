module tb_rv_module();
wire [31:0] address;
wire [31:0] data;

reg  clk;
reg  reset;


initial
begin
    clk = 0;
    reset = 1;
    #10
    reset = 0;
    #100;
    $finish;
end

always #1 clk <= ~clk;

ezpipe ezpipe_inst(
        .clk(clk),
        .reset(reset),
        .ibus_addr(address),
        .ibus_data(data)
        );
rom rom_inst(
    .address(address),
    .out(data),
    .clk(clk)
);

initial
begin
    $dumpfile("rv.vcd");
    $dumpvars(0, ezpipe_inst);
    $dumpvars(1, rom_inst);
end

endmodule
