`include "defines.v"

`define STAGE_WIDTH 8
`define TAG_WIDTH 20
`define INDEX_WIDTH 128 // 块高
`define CACHELINE_WIDTH 256 // 块宽

module cache_v2(
    input wire clk,
    input wire rst,

    input wire sram_en,
    input wire [3:0] sram_wen,
    input wire [31:0] sram_addr,
    input wire [31:0] sram_wdata,
    output wire [31:0] sram_rdata,

    output reg ren,
    output reg [31:0] raddr,
    input wire raccept,

    input wire wen_fill,
    input wire [`CACHELINE_WIDTH-1:0] wfill,

    output reg wen,
    output reg [31:0] waddr,
    output reg [`CACHELINE_WIDTH-1:0] wdata,
    input wire wfin,

    output wire stallreq
);
    // index    = 7 (128 line)
    // offset   = 3 (8 word)
    // tag + valid + dirty = 20 + 1 + 1 = 22
    // tag block ram 22*128
    // data block ram 256*128
    // lru reg 128
    reg [`STAGE_WIDTH-1:0] stage;
    wire miss_next;
    wire [31:0] rdata_next;
    reg [`TAG_WIDTH-1:0] ram_tag_way0 [`INDEX_WIDTH-1:0];
    reg [`TAG_WIDTH-1:0] ram_tag_way1 [`INDEX_WIDTH-1:0];
    reg [`INDEX_WIDTH-1:0] lru;
    reg [`INDEX_WIDTH-1:0] ram_dirty_way0;
    reg [`INDEX_WIDTH-1:0] ram_dirty_way1;
    reg [`INDEX_WIDTH-1:0] ram_valid_way0;
    reg [`INDEX_WIDTH-1:0] ram_valid_way1;

    wire [6:0] index_i;
    wire [2:0] offset_i;
    wire [`TAG_WIDTH-1:0] tag_i;

    assign {tag_i,index_i,offset_i} = sram_addr[31:2];

    wire [`TAG_WIDTH-1:0] tag_way0;
    wire [`TAG_WIDTH-1:0] tag_way1;
    wire [`CACHELINE_WIDTH-1:0] cacheline_way0_wdata;
    wire [`CACHELINE_WIDTH-1:0] cacheline_way1_wdata;
    wire [`CACHELINE_WIDTH-1:0] cacheline_way0_rdata;
    wire [`CACHELINE_WIDTH-1:0] cacheline_way1_rdata;
    wire valid_way0;
    wire valid_way1;
    wire dirty_way0;
    wire dirty_way1;
    // wire [31:0] we_source = 32'b0;
    wire [31:0] we_way0;
    wire [31:0] we_way1;

    wire hit_way0;
    wire hit_way1;
    wire [31:0] rdata_way0;
    wire [31:0] rdata_way1;

    // reg [`TAG_WIDTH-1:0] tag_temp;
    reg [2:0] offset_temp;
    reg hit_temp_way0;
    reg hit_temp_way1;
    bram_cache_data ram_data_way0(
        .clka(clk),             // input wire clka
        .ena(sram_en),                 // input wire ena
        .wea(we_way0),                 // input wire [31 : 0] wea
        .addra(index_i),               // input wire [6 : 0] addra
        .dina(cacheline_way0_wdata),                // input wire [255 : 0] dina
        .douta(cacheline_way0_rdata)                // output wire [255 : 0] douta
    );

    bram_cache_data ram_data_way1(
        .clka(clk),             // input wire clka
        .ena(sram_en),                 // input wire ena
        .wea(we_way1),                 // input wire [31 : 0] wea
        .addra(index_i),               // input wire [6 : 0] addra
        .dina(cacheline_way1_wdata),                // input wire [255 : 0] dina
        .douta(cacheline_way1_rdata)                // output wire [255 : 0] douta
    );

    

