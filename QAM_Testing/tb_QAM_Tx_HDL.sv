`timescale 1 ns / 1 ns

// =============================================================================
// Vivado 2019.1 SystemVerilog Testbench: tb_QAM_Tx_HDL
// Verifies the MATLAB HDL Coder generated 8-QAM Transmitter RTL (QAM_Tx_HDL.v)
// against Simulink golden fixed-point output vectors (sfix16_En15).
// =============================================================================

module tb_QAM_Tx_HDL;

  localparam int N_SAMPLES = 4000;
  localparam int CLK_PER   = 10;   // 10 ns clock for simulation speed
  localparam int PIPE_LAT  = 2;    // 2-cycle CRP pipeline latency reported by makehdl

  logic               clk;
  logic               reset;
  logic               clk_enable;
  wire                ce_out;
  wire signed [15:0]  Data_Out_re;
  wire signed [15:0]  Data_Out_im;

  logic [15:0]        golden_re [0:N_SAMPLES-1];
  logic [15:0]        golden_im [0:N_SAMPLES-1];

  int                 out_sample_cnt;
  int                 match_cnt;
  int                 err_cnt;

  // Instantiate 8-QAM Transmitter HDL DUT
  QAM_Tx_HDL u_tx_dut (
    .clk         (clk),
    .reset       (reset),
    .clk_enable  (clk_enable),
    .ce_out      (ce_out),
    .Data_Out_re (Data_Out_re),
    .Data_Out_im (Data_Out_im)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PER/2) clk = ~clk;
  end

  initial begin
    $display("========================================================================");
    $display(" VIVADO 2019.1 RTL VERIFICATION: QAM_Tx_HDL (8-QAM Transmitter)");
    $display("========================================================================");

    $readmemh("d:/HoriTech_Files/QAM_Testing/test_vectors/golden_tx_out_re.mem", golden_re);
    $readmemh("d:/HoriTech_Files/QAM_Testing/test_vectors/golden_tx_out_im.mem", golden_im);
    $display("[TB-TX] Loaded %0d golden complex samples (sfix16_En15).", N_SAMPLES);

    reset          = 1'b1;
    clk_enable     = 1'b0;
    out_sample_cnt = 0;
    match_cnt      = 0;
    err_cnt        = 0;

    repeat (10) @(posedge clk);
    @(negedge clk);
    reset      = 1'b0;
    clk_enable = 1'b1;

    // Wait until N_SAMPLES output strobes (ce_out) have been observed
    wait (out_sample_cnt >= N_SAMPLES);
    @(posedge clk);

    $display("------------------------------------------------------------------------");
    $display(" [TB-TX] QAM_Tx_HDL Verification Summary:");
    $display("   Total Output Samples Checked : %0d", match_cnt + err_cnt);
    $display("   Exact Bit-True Matches       : %0d", match_cnt);
    $display("   Mismatches                   : %0d", err_cnt);
    if (err_cnt == 0 && match_cnt > 3900)
      $display("   STATUS                       : PASS (100%% Bit-Exact Match)");
    else
      $display("   STATUS                       : FAIL");
    $display("========================================================================");
    $finish;
  end

  // Sample and compare on every active ce_out strobe
  always @(posedge clk) begin
    if (!reset && clk_enable && ce_out) begin
      if (out_sample_cnt >= PIPE_LAT && out_sample_cnt < N_SAMPLES) begin
        automatic int g_idx = out_sample_cnt - PIPE_LAT;
        if ((Data_Out_re === $signed(golden_re[g_idx])) &&
            (Data_Out_im === $signed(golden_im[g_idx]))) begin
          match_cnt <= match_cnt + 1;
        end else begin
          err_cnt <= err_cnt + 1;
          if (err_cnt < 10) begin
            $display("[TB-TX] MISMATCH at sample %0d (golden[%0d]): RTL=(%04h, %04h) vs Golden=(%04h, %04h)",
                     out_sample_cnt, g_idx, Data_Out_re[15:0], Data_Out_im[15:0],
                     golden_re[g_idx], golden_im[g_idx]);
          end
        end
      end
      out_sample_cnt <= out_sample_cnt + 1;
    end
  end

endmodule

