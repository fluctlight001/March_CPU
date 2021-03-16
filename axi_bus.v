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

//д��ַͨ���ź�
  output reg [3:0]	    awid,//д��ַID��������־һ��д�ź�
  output reg [31:0]	    awaddr,//д��ַ������һ��дͻ�������д��ַ
  output reg [3:0]	    awlen,//ͻ�����ȣ�����ͻ������Ĵ���
  output reg [2:0]	    awsize,//ͻ����С������ÿ��ͻ��������ֽ���
  output reg [1:0]	    awburst,//ͻ������
  output reg [1:0]	    awlock,//�������źţ����ṩ������ԭ����
  output reg [3:0]	    awcache,//�ڴ����ͣ�����һ�δ���������ͨ��ϵͳ��
  output reg [2:0]	    awprot,//�������ͣ�����һ�δ������Ȩ������ȫ�ȼ�
  output reg 		        awvalid,//��Ч�źţ�������ͨ���ĵ�ַ�����ź���Ч
  input	wire		        awready,//����"��"���Խ��յ�ַ�Ͷ�Ӧ�Ŀ����ź�

//д����ͨ���ź�
  output reg [3:0]	    wid,//һ��д�����ID tag
  output reg [31:0]	    wdata,//д����
  output reg [3:0]	    wstrb,//д������Ч���ֽ��ߣ�����������8bits��������Ч��
  output reg 		        wlast,//�����˴δ��������һ��ͻ������
  output reg		        wvalid,//д��Ч�������˴�д��Ч
  input	wire		        wready,//�����ӻ����Խ���д����
//д��Ӧͨ���ź�
  input	wire [3:0]	    bid,//д��ӦID tag
  input	wire [1:0]	    bresp,//д��Ӧ������д�����״̬ 00Ϊ��������Ȼ���Բ����
  input	wire		        bvalid,//д��Ӧ��Ч
  output reg		        bready,//���������ܹ�����д��Ӧ

//���߲�ӿ�
//����ַͨ���ź�
  output reg [3:0]	    arid,//����ַID��������־һ��д�ź�
  output reg [31:0]	    araddr,//����ַ������һ��дͻ������Ķ���ַ
  output reg [3:0]	    arlen,//ͻ�����ȣ�����ͻ������Ĵ���
  output reg [2:0]	    arsize,//ͻ����С������ÿ��ͻ��������ֽ���
  output reg [1:0]	    arburst,//ͻ������
  output reg [1:0]	    arlock,//�������źţ����ṩ������ԭ����
  output reg [3:0]	    arcache,//�ڴ����ͣ�����һ�δ���������ͨ��ϵͳ��
  output reg [2:0]	    arprot,//�������ͣ�����һ�δ������Ȩ������ȫ�ȼ�
  output reg 		        arvalid,//��Ч�źţ�������ͨ���ĵ�ַ�����ź���Ч
  input	wire		        arready,//����"��"���Խ��յ�ַ�Ͷ�Ӧ�Ŀ����ź�
//������ͨ���ź�
  input	wire [3:0]	    rid,//��ID tag
  input	wire [31:0]	    rdata,//������
  input	wire [1:0]	    rresp,//����Ӧ�������������״̬
  input	wire		        rlast,//������ͻ�������һ�δ���
  input	wire		        rvalid,//������ͨ���ź���Ч
  output reg		        rready//���������ܹ����ն����ݺ���Ӧ��Ϣ
);
  //burst���� 00��ַ���� 01���ַ����
  //size ָ�ֽ���00Ϊ1�ֽڣ�01Ϊ2�ֽ�==16λ 10Ϊ4�ֽ�==32λ
  //len ָ���˶�ȡָ�����������Ϊ len+1
  reg [3:0] state;
  // reg [3:0] state_rw;
  reg [`RegBus] inst_bus;
  reg [`RegBus] pc_index; // pc����
  reg [`RegBus] mem_index; // mem_addr����

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