// lru
    always @ (posedge clk) begin
        if (rst) begin
            lru <= {`INDEX_WIDTH{1'b1}};
        end
        else if (hit_way0 && !hit_way1) begin
            lru[index_i] <= 1'b0;
        end
        else if (!hit_way0 && hit_way1) begin
            lru[index_i] <= 1'b1;
        end
    end

// way0 write
    // way0 valid 
    always @ (posedge clk) begin
        if (rst) begin
            ram_valid_way0 <= `INDEX_WIDTH'b0;
        end
        else if (wen_fill && lru[index_i]) begin
            ram_valid_way0[index_i] <= 1'b1;
        end
    end

    // way0 tag
    always @ (posedge clk) begin
        if (rst) begin
            ram_tag_way0[  0] <= `TAG_WIDTH'd0;
            ram_tag_way0[  1] <= `TAG_WIDTH'd0;
            ram_tag_way0[  2] <= `TAG_WIDTH'd0;
            ram_tag_way0[  3] <= `TAG_WIDTH'd0;
            ram_tag_way0[  4] <= `TAG_WIDTH'd0;
            ram_tag_way0[  5] <= `TAG_WIDTH'd0;
            ram_tag_way0[  6] <= `TAG_WIDTH'd0;
            ram_tag_way0[  7] <= `TAG_WIDTH'd0;
            ram_tag_way0[  8] <= `TAG_WIDTH'd0;
            ram_tag_way0[  9] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 10] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 11] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 12] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 13] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 14] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 15] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 16] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 17] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 18] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 19] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 20] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 21] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 22] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 23] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 24] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 25] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 26] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 27] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 28] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 29] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 30] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 31] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 32] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 33] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 34] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 35] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 36] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 37] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 38] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 39] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 40] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 41] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 42] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 43] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 44] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 45] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 46] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 47] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 48] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 49] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 50] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 51] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 52] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 53] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 54] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 55] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 56] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 57] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 58] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 59] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 60] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 61] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 62] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 63] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 64] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 65] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 66] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 67] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 68] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 69] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 70] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 71] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 72] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 73] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 74] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 75] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 76] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 77] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 78] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 79] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 80] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 81] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 82] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 83] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 84] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 85] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 86] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 87] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 88] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 89] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 90] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 91] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 92] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 93] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 94] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 95] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 96] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 97] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 98] <= `TAG_WIDTH'd0;
            ram_tag_way0[ 99] <= `TAG_WIDTH'd0;
            ram_tag_way0[100] <= `TAG_WIDTH'd0;
            ram_tag_way0[101] <= `TAG_WIDTH'd0;
            ram_tag_way0[102] <= `TAG_WIDTH'd0;
            ram_tag_way0[103] <= `TAG_WIDTH'd0;
            ram_tag_way0[104] <= `TAG_WIDTH'd0;
            ram_tag_way0[105] <= `TAG_WIDTH'd0;
            ram_tag_way0[106] <= `TAG_WIDTH'd0;
            ram_tag_way0[107] <= `TAG_WIDTH'd0;
            ram_tag_way0[108] <= `TAG_WIDTH'd0;
            ram_tag_way0[109] <= `TAG_WIDTH'd0;
            ram_tag_way0[110] <= `TAG_WIDTH'd0;
            ram_tag_way0[111] <= `TAG_WIDTH'd0;
            ram_tag_way0[112] <= `TAG_WIDTH'd0;
            ram_tag_way0[113] <= `TAG_WIDTH'd0;
            ram_tag_way0[114] <= `TAG_WIDTH'd0;
            ram_tag_way0[115] <= `TAG_WIDTH'd0;
            ram_tag_way0[116] <= `TAG_WIDTH'd0;
            ram_tag_way0[117] <= `TAG_WIDTH'd0;
            ram_tag_way0[118] <= `TAG_WIDTH'd0;
            ram_tag_way0[119] <= `TAG_WIDTH'd0;
            ram_tag_way0[120] <= `TAG_WIDTH'd0;
            ram_tag_way0[121] <= `TAG_WIDTH'd0;
            ram_tag_way0[122] <= `TAG_WIDTH'd0;
            ram_tag_way0[123] <= `TAG_WIDTH'd0;
            ram_tag_way0[124] <= `TAG_WIDTH'd0;
            ram_tag_way0[125] <= `TAG_WIDTH'd0;
            ram_tag_way0[126] <= `TAG_WIDTH'd0;
            ram_tag_way0[127] <= `TAG_WIDTH'd0;
        end
        else if (sram_en && wen_fill && lru[index_i]) begin // sram_en 可能不是很需要
            ram_tag_way0[index_i] <= tag_i;
        end
    end

    // way0 data
    assign cacheline_way0_wdata = wen_fill ? wfill :
                                sram_wen == 4'b1111 ? {8{sram_wdata}} :
                                sram_wen == 4'b0001 ? {32{sram_wdata[7:0]}} :
                                sram_wen == 4'b0010 ? {32{sram_wdata[15:8]}} :
                                sram_wen == 4'b0100 ? {32{sram_wdata[23:16]}} :
                                sram_wen == 4'b1000 ? {32{sram_wdata[31:24]}} :
                                sram_wen == 4'b0011 ? {16{sram_wdata[15:0]}} :
                                sram_wen == 4'b1100 ? {16{sram_wdata[31:16]}} :
                                `CACHELINE_WIDTH'b0 ;
    assign we_way0 = sram_en && wen_fill && lru[index_i] ? {32{1'b1}} :
                    (sram_en && |sram_wen && hit_way0) ? offset_i == 0 ? {28'b0,sram_wen} :
                                                        offset_i == 1 ? {24'b0,sram_wen,4'b0} :
                                                        offset_i == 2 ? {20'b0,sram_wen,8'b0} :
                                                        offset_i == 3 ? {16'b0,sram_wen,12'b0} :
                                                        offset_i == 4 ? {12'b0,sram_wen,16'b0} :
                                                        offset_i == 5 ? {8'b0,sram_wen,20'b0} :
                                                        offset_i == 6 ? {4'b0,sram_wen,24'b0} :
                                                        offset_i == 7 ? {sram_wen,28'b0} : 32'b0 :
                                                        32'b0;
                     
    // always @ (*) begin
    //     if (sram_en && wen_fill && lru[index_i]) begin
    //         cacheline_way0_wdata = wfill;
    //         we_way0 = {32{1'b1}};
    //     end
    //     else if (sram_en && |sram_wen && hit_way0) begin
    //         case (sram_wen)
    //             4'b1111:begin
    //                 cacheline_way0_wdata = {8{sram_wdata}};
    //                 we_way0 = 32'b0;
    //                 we_way0[offset_i*4+:4] = 4'b1111; 
    //             end
    //             4'b0001:begin
    //                 cacheline_way0_wdata = {32{sram_wdata[7:0]}};
    //                 we_way0 = 32'b0;
    //                 we_way0[offset_i*4+:4] = 4'b0001;
    //             end
    //             4'b0010:begin
    //                 cacheline_way0_wdata = {32{sram_wdata[15:8]}};
    //                 we_way0 = 32'b0;
    //                 we_way0[offset_i*4+:4] = 4'b0010;
    //             end
    //             4'b0100:begin
    //                 cacheline_way0_wdata = {32{sram_wdata[23:16]}};
    //                 we_way0 = 32'b0;
    //                 we_way0[offset_i*4+:4] = 4'b0100;
    //             end
    //             4'b1000:begin
    //                 cacheline_way0_wdata = {32{sram_wdata[31:24]}};
    //                 we_way0 = 32'b0;
    //                 we_way0[offset_i*4+:4] = 4'b1000;
    //             end
    //             4'b0011:begin
    //                 cacheline_way0_wdata = {16{sram_wdata[15:0]}};
    //                 we_way0 = 32'b0;
    //                 we_way0[offset_i*4+:4] = 4'b0011;
    //             end
    //             4'b1100:begin
    //                 cacheline_way0_wdata = {16{sram_wdata[31:16]}};
    //                 we_way0 = 32'b0;
    //                 we_way0[offset_i*4+:4] = 4'b1100;
    //             end
    //         endcase
    //     end
    //     else begin
    //         cacheline_way0_wdata = `CACHELINE_WIDTH'b0;
    //         we_way0 = 32'b0;
    //     end
    // end

    // way0 dirty
    always @ (posedge clk) begin
        if (rst) begin
            ram_dirty_way0 <= 16'h0;
        end
        else if (sram_en && sram_wen != 4'b0 && hit_way0) begin
            ram_dirty_way0[index_i] <= 1'b1;
        end
    end

// way0 read
    assign valid_way0 = ram_valid_way0[index_i];
    assign tag_way0 = ram_tag_way0[index_i];
    assign dirty_way0 = ram_dirty_way0[index_i];

    assign hit_way0 = !valid_way0 ? 1'b0
                    : tag_way0 == tag_i ? 1'b1 : 1'b0;
    assign rdata_way0 = cacheline_way0_rdata[offset_temp*32+:32];

// way1 write
    // way1 valid 
    always @ (posedge clk) begin
        if (rst) begin
            ram_valid_way1 <= `INDEX_WIDTH'b0;
        end
        else if (wen_fill && !lru[index_i]) begin
            ram_valid_way1[index_i] <= 1'b1;
        end
    end

    // way1 tag
    always @ (posedge clk) begin
        if (rst) begin
            ram_tag_way1[  0] <= `TAG_WIDTH'd0;
            ram_tag_way1[  1] <= `TAG_WIDTH'd0;
            ram_tag_way1[  2] <= `TAG_WIDTH'd0;
            ram_tag_way1[  3] <= `TAG_WIDTH'd0;
            ram_tag_way1[  4] <= `TAG_WIDTH'd0;
            ram_tag_way1[  5] <= `TAG_WIDTH'd0;
            ram_tag_way1[  6] <= `TAG_WIDTH'd0;
            ram_tag_way1[  7] <= `TAG_WIDTH'd0;
            ram_tag_way1[  8] <= `TAG_WIDTH'd0;
            ram_tag_way1[  9] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 10] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 11] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 12] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 13] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 14] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 15] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 16] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 17] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 18] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 19] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 20] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 21] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 22] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 23] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 24] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 25] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 26] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 27] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 28] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 29] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 30] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 31] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 32] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 33] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 34] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 35] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 36] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 37] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 38] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 39] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 40] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 41] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 42] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 43] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 44] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 45] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 46] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 47] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 48] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 49] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 50] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 51] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 52] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 53] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 54] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 55] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 56] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 57] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 58] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 59] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 60] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 61] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 62] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 63] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 64] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 65] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 66] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 67] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 68] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 69] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 70] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 71] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 72] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 73] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 74] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 75] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 76] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 77] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 78] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 79] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 80] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 81] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 82] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 83] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 84] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 85] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 86] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 87] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 88] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 89] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 90] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 91] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 92] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 93] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 94] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 95] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 96] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 97] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 98] <= `TAG_WIDTH'd0;
            ram_tag_way1[ 99] <= `TAG_WIDTH'd0;
            ram_tag_way1[100] <= `TAG_WIDTH'd0;
            ram_tag_way1[101] <= `TAG_WIDTH'd0;
            ram_tag_way1[102] <= `TAG_WIDTH'd0;
            ram_tag_way1[103] <= `TAG_WIDTH'd0;
            ram_tag_way1[104] <= `TAG_WIDTH'd0;
            ram_tag_way1[105] <= `TAG_WIDTH'd0;
            ram_tag_way1[106] <= `TAG_WIDTH'd0;
            ram_tag_way1[107] <= `TAG_WIDTH'd0;
            ram_tag_way1[108] <= `TAG_WIDTH'd0;
            ram_tag_way1[109] <= `TAG_WIDTH'd0;
            ram_tag_way1[110] <= `TAG_WIDTH'd0;
            ram_tag_way1[111] <= `TAG_WIDTH'd0;
            ram_tag_way1[112] <= `TAG_WIDTH'd0;
            ram_tag_way1[113] <= `TAG_WIDTH'd0;
            ram_tag_way1[114] <= `TAG_WIDTH'd0;
            ram_tag_way1[115] <= `TAG_WIDTH'd0;
            ram_tag_way1[116] <= `TAG_WIDTH'd0;
            ram_tag_way1[117] <= `TAG_WIDTH'd0;
            ram_tag_way1[118] <= `TAG_WIDTH'd0;
            ram_tag_way1[119] <= `TAG_WIDTH'd0;
            ram_tag_way1[120] <= `TAG_WIDTH'd0;
            ram_tag_way1[121] <= `TAG_WIDTH'd0;
            ram_tag_way1[122] <= `TAG_WIDTH'd0;
            ram_tag_way1[123] <= `TAG_WIDTH'd0;
            ram_tag_way1[124] <= `TAG_WIDTH'd0;
            ram_tag_way1[125] <= `TAG_WIDTH'd0;
            ram_tag_way1[126] <= `TAG_WIDTH'd0;
            ram_tag_way1[127] <= `TAG_WIDTH'd0;

        end
        else if (sram_en && wen_fill && !lru[index_i]) begin
            ram_tag_way1[index_i] <= tag_i;
        end
    end

    // way1 data
    assign cacheline_way1_wdata = wen_fill ? wfill :
                                sram_wen == 4'b1111 ? {8{sram_wdata}} :
                                sram_wen == 4'b0001 ? {32{sram_wdata[7:0]}} :
                                sram_wen == 4'b0010 ? {32{sram_wdata[15:8]}} :
                                sram_wen == 4'b0100 ? {32{sram_wdata[23:16]}} :
                                sram_wen == 4'b1000 ? {32{sram_wdata[31:24]}} :
                                sram_wen == 4'b0011 ? {16{sram_wdata[15:0]}} :
                                sram_wen == 4'b1100 ? {16{sram_wdata[31:16]}} :
                                `CACHELINE_WIDTH'b0 ;
    assign we_way1 = sram_en && wen_fill && !lru[index_i] ? {32{1'b1}} :
                    (sram_en && |sram_wen && hit_way1) ? offset_i == 0 ? {28'b0,sram_wen} :
                                                        offset_i == 1 ? {24'b0,sram_wen,4'b0} :
                                                        offset_i == 2 ? {20'b0,sram_wen,8'b0} :
                                                        offset_i == 3 ? {16'b0,sram_wen,12'b0} :
                                                        offset_i == 4 ? {12'b0,sram_wen,16'b0} :
                                                        offset_i == 5 ? {8'b0,sram_wen,20'b0} :
                                                        offset_i == 6 ? {4'b0,sram_wen,24'b0} :
                                                        offset_i == 7 ? {sram_wen,28'b0} : 32'b0 :
                                                        32'b0;
    // always @ (*) begin
    //     if (sram_en && wen_fill && !lru[index_i]) begin
    //         cacheline_way1_wdata = wfill;
    //         we_way1 = {32{1'b1}};
    //     end
    //     else if (sram_en && |sram_wen && hit_way1) begin
    //         case (sram_wen)
    //             4'b1111:begin
    //                 cacheline_way1_wdata = {8{sram_wdata}};
    //                 we_way1 = 32'b0;
    //                 we_way1[offset_i*4+:4] = 4'b1111; 
    //             end
    //             4'b0001:begin
    //                 cacheline_way1_wdata = {32{sram_wdata[7:0]}};
    //                 we_way1 = 32'b0;
    //                 we_way1[offset_i*4+:4] = 4'b0001;
    //             end
    //             4'b0010:begin
    //                 cacheline_way1_wdata = {32{sram_wdata[15:8]}};
    //                 we_way1 = 32'b0;
    //                 we_way1[offset_i*4+:4] = 4'b0010;
    //             end
    //             4'b0100:begin
    //                 cacheline_way1_wdata = {32{sram_wdata[23:16]}};
    //                 we_way1 = 32'b0;
    //                 we_way1[offset_i*4+:4] = 4'b0100;
    //             end
    //             4'b1000:begin
    //                 cacheline_way1_wdata = {32{sram_wdata[31:24]}};
    //                 we_way1 = 32'b0;
    //                 we_way1[offset_i*4+:4] = 4'b1000;
    //             end
    //             4'b0011:begin
    //                 cacheline_way1_wdata = {16{sram_wdata[15:0]}};
    //                 we_way1 = 32'b0;
    //                 we_way1[offset_i*4+:4] = 4'b0011;
    //             end
    //             4'b1100:begin
    //                 cacheline_way1_wdata = {16{sram_wdata[31:16]}};
    //                 we_way1 = 32'b0;
    //                 we_way1[offset_i*4+:4] = 4'b1100;
    //             end
    //         endcase 
    //     end
    //     else begin
    //         cacheline_way1_wdata = `CACHELINE_WIDTH'b0;
    //         we_way1 = 32'b0;
    //     end
    // end

    // way1 dirty 
    always @ (posedge clk) begin
        if (rst) begin
            ram_dirty_way1 <= 16'b0;
        end
        else if (sram_en && sram_wen != 4'b0 && hit_way1) begin
            ram_dirty_way1[index_i] <= 1'b1;
        end
    end

// way1 read
    assign valid_way1 = ram_valid_way1[index_i];
    assign tag_way1 = ram_tag_way1[index_i];
    assign dirty_way1 = ram_dirty_way1[index_i];

    assign hit_way1 = !valid_way1 ? 1'b0 
                    : tag_way1 == tag_i ? 1'b1 : 1'b0;
    assign rdata_way1 = cacheline_way1_rdata[offset_temp*32+:32];

// merge 
    assign miss_next = !sram_en ? `False_v : !hit_way0  && !hit_way1 ? `True_v : `False_v;

    assign sram_rdata = rst ? 32'b0
                      : hit_temp_way0 ? rdata_way0 
                      : hit_temp_way1 ? rdata_way1
                      : 32'b0;

    assign stallreq = rst ? `False_v
                    : !sram_en ? `False_v
                    : miss_next ? `True_v
                    : `False_v;

// read out port
    always @ (posedge clk) begin
        if (rst) begin
            offset_temp <= 3'b0;
            hit_temp_way0 <= 1'b0;
            hit_temp_way1 <= 1'b0;
        end
        else begin
            offset_temp <= offset_i;
            hit_temp_way0 <= hit_way0;
            hit_temp_way1 <= hit_way1;
        end
    end
    // always @ (posedge clk) begin
    //     if (rst) begin
    //         sram_rdata <= 32'b0;
    //     end
    //     else if (!sram_en) begin
    //         sram_rdata <= 32'b0;
    //     end
    //     else if (!miss_next && sram_en) begin
    //         sram_rdata <= rdata_next;
    //     end
    //     else if (miss_next) begin
    //         sram_rdata <= 32'b0;
    //     end
    // end

    always @ (posedge clk) begin
        if (rst) begin
            stage <= 4'd1;
            ren <= `False_v;
            raddr <= 32'b0;
        end
        else begin
            case(1'b1)
                stage[0]:begin
                    if (miss_next) begin
                        ren <= `True_v;
                        raddr <= {sram_addr[31:5],5'b0};
                        stage <= stage << 1;
                    end
                end
                stage[1]:begin
                    if (raccept) begin
                        ren <= `False_v;
                        raddr <= 32'b0;
                        stage <= stage << 1;
                    end
                end
                stage[2]:begin
                    if (wen_fill) begin
                        stage <= stage << 1;
                    end
                end
                stage[3]:begin
                    stage <= 4'd1;
                end
            endcase
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            wen <= `False_v;
            waddr <= 32'b0;
            wdata <= `CACHELINE_WIDTH'b0;
        end
        else if (ren && !lru[index_i]) begin
            wen <= `True_v;
            waddr <= {ram_tag_way1[index_i],index_i,5'b0};
            wdata <= cacheline_way1_rdata;
        end
        else if (ren && lru[index_i]) begin
            wen <= `True_v;
            waddr <= {ram_tag_way0[index_i],index_i,5'b0};
            wdata <= cacheline_way0_rdata;
        end
        else begin
            wen <= `False_v;
            waddr <= 32'b0;
            wdata <= `CACHELINE_WIDTH'b0;
        end
    end
    
endmodule