# FM modulator / demodulator project — hand-over

Written on 2026-11-13. This file is everything needed to continue the work on another computer: what the project is, what exists, how to rebuild and re-verify it, what has been checked, and what is still open.

---

## 1. What the project is

A narrowband FM **demodulator** and **modulator** for an FPGA.

| Item | Value |
|---|---|
| Signal | FM, complex baseband I/Q, filtered to a 12.5 kHz channel |
| Sample rate | 48 kS/s |
| Sample format | "I-16" or "I-32": signed 16-bit or 32-bit integers, interleaved I, Q, I, Q … (I first) |
| Peak deviation | ±2.5 kHz |
| Demodulator chain | CORDIC (phase) → phase difference → squelch → de-emphasis → 300 Hz high-pass → 3 kHz low-pass → 16-bit audio |
| Modulator chain | 16-bit audio → 300 Hz high-pass → 3 kHz low-pass → pre-emphasis → deviation limiter → phase accumulator → CORDIC (sin/cos) → I/Q |
| FPGA | Kintex-7 `xc7k410tlfbg900-2L`, Vivado **2019.1**, project `FM_Demod`, block design `FM_Demod` |

The owner's instructions so far, in order:

1. Demodulate with a CORDIC, phase-wise, then squelch, then de-emphasis, with a 300 Hz HPF and a 3 kHz LPF.
2. Make a MATLAB model first to verify the design; the test signal must be generated in MATLAB (there is no real recording).
3. Document the model parameters in a Word file (black text, default unstyled tables, detailed).
4. Build the design in the Vivado **block design**, using **Xilinx IP cores wherever possible**, with **both** the modulator and the demodulator chain.

---

## 2. State at hand-over

| Piece | State |
|---|---|
| MATLAB demodulator model (float and bit-accurate fixed point) | Done. Self-test passes all 17 checks for I-16 and I-32 (re-run 2026-11-13). |
| MATLAB modulator model (bit-accurate) | Done. |
| Word document of the demodulator model | Done: `docs/FM_Demodulator_Model_Parameters.docx`. It does **not** cover the modulator or the hardware yet. |
| Vivado block design, both chains | Done, built by script, validates with no errors or critical warnings (49 IP cells plus 3 small RTL modules). |
| Simulation of the block design against the models, **I-16** | Done: **18 of 18 checks pass** (section 8). |
| Simulation of the block design against the models, **I-32** | Block design builds and validates. Simulation was **still running when this file was written** — see the note below. |
| Synthesis, implementation, timing | **Not run.** |
| Constraints (pins, clock) | **None exist.** The project has no XDC file. |
| Connection to real I/Q and audio hardware | **Not designed.** The block design has plain data/valid ports (section 5). |

> **Note on the project state.** The block design in the project is built for one input width at a time. While this file was being written it was the I-32 build with its simulation in progress. Run `build_bd.tcl` with argument `16` (section 7) to get the default I-16 design back; that is the configuration that is fully verified. If section 8 has no I-32 results table, the I-32 simulation was never finished.

The folder is not a git repository.

---

## 3. Folder map

