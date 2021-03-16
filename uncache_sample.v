`include "defines.v"
`define T1 2'b00
`define T2 2'b01
`define T3 2'b11
`define T4 2'b10

module uncache_sample(
    input wire clk,
    input wire rst,
    input wire en,
    // cpu i/o
    input wire [3:0] wen,
    input wire [31:0] addr,
    input wire [31:0] wdata,
    output reg [31:0] rdata,

    // axi i/o
    output reg axi_en, // en
    input wire accept,
    output reg [3:0] axi_wsel, // wen
    output reg [31:0] axi_addr, // addr
    output reg [31:0] axi_wdata, // wdata
    input wire [31:0] axi_rdata, // rdata
    input wire fin,

    output wire stallreq
);
    reg [1:0] stage;
    reg end_stall;
    assign stallreq = en & end_stall;

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            axi_en <= `False_v;
            axi_wsel <= 4'b0;
            axi_addr <= 32'b0;
            axi_wdata <= 32'b0;

            stage <= `T1;
        end
        else begin
            case (stage)
                `T1:begin
                    if (en) begin // write
                        axi_en <= `True_v;
                        axi_wsel <= wen;
                        axi_addr <= addr;
                        axi_wdata <= wdata;
                        stage <= `T2;
                    end
                    end_stall <= 1'b1;
                end
                `T2:begin
                    if (accept == 1'b1) begin
                        axi_en <= `False_v;
                        axi_wsel <= 4'b0;
                        axi_addr <= 32'b0;
                        axi_wdata <= 32'b0;
                        stage <= `T3;
                    end
                end
                `T3:begin
                    if (fin == `True_v) begin
                        stage <= `T4;
                        rdata <= axi_rdata;
                        end_stall <= 1'b0;
                    end
                end
                `T4:begin
                    stage <= `T1;
                    end_stall <= 1'b1;
                end
            endcase
        end
    end
endmodule 