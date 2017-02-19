// Generic address decoder.
//
// Multiplexes N devices on the simple picoriscv32 bus, based on
// individual decode signals.
module addr_decoder #(parameter N=2)
   ( input wire		   cpu_mem_valid,
     output wire 	   cpu_mem_ready,
     output wire [31:0]    cpu_mem_rdata,

     input wire [N-1:0]    dev_decode,

     output wire [N-1:0]   dev_mem_valid,
     input wire [N-1:0]    dev_mem_ready,
     input wire [N*32-1:0] dev_mem_rdata );

   genvar i;
   wire   tmp_mem_ready[0:N-1];
   wire [31:0] tmp_mem_rdata[0:N-1];

   generate
      for (i = 0; i < N; i = i + 1) begin
	 assign dev_mem_valid[i] = dev_decode[i] & cpu_mem_valid;
      end
   endgenerate

   generate
      assign tmp_mem_ready[0] = dev_decode[0] & dev_mem_ready[0];
      assign tmp_mem_rdata[0] = { 32 {dev_decode[0]} } & dev_mem_rdata[31:0];

      for (i = 1; i < N; i = i + 1) begin
	 assign tmp_mem_ready[i] = tmp_mem_ready[i-1] |
	       (dev_decode[i] & dev_mem_ready[i]);
	 assign tmp_mem_rdata[i] = tmp_mem_rdata[i-1] |
	       ( { 32 {dev_decode[i]} } & dev_mem_rdata[i*32+31 : i*32]);
      end

      assign cpu_mem_ready = tmp_mem_ready[N-1];
      assign cpu_mem_rdata = tmp_mem_rdata[N-1];
   endgenerate

endmodule // addr_decoder
