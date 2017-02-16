`timescale 1 ns / 100 ps

module top();
   reg clk;
   reg nrst;
   reg [63:0] num_cycles;

   wire [31:0] mem_addr;
   wire [31:0] mem_wdata;
   wire [31:0] mem_rdata;
   wire [3:0]  mem_wstrb;
   wire mem_valid, mem_ready;

   wire cpu_trap;
   wire mem_instr;
   reg [31:0] cpu_irq;
   wire [31:0] cpu_eoi;
   wire        cpu_trace_valid;
   wire [35:0] cpu_trace_data;

   initial begin
      nrst = 1'b0;
      cpu_irq = 0;
      #100
      nrst = 1'b1;
   end

   initial begin
      clk = 1'b0;
      num_cycles = 0;
   end
   always begin
      #10 clk = 1'b1;
      num_cycles <= num_cycles + 1;
      #10 clk = 1'b0;
      if (num_cycles >= 100)
	$finish;
   end

   initial
     $monitor($time, " #cy=%d clk=%b val=%b ins=%b rdy=%b wstrb=%b addr=%h wdat=%h rdat=%h", num_cycles, clk, mem_valid, mem_instr, mem_ready, mem_wstrb, mem_addr, mem_wdata, mem_rdata);

   memcontroller_bram mem_controller
     ( .mem_valid(mem_valid),
       .mem_ready(mem_ready),
       .mem_addr(mem_addr),
       .mem_wdata(mem_wdata),
       .mem_wstrb(mem_wstrb),
       .mem_rdata(mem_rdata),
       .clk(clk),
       .nrst(nrst)
       );

   picorv32 cpu
     ( .clk(clk),
       .resetn(nrst),
       .trap(cpu_trap),

       .mem_valid(mem_valid),
       .mem_instr(mem_instr),
       .mem_ready(mem_ready),
       .mem_addr(mem_addr),
       .mem_wdata(mem_wdata),
       .mem_wstrb(mem_wstrb),
       .mem_rdata(mem_rdata),

       // Look-ahead interface not used.
       // PCPI not used.

       .irq(cpu_irq),
       .eoi(cpu_eoi),
       .trace_valid(cpu_trace_valid),
       .trace_data(cpu_trace_data)
       );
				     
endmodule // top
