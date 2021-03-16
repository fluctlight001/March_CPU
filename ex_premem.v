`include "defines.v" 
module ex_premem(
  input wire clk,
  input wire rst,
  input wire [`StallBus] stall,
  input wire flush,

  input wire [`RegAddrBus] ex_waddr,
  input wire ex_wreg,
  input wire [`RegBus] ex_wdata,

  output reg [`RegAddrBus] premem_waddr,
  output reg premem_wreg,
  output reg [`RegBus] premem_wdata,

// HI LO 
  input wire [`RegBus] ex_hi,
  input wire [`RegBus] ex_lo,
  input wire ex_whilo,

  output reg [`RegBus] premem_hi,
  output reg [`RegBus] premem_lo,
  output reg premem_whilo,

// premem
  input wire [`AluOpBus] ex_aluop,
  input wire [`RegBus] ex_mem_addr,
  input wire [`RegBus] ex_reg2,

  output reg [`AluOpBus] premem_aluop,
  output reg [`RegBus] premem_mem_addr,
  output reg [`RegBus] premem_reg2,

//cp0_reg
  input wire ex_cp0_reg_we,
  input wire [4:0] ex_cp0_reg_write_addr,
  input wire [`RegBus] ex_cp0_reg_data,

  output reg premem_cp0_reg_we,
  output reg [4:0] premem_cp0_reg_write_addr,
  output reg [`RegBus] premem_cp0_reg_data,

// pc
  input wire [`InstAddrBus] ex_pc,
  output reg [`InstAddrBus] premem_pc,

// excepttype
  input wire [31:0] ex_excepttype,
  input wire ex_is_in_delayslot,
  input wire [`RegBus] ex_badvaddr,

  output reg [31:0] premem_excepttype,
  output reg premem_is_in_delayslot,
  output reg [`RegBus] premem_badvaddr
);

  reg [31:0] excepttype_temp; // 避免异常出现后还有内容写入dcache和ram
  always @ (posedge clk) begin
    if (rst == `RstEnable) begin
      premem_waddr <= `NOPRegAddr;
      premem_wreg <= `WriteDisable;
      premem_wdata <= `ZeroWord;
      premem_hi <= `ZeroWord;
      premem_lo <= `ZeroWord;
      premem_whilo <= `WriteDisable;

      premem_aluop <= `NOP;
      premem_mem_addr <= `ZeroWord;
      premem_reg2 <= `ZeroWord;

      premem_cp0_reg_we <= `WriteDisable;
      premem_cp0_reg_write_addr <= 5'b00000;
      premem_cp0_reg_data <= `ZeroWord;

      premem_pc <= `ZeroWord;

      premem_excepttype <= `ZeroWord;
      premem_is_in_delayslot <= `NotInDelaySlot;
      premem_badvaddr <= `ZeroWord;

      excepttype_temp <= `ZeroWord;
    end
    else if (flush == `True_v) begin
      premem_waddr <= `NOPRegAddr;
      premem_wreg <= `WriteDisable;
      premem_wdata <= `ZeroWord;
      premem_hi <= `ZeroWord;
      premem_lo <= `ZeroWord;
      premem_whilo <= `WriteDisable;

      premem_aluop <= `NOP;
      premem_mem_addr <= `ZeroWord;
      premem_reg2 <= `ZeroWord;

      premem_cp0_reg_we <= `WriteDisable;
      premem_cp0_reg_write_addr <= 5'b00000;
      premem_cp0_reg_data <= `ZeroWord;

      premem_pc <= `ZeroWord;

      premem_excepttype <= `ZeroWord;
      premem_is_in_delayslot <= `NotInDelaySlot;
      premem_badvaddr <= `ZeroWord;

      excepttype_temp <= `ZeroWord;
    end
    else if (stall[4] == `Stop && stall[5] == `NoStop) begin
      premem_waddr <= `NOPRegAddr;
      premem_wreg <= `WriteDisable;
      premem_wdata <= `ZeroWord;
      premem_hi <= `ZeroWord;
      premem_lo <= `ZeroWord;
      premem_whilo <= `WriteDisable;

      premem_aluop <= `NOP;
      premem_mem_addr <= `ZeroWord;
      premem_reg2 <= `ZeroWord;

      premem_cp0_reg_we <= `WriteDisable;
      premem_cp0_reg_write_addr <= 5'b00000;
      premem_cp0_reg_data <= `ZeroWord;

      premem_pc <= `ZeroWord;

      premem_excepttype <= `ZeroWord;
      premem_is_in_delayslot <= `NotInDelaySlot;
      premem_badvaddr <= `ZeroWord;
    end
    else if (stall[4] == `NoStop) begin
      premem_waddr <= ex_waddr;
      premem_wreg <= ex_wreg;
      premem_wdata <= ex_wdata;
      premem_hi <= ex_hi;
      premem_lo <= ex_lo;
      premem_whilo <= ex_whilo;

      premem_aluop <= ex_aluop;
      premem_mem_addr <= ex_mem_addr;
      premem_reg2 <= ex_reg2;

      premem_cp0_reg_we <= ex_cp0_reg_we;
      premem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
      premem_cp0_reg_data <= ex_cp0_reg_data;

      premem_pc <= ex_pc;

      if (|excepttype_temp == 1'b1) begin
        premem_excepttype <= excepttype_temp;
      end
      else begin
        premem_excepttype <= ex_excepttype;
        excepttype_temp <= ex_excepttype;  
      end
      premem_is_in_delayslot <= ex_is_in_delayslot;
      premem_badvaddr <= ex_badvaddr;
    end // if
  end // always
endmodule