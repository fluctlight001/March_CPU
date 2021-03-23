`include "defines.v"
`define T1 2'b00
`define T2 2'b01
`define T3 2'b11
`define T4 2'b10
module cache_sample(
    input wire clk,
    input wire rst,
    input wire en,

    input wire [3:0] wen,
    input wire [31:0] addr,
    input wire [31:0] wdata,
    output reg [31:0] rdata,

    output reg wen_back, // 写回使能
    output reg [31:0] waddr, // 写回目标地址
    output reg [511:0] wback, // 写回数据
    input wire fin, // 写回完成标记

    input wire wen_fill, // 填充使能
    input wire [511:0] wfill, // 填充数据
    
    output reg miss, // 缺失使能
    output reg [31:0] miss_addr, // 缺失地址
    input wire accept, // 缺失信号接收确认信号
    output wire stallreq
);
    reg [511:0] ram_data_way0 [15:0];
    reg [511:0] ram_data_way1 [15:0];
    reg [21:0] ram_tag_way0 [15:0];
    reg [21:0] ram_tag_way1 [15:0];
    reg [15:0] lru;
    reg [15:0] ram_dirty_way0;
    reg [15:0] ram_dirty_way1;
    reg [15:0] ram_valid_way0;
    reg [15:0] ram_valid_way1;

    wire [3:0] index_i;
    wire [3:0] offset_i;
    wire [21:0] tag_i;

    assign {tag_i,index_i,offset_i} = addr[31:2];

    wire valid_way0;
    wire valid_way1;
    wire [21:0] tag_way0;
    wire [21:0] tag_way1;
    wire [511:0] cacheline_way0;
    wire [511:0] cacheline_way1;
    wire dirty_way0;
    wire dirty_way1;

    wire hit_way0;
    wire hit_way1;
    wire [31:0] rdata_way0;
    wire [31:0] rdata_way1;

    wire [31:0] rdata_next;

    wire miss_next;

    reg [1:0] stage;


// lru
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            lru <= 16'hffff;
        end
        else if (hit_way0 == 1'b1 && hit_way1 == 1'b0) begin
            lru[index_i] <= 1'b0;
        end
        else if (hit_way0 == 1'b0 && hit_way1 == 1'b1) begin
            lru[index_i] <= 1'b1;
        end
        else begin
            
        end 
    end

// way0 write
    // way0 valid
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ram_valid_way0 <= 16'h0;
        end
        else if (wen_fill == `True_v && lru[index_i] == 1'b1) begin
            ram_valid_way0[index_i] <= 1'b1;
        end
    end

    // way0 tag
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ram_tag_way0[ 0] <= 22'd0;
            ram_tag_way0[ 1] <= 22'd0;
            ram_tag_way0[ 2] <= 22'd0;
            ram_tag_way0[ 3] <= 22'd0;
            ram_tag_way0[ 4] <= 22'd0;
            ram_tag_way0[ 5] <= 22'd0;
            ram_tag_way0[ 6] <= 22'd0;
            ram_tag_way0[ 7] <= 22'd0;
            ram_tag_way0[ 8] <= 22'd0;
            ram_tag_way0[ 9] <= 22'd0;
            ram_tag_way0[10] <= 22'd0;
            ram_tag_way0[11] <= 22'd0;
            ram_tag_way0[12] <= 22'd0;
            ram_tag_way0[13] <= 22'd0;
            ram_tag_way0[14] <= 22'd0;
            ram_tag_way0[15] <= 22'd0;
        end
        else if (en == `True_v && wen_fill == `True_v && lru[index_i] == 1'b1) begin
            ram_tag_way0[index_i] <= tag_i;
        end
    end
    
    // way0 data
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ram_data_way0[ 0] <= 512'd0;
            ram_data_way0[ 1] <= 512'd0;
            ram_data_way0[ 2] <= 512'd0;
            ram_data_way0[ 3] <= 512'd0;
            ram_data_way0[ 4] <= 512'd0;
            ram_data_way0[ 5] <= 512'd0;
            ram_data_way0[ 6] <= 512'd0;
            ram_data_way0[ 7] <= 512'd0;
            ram_data_way0[ 8] <= 512'd0;
            ram_data_way0[ 9] <= 512'd0;
            ram_data_way0[10] <= 512'd0;
            ram_data_way0[11] <= 512'd0;
            ram_data_way0[12] <= 512'd0;
            ram_data_way0[13] <= 512'd0;
            ram_data_way0[14] <= 512'd0;
            ram_data_way0[15] <= 512'd0;
        end
        else if (en == `True_v && wen_fill == `True_v && lru[index_i] == 1'b1) begin
            ram_data_way0[index_i] <= wfill;
        end
        else if (en == `True_v && |wen && hit_way0) begin
            case (wen)
                4'b1111:begin
                    ram_data_way0[index_i][offset_i*32+:32] = wdata;
                end
                4'b0001:begin
                    ram_data_way0[index_i][offset_i*32+0+:8] = wdata[7:0];
                end
                4'b0010:begin
                    ram_data_way0[index_i][offset_i*32+8+:8] = wdata[15:8];
                end
                4'b0100:begin
                    ram_data_way0[index_i][offset_i*32+16+:8] = wdata[23:16];
                end
                4'b1000:begin
                    ram_data_way0[index_i][offset_i*32+24+:8] = wdata[31:24];
                end
                4'b0011:begin
                    ram_data_way0[index_i][offset_i*32+0+:16] = wdata[15:0];
                end
                4'b1100:begin
                    ram_data_way0[index_i][offset_i*32+16+:16] = wdata[31:16];
                end
            endcase
        end
    end  

    // way0 dirty
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ram_dirty_way0 <= 16'h0;
        end
        else if (en == `True_v && wen != 4'b0 && hit_way0 == 1'b1) begin
            ram_dirty_way0[index_i] <= 1'b1;
        end
    end

// way0 read
    assign valid_way0 = ram_valid_way0[index_i];
    assign tag_way0 = ram_tag_way0[index_i];
    assign cacheline_way0 = ram_data_way0[index_i];
    assign dirty_way0 = ram_dirty_way0[index_i];

    assign hit_way0 = valid_way0 == 1'b0 ? 1'b0 
                    :  tag_way0 == tag_i ? 1'b1 : 1'b0;
    assign rdata_way0 = cacheline_way0[offset_i*32+:32];


// way1 write
    // way1 valid
    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            ram_valid_way1 <= 16'h0;
        end
        else if (wen_fill == `True_v && lru[index_i] == 1'b0) begin
            ram_valid_way1[index_i] <= 1'b1;
        end
    end

    // way1 tag
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ram_tag_way1[ 0] <= 22'd0;
            ram_tag_way1[ 1] <= 22'd0;
            ram_tag_way1[ 2] <= 22'd0;
            ram_tag_way1[ 3] <= 22'd0;
            ram_tag_way1[ 4] <= 22'd0;
            ram_tag_way1[ 5] <= 22'd0;
            ram_tag_way1[ 6] <= 22'd0;
            ram_tag_way1[ 7] <= 22'd0;
            ram_tag_way1[ 8] <= 22'd0;
            ram_tag_way1[ 9] <= 22'd0;
            ram_tag_way1[10] <= 22'd0;
            ram_tag_way1[11] <= 22'd0;
            ram_tag_way1[12] <= 22'd0;
            ram_tag_way1[13] <= 22'd0;
            ram_tag_way1[14] <= 22'd0;
            ram_tag_way1[15] <= 22'd0;
        end
        else if (en == `True_v && wen_fill == `True_v && lru[index_i] == 1'b0) begin
            ram_tag_way1[index_i] <= tag_i; 
        end
    end

    // way1 data
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ram_data_way1[ 0] <= 512'd0;
            ram_data_way1[ 1] <= 512'd0;
            ram_data_way1[ 2] <= 512'd0;
            ram_data_way1[ 3] <= 512'd0;
            ram_data_way1[ 4] <= 512'd0;
            ram_data_way1[ 5] <= 512'd0;
            ram_data_way1[ 6] <= 512'd0;
            ram_data_way1[ 7] <= 512'd0;
            ram_data_way1[ 8] <= 512'd0;
            ram_data_way1[ 9] <= 512'd0;
            ram_data_way1[10] <= 512'd0;
            ram_data_way1[11] <= 512'd0;
            ram_data_way1[12] <= 512'd0;
            ram_data_way1[13] <= 512'd0;
            ram_data_way1[14] <= 512'd0;
            ram_data_way1[15] <= 512'd0;
        end
        else if (en == `True_v && wen_fill == `True_v && lru[index_i] == 1'b0) begin
            ram_data_way1[index_i] <= wfill;
        end
        else if (en == `True_v && |wen && hit_way1) begin
            case (wen)
                4'b1111:begin
                    ram_data_way1[index_i][offset_i*32+:32] = wdata;
                end
                4'b0001:begin
                    ram_data_way1[index_i][offset_i*32+0+:8] = wdata[7:0];
                end
                4'b0010:begin
                    ram_data_way1[index_i][offset_i*32+8+:8] = wdata[15:8];
                end
                4'b0100:begin
                    ram_data_way1[index_i][offset_i*32+16+:8] = wdata[23:16];
                end
                4'b1000:begin
                    ram_data_way1[index_i][offset_i*32+24+:8] = wdata[31:24];
                end
                4'b0011:begin
                    ram_data_way1[index_i][offset_i*32+0+:16] = wdata[15:0];
                end
                4'b1100:begin
                    ram_data_way1[index_i][offset_i*32+16+:16] = wdata[31:16];
                end
            endcase
        end
    end
    
    // way1 dirty
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ram_dirty_way1 <= 16'h0;
        end
        else begin
            ram_dirty_way1[index_i] <= 1'b1;
        end
    end
// way1 read
    assign valid_way1 = ram_valid_way1[index_i];
    assign tag_way1 = ram_tag_way1[index_i];
    assign cacheline_way1 = ram_data_way1[index_i];
    assign dirty_way1 = ram_dirty_way1[index_i];

    assign hit_way1 = valid_way1 == 1'b0 ? 1'b0 
                    : tag_way1 == tag_i ? 1'b1 : 1'b0;
    assign rdata_way1 = cacheline_way1[offset_i*32+:32];




// merge
    assign miss_next = !en ? `False_v :  hit_way0 == 1'b0 && hit_way1 == 1'b0 ? `True_v : `False_v;

    assign rdata_next = rst == `RstEnable ? 32'b0
                : hit_way0 == 1'b1 ? rdata_way0
                : hit_way1 == 1'b1 ? rdata_way1
                : 32'b0;
    
    assign stallreq = rst == `RstEnable ? `False_v 
                    : en == `ChipDisable ? `False_v 
                    : miss_next ? `True_v
                    : `False_v;

// read out port
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            rdata <= 32'b0;
        end
        else if (!en) begin
            rdata <= 32'b0;
        end
        else if (!miss_next && en)  begin
            rdata <= rdata_next;
        end
        else if (miss_next) begin
            rdata <= 32'b0;
        end
    end

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            miss <= `False_v;
            miss_addr <= 32'b0;
            stage <= `T1;
        end
        else begin
            case (stage)
                `T1:begin
                    if (miss_next == `True_v)begin
                        miss <= `True_v;
                        miss_addr <= {addr[31:6],6'b0};
                        stage <= `T2;
                    end
                end
                `T2:begin
                    if (accept == `True_v) begin
                        miss <= `False_v;
                        miss_addr <= 32'b0;
                        stage <= `T3;
                    end
                end
                `T3:begin
                    if (wen_fill == 1'b1) begin
                        stage <= `T4;
                    end
                end
                `T4:begin
                    stage <= `T1;
                end
            endcase 
        end
    end

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            wen_back <= `False_v;
            waddr <= 32'b0;
            wback <= 512'b0;
        end
        else if (miss_next == `True_v && lru[index_i] == 1'b0) begin
            wen_back <= `True_v;
            waddr <= {ram_tag_way1[index_i],index_i,6'b0};
            wback <= ram_data_way1[index_i];
        end
        else if (miss_next == `True_v && lru[index_i] == 1'b1) begin
            wen_back <= `True_v;
            waddr <= {ram_tag_way0[index_i],index_i,6'b0};
            wback <= ram_data_way0[index_i];
        end
        else begin
            wen_back <= `False_v;
            waddr <= 32'b0;
            wback <= 512'b0;
        end
    end

endmodule