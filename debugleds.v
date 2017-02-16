module debugleds(
    input 	    mem_valid,
    input [31:0]    mem_addr,
    input [31:0]    mem_wdata,
    input [ 3:0]    mem_wstrb,
    input 	    clk,
    output reg [7:0] leds
);

   always @(posedge clk) begin
      if (mem_valid & (mem_addr[8:2] == 7'b1111111) & mem_wstrb[3]) begin
	 leds <= mem_wdata[31:24];
      end
   end // always @ (posedge clk)

endmodule
