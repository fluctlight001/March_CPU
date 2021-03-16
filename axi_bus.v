`include "defines.v"
module axi_bus(
  input wire clk,
  input wire rst,

// from icache
  input wire [`InstAddrBus] pc_i,
  input wire isMiss_from_icache,

// to icache
  output reg we_icache_o,
  output reg [`InstAddrBus] pc_icache_o,
  output reg [`InstBus] inst_icache_o,
  output reg last_for_icache,

// from dcache
  input wire [`RegBus] mem_addr_i,
  input wire mem_we_i,
  input wire [3:0] mem_sel_i,
  input wire [`RegBus] mem_data_i,
  input wire mem_ce_i,
  input wire isMiss_from_dcache,
  input wire cache_i,

// to dcache
  output reg [`RegBus] mem_addr_o,
  output reg mem_we_o,
  output reg [`RegBus] mem_data_o,
  output reg cache_o,
  output reg last_for_dcache,

//写地址通道信号
  output reg [3:0]	    awid,//写地址ID，用来标志一组写信号
  output reg [31:0]	    awaddr,//写地址，给出一次写突发传输的写地址
  output reg [3:0]	    awlen,//突发长度，给出突发传输的次数
  output reg [2:0]	    awsize,//突发大小，给出每次突发传输的字节数
  output reg [1:0]	    awburst,//突发类型
  output reg [1:0]	    awlock,//总线锁信号，可提供操作的原子性
  output reg [3:0]	    awcache,//内存类型，表明一次传输是怎样通过系统的
  output reg [2:0]	    awprot,//保护类型，表明一次传输的特权级及安全等级
  output reg 		        awvalid,//有效信号，表明此通道的地址控制信号有效
  input	wire		        awready,//表明"从"可以接收地址和对应的控制信号

//写数据通道信号
  output reg [3:0]	    wid,//一次写传输的ID tag
  output reg [31:0]	    wdata,//写数据
  output reg [3:0]	    wstrb,//写数据有效的字节线，用来表明哪8bits数据是有效的
  output reg 		        wlast,//表明此次传输是最后一个突发传输
  output reg		        wvalid,//写有效，表明此次写有效
  input	wire		        wready,//表明从机可以接收写数据
//写响应通道信号
  input	wire [3:0]	    bid,//写响应ID tag
  input	wire [1:0]	    bresp,//写响应，表明写传输的状态 00为正常，当然可以不理会
  input	wire		        bvalid,//写响应有效
  output reg		        bready,//表明主机能够接收写响应

//总线侧接口
//读地址通道信号
  output reg [3:0]	    arid,//读地址ID，用来标志一组写信号
  output reg [31:0]	    araddr,//读地址，给出一次写突发传输的读地址
  output reg [3:0]	    arlen,//突发长度，给出突发传输的次数
  output reg [2:0]	    arsize,//突发大小，给出每次突发传输的字节数
  output reg [1:0]	    arburst,//突发类型
  output reg [1:0]	    arlock,//总线锁信号，可提供操作的原子性
  output reg [3:0]	    arcache,//内存类型，表明一次传输是怎样通过系统的
  output reg [2:0]	    arprot,//保护类型，表明一次传输的特权级及安全等级
  output reg 		        arvalid,//有效信号，表明此通道的地址控制信号有效
  input	wire		        arready,//表明"从"可以接收地址和对应的控制信号
