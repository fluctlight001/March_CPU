`include "defines.v"
module control(
    input wire clk,
    input wire rstn,

    input wire inst_sram_en,
    input wire [3:0] inst_sram_wen,
    input wire [31:0] inst_sram_addr,
    input wire [31:0] inst_sram_wdata,
    output reg [31:0] inst_sram_rdata,
    output reg inst_sram_rvalid,

    input wire data_sram_en,
    input wire [3:0] data_sram_wen,
    input wire [31:0] data_sram_addr,
    input wire [31:0] data_sram_wdata,
    output reg [31:0] data_sram_rdata,
    output reg data_sram_rvalid,

    input wire data_uncache_en,
    output reg data_uncache_accept,
    input wire [3:0] data_uncache_wen,
    input wire [31:0] data_uncache_addr,
    input wire [31:0] data_uncache_wdata,
    output reg [31:0] data_uncache_rdata,
    output reg data_uncache_fin,

    output         reg inst_req     ,
    output         reg inst_wr      ,
    output reg [1 :0]  inst_size    ,
    output reg [31:0] inst_addr    ,
    output reg [31:0] inst_wdata   ,
    input   [31:0] inst_rdata   ,
    input          inst_addr_ok ,
    input          inst_data_ok ,

    output         reg data_req     ,
    output         reg data_wr      ,
    output reg [1 :0] data_size    ,
    output reg [31:0] data_addr    ,
    output reg [31:0] data_wdata   ,
    input   [31:0] data_rdata   ,
    input          data_addr_ok ,
    input          data_data_ok 
);

    wire [1:0] data_size_temp;
    assign data_size_temp = data_sram_wen == 4'b0001 ? 2'b00
                          : data_sram_wen == 4'b0010 ? 2'b00
                          : data_sram_wen == 4'b0100 ? 2'b00
                          : data_sram_wen == 4'b1000 ? 2'b00
                          : data_sram_wen == 4'b0011 ? 2'b01
                          : data_sram_wen == 4'b1100 ? 2'b01
                          : data_sram_wen == 4'b1111 ? 2'b10
                          : 2'b10;

    wire [1:0] data_size_temp2;
    reg [3:0] data_uncache_wen_buffer;
    assign data_size_temp2 = data_uncache_wen_buffer == 4'b0001 ? 2'b00
                          : data_uncache_wen_buffer == 4'b0010 ? 2'b00
                          : data_uncache_wen_buffer == 4'b0100 ? 2'b00
                          : data_uncache_wen_buffer == 4'b1000 ? 2'b00
                          : data_uncache_wen_buffer == 4'b0011 ? 2'b01
                          : data_uncache_wen_buffer == 4'b1100 ? 2'b01
                          : data_uncache_wen_buffer == 4'b1111 ? 2'b10
                          : 2'b10;
    reg [11:0] stage;
    always @ (posedge clk) begin
        if (!rstn) begin
            // stallreq <= 1'b0;
            inst_sram_rdata <= 32'b0;
            data_sram_rdata <= 32'b0;
            inst_req <= 1'b0;
            data_req <= 1'b0;
            stage <= 12'b0;
            inst_sram_rvalid <= 1'b0;
            data_sram_rvalid <= 1'b0;
            data_uncache_accept <= 1'b0;
            data_uncache_fin <= 1'b0;
        end
        else begin
            case(1'b1)
                stage[0]:begin // stallreq
                    // stallreq <= 1'b1;
                    inst_sram_rvalid <= 1'b0;
                    data_sram_rvalid <= 1'b0;
                    data_uncache_accept <= 1'b0;
                    data_uncache_fin <= 1'b0;
                    data_uncache_wen_buffer <= data_uncache_wen;
                    if (inst_sram_en|data_sram_en|data_uncache_en) begin
                        stage <= stage << 1;    
                    end
                end
                stage[1]:begin
                    if (inst_sram_en) begin
                        inst_req <= 1'b1;
                        inst_wr <= 1'b0;
                        inst_size <= 2'b10;
                        inst_addr <= inst_sram_addr;
                        inst_wdata <= 32'b0;
                        stage <= stage << 1;
                    end
                    else begin
                        stage <= stage << 3;
                    end
                end
                stage[2]:begin
                    if (inst_addr_ok) begin
                        inst_req <= 1'b0;
                        inst_wr <= 1'b0;
                        inst_size <= 2'b00;
                        inst_addr <= 32'b0;
                        inst_wdata <= 32'b0;
                        stage <= stage << 1;
                    end
                end
                stage[3]:begin
                    if (inst_data_ok) begin
                        inst_sram_rdata <= inst_rdata;
                        inst_sram_rvalid <= 1'b1;
                        // stallreq <= 1'b0;
                        stage <= stage << 1;
                    end
                end
                stage[4]:begin
                    inst_sram_rvalid <= 1'b0;
                    if (data_sram_en) begin
                        data_req <= 1'b1;
                        data_wr <= |data_sram_wen ? 1'b1 : 1'b0;
                        data_size <= data_size_temp;
                        data_addr <= data_sram_addr;
                        data_wdata <= data_sram_wdata;
                        stage <= stage << 1;
                    end
                    else begin
                        stage <= stage << 3;
                    end
                end
                stage[5]:begin
                    if (data_addr_ok) begin
                        data_req <= 1'b0;
                        data_wr <= 1'b0;
                        data_size <= 2'b00;
                        data_addr <= 32'b0;
                        data_wdata <= 32'b0;
                        stage <= stage << 1;
                    end
                end
                stage[6]:begin
                    if (data_data_ok) begin
                        data_sram_rdata <= |data_sram_wen ? 32'b0 : data_rdata;
                        data_sram_rvalid <= |data_sram_wen ? 1'b0 : 1'b1;
                        stage <= stage << 1;
                    end
                end
                stage[7]:begin
                    data_sram_rvalid <= 1'b0;
                    if (data_uncache_en) begin
                        data_req <= 1'b1;
                        data_wr <= |data_uncache_wen ? 1'b1 : 1'b0;
                        data_size <= data_size_temp2;
                        data_addr <= data_uncache_addr;
                        data_wdata <= data_uncache_wdata;
                        data_uncache_accept <= 1'b1;
                        stage <= stage << 1;
                    end
                    else begin
                        stage <= stage << 3;
                    end
                end
                stage[8]:begin
                    data_uncache_accept <= 1'b0;
                    if (data_addr_ok) begin
                        data_req <= 1'b0;
                        data_wr <= 1'b0;
                        data_size <= 2'b00;
                        data_addr <= 32'b0;
                        data_wdata <= 32'b0;
                        stage <= stage << 1;
                    end
                end
                stage[9]:begin
                    if (data_data_ok) begin
                        data_uncache_rdata <= |data_uncache_wen_buffer ? 32'b0 : data_rdata;
                        data_uncache_fin <= 1'b1;
                        stage <= stage << 1;
                    end
                end
                stage[10]:begin
                    data_uncache_fin <= 1'b0;
                    stage <= 12'b1;
                end
                default:begin
                    stage <= 12'b1;
                    // stallreq <= 1'b1;
                end
            endcase
        end
    end



endmodule