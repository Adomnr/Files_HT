function S = gen_fm_test_signal(P, opt)
%GEN_FM_TEST_SIGNAL  Generate a narrowband FM test recording as interleaved I/Q.
%
%   S = GEN_FM_TEST_SIGNAL(P) writes data/fm_test_i16.bin or fm_test_i32.bin
%   (per P.IN_W) at 48 kS/s and returns the samples plus the ground truth.
%
%   The recording is: noise only, then an FM carrier, then noise only, so
%   the squelch can be tested. The carrier is modulated by pre-emphasised
%   voice-band tones plus a sub-audible (CTCSS) tone, has a small carrier
%   frequency offset, and the sum of carrier and noise is passed through a
%   12.5 kHz channel filter.
%
%   Name-value options: FileName, Duration, TimeOn, TimeOff, ToneFreqs,
%   CtcssFreq, CtcssDev, PeakDev, FreqOffset, CNR_dB, Amplitude, Seed.

arguments
    P struct
    opt.FileName   (1,:) char   = ''
    opt.Duration   (1,1) double = 3.0             % s
    opt.TimeOn     (1,1) double = 0.5             % carrier on, s
    opt.TimeOff    (1,1) double = 2.5             % carrier off, s
    opt.ToneFreqs  (1,:) double = [400 1000 2500] % voice-band tones, Hz
    opt.CtcssFreq  (1,1) double = 100             % sub-audible tone, Hz
    opt.CtcssDev   (1,1) double = 350             % its deviation, Hz
    opt.PeakDev    (1,1) double = 2500            % total peak deviation, Hz
    opt.FreqOffset (1,1) double = 200             % carrier frequency offset, Hz
    opt.CNR_dB     (1,1) double = 30              % carrier-to-noise in 12.5 kHz
    opt.Amplitude  (1,1) double = 0.5             % carrier amplitude, fraction of full scale
    opt.Seed       (1,1) double = 1
end

fs = P.fs;
n  = round(opt.Duration * fs);
t  = (0:n-1).' / fs;
rs = RandStream('mt19937ar', 'Seed', opt.Seed);

% ---- Message: voice tones, pre-emphasised (+6 dB/octave) ----------------
ph    = 2*pi*rand(rs, 1, numel(opt.ToneFreqs));
m     = sum(sin(2*pi*t*opt.ToneFreqs + ph), 2);
alpha = 1 - exp(-1/(fs*P.DEEMPH_TAU));
mpre  = filter([1, -(1-alpha)]/alpha, 1, m);     % exact inverse of the de-emphasis
mpre(1) = mpre(2);                               % drop the filter start-up spike

voiceDev = opt.PeakDev - opt.CtcssDev;
fdev = voiceDev * mpre / max(abs(mpre)) ...
     + opt.CtcssDev * sin(2*pi*opt.CtcssFreq*t);  % instantaneous deviation, Hz

% ---- FM modulation, carrier keyed on and off ----------------------------
theta = 2*pi*cumsum(opt.FreqOffset + fdev)/fs;
ramp  = 2e-3;                                     % 2 ms raised-cosine edges
env   = min(max((t - opt.TimeOn)/ramp, 0), 1) .* min(max((opt.TimeOff - t)/ramp, 0), 1);
env   = 0.5 - 0.5*cos(pi*env);
sig   = env .* exp(1j*theta);

% ---- Noise and the 12.5 kHz channel filter ------------------------------
chanBw   = 12500;
noiseVar = 10^(-opt.CNR_dB/10) * fs/chanBw;       % total power over fs, carrier power = 1
noise    = sqrt(noiseVar/2) * (randn(rs, n, 1) + 1j*randn(rs, n, 1));
ordCh    = 160;
h        = fir1(ordCh, (chanBw/2)/(fs/2), kaiser(ordCh+1, 7));
r        = filter(h, 1, sig + noise);
delay    = ordCh/2;                               % channel filter delay, samples

% ---- Quantise and write interleaved I/Q, little-endian ------------------
fullScale = 2^(P.IN_W-1) - 1;
I = min(max(round(opt.Amplitude*fullScale*real(r)), -fullScale-1), fullScale);
Q = min(max(round(opt.Amplitude*fullScale*imag(r)), -fullScale-1), fullScale);

fileName = opt.FileName;
if isempty(fileName)
    dataDir = fullfile(fileparts(mfilename('fullpath')), 'data');
    if ~exist(dataDir, 'dir'), mkdir(dataDir); end
    fileName = fullfile(dataDir, sprintf('fm_test_i%d.bin', P.IN_W));
end
fid = fopen(fileName, 'w', 'ieee-le');
assert(fid > 0, 'Cannot create %s', fileName);
fwrite(fid, [I.'; Q.'], sprintf('int%d', P.IN_W));
fclose(fid);

S = struct('fileName', fileName, 'I', I, 'Q', Q, 't', t, ...
           'fdev', fdev, 'toneFreqs', opt.ToneFreqs, 'ctcssFreq', opt.CtcssFreq, ...
           'timeOn', opt.TimeOn + delay/fs, 'timeOff', opt.TimeOff + delay/fs, ...
           'chanDelay', delay, 'opt', opt);
end
