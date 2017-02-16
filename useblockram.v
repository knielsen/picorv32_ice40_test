module memcontroller_bram(
    // Interface to picorv32.
    input 	      mem_valid,
    output reg 	      mem_ready,
    input [31:0]      mem_addr,
    input [31:0]      mem_wdata,
    input [ 3:0]      mem_wstrb,
    output reg [31:0] mem_rdata,
    // Other signals.
    input 	      clk,
    input 	      nrst
);

   reg [31:0] 	  memory [0:127];
   initial begin
      $readmemh("ramdata.list", memory);
      //$display($time, " First couple SRAM locations: 0x%h 0x%h 0x%h 0x%h", memory[0], memory[1], memory[2], memory[3]);
   end
   wire [6:0] adr7;

   assign adr7 = mem_addr[8:2];

   always @(posedge clk) begin
      if (mem_valid) begin
	 mem_ready <= 1'b1;
	 case (mem_wstrb)
	   4'b0000:
	     mem_rdata <= memory[adr7];
	   4'b0001:
	     memory[adr7][7:0] <= mem_wdata[7:0];
	   4'b0010:
	     memory[adr7][15:8] <= mem_wdata[15:8];
	   4'b0100:
	     memory[adr7][23:16] <= mem_wdata[23:16];
	   4'b1000:
	     memory[adr7][31:24] <= mem_wdata[31:24];
	   4'b0011:
	     memory[adr7][15:0] <= mem_wdata[15:0];
	   4'b1100:
	     memory[adr7][31:15] <= mem_wdata[31:15];
	   4'b1111:
	     memory[adr7] <= mem_wdata;
	 endcase // case (mem_wstrb)
      end else // if (mem_valid)
	mem_ready <= 1'b0;
   end // always @ (posedge clk)

endmodule
