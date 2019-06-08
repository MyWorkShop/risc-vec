module tb_rv_module();
wire [31:0] address1;
wire [31:0] data1;
wire [31:0] address2;
wire [31:0] data2;

reg  clk;
reg  reset;


initial
begin
    clk = 0;
    reset = 1;
    #4
    reset = 0;
    #100;
    $finish;
end

always #1 clk <= ~clk;

ezpipe ezpipe_inst(
        .clk(clk),
        .reset(reset),
        .ibus_addr1(address1),
        .ibus_data1(data1),
        .ibus_addr2(address2),
        .ibus_data2(data2)
        );
rom rom_inst(
    .address1(address1),
    .out1(data1),
    .address2(address2),
    .out2(data2),
    .clk(clk)
);

initial
begin
    $dumpfile("rv.vcd");
    $dumpvars(0, ezpipe_inst);
end

endmodule
