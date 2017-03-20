module top (
   output [7:0]  LED,
   output 	 sdram_led,
   input 	 crystal_clk,
   output 	 sdram_gpio1, sdram_gpio2,
   input 	 sdram_gpio3, sdram_gpio4,
   input 	 sdram_gpio5,
   inout [15:0]  mem_d,
   output [12:0] sdram_addr,
   output 	 sdram_rasn,
   output 	 sdram_casn,
   output [1:0]  sdram_dqm,
   output 	 sdram_clk,
   output 	 sdram_cke,
   output 	 sdram_wen,
   output [1:0]  sdram_blockaddr,
   output 	 mem_cs1,
   output 	 mem_cs2
);

   wire      clk;
   wire      pll_clock;
   reg [15:0] reset_counter = 16'd0;
   reg 	     nrst = 1'b0;

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
   wire sdram_busdir;
   wire sdram_csn;

   wire cpu_trap;
   wire mem_instr;
   reg [31:0] cpu_irq = 0;
   wire [31:0] cpu_eoi;
   wire        cpu_trace_valid;
   wire [35:0] cpu_trace_data;

   wire [7:0]  output_leds;

   //assign clk = crystal_clk;
   assign clk = pll_clock;
   assign LED = output_leds;

   always @(posedge crystal_clk) begin
      reset_counter <= reset_counter + 16'd1;
      if (reset_counter[15])
	nrst <= 1'b1;
   end

   assign sdram_led = LED[0];

   wire pll_dummy_out, pll_lock1;
   SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"), .PLLOUT_SELECT("GENCLK"),
		   //.DIVR(4'd0), .DIVF(7'd63), .DIVQ(3'd4), // 12/1*64/16->48 MHz
		   .DIVR(4'd0), .DIVF(7'd63), .DIVQ(3'd5), // 12/1*64/32->24 MHz
		   .FILTER_RANGE(3'b001)
   ) mypll (.REFERENCECLK(crystal_clk),
	    .PLLOUTGLOBAL(pll_clock), .PLLOUTCORE(pll_dummy_out), .LOCK(pll_lock1),
	    .RESETB(1'b1), .BYPASS(1'b0));

   SB_IO #(.PIN_TYPE(6'b1010_01), .PULLUP(1'b0))
     io_mem_d[15:0](.PACKAGE_PIN(mem_d),
	   .OUTPUT_ENABLE({16{sdram_busdir}}),
	   .D_OUT_0(sdram_dq_write),
	   .D_IN_0(sdram_dq_read)
	   );

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
   assign mem_cs1 = sdram_csn;
   assign mem_cs2 = sdram_csn;

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

endmodule
