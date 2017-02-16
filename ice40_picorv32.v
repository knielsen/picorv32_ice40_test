module top (
   output [7:0]   LED,
   input 	  crystal_clk,
);

   wire      clk;
   reg [1:0] reset_counter = 2'b00;
   reg 	     nrst = 1'b0;

   wire [31:0] mem_addr;
   wire [31:0] mem_wdata;
   wire [31:0] mem_rdata;
   wire [3:0]  mem_wstrb;
   wire mem_valid, mem_ready;

   wire cpu_trap;
   wire mem_instr;
   reg [31:0] cpu_irq = 0;
   wire [31:0] cpu_eoi;
   wire        cpu_trace_valid;
   wire [35:0] cpu_trace_data;

   wire [7:0]  output_leds;

   assign clk = crystal_clk;
   assign LED = output_leds;

   always @(posedge clk) begin
      reset_counter <= reset_counter + 2'b01;
      if (reset_counter == 2'b11)
	nrst <= 1'b1;
   end

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

   debugleds leds_module
     ( .mem_valid(mem_valid),
       .mem_addr(mem_addr),
       .mem_wdata(mem_wdata),
       .mem_wstrb(mem_wstrb),
       .clk(clk),
       .leds(output_leds)
       );

endmodule
