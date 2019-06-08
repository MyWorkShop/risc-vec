module rom(input [31:0] address1,
           output reg [31:0] out1,
           input [31:0] address2,
           output reg [31:0] out2,
           input clk);

    reg [31:0] mem [1023:0];
    
    initial 
    $readmemh("rom.patt",mem);

    always @ *
    begin
        out1 = mem[address1 >> 2];
        out2 = mem[address2 >> 2];
    end

endmodule