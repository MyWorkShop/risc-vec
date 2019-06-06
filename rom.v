module rom(input [31:0] address,
           output reg [31:0] out,
           input clk);

    reg [31:0] mem [1023:0];
    
    initial 
    $readmemh("rom.patt",mem);

    always @ *
    begin
        out = mem[address >> 2];
    end

endmodule