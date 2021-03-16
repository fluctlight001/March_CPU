`include "defines.v"
module mmu(
  input wire [`RegBus] mem_addr_i,
  output wire [`RegBus] mem_addr_o,
  output wire cache_o
);
  assign mem_addr_o = (mem_addr_i < 32'h80000000) ? mem_addr_i :
                      (mem_addr_i < 32'hA0000000) ? (mem_addr_i - 32'h80000000) :
                      (mem_addr_i < 32'hC0000000) ? (mem_addr_i - 32'hA0000000) :
                      (mem_addr_i < 32'hE0000000) ? (mem_addr_i) :
                      (mem_addr_i <= 32'hFFFFFFFF) ? (mem_addr_i) : 
                      32'h00000000;
  assign cache_o =  (mem_addr_i < 32'h80000000) ? `Cache :
                    (mem_addr_i < 32'hA0000000) ? `Cache :
                    (mem_addr_i < 32'hC0000000) ? `UnCache :
                    (mem_addr_i < 32'hE0000000) ? `Cache :
                    (mem_addr_i <= 32'hFFFFFFFF) ? `Cache : 
                    `Cache;
endmodule