module top ();
   reg clk;
   reg [31:0] num_cycles;

   reg cpu_mem_valid;
   wire cpu_mem_ready;
   reg [31:0] cpu_mem_addr;
   wire [31:0] cpu_mem_rdata;
   reg [31:0] cpu_mem_wdata;
   reg [3:0]  cpu_mem_wstrb;

   wire       d1_mem_valid;
   reg 	      d1_mem_ready;
   wire [31:0] d1_mem_addr;
   reg [31:0]  d1_mem_rdata;
   wire [31:0] d1_mem_wdata;
   wire [3:0]  d1_mem_wstrb;

   wire        d2_mem_valid;
   reg 	       d2_mem_ready;
   wire [31:0] d2_mem_addr;
   reg [31:0] d2_mem_rdata;
   wire [31:0] d2_mem_wdata;
   wire [3:0]  d2_mem_wstrb;

   wire       decode_d1, decode_d2;

   // Device d1, at 0x200040xx.
   reg [31:0] d1_cnt;
   reg [31:0] d1_val;
   initial begin
      d1_cnt = 0;
      d1_val = 'haa;
   end
   assign decode_d1 = ( cpu_mem_addr[31:8] == 24'h200040);
   always @(posedge clk) begin

      d1_cnt <= d1_cnt + 1;
      if (d1_mem_valid) begin
	 d1_mem_ready <= 1'b1;
	 if (d1_mem_wstrb == 4'b000) begin
	    case (d1_mem_addr[7:0])
	      8'h00: d1_mem_rdata <= d1_cnt;
	      8'h40: d1_mem_rdata <= 8'd42;
	      8'h44: d1_mem_rdata <= 8'h42;
	      8'h48: d1_mem_rdata <= d1_val;
	      default: d1_mem_rdata <= 8'h00;
	    endcase // case (d1_mem_addr[7:0])
	 end else begin
	    case (d1_mem_addr[7:0])
	      8'h00: d1_cnt <= d1_mem_wdata;
	      8'h48: d1_val <= d1_mem_wdata;
	    endcase // case (d1_mem_addr[7:0])
	 end // else: !if(d1_mem_wstrb == 4'b000)
      end else // if (d1_mem_valid)
	d1_mem_ready <= 1'b0;
   end
   assign d1_mem_addr = cpu_mem_addr;
   assign d1_mem_wdata = cpu_mem_wdata;
   assign d1_mem_wstrb = cpu_mem_wstrb;


   // Device d2, at 0x2005xxx.
   reg [31:0] d2_cnt;
   reg [31:0] d2_val;
   initial begin
      d2_cnt = 100000;
      d2_val = 'h55;
   end
   assign decode_d2 = ( cpu_mem_addr[31:12] == 20'h20005);
   always @(posedge clk) begin

      d2_cnt <= d2_cnt - 1;
      if (d2_mem_valid) begin
	 d2_mem_ready <= 1'b1;
	 if (d2_mem_wstrb == 4'b000) begin
	    case (d2_mem_addr[11:0])
	      11'h120: d2_mem_rdata <= d2_val;
	      11'h124: d2_mem_rdata <= d2_cnt;
	      11'h128: d2_mem_rdata <= 8'hca;
	      11'h12c: d2_mem_rdata <= 8'hfe;
	      default: d2_mem_rdata <= 8'hff;
	    endcase // case (d2_mem_addr[11:0])
	 end else begin
	    case (d2_mem_addr[11:0])
	      11'h120: d2_val <= d2_mem_wdata;
	      11'h124: d2_cnt <= d2_mem_wdata;
	    endcase // case (d2_mem_addr[11:0])
	 end // else: !if(d2_mem_wstrb == 4'b000)
      end else // if (d2_mem_valid)
	d2_mem_ready <= 1'b0;
   end
   assign d2_mem_addr = cpu_mem_addr;
   assign d2_mem_wdata = cpu_mem_wdata;
   assign d2_mem_wstrb = cpu_mem_wstrb;


   addr_decoder my_addr_mux
     ( .cpu_mem_valid(cpu_mem_valid),
       .cpu_mem_ready(cpu_mem_ready),
       .cpu_mem_rdata(cpu_mem_rdata),
       .dev_decode({ decode_d2, decode_d1 }),
       .dev_mem_valid({ d2_mem_valid, d1_mem_valid }),
       .dev_mem_ready({ d2_mem_ready, d1_mem_ready }),
       .dev_mem_rdata({ d2_mem_rdata, d1_mem_rdata }));

   initial begin
      clk = 1'b0;
      num_cycles = 0;
      //$monitor($time, " clk=%b decode_d1=%b cpu_mem_valid=%b d1_mem_valid=%b cpu_mem_ready=%b d1_mem_ready=%b", clk, decode_d1, cpu_mem_valid, d1_mem_valid, cpu_mem_ready, d1_mem_ready);
   end
   always begin
      #10 clk = 1'b1;
      num_cycles <= num_cycles + 1;
      #10 clk = 1'b0;
      if (num_cycles >= 25)
	$finish;
   end

   initial begin
      $display($time, " Testing address decoder");

      wait(num_cycles == 10);
      wait(clk == 1'b0);
      cpu_mem_addr <= 32'h20004000;
      cpu_mem_wstrb <= 4'b0000;
      cpu_mem_valid <= 1'b1;
      wait(cpu_mem_ready == 1'b1);
      $display($time, " d1(0x20004000) read as %d", cpu_mem_rdata);
      $display($time, "   d1_decode=%b d1_mem_addr=0x%h d1_mem_rdata=0x%h", decode_d1, d1_mem_addr, d1_mem_rdata);

      cpu_mem_valid <= 0;
      wait(cpu_mem_ready == 0);
      wait(clk == 1'b0);
      cpu_mem_addr <= 32'h20004000;
      cpu_mem_wstrb <= 4'b0000;
      cpu_mem_valid <= 1'b1;
      wait(cpu_mem_ready == 1'b1);
      $display($time, " d1(0x20004000) read as %d", cpu_mem_rdata);

      cpu_mem_valid <= 0;
      wait(cpu_mem_ready == 0);
      wait(clk == 1'b0);
      cpu_mem_addr <= 32'h20005120;
      cpu_mem_wstrb <= 4'b1111;
      cpu_mem_wdata <= 'd42042;
      cpu_mem_valid <= 1'b1;
      wait(cpu_mem_ready == 1'b1);
      $display($time, " d2(0x20005120) written as %d", cpu_mem_wdata);

      cpu_mem_valid <= 0;
      wait(cpu_mem_ready == 0);
      wait(clk == 1'b0);
      cpu_mem_addr <= 32'h20004000;
      cpu_mem_wstrb <= 4'b0000;
      cpu_mem_valid <= 1'b1;
      wait(cpu_mem_ready == 1'b1);
      $display($time, " d1(0x20004000) read as %d", cpu_mem_rdata);

      cpu_mem_valid <= 0;
      wait(cpu_mem_ready == 0);
      wait(clk == 1'b0);
      cpu_mem_addr <= 32'h20004048;
      cpu_mem_wstrb <= 4'b1111;
      cpu_mem_wdata <= 'd12345;
      cpu_mem_valid <= 1'b1;
      wait(cpu_mem_ready == 1'b1);
      $display($time, " d1(0x20004048) written as %d", cpu_mem_wdata);

      cpu_mem_valid <= 0;
      wait(cpu_mem_ready == 0);
      wait(clk == 1'b0);
      cpu_mem_addr <= 32'h20005120;
      cpu_mem_wstrb <= 4'b0000;
      cpu_mem_valid <= 1'b1;
      wait(cpu_mem_ready == 1'b1);
      $display($time, " d2(0x20005120) read as %d", cpu_mem_rdata);
      $display($time, "   d2_decode=%b d2_val=%d d2_rdata=%d d2_addr=0x%h", decode_d2, d2_val, d2_mem_rdata, d2_mem_addr);

      cpu_mem_valid <= 0;
      wait(cpu_mem_ready == 0);
      wait(clk == 1'b0);
      cpu_mem_addr <= 32'h20004048;
      cpu_mem_wstrb <= 4'b0000;
      cpu_mem_valid <= 1'b1;
      wait(cpu_mem_ready == 1'b1);
      $display($time, " d1(0x20004048) read as %d", cpu_mem_rdata);

   end

endmodule // top
