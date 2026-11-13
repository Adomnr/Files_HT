`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// round_sat - drop SHIFT low bits (floor, or round half up when ROUND = 1) and
// saturate the result.
//
//   LIMIT = 0 : saturate to the full signed OUT_W range
//   LIMIT > 0 : saturate symmetrically to +/- LIMIT (used as deviation limiter)
//
// Registered output, one clock of latency, held until the next sample.
// -----------------------------------------------------------------------------
module round_sat #(
    parameter integer IN_W  = 26,
    parameter integer SHIFT = 8,
    parameter integer ROUND = 1,
    parameter integer OUT_W = 16,
    parameter integer LIMIT = 0
) (
    input  wire                    aclk,
    input  wire                    aresetn,
    input  wire                    in_valid,
    input  wire signed [IN_W-1:0]  in_data,
    output reg                     out_valid,
    output reg  signed [OUT_W-1:0] out_data
);
    wire signed [IN_W:0] half = (ROUND != 0 && SHIFT > 0) ? ({{IN_W{1'b0}}, 1'b1} << (SHIFT > 0 ? SHIFT-1 : 0))
                                                          : {(IN_W+1){1'b0}};
    wire signed [IN_W:0] ext  = {in_data[IN_W-1], in_data};
    wire signed [IN_W:0] q    = (ext + half) >>> SHIFT;

    wire signed [IN_W:0] hi = (LIMIT > 0) ?  LIMIT : ((1 <<< (OUT_W-1)) - 1);
    wire signed [IN_W:0] lo = (LIMIT > 0) ? -LIMIT : -(1 <<< (OUT_W-1));

    wire signed [IN_W:0] y = (q > hi) ? hi : (q < lo) ? lo : q;

    always @(posedge aclk) begin
        if (!aresetn) begin
            out_valid <= 1'b0; out_data <= 0;
        end else begin
            out_valid <= in_valid;
            if (in_valid) out_data <= y[OUT_W-1:0];
        end
    end
endmodule
