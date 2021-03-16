`include "defines.v"
module mycpu_top(
    input wire [5:0] ext_int,
    input wire aclk,
    input wire aresetn,
    output wire[3:0]   arid,
    output wire[31:0]  araddr,
    output wire[3:0]   arlen,
    output wire[2:0]   arsize,
    output wire[1:0]   arburst,
    output wire[1:0]   arlock,
    output wire[3:0]   arcache,
    output wire[2:0]   arprot,
    output wire        arvalid,
    input  wire        arready,

    input  wire[3:0]   rid,
    input  wire[31:0]  rdata,
    input  wire[1:0]   rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,

    output wire[3:0]   awid,
    output wire[31:0]  awaddr,
    output wire[3:0]   awlen,
    output wire[2:0]   awsize,
    output wire[1:0]   awburst,
    output wire[1:0]   awlock,
    output wire[3:0]   awcache,
    output wire[2:0]   awprot,
    output wire        awvalid,
    input  wire        awready,

    output wire[3:0]   wid,
    output wire[31:0]  wdata,
    output wire[3:0]   wstrb,
    output wire        wlast,
    output wire        wvalid,
    input  wire        wready,

    input  wire[3:0]   bid,
    input  wire[1:0]   bresp,
    input  wire        bvalid,
    output wire        bready,

    output wire [31:0] debug_wb_pc,
    output wire [3 :0] debug_wb_rf_wen,
    output wire [4 :0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire stallreq_from_outside;
    wire stallreq_from_icache;
    wire stallreq_from_dcache;
    wire stallreq_from_uncache;

    wire inst_sram_en;
    wire [3:0] inst_sram_wen;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata;
    
    wire data_sram_en;
    wire [3:0] data_sram_wen;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_addr_mmu;
    wire [31:0] data_sram_wdata;
    wire [31:0] data_sram_rdata;
    wire [31:0] data_sram_rdata_cache;
    wire [31:0] data_sram_rdata_uncache;
    wire data_sram_rvalid;
    
    wire data_cache_sel;
    reg data_cache_state;

    assign stallreq_from_outside = stallreq_from_icache | stallreq_from_dcache | stallreq_from_uncache;

    mycpu_core u_mycpu_core(
    	.clk               (aclk              ),
        .resetn            (aresetn           ),
        .int               (ext_int           ),
        .inst_sram_en      (inst_sram_en      ),
        .inst_sram_wen     (inst_sram_wen     ),
        .inst_sram_addr    (inst_sram_addr    ),
        .inst_sram_wdata   (inst_sram_wdata   ),
        .inst_sram_rdata   (inst_sram_rdata   ),
        .data_sram_en      (data_sram_en      ),
        .data_sram_wen     (data_sram_wen     ),
        .data_sram_addr    (data_sram_addr    ),
        .data_sram_wdata   (data_sram_wdata   ),
        .data_sram_rdata   (data_sram_rdata   ),
        .debug_wb_pc       (debug_wb_pc       ),
        .debug_wb_rf_wen   (debug_wb_rf_wen   ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata ),
        .stallreq_from_bus (stallreq_from_outside )
    );

    mmu u_mmu(
        .mem_addr_i (data_sram_addr     ),
        .mem_addr_o (data_sram_addr_mmu ),
        .cache_o    (data_cache_sel     )
    );

    always @ (posedge aclk) begin
        if (!aresetn) begin
            data_cache_state <= 1'b0;
        end
        else begin
            data_cache_state <= data_cache_sel;
        end
    end
    
    assign data_sram_rdata = data_cache_state ? data_sram_rdata_cache : data_sram_rdata_uncache;

    wire data_uncache_en;
    wire data_uncache_accept;
    wire [3:0] data_uncache_wen;
    wire [31:0] data_uncache_addr;
    wire [31:0] data_uncache_wdata;
    wire [31:0] data_uncache_rdata;
    wire data_uncache_fin;

    uncache_sample u_uncache(
    	.clk       (aclk       ),
        .rst       (!aresetn       ),

        .en        (data_sram_en        ),
        .wen       (data_sram_wen       ),
        .addr      (data_sram_addr_mmu      ),
        .wdata     (data_sram_wdata     ),
        .rdata     (data_sram_rdata_uncache     ),

        .axi_en    (data_uncache_en    ),
        .accept    (data_uncache_accept    ),
        .axi_wsel  (data_uncache_wen  ),
        .axi_addr  (data_uncache_addr  ),
        .axi_wdata (data_uncache_wdata ),
        .axi_rdata (data_uncache_rdata ),
        .fin       (data_uncache_fin       ),

        .stallreq  (stallreq_from_uncache  )
    );
    

    wire dcache_ren;
    wire [31:0] dcache_raddr;
    wire dcache_raccept;

    wire dcache_wen_fill;
    wire [511:0] dcache_wfill;
    
    wire dcache_wen;
    wire [31:0] dcache_waddr;
    wire [511:0] dcache_wdata;
    wire dcache_wfin;

    cache_sample u_dcache(
    	.clk       (aclk       ),
        .rst       (!aresetn       ),
        // mycpu_core
        .en        (data_sram_en & data_cache_sel        ),
        .wen       (data_sram_wen       ),
        .addr      (data_sram_addr_mmu  ),
        .wdata     (data_sram_wdata     ),
        .rdata     (data_sram_rdata_cache     ),

        // dcache_interface
        .wen_back  (dcache_wen  ),
        .waddr     (dcache_waddr     ),
        .wback     (dcache_wdata     ),
        .fin       (dcache_wfin       ),

        .wen_fill  (dcache_wen_fill  ),
        .wfill     (dcache_wfill     ),

        .miss      (dcache_ren      ),
        .miss_addr (dcache_raddr ),
        .accept    (dcache_raccept    ),

        .stallreq  (stallreq_from_dcache  )
    );

    wire dcache_sram_en;
    wire [3:0] dcache_sram_wen;
    wire [31:0] dcache_sram_addr;
    wire [31:0] dcache_sram_wdata;
    wire [31:0] dcache_sram_rdata;
    wire dcache_sram_rvalid;

    cache_interface u_dcache_interface(
    	.clk         (aclk         ),
        .rst         (!aresetn         ),

        .ren         (dcache_ren         ),
        .raddr       (dcache_raddr       ),
        .raccept     (dcache_raccept     ),
        
        .wen_fill    (dcache_wen_fill    ),
        .wfill       (dcache_wfill       ),
        
        .wen         (dcache_wen         ),
        .waddr       (dcache_waddr       ),
        .wdata       (dcache_wdata       ),
        .wfin        (dcache_wfin        ),
        
        .sram_en     (dcache_sram_en     ),
        .sram_wen    (dcache_sram_wen    ),
        .sram_addr   (dcache_sram_addr   ),
        .sram_wdata  (dcache_sram_wdata  ),
        .sram_rdata  (dcache_sram_rdata  ),
        .sram_rvalid (dcache_sram_rvalid )
    );
    
    wire icache_ren;
    wire [31:0] icache_raddr;
    wire icache_raccept;

    wire icache_wen_fill;
    wire [511:0] icache_wfill;
    
    wire icache_wen;
    wire [31:0] icache_waddr;
    wire [511:0] icache_wdata;
    wire icache_wfin;

    cache_sample u_icache(
    	.clk       (aclk      ),
        .rst       (!aresetn  ),
        // mycpu_core
        .en        (inst_sram_en        ),
        .wen       (inst_sram_wen       ),
        .addr      (inst_sram_addr      ),
        .wdata     (inst_sram_wdata     ),
        .rdata     (inst_sram_rdata     ),
        
        // icache_interface
        .wen_back  (icache_wen  ),
        .waddr     (icache_waddr     ),
        .wback     (icache_wdata     ),
        .fin       (icache_wfin       ),

        .wen_fill  (icache_wen_fill  ),
        .wfill     (icache_wfill     ),

        .miss      (icache_ren      ),
        .miss_addr (icache_raddr ),
        .accept    (icache_raccept    ),
        
        // to cpu
        .stallreq  (stallreq_from_icache  )
    );

    wire icache_sram_en;
    wire [3:0] icache_sram_wen;
    wire [31:0] icache_sram_addr;
    wire [31:0] icache_sram_wdata;
    wire [31:0] icache_sram_rdata;
    wire icache_sram_rvalid;
    
    cache_interface u_icache_interface(
    	.clk         (aclk        ),
        .rst         (!aresetn    ),

        .ren         (icache_ren         ),
        .raddr       (icache_raddr       ),
        .raccept     (icache_raccept     ),

        .wen_fill    (icache_wen_fill    ),
        .wfill       (icache_wfill       ),

        .wen         (icache_wen         ),
        .waddr       (icache_waddr       ),
        .wdata       (icache_wdata       ),
        .wfin        (icache_wfin        ),

        .sram_en     (icache_sram_en     ),
        .sram_wen    (icache_sram_wen    ),
        .sram_addr   (icache_sram_addr   ),
        .sram_wdata  (icache_sram_wdata  ),
        .sram_rdata  (icache_sram_rdata  ),
        .sram_rvalid (icache_sram_rvalid )
    );
    
    wire inst_req;
    wire inst_wr;
    wire  [1 :0] inst_size;
    wire  [31:0] inst_addr    ;
    wire  [31:0] inst_wdata   ;
    wire [31:0] inst_rdata   ;
    wire        inst_addr_ok ;
    wire        inst_data_ok ;
    
    wire         data_req     ;
    wire         data_wr      ;
    wire  [1 :0] data_size    ;
    wire  [31:0] data_addr    ;
    wire  [31:0] data_wdata   ;
    wire [31:0] data_rdata   ;
    wire        data_addr_ok ;
    wire        data_data_ok ;

    control u_control(
    	.clk             (aclk            ),
        .rstn            (aresetn         ),
        // .stallreq        (stallreq_from_bus        ),

        .inst_sram_en    (icache_sram_en    ),
        .inst_sram_wen   (icache_sram_wen   ),
        .inst_sram_addr  (icache_sram_addr  ),
        .inst_sram_wdata (icache_sram_wdata ),
        .inst_sram_rdata (icache_sram_rdata ),
        .inst_sram_rvalid(icache_sram_rvalid),

        .data_sram_en    (dcache_sram_en    ),
        .data_sram_wen   (dcache_sram_wen   ),
        .data_sram_addr  (dcache_sram_addr  ),
        .data_sram_wdata (dcache_sram_wdata ),
        .data_sram_rdata (dcache_sram_rdata ),
        .data_sram_rvalid(dcache_sram_rvalid),

        .data_uncache_en     (data_uncache_en     ),
        .data_uncache_accept (data_uncache_accept ),
        .data_uncache_wen    (data_uncache_wen    ),
        .data_uncache_addr   (data_uncache_addr   ),
        .data_uncache_wdata  (data_uncache_wdata  ),
        .data_uncache_rdata  (data_uncache_rdata  ),
        .data_uncache_fin    (data_uncache_fin    ),

        .inst_req        (inst_req        ),
        .inst_wr         (inst_wr         ),
        .inst_size       (inst_size       ),
        .inst_addr       (inst_addr       ),
        .inst_wdata      (inst_wdata      ),
        .inst_rdata      (inst_rdata      ),
        .inst_addr_ok    (inst_addr_ok    ),
        .inst_data_ok    (inst_data_ok    ),
        .data_req        (data_req        ),
        .data_wr         (data_wr         ),
        .data_size       (data_size       ),
        .data_addr       (data_addr       ),
        .data_wdata      (data_wdata      ),
        .data_rdata      (data_rdata      ),
        .data_addr_ok    (data_addr_ok    ),
        .data_data_ok    (data_data_ok    )
    );
    

    cpu_axi_interface u_cpu_axi_interface(
    	.clk          (aclk          ),
        .resetn       (aresetn       ),
        .inst_req     (inst_req     ),
        .inst_wr      (inst_wr      ),
        .inst_size    (inst_size    ),
        .inst_addr    (inst_addr    ),
        .inst_wdata   (inst_wdata   ),
        .inst_rdata   (inst_rdata   ),
        .inst_addr_ok (inst_addr_ok ),
        .inst_data_ok (inst_data_ok ),

        .data_req     (data_req     ),
        .data_wr      (data_wr      ),
        .data_size    (data_size    ),
        .data_addr    (data_addr    ),
        .data_wdata   (data_wdata   ),
        .data_rdata   (data_rdata   ),
        .data_addr_ok (data_addr_ok ),
        .data_data_ok (data_data_ok ),

        .arid         (arid         ),
        .araddr       (araddr       ),
        .arlen        (arlen        ),
        .arsize       (arsize       ),
        .arburst      (arburst      ),
        .arlock       (arlock       ),
        .arcache      (arcache      ),
        .arprot       (arprot       ),
        .arvalid      (arvalid      ),
        .arready      (arready      ),
        .rid          (rid          ),
        .rdata        (rdata        ),
        .rresp        (rresp        ),
        .rlast        (rlast        ),
        .rvalid       (rvalid       ),
        .rready       (rready       ),
        .awid         (awid         ),
        .awaddr       (awaddr       ),
        .awlen        (awlen        ),
        .awsize       (awsize       ),
        .awburst      (awburst      ),
        .awlock       (awlock       ),
        .awcache      (awcache      ),
        .awprot       (awprot       ),
        .awvalid      (awvalid      ),
        .awready      (awready      ),
        .wid          (wid          ),
        .wdata        (wdata        ),
        .wstrb        (wstrb        ),
        .wlast        (wlast        ),
        .wvalid       (wvalid       ),
        .wready       (wready       ),
        .bid          (bid          ),
        .bresp        (bresp        ),
        .bvalid       (bvalid       ),
        .bready       (bready       )
    );
    
    
endmodule