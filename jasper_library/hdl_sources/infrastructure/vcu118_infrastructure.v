module vcu118_infrastructure(
    input  sys_clk_buf_n,
    input  sys_clk_buf_p,

    output sys_clk0,
    output sys_clk90,
    output sys_clk180,
    output sys_clk270,

    output clk_200_0,
    output clk_200_90,
    output clk_200_180,
    output clk_200_270,

    output sys_rst,
    output sys_clk_rst_sync,
    output idelay_rdy
  );

  // Sys clk is 300MHz on the VCU118
  wire sys_clk_ds;
  IBUFGDS #(
    .IOSTANDARD("LVDS")
  ) ibufgds_sys_clk (
    .I (sys_clk_buf_p),
    .IB(sys_clk_buf_n),
    .O (sys_clk_ds)
  );

  wire fb_clk;

  wire sys_clk0_dcm;
  wire sys_clk90_dcm;
  wire sys_clk180_dcm;
  wire sys_clk270_dcm;
  wire clk_200_0_dcm;
  wire clk_200_90_dcm;
  wire clk_200_180_dcm;
  wire clk_200_270_dcm;

  wire clk_fb;

  wire pll_lock;
  assign pll_lock = 1'b1;

  MMCME4_ADV #(
   .COMPENSATION       ("AUTO"),
   .CLKFBOUT_MULT_F    (4), // Multiply value for all CLKOUT (5.0-64.0).
   .CLKFBOUT_PHASE     (0.0),
   .CLKIN1_PERIOD      (4.0), // VCU118 clock is 250 MHz
   .CLKOUT0_DIVIDE_F   (1.0), // Divide amount for CLKOUT0 (1.000-128.000).
   .CLKOUT0_DUTY_CYCLE (0.5),
   .CLKOUT1_DUTY_CYCLE (0.5),
   .CLKOUT2_DUTY_CYCLE (0.5),
   .CLKOUT3_DUTY_CYCLE (0.5),
   .CLKOUT4_DUTY_CYCLE (0.5),
   .CLKOUT5_DUTY_CYCLE (0.5),
   .CLKOUT6_DUTY_CYCLE (0.5),
   .CLKOUT0_PHASE      (0.0),
   .CLKOUT1_PHASE      (0.0),
   .CLKOUT2_PHASE      (90),
   .CLKOUT3_PHASE      (0.0),
   .CLKOUT4_PHASE      (90),
   .CLKOUT5_PHASE      (270),
   .CLKOUT6_PHASE      (0.0),
   .CLKOUT1_DIVIDE     (10),// 100MHz
   .CLKOUT2_DIVIDE     (10),// 100MHz
   .CLKOUT3_DIVIDE     (5), // 200MHz
   .CLKOUT4_DIVIDE     (5), // 200MHz
   .CLKOUT5_DIVIDE     (5), // 200MHz
   .CLKOUT6_DIVIDE     (1),
   .CLKOUT4_CASCADE    ("FALSE"),
   .DIVCLK_DIVIDE      (1), // Master division value (1-80)
   .REF_JITTER1        (0.0),
   .STARTUP_WAIT       ("FALSE")
  ) MMCM_BASE_inst (
   .CLKIN1   (sys_clk_ds),
   .CLKFBIN  (clk_fb),

   .CLKFBOUT  (clk_fb),
   .CLKFBOUTB (),

   .CLKOUT0  (),
   .CLKOUT0B (),
   .CLKOUT1  (sys_clk0_dcm),
   .CLKOUT1B (sys_clk180_dcm),
   .CLKOUT2  (sys_clk90_dcm),
   .CLKOUT2B (sys_clk270_dcm),
   .CLKOUT3  (clk_200_0_dcm),
   .CLKOUT3B (clk_200_180_dcm),
   .CLKOUT4  (clk_200_90_dcm),
   .CLKOUT5  (clk_200_270_dcm),
   .CLKOUT6  (),
   .LOCKED   (),//(pll_lock),

   .PWRDWN   (1'b0),
   .RST      (1'b0)

  );


  BUFG bufg_sysclk[7:0](
    .I({sys_clk0_dcm, sys_clk90_dcm, sys_clk180_dcm, sys_clk270_dcm, clk_200_0_dcm, clk_200_90_dcm, clk_200_180_dcm, clk_200_270_dcm}),
    .O({sys_clk0,     sys_clk90,     sys_clk180,     sys_clk270,     clk_200_0,     clk_200_90,     clk_200_180,     clk_200_270})
  );
  
  /* reset gen */
  reg sys_rst_reg_z;
  reg sys_rst_reg;
  reg [15:0] sys_rst_counter;
  always @(posedge sys_clk0) begin
    sys_rst_reg_z <= sys_rst_reg;
    if (!pll_lock) begin
      sys_rst_reg     <= 1'b0;
      sys_rst_counter <= {16{1'b0}};
    end else begin
      if (sys_rst_counter == {16{1'b1}}) begin
        sys_rst_reg <= 1'b0;
        sys_rst_counter <= {16{1'b1}};
      end else begin
        sys_rst_reg <= 1'b1;
        sys_rst_counter <= sys_rst_counter + 16'd1;
      end
    end

  end
  assign sys_rst = sys_rst_reg_z & pll_lock;

  /* io delay reset */

  IDELAYCTRL #(
    .SIM_DEVICE("ULTRASCALE")
  ) idelayctrl_inst(
    .REFCLK(clk_200),
    .RST(sys_rst),
    .RDY(idelay_rdy)
  );
  
  /*
   * Synchronizes an active-high asynchronous reset signal to a given clock by
   * using a pipeline of N registers.
   * Copyright (c) 2014-2018 Alex Forencich
   */
  (*ASYNC_REG = "TRUE" *) reg [3:0] sync_reg = {4{1'b1}};
  assign sys_clk_rst_sync = sync_reg[3];
  wire sync_clk;
  wire sync_rst;
  assign sync_clk = sys_clk0;
  assign sync_rst = ~pll_lock; 
 
  always @(posedge sync_clk or posedge sync_rst) begin
      if (sync_rst)
          sync_reg <= {4{1'b1}};
      else
          sync_reg <= {sync_reg[2:0], 1'b0};
  end

endmodule
