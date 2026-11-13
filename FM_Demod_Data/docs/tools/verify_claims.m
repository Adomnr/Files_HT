function verify_claims()
% Check numeric statements made in the document against the model.
for w = [16 32]
    P = fm_params(w);
    S = gen_fm_test_signal(P);
    [a, d] = fm_demod_fixed(S.I, S.Q, P);
    fprintf('--- I-%d\n', w);
    fprintf('max |bq| per section / 2^25: %s\n', mat2str(max(abs(d.bq))/2^25, 4));
    fprintf('max |deemph| / 2^17: %.4f\n', max(abs(d.deemph))/2^17);
    fprintf('disc saturated samples: gate open %d, gate closed %d\n', ...
        nnz((d.disc==32767 | d.disc==-32768) & d.gate), nnz((d.disc==32767 | d.disc==-32768) & ~d.gate));
    fprintf('deemph last value %d, bq last row %s, audio last %d\n', d.deemph(end), mat2str(d.bq(end,:)), a(end));
    t = (0:numel(a)-1).'/P.fs;
    q = t < S.timeOn - 0.05;
    fprintf('noise-only level mean: %.2f dBFS\n', 20*log10(mean(d.level(q & t > 0.1))/P.CORDIC_GAIN/2^(w-1)));
    on = t > S.timeOn + 0.1 & t < S.timeOff - 0.05;
    fprintf('carrier level mean: %.2f dBFS\n', 20*log10(mean(d.level(on))/P.CORDIC_GAIN/2^(w-1)));
    fprintf('disc mean while on: %.1f LSB, peak %.0f, audio peak while on %d\n', mean(d.disc(on)), max(abs(d.disc(on))), max(abs(a(on))));
    fprintf('audio peak in tail burst: %d\n', max(abs(a(t > S.timeOff))));
    fprintf('audio max while noise only before carrier: %d\n', max(abs(a(q))));
end
P = fm_params(16);
c = P.SOS_INT / 2^P.BQ_COEF_FRAC;
for k = 1:4
    h = impz(1, [1 c(k,4) c(k,5)], 20000);
    fprintf('section %d: noise power gain of 1/A = %.1f dB, e = 1+a1+a2 = %.6f\n', k, 10*log10(sum(h.^2)), 1+c(k,4)+c(k,5));
end
% pre-rounding variant: where do the HPF sections stick? (round-half-up quantiser)
fprintf('one-pole gain at 1 kHz without make-up: %.3f (%.2f dB)\n', ...
    abs(freqz(P.DEEMPH_ALPHA/65536, [1 -(1-P.DEEMPH_ALPHA/65536)], [1000 1000], P.fs)) * [1;0], ...
    20*log10(abs(freqz(P.DEEMPH_ALPHA/65536, [1 -(1-P.DEEMPH_ALPHA/65536)], [1000 1000], P.fs)) * [1;0]));
end
