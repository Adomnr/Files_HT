function V = hw_export_vectors(inW, len)
%HW_EXPORT_VECTORS  Write stimulus for the Vivado simulation (tb_fm.sv) and
%   keep the model's answers for HW_COMPARE.
%
%   V = HW_EXPORT_VECTORS(16)            short vectors, 0.25 s (default)
%   V = HW_EXPORT_VECTORS(16, 'full')    3 s receiver / 1.2 s modulator
%   V = HW_EXPORT_VECTORS(32, ...)       the same for I-32
%
%   The Vivado simulator runs the block design at only a few samples per
%   second of wall-clock time, so the short set (12000 samples) is the one
%   for everyday use; the full set takes hours.
%
%   Files go to matlab/data/hw_i<inW>/ :
%     rx_iq.txt      "I Q" per line, the receiver test signal (noise,
%                    carrier with tones, noise - as in RUN_FM_DEMOD_TEST)
%     tx_audio.txt   one sample per line, audio for the modulator
%     expected.mat   model outputs for both

if nargin < 1, inW = 16; end
if nargin < 2, len = 'short'; end
P = fm_params(inW);
outDir = fullfile(fileparts(mfilename('fullpath')), 'data', sprintf('hw_i%d', inW));
if ~exist(outDir, 'dir'), mkdir(outDir); end

switch lower(len)
    case 'full',  rxDur = 3.0;  rxOn = 0.5;  rxOff = 2.5;  txDur = 1.2;  txStep = 1.0;
    case 'short', rxDur = 0.25; rxOn = 0.03; rxOff = 0.19; txDur = 0.25; txStep = 0.2;
    otherwise,    error('len must be ''short'' or ''full''');
end

% ---- receiver test: noise, carrier with tones, noise --------------------
S = gen_fm_test_signal(P, 'Duration', rxDur, 'TimeOn', rxOn, 'TimeOff', rxOff, ...
                       'FileName', fullfile(outDir, 'rx_iq.bin'));
[rxAudio, rxDbg] = fm_demod_fixed(S.I, S.Q, P);

% ---- modulator test: three tones, then 4x the level to hit the limiter --
n   = round(txDur * P.fs);
t   = (0:n-1).' / P.fs;
lvl = 1500 * ones(n,1);
lvl(t >= txStep) = 6000;
txAudio = round(lvl .* (sin(2*pi*400*t) + sin(2*pi*1000*t + 1) + sin(2*pi*2500*t + 2)));
[txI, txQ, txDbg] = fm_mod_fixed(txAudio, P);

% ---- loopback: model modulator output through the model demodulator -----
[lbAudio, lbDbg] = fm_demod_fixed(txI, txQ, P);

write_cols(fullfile(outDir, 'rx_iq.txt'),    [S.I(:) S.Q(:)]);
write_cols(fullfile(outDir, 'tx_audio.txt'), txAudio);

V = struct('inW', inW, 'dir', outDir, 'len', lower(len), ...
           'timeOn', S.timeOn, 'timeOff', S.timeOff, 'txStep', txStep, ...
           'rxI', S.I(:), 'rxQ', S.Q(:), 'rxAudio', rxAudio, 'rxGate', rxDbg.gate, ...
           'txAudio', txAudio, 'txI', txI, 'txQ', txQ, 'txDev', txDbg.dev_hz, ...
           'txLimited', abs(txDbg.pre) > P.MOD_DEV_LIMIT, ...
           'lbAudio', lbAudio, 'lbGate', lbDbg.gate);
save(fullfile(outDir, 'expected.mat'), '-struct', 'V');
% results of an earlier simulation no longer belong to these vectors
old = {'rx_audio_hw.txt', 'tx_iq_hw.txt', 'lb_audio_hw.txt'};
for i = 1:numel(old)
    if exist(fullfile(outDir, old{i}), 'file'), delete(fullfile(outDir, old{i})); end
end
fprintf('I-%d %s vectors in %s: %d receiver samples, %d modulator samples\n', ...
        inW, lower(len), outDir, numel(S.I), n);
fprintf('  receiver: squelch opens at sample %d, closes at sample %d\n', ...
        find(rxDbg.gate, 1), find(rxDbg.gate, 1, 'last') + 1);
fprintf('  modulator: peak deviation %.0f Hz, limiter active on %d samples\n', ...
        max(abs(txDbg.dev_hz)), nnz(V.txLimited));
end

function write_cols(fileName, M)
fid = fopen(fileName, 'w');
assert(fid > 0, 'Cannot open %s', fileName);
fmt = [repmat('%d ', 1, size(M,2)-1) '%d\n'];
fprintf(fid, fmt, M.');
fclose(fid);
end
