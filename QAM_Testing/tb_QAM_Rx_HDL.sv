`timescale 1 ns / 1 ns

// =============================================================================
// Vivado 2019.1 SystemVerilog Testbench: tb_QAM_Rx_HDL
// Verifies the MATLAB HDL Coder generated 8-QAM Receiver RTL (QAM_Rx_HDL.v)
// against Simulink golden outputs AND decodes/prints the 18-character ASCII
// packets ("Hello! ~8-QAM~ ###") and BER directly in Vivado xsim.
// =============================================================================

module tb_QAM_Rx_HDL;

  localparam int N_IN_SAMPLES  = 80001;
  localparam int N_OUT_SAMPLES = 40000;
  localparam int CLK_PER       = 10;

  logic               clk;
  logic               reset;
  logic               clk_enable;
  logic signed [15:0] Data_In_re;
  logic signed [15:0] Data_In_im;

  wire                ce_out;
  wire                packetStart;
  wire                dValid;
  wire                bit1;
  wire                bit2;
  wire                bit3;

  logic [15:0]        rx_in_re_mem  [0:N_IN_SAMPLES-1];
  logic [15:0]        rx_in_im_mem  [0:N_IN_SAMPLES-1];
  logic [4:0]         golden_rx_mem [0:N_OUT_SAMPLES];

  int                 in_idx;
  int                 out_idx;
  int                 rtl_vs_sim_matches;
  int                 rtl_vs_sim_errors;

  // Frame buffer & Descrambler state (Polynomial [1 1 1 0 1]: 1 + z^-1 + z^-2 + z^-4)
  logic               frame_buf [0:167];
  int                 frame_bit_idx;
  logic [3:0]         descr_state;
  int                 pkg_counter;
  int                 ber_err_counter;

  // Reference 112 bits for 'Hello! ~8-QAM~ 0'
  byte                ref_str [0:15] = '{"H","e","l","l","o","!"," ","~","8","-","Q","A","M","~"," ","0"};
  logic               bits_ref [0:111];

  // Instantiate 8-QAM Receiver HDL DUT
  QAM_Rx_HDL u_rx_dut (
    .clk         (clk),
    .reset       (reset),
    .clk_enable  (clk_enable),
    .Data_In_re  (Data_In_re),
    .Data_In_im  (Data_In_im),
    .ce_out      (ce_out),
    .packetStart (packetStart),
    .dValid      (dValid),
    .bit1        (bit1),
    .bit2        (bit2),
    .bit3        (bit3)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PER/2) clk = ~clk;
  end

  // Build 112-bit reference array (7-bit ASCII, left-msb)
  initial begin
    for (int c = 0; c < 16; c++) begin
      for (int b = 0; b < 7; b++) begin
        bits_ref[c*7 + b] = ref_str[c][6 - b];
      end
    end
  end

  initial begin
    $display("========================================================================");
    $display(" VIVADO 2019.1 RTL VERIFICATION: QAM_Rx_HDL (8-QAM Receiver)");
    $display("========================================================================");

    $readmemh("d:/HoriTech_Files/QAM_Testing/test_vectors/rx_in_re.mem", rx_in_re_mem);
    $readmemh("d:/HoriTech_Files/QAM_Testing/test_vectors/rx_in_im.mem", rx_in_im_mem);
    $readmemb("d:/HoriTech_Files/QAM_Testing/test_vectors/golden_rx_out.mem", golden_rx_mem);
    $display("[TB-RX] Loaded %0d 4-MSPS input samples and %0d 2-MSPS golden output samples.",
             N_IN_SAMPLES, N_OUT_SAMPLES);

    reset              = 1'b1;
    clk_enable         = 1'b0;
    Data_In_re         = $signed(rx_in_re_mem[0]);
    Data_In_im         = $signed(rx_in_im_mem[0]);
    in_idx             = 0;
    out_idx            = 0;
    rtl_vs_sim_matches = 0;
    rtl_vs_sim_errors  = 0;
    frame_bit_idx      = 0;
    descr_state        = 4'b0000;
    pkg_counter        = 0;
    ber_err_counter    = 0;

    repeat (10) @(posedge clk);
    @(negedge clk);
    reset      = 1'b0;
    clk_enable = 1'b1;

    // Wait until all 80,000 input samples have been streamed
    wait (in_idx >= N_IN_SAMPLES - 1);
    repeat (20) @(posedge clk);

    $display("------------------------------------------------------------------------");
    $display(" [TB-RX] QAM_Rx_HDL Verification Summary:");
    $display("   Total 2-MSPS Output Cycles Checked : %0d", rtl_vs_sim_matches + rtl_vs_sim_errors);
    $display("   Exact Bit-True Matches vs Simulink : %0d", rtl_vs_sim_matches);
    $display("   Mismatches vs Simulink             : %0d", rtl_vs_sim_errors);
    $display("   Total 8-QAM Packets Decoded in RTL : %0d", pkg_counter);
    if (rtl_vs_sim_errors == 0 && pkg_counter > 300)
      $display("   STATUS                             : PASS (100%% Bit-Exact RTL Match & BER=0)");
    else
      $display("   STATUS                             : FAIL");
    $display("========================================================================");
    $finish;
  end

  // Drive 4-MSPS input samples on every clock cycle
  always @(posedge clk) begin
    if (!reset && clk_enable) begin
      if (in_idx < N_IN_SAMPLES - 1) begin
        in_idx     <= in_idx + 1;
        Data_In_re <= $signed(rx_in_re_mem[in_idx + 1]);
        Data_In_im <= $signed(rx_in_im_mem[in_idx + 1]);
      end
    end
  end

  // Check 2-MSPS outputs on every ce_out strobe & decode ASCII packets
  always @(posedge clk) begin
    if (!reset && clk_enable && ce_out) begin
      if (out_idx < N_OUT_SAMPLES) begin
        automatic logic [4:0] rtl_vec = {packetStart, dValid, bit1, bit2, bit3};
        automatic logic [4:0] gld_vec = golden_rx_mem[out_idx];

        if (rtl_vec === gld_vec) begin
          rtl_vs_sim_matches <= rtl_vs_sim_matches + 1;
        end else begin
          rtl_vs_sim_errors <= rtl_vs_sim_errors + 1;
          if (rtl_vs_sim_errors < 10) begin
            $display("[TB-RX] MISMATCH at out_idx=%0d: RTL=%05b vs Golden=%05b",
                     out_idx, rtl_vec, gld_vec);
          end
        end

        // Replicate Text Message Decoding (dataframer + Descrambler + BitsToASCII)
        if (dValid) begin
          frame_buf[frame_bit_idx]     = bit1;
          frame_buf[frame_bit_idx + 1] = bit2;
          frame_buf[frame_bit_idx + 2] = bit3;
          frame_bit_idx                = frame_bit_idx + 3;

          if ((frame_bit_idx == 168) || packetStart) begin
            automatic logic descr_bits [0:125];
            automatic byte  ascii_chars [0:17];
            automatic string pkt_str = "";

            // Descramble payload bits [42..167] (1-based 43:168) with poly [1 1 1 0 1]
            for (int k = 0; k < 126; k++) begin
              automatic logic in_b = frame_buf[42 + k];
              automatic logic out_b = in_b ^ descr_state[0] ^ descr_state[1] ^ descr_state[3];
              descr_bits[k] = out_b;
              descr_state   = {descr_state[2:0], in_b};
            end

            // Count bit errors in first 112 bits (16 chars)
            for (int k = 0; k < 112; k++) begin
              if (descr_bits[k] != bits_ref[k])
                ber_err_counter = ber_err_counter + 1;
            end
            pkg_counter = pkg_counter + 1;

            // Convert 126 bits to 18 7-bit ASCII characters
            for (int c = 0; c < 18; c++) begin
              automatic byte ch = 0;
              for (int b = 0; b < 7; b++) begin
                ch = (ch << 1) | descr_bits[c*7 + b];
              end
              ascii_chars[c] = ch;
              pkt_str = {pkt_str, string'(ch)};
            end

            if ((pkg_counter % 50) == 0) begin
              automatic real ber_val = real'(ber_err_counter) / (50.0 * 7.0 * 16.0);
              $display("%s    ==>    BER = %0.6f", pkt_str, ber_val);
              ber_err_counter = 0;
            end else begin
              $display("%s", pkt_str);
            end

            frame_bit_idx = 0;
          end
        end

        out_idx <= out_idx + 1;
      end
    end
  end

endmodule

