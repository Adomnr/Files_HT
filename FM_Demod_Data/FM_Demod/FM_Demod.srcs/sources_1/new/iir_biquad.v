`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// iir_biquad - one direct-form-I second-order section, integer coefficients.
//
//   y[n] = fix( (B0*x[n] + B1*x[n-1] + B2*x[n-2] - A1*y[n-1] - A2*y[n-2]) / 2^FRAC )
//
// Bit-accurate with biquad_fixed() in matlab/fm_demod_fixed.m:
//   * the quotient is truncated toward zero (not floored, not rounded) so the
//     state always decays to exactly 0 when the input goes quiet;
//   * the result saturates to DATA_W bits.
//
// One multiplier is shared by the five products (one product per clock), so a
// sample takes 8 clocks. in_valid must not be asserted more often than that.
// Outputs are registered and held until the next sample.
// -----------------------------------------------------------------------------
module iir_biquad #(
    parameter integer DATA_W = 26,       // data word length (signed)
    parameter integer COEF_W = 18,       // coefficient word length (signed)
    parameter integer FRAC   = 16,       // fractional bits of the coefficients
    parameter integer B0     = 65536,
    parameter integer B1     = 0,
    parameter integer B2     = 0,
    parameter integer A1     = 0,
    parameter integer A2     = 0
) (
    input  wire                     aclk,
    input  wire                     aresetn,
    input  wire                     in_valid,
    input  wire signed [DATA_W-1:0] in_data,
    output reg                      out_valid,
    output reg  signed [DATA_W-1:0] out_data
);
    localparam integer PROD_W = DATA_W + COEF_W;
    localparam integer ACC_W  = PROD_W + 3;          // sum of five products

    wire signed [COEF_W-1:0] c_b0 = B0;
    wire signed [COEF_W-1:0] c_b1 = B1;
    wire signed [COEF_W-1:0] c_b2 = B2;
    wire signed [COEF_W-1:0] c_a1 = -A1;
    wire signed [COEF_W-1:0] c_a2 = -A2;

    reg signed [DATA_W-1:0] x0, x1, x2, y1, y2;

    // stage A: operand select, stage B: multiply, stage C: accumulate
    reg        run;
    reg  [2:0] sel;
    reg        va, vb, la, lb, done;
    reg signed [COEF_W-1:0] mc;
    reg signed [DATA_W-1:0] md;
    reg signed [PROD_W-1:0] prod;
    reg signed [ACC_W-1:0]  acc;

    // truncate toward zero: add (2^FRAC - 1) to a negative sum before shifting
    wire signed [ACC_W-1:0] bias  = acc[ACC_W-1] ? {{(ACC_W-FRAC){1'b0}}, {FRAC{1'b1}}}
                                                 : {ACC_W{1'b0}};
    wire signed [ACC_W-1:0] quo   = (acc + bias) >>> FRAC;
    wire                    ovf_p = ~quo[ACC_W-1] &  (|quo[ACC_W-2:DATA_W-1]);
    wire                    ovf_n =  quo[ACC_W-1] & ~(&quo[ACC_W-2:DATA_W-1]);
    wire signed [DATA_W-1:0] y_sat = ovf_p ? {1'b0, {(DATA_W-1){1'b1}}} :
                                     ovf_n ? {1'b1, {(DATA_W-1){1'b0}}} :
                                             quo[DATA_W-1:0];

    always @(posedge aclk) begin
        if (!aresetn) begin
            x0 <= 0; x1 <= 0; x2 <= 0; y1 <= 0; y2 <= 0;
            run <= 1'b0; sel <= 3'd0;
            va <= 1'b0; vb <= 1'b0; la <= 1'b0; lb <= 1'b0; done <= 1'b0;
            mc <= 0; md <= 0; prod <= 0; acc <= 0;
            out_valid <= 1'b0; out_data <= 0;
        end else begin
            out_valid <= 1'b0;

            // new sample: shift the input history, start the five products
            if (in_valid) begin
                x2  <= x1;
                x1  <= x0;
                x0  <= in_data;
                run <= 1'b1;
                sel <= 3'd0;
            end else if (run) begin
                sel <= sel + 3'd1;
                if (sel == 3'd4) run <= 1'b0;
            end

            // stage A
            va <= run;
            la <= run && (sel == 3'd4);
            case (sel)
                3'd0:    begin mc <= c_b0; md <= x0; end
                3'd1:    begin mc <= c_b1; md <= x1; end
                3'd2:    begin mc <= c_b2; md <= x2; end
                3'd3:    begin mc <= c_a1; md <= y1; end
                default: begin mc <= c_a2; md <= y2; end
            endcase

            // stage B
            vb   <= va;
            lb   <= la;
            prod <= mc * md;

            // stage C
            done <= lb;
            if (vb) acc <= acc + prod;

            // result
            if (done) begin
                y2        <= y1;
                y1        <= y_sat;
                out_data  <= y_sat;
                out_valid <= 1'b1;
                acc       <= 0;
            end
        end
    end
endmodule
