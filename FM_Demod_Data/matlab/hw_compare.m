function R = hw_compare(inW)
%HW_COMPARE  Check the Vivado simulation results against the MATLAB models.
%
%   R = HW_COMPARE(16)   or   HW_COMPARE(32)
%
%   Run after HW_EXPORT_VECTORS and vivado/run_sim.tcl. Three comparisons:
%     receiver   hardware audio and squelch gate  vs  FM_DEMOD_FIXED
%     modulator  hardware I/Q                     vs  FM_MOD_FIXED
%     loopback   hardware modulator -> hardware receiver  vs  the two models
%
%   The receiver is not expected to be bit-identical: the Xilinx CORDIC IP
%   rounds differently from the model's CORDIC. Everything after the CORDIC
%   is bit-exact given the same phase, so the audio error stays small.

if nargin < 1, inW = 16; end
P   = fm_params(inW);
dir_ = fullfile(fileparts(mfilename('fullpath')), 'data', sprintf('hw_i%d', inW));
V   = load(fullfile(dir_, 'expected.mat'));
rx  = readmatrix(fullfile(dir_, 'rx_audio_hw.txt'));
tx  = readmatrix(fullfile(dir_, 'tx_iq_hw.txt'));
lb  = readmatrix(fullfile(dir_, 'lb_audio_hw.txt'));

checks = {};
    function add(name, value, ok, limit)
        checks(end+1,:) = {name, value, limit, ok}; %#ok<AGROW>
    end

% ---- receiver ---------------------------------------------------------
add('RX: output sample count', size(rx,1), size(rx,1) == numel(V.rxAudio), sprintf('== %d', numel(V.rxAudio)));
n   = min(size(rx,1), numel(V.rxAudio));
t   = (0:n-1).' / P.fs;
e   = rx(1:n,1) - V.rxAudio(1:n);
gHw = rx(1:n,2) ~= 0;
gM  = V.rxGate(1:n);
steady = t >= V.timeOn + 0.05 & t < V.timeOff - 0.02;
muted  = t < V.timeOn - 0.01;                      % before the carrier
tail   = t > V.timeOff + 0.03;                     % after the squelch has closed
snr = 10*log10(sum(V.rxAudio(steady).^2) / max(sum(e(steady).^2), eps));
add('RX: squelch gate samples differing from model', nnz(gHw ~= gM), nnz(gHw ~= gM) <= 2, '<= 2');
add('RX: gate open intervals', nnz(diff([0; gHw]) == 1), nnz(diff([0; gHw]) == 1) == 1, '== 1');
add('RX: audio vs model, carrier on, SNR (dB)', snr, snr > 50, '> 50');
add('RX: audio vs model, carrier on, max error (LSB)', max(abs(e(steady))), max(abs(e(steady))) < 16, '< 16');
add('RX: audio before the carrier, max (LSB)', max(abs(rx(muted,1))), max(abs(rx(muted,1))) == 0, '== 0');
add('RX: audio vs model after squelch closed, max error (LSB)', max(abs(e(tail))), max(abs(e(tail))) < 16, '< 16');

% ---- modulator ----------------------------------------------------------
add('TX: output sample count', size(tx,1), size(tx,1) == numel(V.txI), sprintf('== %d', numel(V.txI)));
m   = min(size(tx,1), numel(V.txI));
eI  = tx(1:m,1) - V.txI(1:m);
eQ  = tx(1:m,2) - V.txQ(1:m);
eIQ = max(abs([eI; eQ]));
amp = hypot(tx(1:m,1), tx(1:m,2));
add('TX: I/Q vs model, max error (LSB)', eIQ, eIQ <= 4, '<= 4');
add('TX: envelope ripple (LSB)', max(abs(amp - P.MOD_AMPL)), max(abs(amp - P.MOD_AMPL)) <= 4, '<= 4');
% deviation actually produced: phase step of the hardware I/Q
dphi = angle((tx(2:m,1) + 1j*tx(2:m,2)) .* conj(tx(1:m-1,1) + 1j*tx(1:m-1,2)));
dev  = dphi * P.fs / (2*pi);
add('TX: peak deviation (Hz)', max(abs(dev)), max(abs(dev)) < P.MOD_MAX_DEV + 5, sprintf('< %d', P.MOD_MAX_DEV + 5));
add('TX: deviation vs model, max error (Hz)', max(abs(dev - V.txDev(2:m))), max(abs(dev - V.txDev(2:m))) < 5, '< 5');

% ---- loopback -----------------------------------------------------------
add('LB: output sample count', size(lb,1), size(lb,1) == numel(V.lbAudio), sprintf('== %d', numel(V.lbAudio)));
k   = min(size(lb,1), numel(V.lbAudio));
tl  = (0:k-1).' / P.fs;
el  = lb(1:k,1) - V.lbAudio(1:k);
lin = false(k,1);                                  % settled, limiter not active;
lin(round(0.05*P.fs)+1 : min(k, round((V.txStep - 0.01)*P.fs))) = true;   % whole cycles of all tones
snrL = 10*log10(sum(V.lbAudio(lin).^2) / max(sum(el(lin).^2), eps));
add('LB: audio vs model chain, SNR (dB)', snrL, snrL > 50, '> 50');
add('LB: audio vs model chain, max error (LSB)', max(abs(el(lin))), max(abs(el(lin))) < 16, '< 16');
% end-to-end gain per tone: hardware loopback audio against the audio applied
f    = [400 1000 2500];
c    = P.SOS_INT / 2^P.BQ_COEF_FRAC;
z    = exp(1j*2*pi*f/P.fs);
hbp  = ones(size(z));
for s = 1:size(c,1)
    hbp = hbp .* (c(s,1) + c(s,2)./z + c(s,3)./z.^2) ./ (1 + c(s,4)./z + c(s,5)./z.^2);
end
for i = 1:numel(f)
    w   = exp(-1j*2*pi*f(i)*tl(lin));
    g   = abs(sum(lb(lin,1) .* w)) / abs(sum(V.txAudio(lin) .* w));
    gdb = 20*log10(g) - 20*log10(abs(hbp(i))^2);    % both ends have the band filter
    add(sprintf('LB: %d Hz gain error vs two band filters (dB)', f(i)), gdb, abs(gdb) < 0.2, '|x| < 0.2');
end

% ---- report ---------------------------------------------------------------
fprintf('\nHardware simulation vs MATLAB model, I-%d\n', inW);
for i = 1:size(checks,1)
    fprintf('  %-58s %12.4g   limit %-10s %s\n', checks{i,1}, checks{i,2}, checks{i,3}, ...
            ternary(checks{i,4}, 'PASS', 'FAIL'));
end
R = struct('inW', inW, 'checks', {checks}, 'pass', all([checks{:,4}]));
fprintf('  %d of %d checks passed\n', nnz([checks{:,4}]), size(checks,1));
end

function s = ternary(c, a, b)
if c, s = a; else, s = b; end
end
