function R = run_fm_demod_test(inW)
%RUN_FM_DEMOD_TEST  Generate a test recording, demodulate it, and check the result.
%
%   R = RUN_FM_DEMOD_TEST(16)   test with an I-16 interleaved recording
%   R = RUN_FM_DEMOD_TEST(32)   test with an I-32 interleaved recording
%
%   Writes to matlab/results: a figure (PNG) and the demodulated audio (WAV).
%   R.pass is true when every check passes.

if nargin < 1, inW = 16; end
P      = fm_params(inW);
fs     = P.fs;
here   = fileparts(mfilename('fullpath'));
outDir = fullfile(here, 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end

fprintf('\n=== FM demodulator model test, I-%d input ===\n', inW);

% ---- Generate, read back, demodulate ------------------------------------
S      = gen_fm_test_signal(P);
[I, Q] = read_iq_interleaved(S.fileName, inW);
[aFix, dF] = fm_demod_fixed(I, Q, P);
[aRef, dR] = fm_demod_float(I, Q, P);
t      = S.t;
n      = numel(t);
steady = t >= S.timeOn + 0.1 & t < S.timeOff - 0.05;   % carrier present, filters settled

R = struct('inW', inW, 'checks', {{}}, 'pass', true);

% ---- Check 1: file round trip -------------------------------------------
R = check(R, 'File read-back matches generated samples', ...
          double(~(isequal(I, S.I) && isequal(Q, S.Q))), 'mismatches', '== 0', @(v) v == 0);

% ---- Check 2: CORDIC phase and magnitude against atan2 / abs ------------
strong  = dF.mag >= P.SQ_TH_OPEN;
phFix   = dF.phase * pi / 2^(P.PHASE_W-1);
phErr   = angle(exp(1j*(phFix(strong) - atan2(Q(strong), I(strong)))));
magTrue = hypot(I(strong), Q(strong));
magErr  = abs(dF.mag(strong)/P.CORDIC_GAIN - magTrue) ./ magTrue;
R = check(R, 'CORDIC phase error, max', max(abs(phErr)), 'rad', '< 1e-4', @(v) v < 1e-4);
R = check(R, 'CORDIC phase error, rms', rms(phErr),      'rad', '< 3e-5', @(v) v < 3e-5);
R = check(R, 'CORDIC magnitude error, max', 100*max(magErr), '%', '< 0.1', @(v) v < 0.1);

% ---- Check 3: squelch opens and closes with the carrier -----------------
iOpen  = find(diff([false; dF.gate]) == 1);
iClose = find(diff([dF.gate; false]) == -1);
R = check(R, 'Squelch open intervals', numel(iOpen), '', '== 1', @(v) v == 1);
if numel(iOpen) == 1 && numel(iClose) == 1
    dOpen  = 1e3*((iOpen  - 1)/fs - S.timeOn);
    dClose = 1e3*((iClose - 1)/fs - S.timeOff);
else
    dOpen = NaN; dClose = NaN;
end
R = check(R, 'Squelch open delay after carrier on',   dOpen,  'ms', '0 to 20', @(v) v >= 0 && v <= 20);
R = check(R, 'Squelch close delay after carrier off', dClose, 'ms', '0 to 30', @(v) v >= 0 && v <= 30);
quiet = t < S.timeOn - 0.01 | t > S.timeOff + 0.2;
R = check(R, 'Audio output while muted, max', max(abs(aFix(quiet))), 'LSB', '== 0', @(v) v == 0);

% ---- Check 4: fixed point against floating point ------------------------
errFF = aFix(steady) - aRef(steady);
snrFF = 10*log10(sum(aRef(steady).^2) / sum(errFF.^2));
R = check(R, 'Fixed vs float audio, SNR', snrFF, 'dB', '> 60', @(v) v > 60);
R = check(R, 'Fixed vs float audio, max error', max(abs(errFF)), 'LSB', '< 8', @(v) v < 8);

% ---- Check 5: quantised filter response against the ideal design --------
fBand  = (P.HPF_FC:10:P.LPF_FC).';
hIdeal = chain_response(P, fBand, false);
hQuant = chain_response(P, fBand, true);
R = check(R, 'Coefficient quantisation, max response error 300-3000 Hz', ...
          max(abs(20*log10(abs(hQuant./hIdeal)))), 'dB', '< 0.1', @(v) v < 0.1);

% ---- Check 6: recovered tone levels against prediction ------------------
fTones  = [S.ctcssFreq, S.toneFreqs];
tw      = t(steady);
devAmp  = tone_fit(S.fdev(steady), tw, fTones);                 % transmitted, Hz
discAmp = devAmp / P.DISC_FS_HZ * 2^(P.AUDIO_W-1);              % at discriminator, LSB
[outAmp, resFix] = tone_fit(aFix(steady), tw, fTones);          % measured, LSB
[~,      resRef] = tone_fit(aRef(steady), tw, fTones);
gainMeas = 20*log10(outAmp ./ discAmp);
gainPred = 20*log10(abs(chain_response(P, fTones(:), false))).';
for k = 2:numel(fTones)
    R = check(R, sprintf('Tone %4d Hz gain error (predicted %+.2f dB)', fTones(k), gainPred(k)), ...
              gainMeas(k) - gainPred(k), 'dB', '|x| < 0.2', @(v) abs(v) < 0.2);
end
R = check(R, sprintf('Sub-audible %d Hz gain error (predicted %+.2f dB)', fTones(1), gainPred(1)), ...
          gainMeas(1) - gainPred(1), 'dB', '|x| < 1', @(v) abs(v) < 1);

% ---- Check 7: output quality --------------------------------------------
pVoice   = sum(outAmp(2:end).^2)/2;
sinadFix = 10*log10(pVoice / mean(resFix.^2));
sinadRef = 10*log10(pVoice / mean(resRef.^2));
R = check(R, 'Audio SINAD, fixed point', sinadFix, 'dB', '> 20', @(v) v > 20);
R = check(R, 'SINAD loss, fixed vs float', sinadRef - sinadFix, 'dB', '< 0.1', @(v) v < 0.1);

% ---- Outputs -------------------------------------------------------------
wavFile = fullfile(outDir, sprintf('audio_out_i%d.wav', inW));
audiowrite(wavFile, aFix/2^(P.AUDIO_W-1), fs, 'BitsPerSample', 16);
pngFile = fullfile(outDir, sprintf('fm_demod_i%d.png', inW));
make_figure(pngFile, P, S, I, Q, aFix, dF, steady, fTones, gainMeas);

R.gateMatchesFloat = isequal(dF.gate, dR.gate);
R.wavFile = wavFile;
R.pngFile = pngFile;
R.audio   = aFix;
R.dbg     = dF;
if R.pass, verdict = 'ALL CHECKS PASSED'; else, verdict = 'SOME CHECKS FAILED'; end
fprintf('--- %s (%d samples, %.1f s) ---\n', verdict, n, n/fs);
end

% =========================================================================
function R = check(R, name, value, unit, limit, okFcn)
ok = okFcn(value);
if ok, tag = 'PASS'; else, tag = 'FAIL'; end
fprintf('  [%s] %-58s %12.4g %-10s (limit %s)\n', tag, name, value, unit, limit);
R.checks(end+1,:) = {name, value, unit, limit, ok};
R.pass = R.pass && ok;
end

% =========================================================================
function h = chain_response(P, f, quantised)
%CHAIN_RESPONSE  Response from discriminator output to audio output at f (Hz).
w = 2*pi*f(:)/P.fs;
z = exp(1j*w);
if quantised
    alpha = P.DEEMPH_ALPHA / 2^P.DEEMPH_FRAC;
    c     = P.SOS_INT / 2^P.BQ_COEF_FRAC;
    sos   = [c(:,1:3), ones(size(c,1),1), c(:,4:5)];
    g     = 1;
else
    alpha = 1 - exp(-1/(P.fs*P.DEEMPH_TAU));
    sos   = [P.HPF_SOS; P.LPF_SOS];
    g     = P.HPF_G * P.LPF_G;
end
h = g * 2^P.DEEMPH_GAIN_LOG2 * alpha ./ (1 - (1-alpha)./z);
for k = 1:size(sos,1)
    h = h .* (sos(k,1) + sos(k,2)./z + sos(k,3)./z.^2) ./ (sos(k,4) + sos(k,5)./z + sos(k,6)./z.^2);
end
end

% =========================================================================
function [amp, resid] = tone_fit(x, t, f)
%TONE_FIT  Least-squares amplitudes of tones at frequencies f, plus residual.
A     = [cos(2*pi*t*f(:).'), sin(2*pi*t*f(:).'), ones(numel(t),1)];
c     = A \ x;
nf    = numel(f);
amp   = hypot(c(1:nf), c(nf+1:2*nf)).';
resid = x - A*c;
end

% =========================================================================
function make_figure(pngFile, P, S, I, Q, aFix, dF, steady, fTones, gainMeas)
fs   = P.fs;
t    = S.t;
blue = [42 120 214]/255;  orange = [235 104 52]/255;
ink  = [11 11 11]/255;    ink2 = [82 81 78]/255;   surface = [252 252 251]/255;

fig = figure('Visible', 'off', 'Color', surface, 'Position', [50 50 1500 1050]);
tl  = tiledlayout(fig, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, sprintf('FM demodulator fixed-point model, I-%d input, 48 kS/s', P.IN_W), ...
      'FontName', 'Segoe UI', 'FontWeight', 'bold', 'Color', ink);

% 1. Input spectrum
ax = nexttile(tl);
x  = complex(I(steady), Q(steady)) / 2^(P.IN_W-1);
[pxx, f] = pwelch(x, hann(4096), 2048, 4096, fs, 'centered', 'power');
plot(ax, f/1e3, 10*log10(pxx), 'Color', blue, 'LineWidth', 1.2);
style(ax, 'Input I/Q spectrum while the carrier is on', 'Frequency, kHz', 'Power, dBFS');
xlim(ax, [-24 24]);

% 2. Squelch level and thresholds
ax  = nexttile(tl);
ref = 2^(P.IN_W-1) * P.CORDIC_GAIN;
lv  = 20*log10(max(dF.level, 1) / ref);
on  = t(dF.gate);
hold(ax, 'on');
if ~isempty(on)
    patch(ax, [on(1) on(end) on(end) on(1)], [-60 -60 0 0], blue, ...
          'FaceAlpha', 0.10, 'EdgeColor', 'none');
    text(ax, mean([on(1) on(end)]), -55, 'squelch open', 'Color', ink2, ...
         'HorizontalAlignment', 'center', 'FontName', 'Segoe UI');
end
plot(ax, t, lv, 'Color', blue, 'LineWidth', 1.2);
yline(ax, 20*log10(P.SQ_OPEN_FRAC),  '--', 'open threshold',  'Color', ink2, ...
      'LabelHorizontalAlignment', 'left', 'FontName', 'Segoe UI');
yline(ax, 20*log10(P.SQ_CLOSE_FRAC), '--', 'close threshold', 'Color', ink2, ...
      'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom', 'FontName', 'Segoe UI');
style(ax, 'Squelch: averaged signal level', 'Time, s', 'Level, dBFS');
ylim(ax, [-60 0]);

% 3. Discriminator output around carrier turn-on
ax  = nexttile(tl);
win = t >= S.timeOn - 0.01 & t < S.timeOn + 0.02;
plot(ax, 1e3*(t(win) - S.timeOn), dF.disc(win) * P.DISC_FS_HZ / 2^(P.AUDIO_W-1) / 1e3, ...
     'Color', blue, 'LineWidth', 1.0);
style(ax, 'Discriminator output at carrier turn-on (before squelch)', ...
      'Time from carrier on, ms', 'Frequency deviation, kHz');

% 4. Audio output, whole recording
ax = nexttile(tl);
plot(ax, t, aFix, 'Color', blue, 'LineWidth', 0.6);
style(ax, 'Audio output (16-bit)', 'Time, s', 'Amplitude, LSB');
ylim(ax, [-32768 32767]);

% 5. Audio spectrum
ax = nexttile(tl);
[pa, fa] = pwelch(aFix(steady) / 2^(P.AUDIO_W-1), hann(8192), 4096, 8192, fs, 'power');
plot(ax, fa/1e3, 10*log10(pa), 'Color', blue, 'LineWidth', 1.2);
style(ax, 'Audio output spectrum while the carrier is on', 'Frequency, kHz', 'Power, dBFS');
xlim(ax, [0 8]);  ylim(ax, [-120 0]);

% 6. Predicted response and measured tone gains
ax = nexttile(tl);
fc = logspace(log10(50), log10(10000), 400).';
semilogx(ax, fc, 20*log10(abs(chain_response(P, fc, true))), 'Color', blue, 'LineWidth', 1.5);
hold(ax, 'on');
semilogx(ax, fTones, gainMeas, 'o', 'Color', orange, 'MarkerFaceColor', orange, ...
         'MarkerEdgeColor', surface, 'MarkerSize', 8, 'LineWidth', 1.5);
style(ax, 'De-emphasis + 300 Hz HPF + 3 kHz LPF: gain', 'Frequency, Hz', 'Gain, dB');
xlim(ax, [50 10000]);  ylim(ax, [-80 20]);
lg = legend(ax, {'predicted (quantised coefficients)', 'measured on test tones'}, ...
            'Location', 'south', 'Box', 'off', 'FontName', 'Segoe UI');
lg.TextColor = ink;

exportgraphics(fig, pngFile, 'Resolution', 110);
close(fig);
end

% =========================================================================
function style(ax, ttl, xl, yl)
ink = [11 11 11]/255;  ink2 = [82 81 78]/255;
set(ax, 'Color', [252 252 251]/255, 'Box', 'off', 'FontName', 'Segoe UI', 'FontSize', 9, ...
        'XColor', ink2, 'YColor', ink2, 'GridColor', [225 224 217]/255, 'GridAlpha', 1, ...
        'XGrid', 'on', 'YGrid', 'on', 'XMinorGrid', 'off', 'YMinorGrid', 'off', ...
        'TickDir', 'out', 'Layer', 'bottom');
title(ax, ttl, 'FontWeight', 'normal', 'Color', ink, 'FontSize', 10);
ax.TitleHorizontalAlignment = 'left';
xlabel(ax, xl, 'Color', ink2);
ylabel(ax, yl, 'Color', ink2);
end
