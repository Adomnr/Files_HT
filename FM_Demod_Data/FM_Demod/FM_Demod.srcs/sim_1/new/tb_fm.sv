`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// tb_fm - file-driven test bench for block design FM_Demod.
//
//   dut : receiver fed with rx_iq.txt, modulator fed with tx_audio.txt
//   lb  : second copy whose receiver is fed by the modulator output of dut
//         (loopback)
//
// Stimulus comes from matlab/hw_export_vectors.m, results are checked by
// matlab/hw_compare.m. The directory is passed with  -testplusarg DIR=<path>.
// One sample is applied every SPACING clocks (the design only needs the
// samples to be at least ~50 clocks apart; the real rate is 48 kS/s).
// +SPACING=<n> overrides it at run time.
// -----------------------------------------------------------------------------
module tb_fm;
    parameter int IN_W    = 16;
    parameter int SPACING = 64;

    string dir;
    int    spacing = SPACING;          // clocks per sample, override with +SPACING=<n>
    logic aclk = 1'b0, aresetn = 1'b0;
    always #5 aclk = ~aclk;

    logic [2*IN_W-1:0] rx_iq = '0;
    logic              rx_iq_v = 1'b0;
    logic [15:0]       tx_audio = '0;
    logic              tx_audio_v = 1'b0;
    wire  [15:0]       rx_audio, lb_audio;
    wire               rx_audio_v, rx_sq, lb_audio_v, lb_sq;
    wire  [2*IN_W-1:0] tx_iq;
    wire               tx_iq_v;
    bit                rx_done = 0, tx_done = 0;

    FM_Demod_wrapper dut (
        .aclk(aclk), .aresetn(aresetn),
        .rx_iq_tdata(rx_iq),       .rx_iq_tvalid(rx_iq_v),
        .rx_audio_tdata(rx_audio), .rx_audio_tvalid(rx_audio_v), .rx_squelch_open(rx_sq),
        .tx_audio_tdata(tx_audio), .tx_audio_tvalid(tx_audio_v),
        .tx_iq_tdata(tx_iq),       .tx_iq_tvalid(tx_iq_v));

    FM_Demod_wrapper lb (
        .aclk(aclk), .aresetn(aresetn),
        .rx_iq_tdata(tx_iq),       .rx_iq_tvalid(tx_iq_v),
        .rx_audio_tdata(lb_audio), .rx_audio_tvalid(lb_audio_v), .rx_squelch_open(lb_sq),
        .tx_audio_tdata(16'd0),    .tx_audio_tvalid(1'b0),
        .tx_iq_tdata(),            .tx_iq_tvalid());

    int f_rx, f_tx, f_lb;

    initial begin
        if (!$value$plusargs("DIR=%s", dir)) $fatal(1, "missing +DIR=<vector directory>");
        void'($value$plusargs("SPACING=%d", spacing));
        $display("tb_fm: IN_W=%0d, %0d clocks per sample, vectors in %s", IN_W, spacing, dir);
        f_rx = $fopen({dir, "/rx_audio_hw.txt"}, "w");
        f_tx = $fopen({dir, "/tx_iq_hw.txt"},    "w");
        f_lb = $fopen({dir, "/lb_audio_hw.txt"}, "w");
        repeat (20) @(posedge aclk);
        aresetn <= 1'b1;
    end

    // receiver stimulus
    initial begin : rx_stim
        int fi, i, q, n;
        wait (aresetn);
        repeat (20) @(posedge aclk);
        fi = $fopen({dir, "/rx_iq.txt"}, "r");
        if (fi == 0) $fatal(1, "cannot open rx_iq.txt");
        n = 0;
        while ($fscanf(fi, "%d %d", i, q) == 2) begin
            rx_iq   <= {q[IN_W-1:0], i[IN_W-1:0]};
            rx_iq_v <= 1'b1;
            @(posedge aclk);
            rx_iq_v <= 1'b0;
            repeat (spacing-1) @(posedge aclk);
            n++;
        end
        $fclose(fi);
        $display("tb_fm: %0d receiver samples applied", n);
        rx_done = 1;
    end

    // modulator stimulus
    initial begin : tx_stim
        int fi, a, n;
        wait (aresetn);
        repeat (20) @(posedge aclk);
        fi = $fopen({dir, "/tx_audio.txt"}, "r");
        if (fi == 0) $fatal(1, "cannot open tx_audio.txt");
        n = 0;
        while ($fscanf(fi, "%d", a) == 1) begin
            tx_audio   <= a[15:0];
            tx_audio_v <= 1'b1;
            @(posedge aclk);
            tx_audio_v <= 1'b0;
            repeat (spacing-1) @(posedge aclk);
            n++;
        end
        $fclose(fi);
        $display("tb_fm: %0d modulator samples applied", n);
        tx_done = 1;
    end

    // result capture
    always @(posedge aclk) begin
        if (rx_audio_v) $fdisplay(f_rx, "%0d %0d", $signed(rx_audio), rx_sq);
        if (tx_iq_v)    $fdisplay(f_tx, "%0d %0d", $signed(tx_iq[IN_W-1:0]), $signed(tx_iq[2*IN_W-1:IN_W]));
        if (lb_audio_v) $fdisplay(f_lb, "%0d %0d", $signed(lb_audio), lb_sq);
    end

    initial begin
        wait (rx_done && tx_done);
        repeat (4*spacing) @(posedge aclk);
        $fclose(f_rx); $fclose(f_tx); $fclose(f_lb);
        $display("tb_fm: finished");
        $finish;
    end
endmodule