```
HT_Data/
├─ HANDOFF.md                         this file
├─ matlab/                            models, test signal, hardware comparison
│  ├─ fm_params.m                     ALL design numbers (single source of truth)
│  ├─ gen_fm_test_signal.m            makes the receiver test signal (noise, FM carrier, noise)
│  ├─ read_iq_interleaved.m           reads an I-16 / I-32 interleaved file
│  ├─ fm_demod_float.m                reference demodulator, floating point
│  ├─ fm_demod_fixed.m                demodulator, bit-accurate integer model
│  ├─ fm_mod_fixed.m                  modulator, bit-accurate integer model
│  ├─ biquad_fixed.m                  one biquad section, shared by both models
│  ├─ run_fm_demod_test.m             self-test of the demodulator model (17 checks, figure, WAV)
│  ├─ hw_export_vectors.m             writes stimulus for the Vivado simulation + model answers
│  ├─ hw_compare.m                    compares Vivado simulation output with the models
│  ├─ data/                           generated: test signals, hw_i16/, hw_i32/ vector folders
│  └─ results/                        generated: figures and WAV files from the self-test
├─ vivado/
│  ├─ build_bd.tcl                    (re)builds the block design; argument 16 or 32
│  ├─ run_sim.tcl                     sets up the simulation in the project, writes xsim scripts
│  └─ xsim_batch.bat                  compiles, elaborates and runs the simulation from the command line
├─ FM_Demod/                          Vivado 2019.1 project
│  ├─ FM_Demod.xpr
│  └─ FM_Demod.srcs/
│     ├─ sources_1/bd/FM_Demod/FM_Demod.bd      the block design
│     ├─ sources_1/new/iir_biquad.v             biquad section (no suitable Xilinx IP)
│     ├─ sources_1/new/fm_squelch.v             squelch (kept as one replaceable block)
│     ├─ sources_1/new/round_sat.v              shift / round / saturate / limit
│     └─ sim_1/new/tb_fm.sv                     file-driven test bench
└─ docs/
   ├─ FM_Demodulator_Model_Parameters.docx
   └─ tools/                          build_doc.py (python-docx generator of the .docx),
                                      dump_params.m, verify_claims.m (helpers used while writing it)
```

**What to copy to the other computer:** the whole `HT_Data` folder. `FM_Demod/FM_Demod.cache`, `.sim`, `.ip_user_files` and `.hw`, and `matlab/data`, `matlab/results`, are generated and can be left out; everything in them is recreated by the steps in section 7.

---

## 4. Tools and machine-specific settings

| Tool | Version used | Needed for |
|---|---|---|
| Vivado | **2019.1** (was installed at `C:\Xilinx\Vivado\2019.1`) | block design, simulation. The IP versions in `build_bd.tcl` (cordic 6.0, fir_compiler 7.2, c_addsub 12.0, c_accum 12.0, c_shift_ram 12.0, mult_gen 12.0, xlslice 1.0, xlconcat 2.1, xlconstant 1.1, util_vector_logic 2.0) are those of 2019.1. A newer Vivado will ask to upgrade the IP and the hard-coded simulation library names in `xsim_batch.bat` will change. |
| MATLAB | R2025b with **Signal Processing Toolbox** (`butter`, `zp2sos`, `fir1`, `kaiser`) | models and comparison |
| Python 3 + `python-docx` | 3.13 / 1.2.0 | only to regenerate the Word document |

Things tied to the old machine:

- `vivado/xsim_batch.bat` has `set VIVADO_BIN=C:\Xilinx\Vivado\2019.1\bin` — change it if Vivado is elsewhere.
- `FM_Demod.xpr` stores its own absolute path and the absolute path of the vector folder (simulation option `-testplusarg DIR=...`). Vivado corrects the first on opening; `run_sim.tcl` rewrites the second. All paths in the scripts are relative to the script location.
- The operating system was Windows 11; the commands below are for PowerShell or `cmd`.

---

## 5. The hardware design

### 5.1 Conventions

- One clock `aclk`, active-low synchronous reset `aresetn`.
- Each sample is accompanied by a one-clock `valid` strobe. Data outputs are registered and hold their value until the next sample.
- No back-pressure (`tready`) anywhere. Samples must arrive at least about 50 clocks apart (the word-serial CORDIC is the slowest block). At 48 kS/s that means any clock above roughly 5 MHz; the block design declares 100 MHz, which is an assumption (2083 clocks per sample).
- The input width `IN_W` (16 or 32) is fixed when the block design is built. It changes the I/Q port width, the CORDIC widths and the squelch thresholds; everything after the CORDIC is the same.

### 5.2 Top-level ports (wrapper `FM_Demod_wrapper`)

