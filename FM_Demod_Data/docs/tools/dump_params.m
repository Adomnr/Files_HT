function dump_params(outFile)
% Dump model parameters and derived quantities to JSON for the document.
D = struct();
for w = [16 32]
    P = fm_params(w);
    key = sprintf('w%d', w);
    D.(key) = P;
end
P  = fm_params(16);
fs = P.fs;

% De-emphasis derived values
aq = P.DEEMPH_ALPHA / 2^P.DEEMPH_FRAC;
D.deemph.alpha_exact   = 1 - exp(-1/(fs*P.DEEMPH_TAU));
D.deemph.alpha_quant   = aq;
D.deemph.tau_quant     = -1/(fs*log(1-aq));
D.deemph.corner_exact  = 1/(2*pi*P.DEEMPH_TAU);
D.deemph.corner_quant  = 1/(2*pi*D.deemph.tau_quant);

% Responses (quantised coefficients)
f  = [100 150 250 300 400 1000 2500 3000 4000 6000];
z  = exp(1j*2*pi*f/fs);
hd = 2^P.DEEMPH_GAIN_LOG2 * aq ./ (1 - (1-aq)./z);
c  = P.SOS_INT / 2^P.BQ_COEF_FRAC;
hh = ones(size(z)); hl = ones(size(z));
for k = 1:2, hh = hh .* (c(k,1)+c(k,2)./z+c(k,3)./z.^2) ./ (1+c(k,4)./z+c(k,5)./z.^2); end
for k = 3:4, hl = hl .* (c(k,1)+c(k,2)./z+c(k,3)./z.^2) ./ (1+c(k,4)./z+c(k,5)./z.^2); end
D.resp.f       = f;
D.resp.deemph  = 20*log10(abs(hd));
D.resp.hpf     = 20*log10(abs(hh));
D.resp.lpf     = 20*log10(abs(hl));
D.resp.total   = 20*log10(abs(hd.*hh.*hl));

% Pole radius / frequency / Q of each quantised section
for k = 1:4
    p = roots([1 c(k,4) c(k,5)]);
    D.poles(k).radius = abs(p(1));
    D.poles(k).freq   = abs(angle(p(1)))*fs/(2*pi);
    D.poles(k).deadband = 0.5/abs(1 + c(k,4) + c(k,5));
end
D.sq.tau_ms  = 1e3*2^P.SQ_AVG_LOG2/fs;
D.phase_lsb_rad = pi/2^(P.PHASE_W-1);
D.disc_lsb_hz   = P.DISC_FS_HZ/2^(P.AUDIO_W-1);
fid = fopen(outFile,'w'); fwrite(fid, jsonencode(D, 'PrettyPrint', true)); fclose(fid);
end
