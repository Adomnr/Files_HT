function [audio, dbg] = fm_demod_fixed(I, Q, P)
%FM_DEMOD_FIXED  Bit-accurate fixed-point model of the FM demodulator.
%
%   [audio, dbg] = FM_DEMOD_FIXED(I, Q, P)
%
%   I, Q   integer-valued input samples (P.IN_W bits each)
%   P      parameters from FM_PARAMS
%   audio  16-bit signed output samples (integer-valued doubles)
%   dbg    output of every stage, for comparison against RTL simulation
%
%   All values are integers held in doubles. Every operation is an add, a
%   subtract, an integer multiply or a floor-divide by a power of two (an
%   arithmetic right shift), so the results are exact and map one-to-one
%   onto hardware. The widest intermediate is under 2^53.

I = double(I(:));
Q = double(Q(:));
n = numel(I);

% ---- 1. CORDIC: phase and magnitude ------------------------------------
[phase, mag] = cordic_vectoring(I, Q, P);

% ---- 2. Phase difference, wrapped to PHASE_W bits -----------------------
half = 2^(P.PHASE_W-1);
dphi = phase - [0; phase(1:end-1)];
dphi = mod(dphi + half, 2*half) - half;                 % two's-complement wrap
disc = sat(floor(dphi / 2^P.DISC_SHIFT), P.AUDIO_W);    % 16-bit, full scale = 6 kHz

% ---- 3. Squelch: averaged magnitude, thresholds with hysteresis --------
K     = P.SQ_AVG_LOG2;
level = zeros(n,1);
gate  = false(n,1);
acc   = 0;
open  = false;
for k = 1:n
    acc = acc + mag(k) - floor(acc / 2^K);
    lv  = floor(acc / 2^K);
    if open
        if lv <  P.SQ_TH_CLOSE, open = false; end
    else
        if lv >= P.SQ_TH_OPEN,  open = true;  end
    end
    level(k) = lv;
    gate(k)  = open;
end
sq = disc .* gate;                                      % muted when closed

% ---- 4. De-emphasis (one pole), make-up gain of 4 ----------------------
F   = P.DEEMPH_FRAC;
de  = zeros(n,1);
acc = 0;
for k = 1:n
    acc   = acc + P.DEEMPH_ALPHA * (sq(k) - floor(acc / 2^F));
    de(k) = floor(acc / 2^(F - P.DEEMPH_GAIN_LOG2));
end
de = sat(de, P.DEEMPH_OUT_W);

% ---- 5. 300 Hz HPF then 3 kHz LPF: cascade of biquads ------------------
G     = P.BQ_GUARD;
nSec  = size(P.SOS_INT, 1);
bq    = zeros(n, nSec);
x     = de * 2^G;                                       % add guard bits
for s = 1:nSec
    x = biquad_fixed(x, P.SOS_INT(s,:), P.BQ_COEF_FRAC, P.BQ_DATA_W);
    bq(:,s) = x;
end
audio = sat(floor((x + 2^(G-1)) / 2^G), P.AUDIO_W);     % round off guard bits

dbg = struct('phase', phase, 'mag', mag, 'dphi', dphi, 'disc', disc, ...
             'level', level, 'gate', gate, 'sq', sq, 'deemph', de, ...
             'bq', bq, 'audio', audio);
end

% =========================================================================
function [z, mag] = cordic_vectoring(I, Q, P)
%CORDIC_VECTORING  Phase and magnitude of I + jQ by shift-and-add rotations.
%   z    phase, signed PHASE_W bits, 2^(PHASE_W-1) = pi
%   mag  magnitude in input LSBs, scaled by the CORDIC gain (1.6468)

x = I * 2^P.CORDIC_GUARD;
y = Q * 2^P.CORDIC_GUARD;

% Move left-half-plane vectors into the right half plane (rotate by pi).
neg    = x < 0;
x(neg) = -x(neg);
y(neg) = -y(neg);
z      = zeros(size(x));
z(neg) = -2^(P.PHASE_W-1);

for i = 0:P.CORDIC_ITER-1
    d  = 2*(y >= 0) - 1;            % +1: rotate clockwise, -1: anticlockwise
    xs = floor(x / 2^i);            % arithmetic right shifts
    ys = floor(y / 2^i);
    x  = x + d .* ys;
    y  = y - d .* xs;
    z  = z + d * P.ATAN_TAB(i+1);
end

half = 2^(P.PHASE_W-1);
z    = mod(z + half, 2*half) - half;        % PHASE_W-bit register wraps
mag  = floor(x / 2^P.CORDIC_GUARD);
end

% =========================================================================
function v = sat(v, w)
%SAT  Saturate to a signed w-bit range.
v = min(max(v, -2^(w-1)), 2^(w-1) - 1);
end
