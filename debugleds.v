module debugleds(
    input 	     mem_valid,
    output reg 	     mem_ready,
    input [5:0]      mem_addr,
    input [31:0]     mem_wdata,
    input [ 3:0]     mem_wstrb,
    input 	     clk,
    input 	     nrst,
    output reg [7:0] leds
);

   always @(posedge clk) begin
      if (!nrst) begin
	 leds <= 8'b00000000;
	 mem_ready <= 1'b0;
      end else begin
	 if (mem_valid) begin
	    if ((mem_addr == 6'h3f) & mem_wstrb[3])
	      leds <= mem_wdata[31:24];
	    mem_ready <= 1'b1;
	 end else
	   mem_ready <= 1'b0;
      end
   end // always @ (posedge clk)

endmodule