| Port | Dir | Width | Meaning |
|---|---|---|---|
| `aclk`, `aresetn` | in | 1 | clock, active-low reset |
| `rx_iq_tdata` | in | 2·IN_W | received sample, `{Q, I}` (I in the low half) |
| `rx_iq_tvalid` | in | 1 | strobe |
| `rx_audio_tdata` | out | 16 | demodulated audio, signed |
| `rx_audio_tvalid` | out | 1 | strobe |
| `rx_squelch_open` | out | 1 | 1 while the squelch passes audio |
| `tx_audio_tdata` | in | 16 | audio to transmit, signed, same scale as `rx_audio_tdata` |
| `tx_audio_tvalid` | in | 1 | strobe |
| `tx_iq_tdata` | out | 2·IN_W | modulated sample, `{Q, I}`, amplitude 2^(IN_W−2) (half scale) |
| `tx_iq_tvalid` | out | 1 | strobe |

There is no de-interleaver: whatever feeds `rx_iq` must already have paired I with Q.

### 5.3 Demodulator, hierarchy `fm_demod`

| Step | Cells | Type | What it does |
|---|---|---|---|
| Input formatting | `iq_i`, `iq_q`, `iq_*_sign`, `iq_pad`, `iq_pack` | xlslice / xlconstant / xlconcat | sign-extends I and Q by two bits (the CORDIC needs inputs within ±1) |
| Phase and magnitude | `cordic_rx` | **cordic 6.0**, Translate, word-serial, scaled radians, no scale compensation | output width IN_W+6; phase taken as 20 bits with 2^19 = π; magnitude = amplitude × 1.1644 |
| Phase difference | `phase_z1`, `phase_diff`, `disc_vld`, `mag_reg` | c_shift_ram, **c_addsub** | φ[n] − φ[n−1], wrapping in 20 bits |
| Scale to audio | `disc_sat` | RTL `round_sat` | ÷4 (floor) and saturate to 16 bits; full scale = 6 kHz deviation |
| Squelch | `squelch`, `sq_th_open`, `sq_th_close` | RTL `fm_squelch`, xlconstant | level = running average of the magnitude over 2^8 samples (5.3 ms); opens at ≥ 12.5 % of full-scale amplitude, closes below 6.25 %; audio forced to 0 when closed |
| De-emphasis | `de_sub`, `de_mul`, `de_acc`, `de_fb`, `de_out`, `de_ce`, `de_vld` | c_addsub, **mult_gen** (constant 1795), **c_accum** | acc += 1795·(x − acc/2^16); y = acc/2^14. One pole, 750 µs, make-up gain 4, 18-bit output |
| Band filters | `bq_zero`, `bq_guard`, `bq0`…`bq3` | RTL `iir_biquad` ×4 | two high-pass sections (300 Hz, 4th-order Butterworth) and two low-pass sections (3 kHz, 4th-order Butterworth); 26-bit data with 8 guard bits |
| Output | `out_round` | RTL `round_sat` | round to 16 bits, saturate |

### 5.4 Modulator, hierarchy `fm_mod`

| Step | Cells | Type | What it does |
|---|---|---|---|
| Band filters | `bq_zero`, `bq_guard`, `bq0`…`bq3`, `bq_round` | RTL `iir_biquad` ×4, `round_sat` | same coefficients as the demodulator, 24-bit data |
| Pre-emphasis | `pre_emph`, `pre_sel` | **fir_compiler 7.2**, 2 taps, integer coefficients `[9347, −9091]` | exact inverse of the de-emphasis, scaled by 2^8 so the output is the frequency word directly |
| Deviation limiter | `dev_limit` | RTL `round_sat` | hard clip at ±13,981,013 = ±2.5 kHz |
| Phase accumulator | `phase_acc`, `phase_vld` | **c_accum**, 28 bits | 2^28 = one cycle; 1 LSB of the frequency word = 48000/2^28 Hz |
| Carrier | `phase_sign`, `phase_lsb`, `phase_pack`, `cordic_tx` | **cordic 6.0**, Sin_and_Cos, word-serial | output `{sin, cos}` = `{Q, I}` |

The audio scale of the modulator is chosen so that modulator → demodulator has unity gain apart from the two sets of band filters.

### 5.5 The three RTL modules

Used only where no Xilinx IP fits. All are plain Verilog with parameters and are instantiated in the block design as module references.

