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

   wire bram_decode, leds_decode, sdram_decode;
   wire bram_mem_valid, leds_mem_valid, sdram_mem_valid;
   wire bram_mem_ready, leds_mem_ready, sdram_mem_ready;
   wire [31:0] bram_mem_rdata;
   wire [31:0] leds_mem_rdata;
   wire [31:0] sdram_mem_rdata;

   wire [15:0] sdram_dq_read;
   wire [15:0] sdram_dq_write;
   wire [15:0] sdram_dq_inout;
   wire sdram_busdir;
   wire [12:0] sdram_addr;
   wire [1:0] sdram_blockaddr;
   wire sdram_clk;
   wire sdram_cke;
   wire sdram_csn;
   wire sdram_rasn;
   wire sdram_casn;
   wire sdram_wen;
   wire [1:0] sdram_dqm;

   wire cpu_trap;
   wire mem_instr;
   reg [31:0] cpu_irq;
   wire [31:0] cpu_eoi;
   wire        cpu_trace_valid;
   wire [35:0] cpu_trace_data;

   wire [7:0]  output_leds;

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
      if (num_cycles >= 20000*100)
	$finish;
   end

   initial begin
     //$monitor($time, " #cy=%d clk=%b val=%b ins=%b rdy=%b wstrb=%b addr=%h wdat=%h rdat=%h", num_cycles, clk, mem_valid, mem_instr, mem_ready, mem_wstrb, mem_addr, mem_wdata, mem_rdata);
   end

   // Built-in BRAM is at 0x0000xxxx.
   assign bram_decode = (mem_addr[31:16] == 16'h0000);
   memcontroller_bram mem_controller
     ( .mem_valid(bram_mem_valid),
       .mem_ready(bram_mem_ready),
       .mem_addr(mem_addr),
       .mem_wdata(mem_wdata),
       .mem_wstrb(mem_wstrb),
       .mem_rdata(bram_mem_rdata),
       .clk(clk),
       .nrst(nrst)
       );

   // LEDs are at 0x400000xx.
   assign leds_decode = (mem_addr[31:8] == 24'h400000);
   debugleds leds_module
     ( .mem_valid(leds_mem_valid),
       .mem_ready(leds_mem_ready),
       .mem_addr(mem_addr[7:2]),
       .mem_wdata(mem_wdata),
       .mem_wstrb(mem_wstrb),
       .clk(clk),
       .nrst(nrst),
       .leds(output_leds)
       );
   assign leds_mem_rdata = 32'b0;

   // SDRAM is at 0x2xxxxxxx.
   assign sdram_decode = (mem_addr[31:28] == 4'h2);
   picorv32_sdram sdram
     ( .mem_valid(sdram_mem_valid),
       .mem_ready(sdram_mem_ready),
       .mem_addr(mem_addr),
       .mem_wdata(mem_wdata),
       .mem_wstrb(mem_wstrb),
       .mem_rdata(sdram_mem_rdata),
       .sdram_dq_read(sdram_dq_read),
       .sdram_dq_write(sdram_dq_write),
       .sdram_busdir(sdram_busdir),
       .sdram_addr(sdram_addr),
       .sdram_blockaddr(sdram_blockaddr),
       .sdram_clk(sdram_clk),
       .sdram_cke(sdram_cke),
       .sdram_csn(sdram_csn),
       .sdram_rasn(sdram_rasn),
       .sdram_casn(sdram_casn),
       .sdram_wen(sdram_wen),
       .sdram_dqm(sdram_dqm),
       .clk(clk),
       .nrst(nrst));
   mt48lc16m16a2 sdram_chip_simulation
     ( .Dq(sdram_dq_inout),
       .Addr(sdram_addr),
       .Ba(sdram_blockaddr),
       .Clk(sdram_clk),
       .Cke(sdram_cke),
       .Cs_n(sdram_csn),
       .Ras_n(sdram_rasn),
       .Cas_n(sdram_dasn),
       .We_n(sdram_wen),
       .Dqm(sdram_dqm));
   assign sdram_dq_inout = (!sdram_busdir ? sdram_dq_write : {16{1'bz}});
   assign sdram_dq_read = sdram_dq_inout;

always @(*)
  $display($time, " dco=%b vld=%b rdy=%b adr=0x%h wstr=%b wdata=0x%h rdata=0x%h", { sdram_decode, leds_decode, bram_decode }, { sdram_mem_valid, leds_mem_valid, bram_mem_valid }, { sdram_mem_ready, leds_mem_ready, bram_mem_ready }, mem_addr, mem_wstrb, mem_wdata, mem_rdata);

   addr_decoder #(.N(3)) mydecoder
     ( .cpu_mem_valid(mem_valid),
       .cpu_mem_ready(mem_ready),
       .cpu_mem_rdata(mem_rdata),
       .dev_decode({ sdram_decode, leds_decode, bram_decode }),
       .dev_mem_valid({ sdram_mem_valid, leds_mem_valid, bram_mem_valid }),
       .dev_mem_ready({ sdram_mem_ready, leds_mem_ready, bram_mem_ready }),
       .dev_mem_rdata({ sdram_mem_rdata, leds_mem_rdata, bram_mem_rdata }));

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

   always @(output_leds) begin
      $display($time, " LEDS: %b", output_leds);
   end

endmodule // top