//读数据通道信号
  input	wire [3:0]	    rid,//读ID tag
  input	wire [31:0]	    rdata,//读数据
  input	wire [1:0]	    rresp,//读响应，表明读传输的状态
  input	wire		        rlast,//表明读突发的最后一次传输
  input	wire		        rvalid,//表明此通道信号有效
  output reg		        rready//表明主机能够接收读数据和响应信息
);
  //burst类型 00地址不变 01则地址递增
  //size 指字节数00为1字节，01为2字节==16位 10为4字节==32位
  //len 指定了读取指令的条数数量为 len+1
  reg [3:0] state;
  // reg [3:0] state_rw;
  reg [`RegBus] inst_bus;
  reg [`RegBus] pc_index; // pc增量
  reg [`RegBus] mem_index; // mem_addr增量

  always @ (posedge clk) begin 
    if(rst == `RstEnable)begin
      we_icache_o <= `WriteDisable;
      pc_icache_o <= `ZeroWord;
      inst_icache_o <= `ZeroWord;
      last_for_icache <= `True_v;

      mem_addr_o <= `ZeroWord;
      mem_we_o <= `WriteDisable;
      mem_data_o <= `ZeroWord;
      cache_o <= `Cache;
      last_for_dcache <= `True_v;

      arid <= 4'b0000;
      araddr <= `ZeroWord;
      arlen <= 4'b0000;
      arsize <= 3'b010;
      arburst <= 2'b01;
      arlock <= 2'b00;
      arcache <= 4'b0000;
      arprot <= 3'b000;
      arvalid <= 1'b0;

      rready <= 1'b0;

      awid <= 4'b0001;
      awaddr <= `ZeroWord;
      awlen <= 4'b0000;
      awsize <= 3'b010;
      awburst <= 2'b01;
      awlock <= 2'b00;
      awcache <= 4'b0000;
      awprot <= 3'b000;
      awvalid <= 1'b0;

      wid <= 4'b0001;
      wdata <= `ZeroWord;
      wstrb <= 4'b0000;
      wlast <= 1'b1;
      wvalid <= 1'b0;

      bready <= 1'b0;

      state <= `TEST1;
//      state_rw <= `RW1;
      pc_index <= `ZeroWord;
      mem_index <= `ZeroWord;
    end
    else begin
      case (state)
        `TEST1:begin
          mem_addr_o <= `ZeroWord;
          mem_we_o <= `WriteDisable;
          if (isMiss_from_icache == `True_v) begin
            state <= `READ1;
            arid <= 4'b0000;
            araddr <= pc_i;
            arlen <= 4'b1111;
            arsize <= 3'b010;
            arvalid <= `True_v;
            last_for_icache <= `False_v;
          end
          else if(isMiss_from_dcache == `True_v && mem_we_i == `WriteDisable) begin
            arid <= 4'b0001;
            araddr <= mem_addr_i;
            if (cache_i == `Cache) begin
              arlen <= 4'b1111;
            end
            else begin
              arlen <= 4'd0;  
            end
            if((mem_sel_i == 4'b0001)||(mem_sel_i == 4'b0010)||(mem_sel_i == 4'b0100)||(mem_sel_i == 4'b1000))begin
              arsize <= 3'b000;
            end
              else if((mem_sel_i == 4'b0011)||(mem_sel_i == 4'b1100))begin
              arsize <= 3'b001;
            end
            else if(mem_sel_i == 4'b1111)begin
              arsize <= 3'b010;
            end
            arvalid <= 1'b1;
            state <= `READ3;
            last_for_dcache <= `False_v;
          end
          else if(isMiss_from_dcache == `True_v && mem_we_i == `WriteEnable) begin
            awaddr <= mem_addr_i;
            if((mem_sel_i == 4'b0001)||(mem_sel_i == 4'b0010)||(mem_sel_i == 4'b0100)||(mem_sel_i == 4'b1000))begin
              awsize <= 3'b000;
            end
              else if((mem_sel_i == 4'b0011)||(mem_sel_i == 4'b1100))begin
              awsize <= 3'b001;
            end
            else if(mem_sel_i == 4'b1111)begin
              awsize <= 3'b010;
            end
            awvalid <= 1'b1;
            wstrb <= mem_sel_i;
            bready <= 1'b1;
            state <= `WRITE1;
            last_for_dcache <= `False_v;
          end
          else begin
          state <= `TEST1;
            // nothing
          end
        end
        `READ1:begin
          if (arready == 1'b1) begin
            arvalid <= 1'b0;
            araddr <= `ZeroWord;
            rready <= 1'b1;
            state <= `READ2;
          end
        end
        `READ2:begin
          if (rlast != 1'b1) begin
            if (rvalid == 1'b1) begin
              we_icache_o <= `WriteEnable;
              pc_icache_o <= pc_i + pc_index;
              pc_index <= pc_index + 32'd4;
              inst_icache_o <= rdata;
            end
            else begin
              we_icache_o <= `WriteDisable;
            end
          end
          else begin
            rready <= 1'b0;
            we_icache_o <= `WriteEnable;
            pc_icache_o <= pc_i + pc_index;
            pc_index <= `ZeroWord;
            inst_icache_o <= rdata;
            state <= `TEST2;
          end
        end
        `TEST2:begin
          we_icache_o <= `WriteDisable;
          last_for_icache <= `True_v;
          if (isMiss_from_dcache == `True_v) begin
            if (mem_we_i == `WriteDisable) begin
              arid <= 4'b0001;
              araddr <= mem_addr_i;
              if (cache_i == `Cache) begin
                arlen <= 4'b1111;
              end
              else begin
                arlen <= 4'd0;  
              end
              if((mem_sel_i == 4'b0001)||(mem_sel_i == 4'b0010)||(mem_sel_i == 4'b0100)||(mem_sel_i == 4'b1000))begin
                arsize <= 3'b000;
              end
                else if((mem_sel_i == 4'b0011)||(mem_sel_i == 4'b1100))begin
                arsize <= 3'b001;
              end
              else if(mem_sel_i == 4'b1111)begin
                arsize <= 3'b010;
              end
              arvalid <= 1'b1;
              state <= `READ3;
              last_for_dcache <= `False_v;
            end
            else if (mem_we_i == `WriteEnable) begin
              awaddr <= mem_addr_i;
              if((mem_sel_i == 4'b0001)||(mem_sel_i == 4'b0010)||(mem_sel_i == 4'b0100)||(mem_sel_i == 4'b1000))begin
                awsize <= 3'b000;
              end
                else if((mem_sel_i == 4'b0011)||(mem_sel_i == 4'b1100))begin
                awsize <= 3'b001;
              end
              else if(mem_sel_i == 4'b1111)begin
                awsize <= 3'b010;
              end
              awvalid <= 1'b1;
              wstrb <= mem_sel_i;
              bready <= 1'b1;
              state <= `WRITE1;
              last_for_dcache <= `False_v;
            end
          end
          else begin
            state <= `TEST1;
          end
        end
        `READ3:begin
          if(arready == 1'b1)begin
            arvalid <= 1'b0;
            araddr <= `ZeroWord;
            rready <= 1'b1;
            state <= `READ4;
          end
        end
        `READ4:begin
          if (rlast != 1'b1) begin
            if (rvalid == 1'b1) begin
              mem_we_o <= `WriteEnable;
              mem_addr_o <= mem_addr_i + mem_index;
              mem_index <= mem_index + 32'd4;
              mem_data_o <= rdata;
              cache_o <= cache_i;
            end
            else begin
              mem_we_o <= `WriteDisable;
            end
          end
          else begin
            rready <= 1'b0;
            mem_we_o <= `WriteEnable;
            mem_addr_o <= mem_addr_i + mem_index;
            mem_index <= `ZeroWord;
            mem_data_o <= rdata;
            cache_o <= cache_i;
            state <= `READ5;
          end
        end
        `READ5:begin
          mem_we_o <= `WriteDisable;
          last_for_dcache <= `True_v;
          state <= `TEST1;
        end
        `WRITE1:begin
          if(awready == 1'b1) begin
            awvalid <= 1'b0;
            awaddr <= `ZeroWord;
            wdata <= mem_data_i;
            wvalid <= 1'b1;
            state <= `WRITE2;
          end
          else begin
            state <= `WRITE1;
          end
        end
        `WRITE2:begin
          if(wready == 1'b1)begin
            wdata <= `ZeroWord;
            wvalid <= 1'b0;
            state <= `WRITE3;
          end
          else begin
            state <= `WRITE2;
          end
        end
        `WRITE3:begin
          if(bvalid == 1'b1)begin
            bready <= 1'b0;
            state <= `TEST1;
            last_for_dcache <= `True_v;
            mem_we_o <= `WriteEnable;
          end
        end
        // `WRITE4:begin
          
        // end
      endcase
    end
  end
endmodule