- **`iir_biquad`** — parameters `DATA_W`, `COEF_W` (18), `FRAC` (16), `B0 B1 B2 A1 A2` (integers, Q2.16). One multiplier used five times per sample; 8 clocks per sample; result truncated toward zero and saturated. Bit-identical to `biquad_fixed.m`.
- **`fm_squelch`** — parameters `MAG_W`, `AUDIO_W`, `AVG_LOG2`; ports `mag`, `disc`, `th_open`, `th_close` → `audio`, `gate`, `level`. This is the one block to replace if a different squelch (for example a noise squelch or tone squelch) is wanted; the thresholds are ports, not parameters.
- **`round_sat`** — parameters `IN_W`, `SHIFT`, `ROUND` (0 floor, 1 round half up), `OUT_W`, `LIMIT` (0 = full range, otherwise symmetric ±LIMIT). One clock of latency.

### 5.6 Key numbers (all come from `matlab/fm_params.m`, mirrored at the top of `vivado/build_bd.tcl`)

| Quantity | Value |
|---|---|
| Phase word | 20 bits signed, 2^19 = π |
| Discriminator full scale | 6 kHz (1 audio LSB = 0.183 Hz before de-emphasis) |
| Squelch average | 2^8 samples |
| Squelch thresholds, hardware | I-16: open 4770, close 2385 · I-32: open 312,575,733, close 156,287,866 |
| Squelch thresholds, MATLAB model | I-16: open 6745, close 3373 (same fractions, different CORDIC gain — section 9) |
| De-emphasis | α = 1795 / 65536 (750 µs at 48 kS/s), gain 4 |
| Biquad coefficients `[b0 b1 b2 a1 a2]`, Q2.16 | HPF: `[63218 −126436 63218 −126387 60948]`, `[64541 −129082 64541 −129032 63596]` · LPF: `[1843 3686 1843 −89464 31299]`, `[2176 4352 2176 −105626 48793]` |
| Pre-emphasis FIR | `[9347, −9091]` |
| Deviation limit | 13,981,013 (2.5 kHz) |
| Phase accumulator | 28 bits |
| TX carrier amplitude | 2^(IN_W−2) |

To change a number: change it in `fm_params.m`, mirror it in `build_bd.tcl`, rebuild, re-simulate.

---

## 6. The MATLAB side

- `fm_params(16)` or `fm_params(32)` returns every word length, shift and integer coefficient.
- `run_fm_demod_test(16)` / `run_fm_demod_test(32)` generates a 3 s test signal, runs the float and fixed models and prints 17 pass/fail checks. It writes `matlab/results/fm_demod_i<W>.png` and `audio_out_i<W>.wav`.
- The receiver test signal is: noise only, then an FM carrier, then noise only. The carrier is modulated by pre-emphasised tones at 400, 1000 and 2500 Hz plus a 100 Hz sub-audible tone (350 Hz deviation), total peak deviation 2.5 kHz, 200 Hz carrier offset, 30 dB carrier-to-noise ratio, amplitude half of full scale, passed through a 12.5 kHz channel filter.
- The modulator test signal is three tones (400, 1000, 2500 Hz) whose level is multiplied by 4 near the end to drive the deviation limiter.

---

## 7. How to rebuild and re-verify

Run from the `HT_Data` folder. Replace `16` by `32` for the other input width. `vivado` must be on the PATH, or use the full path to `vivado.bat`.

```powershell
# 1. Model self-test (about 1 minute)
cd matlab
matlab -batch "run_fm_demod_test(16);"

# 2. Stimulus for the hardware simulation (short set: 0.25 s = 12000 samples)
matlab -batch "hw_export_vectors(16);"
cd ..

# 3. Build the block design (deletes and recreates its contents; about 2 minutes)
vivado -mode batch -nojournal -source vivado/build_bd.tcl -tclargs 16

# 4. Write the simulation scripts
vivado -mode batch -nojournal -source vivado/run_sim.tcl -tclargs 16 scripts

# 5. Compile, elaborate, simulate (arguments: input width, clocks per sample)
cmd /c "vivado\xsim_batch.bat 16 32"

# 6. Compare with the models
cd matlab
matlab -batch "hw_compare(16);"
```

