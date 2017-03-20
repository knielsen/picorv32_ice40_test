module picorv32_sdram (
    // Interface to picorv32.
    input 	      mem_valid,
    output reg 	      mem_ready,
    input [31:0]      mem_addr,
    input [31:0]      mem_wdata,
    input [ 3:0]      mem_wstrb,
    output reg [31:0] mem_rdata,
    // Interface to SDRAM chip.
    input [15:0]      sdram_dq_read,
    output [15:0]     sdram_dq_write,
    output 	      sdram_busdir, // 1 means write / output to SDRAM chip.
    output [12:0]     sdram_addr,
    output [1:0]      sdram_blockaddr,
    output 	      sdram_clk,
    output 	      sdram_cke,
    output 	      sdram_csn,
    output 	      sdram_rasn,
    output 	      sdram_casn,
    output 	      sdram_wen,
    output [1:0]      sdram_dqm,
    // Other signals.
    input 	      clk,
    input 	      nrst);

   wire sdram_data_valid;
   wire sdram_busy;
   wire sdram_idle;
   wire sdram_init_done;
   wire sdram_ack;
   wire sdram_addr;
   reg [15:0] sdram_data_in;
   wire [15:0] sdram_data_out;
   reg [26:0] sdram_i_addr;
   reg sdram_adv;
   reg sdram_rwn;
   reg st_running;

   // Some dummy / not-used sdram controller signals.
   wire sdram_data_req, sdram_write_done, sdram_read_done,
	sdram_selfrefresh_req, sdram_loadmod_req, sdram_burststop_req,
	sdram_disable_active, sdram_disable_precharge, sdram_precharge_req,
	sdram_powerdown, sdram_disable_autorefresh;
   wire [1:0] sdram_dqm_dummy_highbits;
   wire [15:0] sdram_data_dummy_highbits;
   wire [15:0] sdram_dq_dummy_highbits;

   assign sdram_selfrefresh_req = 0;
   assign sdram_loadmod_req = 0;
   assign sdram_burststop_req = 0;
   assign sdram_disable_active = 0;
   assign sdram_disable_precharge = 0;
   assign sdram_precharge_req = 0;
   assign sdram_powerdown = 0;
   assign sdram_disable_autorefresh = 0;

   sdram_controller sdram
     ( .o_data_valid(sdram_data_valid),
       .o_data_req(sdram_data_req),
       .o_busy(sdram_busy),
       .o_init_done(sdram_init_done),
       .o_ack(sdram_ack),

       .o_sdram_addr(sdram_addr),
       .o_sdram_blkaddr(sdram_blockaddr),
       .o_sdram_casn(sdram_casn),
       .o_sdram_cke(sdram_cke),
       .o_sdram_csn(sdram_csn),
       .o_sdram_dqm({ sdram_dqm_dummy_highbits, sdram_dqm }),
       .o_sdram_rasn(sdram_rasn),
       .o_sdram_wen(sdram_wen),
       .o_sdram_clk(sdram_clk),
       .o_write_done(sdram_write_done),
       .o_read_done(sdram_read_done),

       .i_data({ 16'd0, sdram_data_in }),
       .o_data({ sdram_data_dummy_highbits, sdram_data_out }),
       .i_sdram_dq({ 16'd0, sdram_dq_read }),
       .o_sdram_dq({ sdram_dq_dummy_highbits, sdram_dq_write }),
       .o_sdram_busdir(sdram_busdir),

       .i_addr(sdram_i_addr),
       .i_adv(sdram_adv),
       .i_clk(clk),
       .i_rst(!nrst),
       .i_rwn(sdram_rwn),
       .i_selfrefresh_req(sdram_selfrefresh_req),
       .i_loadmod_req(sdram_loadmod_req),
       .i_burststop_req(sdram_burststop_req),
       .i_disable_active(sdram_disable_active),
       .i_disable_precharge(sdram_disable_precharge),
       .i_precharge_req(sdram_precharge_req),
       .i_power_down(sdram_powerdown),
       .i_disable_autorefresh(sdram_disable_autorefresh));

   assign sdram_idle = sdram_init_done & !sdram_busy;
   assign cur_state_busy = st_running;

   // State changes.
   always @(posedge clk) begin
      if (!nrst) begin
	 sdram_adv <= 0;
	 mem_ready <= 0;
	 st_running <= 0;
      end else if (mem_valid & !mem_ready & !cur_state_busy & sdram_idle) begin
	 // ToDo: for now, assume word write at 4-byte aligned address.
	 st_running <= 1;
	 sdram_adv <= 1;
	 sdram_i_addr <= {27{mem_addr[27:2], 1'b0}};
	 sdram_rwn <= (!mem_wstrb[1]);
	 sdram_data_in <= mem_wdata;
      end else if (st_running) begin
	 if (sdram_ack)
	   sdram_adv <= 0;
	 if (sdram_idle & !sdram_adv) begin
	    st_running <= 0;
	    mem_ready <= 1;
	 end
	 if (sdram_data_valid)
	   mem_rdata <= { 16'b0, sdram_data_out }; // ToDo: 32-bit support...
      end else
	mem_ready <= 0;
   end

   always @(*)
     $display($time, "   ? nrst=%b vld=%b bsy=%b idl=%b run=%b rdy=%b sdram_vld=%b do=0x%h", nrst, mem_valid, cur_state_busy, sdram_idle, st_running, mem_ready, sdram_data_valid, sdram_data_out);

/*
   always @(posedge clk) begin
      mem_ready <= 0;
      case (state)
	0: begin
	   if (mem_valid) begin
	      state <= 1;
	      sdram_adv <= 1;
	   end
	end
	1: begin
	   state <= 2;
	end
	2: begin
	end
      endcase
   end
*/

endmodule // picorv32_sdram
