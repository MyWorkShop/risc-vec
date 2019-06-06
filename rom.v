module rom(input reg [63:0] address,
           output [63:0] out,
           input clk);

    reg [63:0] mem [1023:0];

    always @(posedge clk)
    begin
        out <= mem[address];
    end

endmodule