`include "defines.v"
module regfile(
  input wire clk,
  input wire rst,
// ��д�׶� ������д
  input wire                we, //write enable positive
  input wire [`RegAddrBus]  waddr,
  input wire [`RegBus]      wdata,
// ������
  input wire                re1, //read enable positive
  input wire [`RegAddrBus]  raddr1,
  output reg [`RegBus]      rdata1,

  input wire                re2,
  input wire [`RegAddrBus]  raddr2,
  output reg [`RegBus]      rdata2,
// ִ�н׶� ����ǰ��
  input wire                ex_forwarding_we,
  input wire [`RegAddrBus]  ex_forwarding_waddr,
  input wire [`RegBus]      ex_forwarding_wdata,

// premem forwarding
  input wire                premem_forwarding_we,
  input wire [`RegAddrBus]  premem_forwarding_waddr,
  input wire [`RegBus]      premem_forwarding_wdata,

// dcache forwarding 
  input wire                dcache_forwarding_we,
  input wire [`RegAddrBus]  dcache_forwarding_waddr,
  input wire [`RegBus]      dcache_forwarding_wdata,

// �ô�׶� ����ǰ��
  input wire                mem_forwarding_we,
  input wire [`RegAddrBus]  mem_forwarding_waddr,
  input wire [`RegBus]      mem_forwarding_wdata        
);

  reg [`RegBus] rf [31:0];


// write all rf
  always @ (posedge clk) begin
    if (rst == `RstEnable) begin
      rf[ 0] <= `ZeroWord;
      rf[ 1] <= `ZeroWord;
      rf[ 2] <= `ZeroWord;
      rf[ 3] <= `ZeroWord;
      rf[ 4] <= `ZeroWord;
      rf[ 5] <= `ZeroWord;
      rf[ 6] <= `ZeroWord;
      rf[ 7] <= `ZeroWord;
      rf[ 8] <= `ZeroWord;
      rf[ 9] <= `ZeroWord;
      rf[10] <= `ZeroWord;
      rf[11] <= `ZeroWord;
      rf[12] <= `ZeroWord;
      rf[13] <= `ZeroWord;
      rf[14] <= `ZeroWord;
      rf[15] <= `ZeroWord;
      rf[16] <= `ZeroWord;
      rf[17] <= `ZeroWord;
      rf[18] <= `ZeroWord;
      rf[19] <= `ZeroWord;
      rf[20] <= `ZeroWord;
      rf[21] <= `ZeroWord;
      rf[22] <= `ZeroWord;
      rf[23] <= `ZeroWord;
      rf[24] <= `ZeroWord;
      rf[25] <= `ZeroWord;
      rf[26] <= `ZeroWord;
      rf[27] <= `ZeroWord;
      rf[28] <= `ZeroWord;
      rf[29] <= `ZeroWord;
      rf[30] <= `ZeroWord;
      rf[31] <= `ZeroWord;
    end
    else if ((we == `WriteEnable) && (waddr >= 5'd1) && (waddr <= 5'd31)) begin
      rf[waddr] <= wdata;
    end
  end

// read reg1
  always @ (*) begin
    if (rst == `RstEnable) begin
      rdata1 <= `ZeroWord;
    end
    else if (re1 == `ReadEnable) begin
      if (raddr1 == 5'd0) begin
        rdata1 <= `ZeroWord;
      end
      else if ((raddr1 == ex_forwarding_waddr) && (ex_forwarding_we == `WriteEnable)) begin
        rdata1 <= ex_forwarding_wdata;
      end
      else if ((raddr1 == premem_forwarding_waddr) && (premem_forwarding_we == `WriteEnable)) begin
        rdata1 <= premem_forwarding_wdata;
      end
      else if ((raddr1 == dcache_forwarding_waddr) && (dcache_forwarding_we == `WriteEnable)) begin
        rdata1 <= dcache_forwarding_wdata;
      end
      else if ((raddr1 == mem_forwarding_waddr) && (mem_forwarding_we == `WriteEnable)) begin
        rdata1 <= mem_forwarding_wdata;
      end
      else if ((raddr1 == waddr) && (we == `WriteEnable)) begin
        rdata1 <= wdata;
      end
      else begin
        rdata1 <= rf[raddr1];
      end
    end
    else begin
      rdata1 <= `ZeroWord;
    end
  end

// read reg2
  always @ (*) begin
    if (rst == `RstEnable) begin
      rdata2 <= `ZeroWord;
    end
    else if (re2 == `ReadEnable) begin
      if (raddr2 == 5'd0) begin
        rdata2 <= `ZeroWord;
      end
      else if ((raddr2 == ex_forwarding_waddr) && (ex_forwarding_we == `WriteEnable)) begin
        rdata2 <= ex_forwarding_wdata;
      end
      else if ((raddr2 == premem_forwarding_waddr) && (premem_forwarding_we == `WriteEnable)) begin
        rdata2 <= premem_forwarding_wdata;
      end
      else if ((raddr2 == dcache_forwarding_waddr) && (dcache_forwarding_we == `WriteEnable)) begin
        rdata2 <= dcache_forwarding_wdata;
      end
      else if ((raddr2 == mem_forwarding_waddr) && (mem_forwarding_we == `WriteEnable)) begin
        rdata2 <= mem_forwarding_wdata;
      end
      else if ((raddr2 == waddr) && (we == `WriteEnable)) begin
        rdata2 <= wdata;
      end    
      else if (re2 == `ReadEnable) begin
        rdata2 <= rf[raddr2];
      end
    end
    else begin
      rdata2 <= `ZeroWord;
    end
  end  
endmodule