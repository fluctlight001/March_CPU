`include "defines.v"
module cache_interface(
    input wire clk,
    input wire rst,

// cache interface
    input wire ren, // miss
    input wire [31:0] raddr, // miss_addr
    output reg raccept, // accept

    output reg wen_fill, 
    output reg [255:0] wfill,

    input wire wen, // wen_back
    input wire [31:0] waddr, // waddr
    input wire [255:0] wdata, // wback
    output reg wfin, // fin

// control interface
    output reg sram_en,
    output reg [3:0] sram_wen,
    output reg [31:0] sram_addr,
    output reg [31:0] sram_wdata,
    input wire [31:0] sram_rdata,
    input wire sram_rvalid
);

    reg [7:0] stage;
    reg [255:0] cache_data_temp;
    reg [31:0] raddr_temp;
    reg [3:0] offset;
    always @ (posedge clk) begin
        if (rst) begin
            raccept <= 1'b0;
            wen_fill <= 1'b0;
            wfin <= 1'b0;
            sram_en <= 1'b0;
            stage <= 8'b1;
            offset <= 4'b0;
        end
        else begin
            case (1'b1)
                stage[0]:begin
                    if (ren) begin
                        raddr_temp <= raddr;
                        raccept <= 1'b1;
                        offset <= 4'b0;
                        stage <= stage << 1;
                    end
                end
                stage[1]:begin
                    sram_en <= 1'b1;
                    sram_wen <= 4'b0;
                    sram_addr <= raddr_temp;
                    sram_wdata <= 32'b0;
                    raddr_temp <= raddr_temp + 4'd4;
                    stage <= stage << 1;
                end
                stage[2]:begin
                    if (sram_rvalid) begin
                        cache_data_temp[offset*32+:32] <= sram_rdata;
                        offset <= offset + 1'b1;
                        if (offset == 4'b0111) begin
                            stage <= stage << 1;
                        end
                        else begin
                            stage <= stage >> 1;
                        end
                    end
                end
                stage[3]:begin
                    sram_en <= 1'b0;
                    wen_fill <= 1'b1;
                    wfill <= cache_data_temp;
                    stage <= stage << 1;
                end
                stage[4]:begin
                    wen_fill <= 1'b0;
                    stage <= 8'b1;
                end
                default:begin
                    stage <= 8'b1;
                end
            endcase
        end
    end

endmodule