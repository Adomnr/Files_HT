function [I, Q, dbg] = fm_mod_fixed(audio, P)
%FM_MOD_FIXED  Fixed-point model of the FM modulator (mirror of FM_DEMOD_FIXED).
%
%   [I, Q, dbg] = FM_MOD_FIXED(audio, P)
%
%   audio  16-bit signed samples at P.fs, same scaling as the demodulator
%          output, so modulator -> demodulator has unity gain in the pass band
%   I, Q   P.IN_W-bit carrier samples, amplitude 2^(IN_W-2) (half scale)
%
%   Chain: 300 Hz HPF -> 3 kHz LPF (same biquads as the receiver)
%          -> pre-emphasis (2-tap FIR, inverse of the de-emphasis)
%          -> deviation limiter -> phase accumulator -> cos/sin
%
%   Everything up to and including the phase accumulator is bit-exact with
%   the block design. The last step uses ideal cos/sin; the CORDIC IP in the
%   hardware agrees with it to within a few LSB.

x = double(audio(:));
G = P.BQ_GUARD;
W = P.AUDIO_W + G;

% ---- band filters ----------------------------------------------------
v  = x * 2^G;
bq = zeros(numel(x), size(P.SOS_INT,1));
for s = 1:size(P.SOS_INT,1)
    v = biquad_fixed(v, P.SOS_INT(s,:), P.BQ_COEF_FRAC, W);
    bq(:,s) = v;
end
y = floor((v + 2^(G-1)) / 2^G);
y = min(max(y, -2^(P.AUDIO_W-1)), 2^(P.AUDIO_W-1) - 1);

% ---- pre-emphasis: output is the frequency word ------------------------
pre = P.MOD_PRE_COEFS(1) * y + P.MOD_PRE_COEFS(2) * [0; y(1:end-1)];

% ---- deviation limiter --------------------------------------------------
fw = min(max(pre, -P.MOD_DEV_LIMIT), P.MOD_DEV_LIMIT);

% ---- phase accumulator, wraps at one cycle ------------------------------
half  = 2^(P.MOD_ACC_W-1);
phase = mod(cumsum(fw) + half, 2*half) - half;

% ---- carrier ------------------------------------------------------------
th = phase * (pi / half);
I  = round(P.MOD_AMPL * cos(th));
Q  = round(P.MOD_AMPL * sin(th));

dbg = struct('bq', bq, 'audio_bp', y, 'pre', pre, 'fw', fw, 'phase', phase, ...
             'dev_hz', fw * P.MOD_HZ_PER_LSB);
end
