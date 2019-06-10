module tb_rv_module();
wire [31:0] address1;
wire [31:0] data1;
wire enable_2;
wire [31:0] address2;
wire [31:0] data2;
wire [31:0] address_ls;
wire [31:0] read;
wire [31:0] write;
wire is_read;
wire is_write;
wire [2:0]  mode;

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
        .ibus_enable_2(enable_2),
        .ibus_addr2(address2),
        .ibus_data2(data2),
        .dbus_addr(address_ls),
        .dbus_data_w(write),
        .dbus_data_r(read),
        .dbus_write(is_write),
        .dbus_read(is_read),
        .dbus_mode(mode)
        );
cache cache_inst(
    .address(address_ls),
    .read(read),
    .write(write),
    .is_read(is_read),
    .is_write(is_write),
    .mode(mode),
    .address1(address1),
    .out1(data1),
    .enable_2(enable_2),
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
