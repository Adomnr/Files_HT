function P = fm_params(inW)
%FM_PARAMS  Design parameters of the FM demodulator (single source of truth).
%
%   P = FM_PARAMS(16)   input samples are I-16 interleaved I/Q
%   P = FM_PARAMS(32)   input samples are I-32 interleaved I/Q
%
%   Every word length, shift and integer coefficient the RTL needs is in P.
%
%   Processing chain (all at 48 kS/s):
%     I/Q -> CORDIC (phase, magnitude) -> phase difference -> squelch
%         -> de-emphasis -> 300 Hz HPF -> 3 kHz LPF -> 16-bit audio

if nargin < 1, inW = 16; end
assert(inW == 16 || inW == 32, 'Input width must be 16 or 32 bits.');

P.fs   = 48000;          % sample rate, Hz
P.IN_W = inW;            % input word length of I and of Q

% ---- CORDIC, vectoring mode -------------------------------------------
P.CORDIC_ITER  = 16;                          % micro-rotations
P.CORDIC_GUARD = 4;                           % fractional guard bits on x/y
P.XY_W         = inW + 2 + P.CORDIC_GUARD;    % x/y register width (2 bits of growth)
P.PHASE_W      = 20;                          % signed phase, 2^(PHASE_W-1) = pi
P.CORDIC_GAIN  = prod(sqrt(1 + 2.^(-2*(0:P.CORDIC_ITER-1))));   % 1.6468
P.ATAN_TAB     = round(atan(2.^-(0:P.CORDIC_ITER-1)) / pi * 2^(P.PHASE_W-1));

% ---- Discriminator (phase difference) ---------------------------------
P.AUDIO_W        = 16;
P.DISC_GAIN_LOG2 = 2;                                        % gain of 4
P.DISC_SHIFT     = P.PHASE_W - P.AUDIO_W - P.DISC_GAIN_LOG2; % right shift of dphi
P.DISC_FS_HZ     = (P.fs/2) / 2^P.DISC_GAIN_LOG2;            % deviation at full scale: 6 kHz

% ---- Squelch (signal level from the CORDIC magnitude) -----------------
P.SQ_AVG_LOG2   = 8;        % level average: time constant 2^8 samples = 5.3 ms
P.SQ_OPEN_FRAC  = 0.125;    % open  when level >= this fraction of input full scale
P.SQ_CLOSE_FRAC = 0.0625;   % close when level <  this fraction of input full scale
% Threshold registers are in CORDIC magnitude units (input LSB x CORDIC gain).
P.SQ_TH_OPEN    = round(P.SQ_OPEN_FRAC  * 2^(inW-1) * P.CORDIC_GAIN);
P.SQ_TH_CLOSE   = round(P.SQ_CLOSE_FRAC * 2^(inW-1) * P.CORDIC_GAIN);
% The block design uses the Xilinx CORDIC IP, whose micro-rotations start at
% i = 1 (after its coarse rotation), so its gain is 1.1644 instead of 1.6468.
% Same fractions of full scale, different register values (build_bd.tcl).
P.HW_CORDIC_GAIN  = prod(sqrt(1 + 2.^(-2*(1:23))));                       % 1.1644
P.HW_SQ_TH_OPEN   = round(P.SQ_OPEN_FRAC  * 2^(inW-1) * P.HW_CORDIC_GAIN);
P.HW_SQ_TH_CLOSE  = round(P.SQ_CLOSE_FRAC * 2^(inW-1) * P.HW_CORDIC_GAIN);

% ---- De-emphasis: y[n] = y[n-1] + alpha*(x[n] - y[n-1]) ---------------
P.DEEMPH_TAU       = 750e-6;   % time constant, s (corner 212 Hz)
P.DEEMPH_FRAC      = 16;       % fractional bits of alpha and of the accumulator
P.DEEMPH_ALPHA     = round((1 - exp(-1/(P.fs*P.DEEMPH_TAU))) * 2^P.DEEMPH_FRAC);
P.DEEMPH_GAIN_LOG2 = 2;        % make-up gain of 4 (about unity at 1 kHz)
P.DEEMPH_OUT_W     = P.AUDIO_W + P.DEEMPH_GAIN_LOG2;   % 18 bits

