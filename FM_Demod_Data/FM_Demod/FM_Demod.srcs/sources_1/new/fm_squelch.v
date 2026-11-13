`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// fm_squelch - level squelch with hysteresis and hard mute.
//
// Bit-accurate with section 3 of matlab/fm_demod_fixed.m:
//   acc   = acc + mag - floor(acc / 2^AVG_LOG2)      one-pole average
//   level = floor(acc / 2^AVG_LOG2)
//   gate opens  when level >= th_open
//   gate closes when level <  th_close
//   audio = gate ? disc : 0
//
// This is the one block to replace if a different squelch is required (noise
// squelch, tone squelch, hang time ...). The interface is: magnitude and
// discriminator sample in, gated sample and gate flag out. The thresholds are
// ports so they can be driven by constants or by registers.
// -----------------------------------------------------------------------------
module fm_squelch #(
    parameter integer MAG_W    = 18,     // magnitude word length (signed, value >= 0)
    parameter integer AUDIO_W  = 16,
    parameter integer AVG_LOG2 = 8       // averaging time constant = 2^AVG_LOG2 samples
) (
    input  wire                      aclk,
    input  wire                      aresetn,
    input  wire                      in_valid,
    input  wire        [MAG_W-1:0]   mag,
    input  wire signed [AUDIO_W-1:0] disc,
    input  wire        [MAG_W-1:0]   th_open,
    input  wire        [MAG_W-1:0]   th_close,
    output reg                       out_valid,
    output reg  signed [AUDIO_W-1:0] audio,
    output reg                       gate,
    output reg         [MAG_W-1:0]   level
);
    localparam integer ACC_W = MAG_W + AVG_LOG2;

    reg  [ACC_W-1:0] acc;

    // a negative magnitude cannot occur with a real vector; clamp it anyway
    wire [MAG_W-1:0] mag_pos  = mag[MAG_W-1] ? {MAG_W{1'b0}} : mag;
    wire [ACC_W-1:0] acc_next = acc + mag_pos - (acc >> AVG_LOG2);
    wire [MAG_W-1:0] lvl_next = acc_next[ACC_W-1:AVG_LOG2];
    wire             gate_next = gate ? ~(lvl_next < th_close) : (lvl_next >= th_open);

    always @(posedge aclk) begin
        if (!aresetn) begin
            acc <= 0; level <= 0; gate <= 1'b0; audio <= 0; out_valid <= 1'b0;
        end else begin
            out_valid <= in_valid;
            if (in_valid) begin
                acc   <= acc_next;
                level <= lvl_next;
                gate  <= gate_next;
                audio <= gate_next ? disc : {AUDIO_W{1'b0}};
            end
        end
    end
endmodule