Notes:

- Step 3 prints `FM build: block design done, 49 cells` on success. It can also be run inside the Vivado GUI with the project open: `set IN_W 16; source vivado/build_bd.tcl`.
- Step 5 is slow: the simulator manages only about 290 clock cycles per second on this design (two copies of the block design, about 100 IP cores). The short vector set took 22 minutes at 32 clocks per sample. `hw_export_vectors(16, 'full')` gives the long set (3 s receiver, 1.2 s modulator), which takes many hours.
- For I-32 use 64 clocks per sample (`xsim_batch.bat 32 64`): its CORDIC needs more clocks per sample than the I-16 one. 32 clocks per sample was verified only for I-16.
- Without the `scripts` argument, `run_sim.tcl` calls `launch_simulation` itself. On the old machine that failed in batch mode ("Spawn failed: Broken pipe"), which is why steps 4 and 5 are separate. From the Vivado GUI, *Run Simulation* works with the settings `run_sim.tcl` leaves in the project.
- The test bench `tb_fm.sv` instantiates the design twice: `dut` (receiver fed from `rx_iq.txt`, modulator fed from `tx_audio.txt`) and `lb` (a second receiver fed by `dut`'s modulator output — the loopback). It writes `rx_audio_hw.txt`, `tx_iq_hw.txt` and `lb_audio_hw.txt` into the vector folder.
- To regenerate the Word document: `python docs/tools/build_doc.py docs/FM_Demodulator_Model_Parameters.docx matlab/results/fm_demod_i16.png` (needs `pip install python-docx`; the text of the document is inside the script).

---

## 8. Verification results

### 8.1 Demodulator model self-test

All 17 checks pass for I-16 and I-32. Examples from the I-32 run: fixed-point versus floating-point audio 71.3 dB, tone gain errors within 0.02 dB of prediction, audio SINAD 32.8 dB.

### 8.2 Block design versus models, I-16 (short vectors, 32 clocks per sample)

| Check | Result | Limit |
|---|---|---|
| RX: output sample count | 12000 | = 12000 |
| RX: squelch gate samples differing from model | 2 | ≤ 2 |
| RX: gate-open intervals | 1 | = 1 |
| RX: audio versus model, carrier on, SNR | 76.2 dB | > 50 dB |
| RX: audio versus model, carrier on, max error | 1 LSB | < 16 LSB |
| RX: audio before the carrier | 0 | = 0 |
| RX: audio versus model after the squelch closed, max error | 0 LSB | < 16 LSB |
| TX: output sample count | 12000 | = 12000 |
| TX: I/Q versus model, max error | 2 LSB | ≤ 4 LSB |
| TX: envelope ripple | 0.96 LSB | ≤ 4 LSB |
| TX: peak deviation | 2502 Hz | < 2505 Hz |
| TX: deviation versus model, max error | 1.8 Hz | < 5 Hz |
| Loopback: output sample count | 12000 | = 12000 |
| Loopback: audio versus model chain, SNR | 70.8 dB | > 50 dB |
| Loopback: audio versus model chain, max error | 2 LSB | < 16 LSB |
| Loopback: 400 / 1000 / 2500 Hz gain error | 0.006 / 0.002 / 0.0005 dB | < 0.2 dB |

**18 of 18 pass.** The limits were chosen before the results were known.

### 8.3 Block design versus models, I-32

Not available at the time of writing (simulation in progress). If results exist they are in `matlab/data/hw_i32/*_hw.txt`; run `hw_compare(32)` — but only if the three files each have 12000 lines.

---

## 9. Where the hardware differs from the model

1. **CORDIC.** The Xilinx CORDIC IP is not bit-identical to the model's own CORDIC, so the receiver is compared by tolerance (it agrees within 1 LSB of audio). Everything after the CORDIC, and the modulator up to the phase accumulator, is bit-exact by construction.
2. **CORDIC gain.** In vector-translate mode without scale compensation the IP has gain **1.1644**, not the textbook 1.6468 of the model: its coarse rotation brings the vector within ±45°, so its micro-rotations start one step later. The squelch thresholds are in magnitude units, so the hardware constants differ from the model's (section 5.6). This was found in simulation (the squelch opened 38 samples late) and fixed in `build_bd.tcl`; `fm_params.m` carries both sets (`SQ_TH_*` and `HW_SQ_TH_*`).
3. **Modulator carrier.** The model uses ideal sin/cos; the IP agrees within 2 LSB.

---

## 10. Assumptions made without a decision from the owner

These were assumed and stated, never confirmed. Each can change the design.

| Topic | Assumed | Why it matters |
|---|---|---|
| Squelch type | Level (carrier) squelch with hysteresis. The owner said "good enough" to the question of whether it is replaceable. | A noise or tone squelch would replace `fm_squelch`. |
| De-emphasis time constant | 750 µs | 50 µs / 75 µs / 530 µs systems exist; changes α and the pre-emphasis FIR. |
| System clock | 100 MHz | Only the declared clock frequency and the FIR IP setting depend on it. |
| How I/Q and audio enter and leave the FPGA | Plain data/valid ports | Real interfaces (ADC/DAC, AXI-Stream with back-pressure, de-interleaver, clock-domain crossing) are not designed. |
| TX carrier amplitude | Half of full scale | Arbitrary choice. |
| Modulator includes the 300 Hz high-pass | Yes (mirror of the receiver) | It would remove a sub-audible (CTCSS) tone if one has to be transmitted. |

---

## 11. Known weaknesses

- **Noise burst at carrier drop.** The squelch level average takes about 11 ms to fall below the close threshold, so about 11 ms of noise reaches the audio when the carrier disappears. Present in model and hardware.
- **Rejection just below 300 Hz is modest** (4th-order high-pass): a 100 Hz tone is attenuated by about 27 dB in total.
- **Deviation limiter is a hard clip** with no filter after it, so heavy limiting widens the transmitted spectrum.
- **Multiplier size.** The demodulator biquads multiply 26-bit data by 18-bit coefficients, one bit wider than a single DSP48E1 port; synthesis will use extra logic or a second DSP slice. Not yet looked at because synthesis has not been run.
- **Verified with short vectors only** (0.25 s). The long set has not been simulated in hardware.

---

## 12. Vivado 2019.1 pitfalls already met

- `open_bd_design` sometimes fails in batch mode ("couldn't read file board_utils.tcl", "invalid command name bd::utils::dbg" or "Failed to load feature 'ipintegrator'"). The scripts call `load_features ipintegrator` first and retry; simply running the script again also works.
- `launch_simulation` from batch mode failed with "Spawn failed: Broken pipe" → use the `scripts` route (section 7).
- The xsim `.bat` wrappers split unquoted arguments at `=`. Inside a batch file write `-testplusarg "DIR=C:/path"`, with the quotes.
- `c_addsub`: set `Out_Width` last in the property list, otherwise changing `Add_Mode` or `Latency` resets it.
- Warnings that are expected on every build: BD 41-1306 (AXI-Stream pins wired by hand), BD 41-1731 (pin type mismatch on clock enables), BD 41-927 (clock properties of module references), c_addsub 12.0-313 (field type on `phase_diff`).

---

## 13. Suggested next steps

1. Finish the I-32 check: build with `32`, simulate with 64 clocks per sample, `hw_compare(32)`; then rebuild with `16`.
2. Run synthesis and look at resource use and timing at the real clock frequency (needs a clock constraint).
3. Get decisions on section 10, above all the real clock and the I/Q and audio interfaces, then add the interface logic and the pin constraints.
4. Extend the Word document with the modulator and the hardware (block list, IP settings, CORDIC gain, verification table).
5. Optional improvements: faster squelch closing, a filter after the deviation limiter, a path for a sub-audible tone around the modulator's high-pass.

---

## 14. Working preferences of the owner

- Model first in MATLAB, then hardware checked against the model.
- In Vivado: block design, Xilinx IP wherever one exists.
- Word documents: black text, default tables without styling, detailed explanations of what each parameter means and how it is modelled.