% ---- 300 Hz high-pass and 3 kHz low-pass (Butterworth biquads) --------
P.HPF_FC       = 300;
P.LPF_FC       = 3000;
P.FILT_ORDER   = 4;                              % per filter -> 2 biquads each
P.BQ_COEF_FRAC = 16;                             % coefficients are signed Q2.16 (18 bits)
P.BQ_GUARD     = 8;                              % fractional guard bits on biquad data
P.BQ_DATA_W    = P.DEEMPH_OUT_W + P.BQ_GUARD;    % 26 bits

[zh, ph, kh] = butter(P.FILT_ORDER, P.HPF_FC/(P.fs/2), 'high');
[zl, pl, kl] = butter(P.FILT_ORDER, P.LPF_FC/(P.fs/2), 'low');
[P.HPF_SOS, P.HPF_G] = zp2sos(zh, ph, kh);       % ideal (unquantised) design
[P.LPF_SOS, P.LPF_G] = zp2sos(zl, pl, kl);

% Integer coefficients, one row per biquad: [b0 b1 b2 a1 a2].
% The zeros are kept exactly at DC (HPF) or Nyquist (LPF) by deriving b
% from the quantised a, with each section normalised to unity passband gain.
S  = 2^P.BQ_COEF_FRAC;
nH = size(P.HPF_SOS, 1);
nL = size(P.LPF_SOS, 1);
P.SOS_INT = zeros(nH + nL, 5);
for k = 1:nH
    a1 = round(P.HPF_SOS(k,5)*S);  a2 = round(P.HPF_SOS(k,6)*S);
    b0 = round((S - a1 + a2)/4);
    P.SOS_INT(k,:) = [b0, -2*b0, b0, a1, a2];
end
for k = 1:nL
    a1 = round(P.LPF_SOS(k,5)*S);  a2 = round(P.LPF_SOS(k,6)*S);
    b0 = round((S + a1 + a2)/4);
    P.SOS_INT(nH+k,:) = [b0, 2*b0, b0, a1, a2];
end
assert(all(abs(P.SOS_INT(:)) < 2^(P.BQ_COEF_FRAC+1)), 'Biquad coefficient does not fit Q2.16.');

% ---- Modulator (mirror of the demodulator) -------------------------------
% Audio scaling is chosen so that modulator -> demodulator has unity gain:
% the frequency word is pre(x) * 2^(MOD_ACC_W-20), with 2^MOD_ACC_W = one
% cycle. With MOD_ACC_W = 28 and the pre-emphasis scaled by 2^8 the FIR
% output is the frequency word directly, no multiplier needed.
P.MOD_ACC_W     = 28;                               % phase accumulator bits
P.MOD_PRE_FRAC  = P.MOD_ACC_W - P.PHASE_W;          % 8
a               = P.DEEMPH_ALPHA / 2^P.DEEMPH_FRAC;
c               = round((1 - a)/a * 2^P.MOD_PRE_FRAC);
P.MOD_PRE_COEFS = [2^P.MOD_PRE_FRAC + c, -c];       % [9347 -9091]
P.MOD_MAX_DEV   = 2500;                             % deviation limiter, Hz
P.MOD_DEV_LIMIT = round(P.MOD_MAX_DEV / P.fs * 2^P.MOD_ACC_W);   % 13981013
P.MOD_HZ_PER_LSB = P.fs / 2^P.MOD_ACC_W;            % frequency word LSB, Hz
P.MOD_AMPL      = 2^(inW-2);                        % carrier amplitude = half scale
end
