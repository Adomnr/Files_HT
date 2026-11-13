function [audio, dbg] = fm_demod_float(I, Q, P)
%FM_DEMOD_FLOAT  Floating-point reference for FM_DEMOD_FIXED.
%
%   Same algorithm and the same (quantised) filter coefficients as the
%   fixed-point model, but with exact atan2 and no rounding of data. The
%   difference between the two outputs is therefore the arithmetic error
%   of the fixed-point design. Output is in 16-bit LSB units, not rounded.

I = double(I(:));
Q = double(Q(:));
n = numel(I);
s = complex(I, Q);

% 1-2. Phase and wrapped phase difference
phase = angle(s);
dphi  = angle(s .* conj([1; s(1:end-1)]));
disc  = dphi / pi * 2^(P.AUDIO_W - 1 + P.DISC_GAIN_LOG2);
disc  = min(max(disc, -2^(P.AUDIO_W-1)), 2^(P.AUDIO_W-1) - 1);

% 3. Squelch
a     = 2^-P.SQ_AVG_LOG2;
mag   = abs(s) * P.CORDIC_GAIN;
level = filter(a, [1, -(1-a)], mag);
gate  = false(n,1);
open  = false;
for k = 1:n
    if open
        if level(k) <  P.SQ_TH_CLOSE, open = false; end
    else
        if level(k) >= P.SQ_TH_OPEN,  open = true;  end
    end
    gate(k) = open;
end
sq = disc .* gate;

% 4. De-emphasis
alpha = P.DEEMPH_ALPHA / 2^P.DEEMPH_FRAC;
de    = 2^P.DEEMPH_GAIN_LOG2 * filter(alpha, [1, -(1-alpha)], sq);

% 5. Band filters, using the quantised coefficients
x = de;
c = P.SOS_INT / 2^P.BQ_COEF_FRAC;
for k = 1:size(c,1)
    x = filter(c(k,1:3), [1, c(k,4:5)], x);
end
audio = x;

dbg = struct('phase', phase, 'mag', mag, 'dphi', dphi, 'disc', disc, ...
             'level', level, 'gate', gate, 'sq', sq, 'deemph', de, 'audio', audio);
end
