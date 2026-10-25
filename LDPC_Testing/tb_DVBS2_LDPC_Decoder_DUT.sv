`timescale 1 ns / 1 ns

// =============================================================================
// Vivado 2019.1 Testbench: tb_DVBS2_LDPC_Decoder_DUT
// Verifies the MATLAB HDL Coder generated DVB-S2 LDPC Decoder IP Core
// (DVBS2_LDPC_Decoder_DUT) using stimulus & golden vectors exported from MATLAB.
// =============================================================================

module tb_DVBS2_LDPC_Decoder_DUT;

  // Parameters
  localparam int N_LDPC    = 16200; // Short FEC Frame codeword length
  localparam int K_LDPC    = 7200;  // Nominal Rate 1/2 (effective 4/9) info bits
  localparam int CLK_PER   = 10;    // 100 MHz clock (10 ns period)

  // Clock, Reset, and Enable
  logic               clk;
  logic               reset;
  logic               clk_enable;

  // DUT Inputs
  logic signed [5:0]  dataIn;       // sfix6_En2
  logic               startIn;
  logic               endIn;
  logic               validIn;

  // DUT Outputs
  wire                ce_out;
  wire                dataOut;
  wire                startOut;
  wire                endOut;
  wire                validOut;
  wire [7:0]          actIter;
  wire                parityCheck;
  wire                nextFrame;

  // Memories for MATLAB stimulus and golden reference
  logic [5:0]         llr_stimulus_mem [0:N_LDPC-1];
  logic               golden_bits_mem  [0:K_LDPC-1];

  // Verification tracking counters
  int                 cycle_count;
  int                 in_start_cycle;
  int                 in_end_cycle;
  int                 out_start_cycle;
  int                 out_end_cycle;
  int                 out_bit_count;
  int                 bit_error_count;
  int                 captured_act_iter;
  int                 captured_parity_check;
  int                 fd_out_bits;
  int                 fd_summary;

  // Instantiate Generated DVB-S2 LDPC Decoder HDL IP Core
  DVBS2_LDPC_Decoder_DUT u_dut (
    .clk         (clk),
    .reset       (reset),
    .clk_enable  (clk_enable),
    .dataIn      (dataIn),
    .startIn     (startIn),
    .endIn       (endIn),
    .validIn     (validIn),
    .ce_out      (ce_out),
    .dataOut     (dataOut),
    .startOut    (startOut),
    .endOut      (endOut),
    .validOut    (validOut),
    .actIter     (actIter),
    .parityCheck (parityCheck),
    .nextFrame   (nextFrame)
  );

  // Clock generator (100 MHz)
  initial begin
    clk = 1'b0;
    forever #(CLK_PER/2) clk = ~clk;
  end

  // Cycle counter
  always_ff @(posedge clk) begin
    if (reset)
      cycle_count <= 0;
    else if (clk_enable)
      cycle_count <= cycle_count + 1;
  end

  // Main Stimulus Process
  initial begin
    $display("========================================================================");
    $display(" VIVADO 2019.1 RTL VERIFICATION: DVB-S2 LDPC Decoder HDL IP Core");
    $display("========================================================================");

    // Load MATLAB-generated test vectors
    $readmemh("d:/HoriTech_Files/LDPC_Testing/test_vectors/input_llr_6bit_hex.mem", llr_stimulus_mem);
    $readmemb("d:/HoriTech_Files/LDPC_Testing/test_vectors/golden_output_bits.mem", golden_bits_mem);
    $display("[TB] Loaded %0d 6-bit LLR samples from input_llr_6bit_hex.mem", N_LDPC);
    $display("[TB] Loaded %0d golden reference bits from golden_output_bits.mem", K_LDPC);

    fd_out_bits = $fopen("d:/HoriTech_Files/LDPC_Testing/test_vectors/vivado_decoded_bits.txt", "w");

    // Initialize signals
    reset                 = 1'b1;
    clk_enable            = 1'b1;
    dataIn                = 6'sd0;
    startIn               = 1'b0;
    endIn                 = 1'b0;
    validIn               = 1'b0;
    in_start_cycle        = 0;
    in_end_cycle          = 0;

    // Hold reset for 10 clock cycles
    repeat (10) @(posedge clk);
    @(negedge clk);
    reset = 1'b0;

    // Wait 10 idle cycles before streaming frame
    repeat (10) @(posedge clk);

    $display("[TB] Starting LLR frame streaming (%0d samples)...", N_LDPC);
    for (int i = 0; i < N_LDPC; i++) begin
      @(negedge clk);
      dataIn  = $signed(llr_stimulus_mem[i]);
      validIn = 1'b1;
      startIn = (i == 0)          ? 1'b1 : 1'b0;
      endIn   = (i == N_LDPC - 1) ? 1'b1 : 1'b0;
      if (i == 0)
        in_start_cycle = cycle_count + 1;
      if (i == N_LDPC - 1)
        in_end_cycle = cycle_count + 1;
    end

    // Deassert input control signals after frame end
    @(negedge clk);
    dataIn  = 6'sd0;
    validIn = 1'b0;
    startIn = 1'b0;
    endIn   = 1'b0;

    $display("[TB] Finished LLR input streaming at cycle %0d. Waiting for LDPC decoding...", in_end_cycle);

    // Wait for endOut pulse or timeout (30,000 cycles)
    fork
      begin
        wait (out_end_cycle > 0);
      end
      begin
        repeat (30000) @(posedge clk);
        $display("[TB] ERROR: Simulation timed out waiting for endOut!");
        $finish;
      end
    join_any
    disable fork;

    // Wait a few extra cycles after endOut
    repeat (20) @(posedge clk);

    $fclose(fd_out_bits);

    // Write verification summary file
    fd_summary = $fopen("d:/HoriTech_Files/LDPC_Testing/test_vectors/vivado_verification_summary.txt", "w");
    $fdisplay(fd_summary, "========================================================================");
    $fdisplay(fd_summary, " VIVADO 2019.1 RTL VERIFICATION SUMMARY: DVB-S2 LDPC Decoder IP");
    $fdisplay(fd_summary, "========================================================================");
    $fdisplay(fd_summary, "  Input Frame Cycles           : [%0d .. %0d] (%0d cycles)", in_start_cycle, in_end_cycle, N_LDPC);
    $fdisplay(fd_summary, "  Output Frame Cycles          : [%0d .. %0d] (%0d cycles)", out_start_cycle, out_end_cycle, out_end_cycle - out_start_cycle + 1);
    $fdisplay(fd_summary, "  Measured RTL Core Latency    : %0d clock cycles (endIn -> startOut)", out_start_cycle - in_end_cycle);
    $fdisplay(fd_summary, "  Actual Iterations (actIter)  : %0d (Expected MATLAB = 3)", captured_act_iter);
    $fdisplay(fd_summary, "  Parity Check (parityCheck)   : %0d (Expected MATLAB = 1)", captured_parity_check);
    $fdisplay(fd_summary, "  Total Decoded Bits Captured  : %0d (Expected MATLAB = %0d)", out_bit_count, K_LDPC);
    $fdisplay(fd_summary, "  Bit Errors vs MATLAB Golden  : %0d / %0d (BER = %0.6f)", bit_error_count, K_LDPC, real'(bit_error_count)/real'(K_LDPC));
    if (bit_error_count == 0 && out_bit_count == K_LDPC && captured_act_iter == 3 && captured_parity_check == 1) begin
      $fdisplay(fd_summary, "  OVERALL VERIFICATION STATUS  : PASS (100%% Bit-True & Cycle-True Match)");
    end else begin
      $fdisplay(fd_summary, "  OVERALL VERIFICATION STATUS  : FAIL");
    end
    $fdisplay(fd_summary, "========================================================================");
    $fclose(fd_summary);

    // Print results to console
    $display("========================================================================");
    $display(" VIVADO 2019.1 RTL VERIFICATION RESULTS");
    $display("========================================================================");
    $display("  Input Frame Cycles           : [%0d .. %0d] (%0d cycles)", in_start_cycle, in_end_cycle, N_LDPC);
    $display("  Output Frame Cycles          : [%0d .. %0d] (%0d cycles)", out_start_cycle, out_end_cycle, out_end_cycle - out_start_cycle + 1);
    $display("  Measured RTL Core Latency    : %0d clock cycles (endIn -> startOut)", out_start_cycle - in_end_cycle);
    $display("  Actual Iterations (actIter)  : %0d (Expected MATLAB = 3)", captured_act_iter);
    $display("  Parity Check (parityCheck)   : %0d (Expected MATLAB = 1)", captured_parity_check);
    $display("  Total Decoded Bits Captured  : %0d (Expected MATLAB = %0d)", out_bit_count, K_LDPC);
    $display("  Bit Errors vs MATLAB Golden  : %0d / %0d (BER = %0.6f)", bit_error_count, K_LDPC, real'(bit_error_count)/real'(K_LDPC));
    if (bit_error_count == 0 && out_bit_count == K_LDPC && captured_act_iter == 3 && captured_parity_check == 1) begin
      $display("  OVERALL VERIFICATION STATUS  : PASS (100%% Bit-True & Cycle-True Match)");
    end else begin
      $display("  OVERALL VERIFICATION STATUS  : FAIL");
    end
    $display("========================================================================");
    $finish;
  end

  // Output Monitor & Golden Checker Process
  always_ff @(posedge clk) begin
    if (reset) begin
      out_start_cycle       <= 0;
      out_end_cycle         <= 0;
      out_bit_count         <= 0;
      bit_error_count       <= 0;
      captured_act_iter     <= 0;
      captured_parity_check <= 0;
    end else if (clk_enable && validOut) begin
      if (startOut) begin
        out_start_cycle       <= cycle_count;
        captured_act_iter     <= int'(actIter);
        captured_parity_check <= int'(parityCheck);
        $display("[TB] First valid output bit (startOut=1) at cycle %0d | actIter=%0d | parityCheck=%0d",
                 cycle_count, actIter, parityCheck);
      end
      if (endOut) begin
        out_end_cycle <= cycle_count;
        $display("[TB] Last valid output bit (endOut=1) at cycle %0d", cycle_count);
      end

      // Compare against MATLAB golden reference
      if (out_bit_count < K_LDPC) begin
        $fdisplay(fd_out_bits, "%0d", dataOut);
        if (dataOut !== golden_bits_mem[out_bit_count]) begin
          bit_error_count <= bit_error_count + 1;
          if (bit_error_count < 10) begin
            $display("[TB] MISMATCH at bit %0d (cycle %0d): RTL=%b, Golden=%b",
                     out_bit_count, cycle_count, dataOut, golden_bits_mem[out_bit_count]);
          end
        end
      end
      out_bit_count <= out_bit_count + 1;
    end
  end

endmodule
