//加载/存储
`define FUNCT3_B    3'b000
`define FUNCT3_H    3'b001
`define FUNCT3_W    3'b010
`define FUNCT3_BU   3'b100
`define FUNCT3_HU   3'b101

module cache(input [31:0]      address,
             output reg [31:0] read,
             input [31:0]      write,
             input             is_read,
             input             is_write,
             input [2:0]       mode,
             input [31:0]      address1,
             output reg [31:0] out1,
             input             enable_2,
             input [31:0]      address2,
             output reg [31:0] out2,
             input             clk);

    reg [7:0] mem [65535:0];
    
    initial 
    $readmemh("rom.patt",mem);

    always @(posedge clk)
    begin
        if(is_read) begin
            case(mode)
                `FUNCT3_B: read <= {{25{mem[address][7]}}, mem[address][6:0]};
                `FUNCT3_H: read <= {{17{mem[address][7]}}, mem[address][6:0], mem[address + 1]};
                `FUNCT3_W: read <= {mem[address], mem[address + 1], mem[address + 2], mem[address + 3]};
                `FUNCT3_BU: read <= {{24{1'b0}}, mem[address]};
                `FUNCT3_HU: read <= {{16{1'b0}}, mem[address], mem[address + 1]};
            endcase
        end 
        if(is_write) begin
            case(mode)
                `FUNCT3_B: mem[address] <= write[7:0];
                `FUNCT3_H: begin
                        mem[address + 1] <= write[7:0];
                        mem[address] <= write[15:8];
                    end
                `FUNCT3_W: begin
                        mem[address + 3] <= write[7:0];
                        mem[address + 2] <= write[15:8];
                        mem[address + 1] <= write[23:16];
                        mem[address] <= write[31:24];
                    end
            endcase
        end
        out1 <= {mem[address1], mem[address1 + 1], mem[address1 + 2], mem[address1 + 3]};
        if(enable_2)
            out2 <= {mem[address2], mem[address2 + 1], mem[address2 + 2], mem[address2 + 3]};
    end

endmodule
