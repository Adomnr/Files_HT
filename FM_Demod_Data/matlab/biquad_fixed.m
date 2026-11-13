function y = biquad_fixed(x, c, frac, dataW)
%BIQUAD_FIXED  Direct-form-I biquad, integer coefficients c = [b0 b1 b2 a1 a2].
%   y[n] = fix((b0 x[n] + b1 x[n-1] + b2 x[n-2] - a1 y[n-1] - a2 y[n-2]) / 2^frac)
%
%   The quotient is truncated toward zero, not rounded. With rounding, the
%   300 Hz high-pass sections (poles very close to z = 1) hold a small DC
%   value forever once the input goes quiet, so a muted output sits at
%   -1 LSB instead of 0. Truncating toward zero always shrinks the state,
%   so it decays to exactly 0.
%   In RTL (iir_biquad.v): add (2^frac - 1) to acc when acc is negative,
%   then shift right.

n  = numel(x);
y  = zeros(n,1);
x1 = 0; x2 = 0; y1 = 0; y2 = 0;
ymax = 2^(dataW-1) - 1;
ymin = -2^(dataW-1);
for k = 1:n
    acc = c(1)*x(k) + c(2)*x1 + c(3)*x2 - c(4)*y1 - c(5)*y2;
    yk  = fix(acc / 2^frac);
    yk  = min(max(yk, ymin), ymax);
    x2 = x1;  x1 = x(k);
    y2 = y1;  y1 = yk;
    y(k) = yk;
end
end
