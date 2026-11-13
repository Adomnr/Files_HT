"""Build the FM demodulator model parameter document (Word .docx)."""
import sys
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

OUT = sys.argv[1]
FIG = sys.argv[2]

BLACK = RGBColor(0, 0, 0)
TEXT_W = 15.9  # cm, A4 with 2.54 cm margins

doc = Document()

# ---- Page: A4, 2.54 cm margins ------------------------------------------
sec = doc.sections[0]
sec.page_width, sec.page_height = Cm(21.0), Cm(29.7)
sec.left_margin = sec.right_margin = sec.top_margin = sec.bottom_margin = Cm(2.54)

# ---- Every style: black text, Calibri -----------------------------------
for el in doc.styles.element.iter(qn('w:color')):
    el.set(qn('w:val'), '000000')
    for a in ('w:themeColor', 'w:themeShade', 'w:themeTint'):
        if el.get(qn(a)) is not None:
            del el.attrib[qn(a)]
for st in doc.styles:
    try:
        st.font.color.rgb = BLACK
    except Exception:
        pass
normal = doc.styles['Normal']
normal.font.name = 'Calibri'
normal.font.size = Pt(11)
normal.paragraph_format.space_after = Pt(6)
for name, size in (('Heading 1', 16), ('Heading 2', 13), ('Heading 3', 11.5)):
    st = doc.styles[name]
    st.font.name = 'Calibri'
    st.font.size = Pt(size)
    st.font.bold = True
    st.font.italic = False
    rpr = st.element.get_or_add_rPr()
    rf = rpr.find(qn('w:rFonts'))
    if rf is None:
        rf = OxmlElement('w:rFonts')
        rpr.insert(0, rf)
    for a in ('w:ascii', 'w:hAnsi', 'w:cs', 'w:eastAsia'):
        rf.set(qn(a), 'Calibri')
    for a in ('w:asciiTheme', 'w:hAnsiTheme', 'w:cstheme', 'w:eastAsiaTheme'):
        if rf.get(qn(a)) is not None:
            del rf.attrib[qn(a)]
    st.paragraph_format.space_before = Pt(14 if name == 'Heading 1' else 10)
    st.paragraph_format.space_after = Pt(4)
    st.paragraph_format.keep_with_next = True


# ---- Helpers -------------------------------------------------------------
def runs(par, text, size=None, bold=False):
    """Add text to a paragraph; `backticks` mark code (Consolas)."""
    for i, seg in enumerate(text.split('`')):
        if not seg:
            continue
        r = par.add_run(seg)
        r.font.color.rgb = BLACK
        r.bold = bold
        if size:
            r.font.size = Pt(size)
        if i % 2 == 1:
            r.font.name = 'Consolas'
            r.font.size = Pt((size or 11) - 1)
    return par


def H(level, text):
    return doc.add_heading(text, level=level)


def Pg(text):
    return runs(doc.add_paragraph(), text)


def Bul(items):
    for it in items:
        runs(doc.add_paragraph(style='List Bullet'), it)


def Num(items):
    """Numbered steps, numbered by hand so every list starts again at 1."""
    for k, it in enumerate(items, 1):
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(1.27)
        p.paragraph_format.first_line_indent = Cm(-0.63)
        p.paragraph_format.space_after = Pt(6 if k == len(items) else 2)
        runs(p, f'{k}.\t{it}')


def Code(lines):
    """Equations / pseudo-code: Consolas block, one paragraph per line."""
    doc.paragraphs[-1].paragraph_format.keep_with_next = True   # lead-in stays with the block
    for k, ln in enumerate(lines):
        p = doc.add_paragraph()
        p.paragraph_format.keep_with_next = k < len(lines) - 1
        p.paragraph_format.left_indent = Cm(0.8)
        p.paragraph_format.space_after = Pt(6 if k == len(lines) - 1 else 0)
        p.paragraph_format.space_before = Pt(0)
        r = p.add_run(ln)
        r.font.name = 'Consolas'
        r.font.size = Pt(9.5)
        r.font.color.rgb = BLACK


def Tbl(headers, rows, widths):
    """Plain grid table: default borders, no shading, no emphasis."""
    assert abs(sum(widths) - TEXT_W) < 0.05, sum(widths)
    t = doc.add_table(rows=1 + len(rows), cols=len(headers))
    t.style = 'Table Grid'
    t.autofit = False
    for r, row in enumerate([headers] + rows):
        assert len(row) == len(headers), row
        for c, txt in enumerate(row):
            cell = t.cell(r, c)
            cell.width = Cm(widths[c])
            par = cell.paragraphs[0]
            par.paragraph_format.space_after = Pt(2)
            par.paragraph_format.space_before = Pt(2)
            runs(par, str(txt), size=10)
    # repeat the first row if the table breaks across pages
    trPr = t.rows[0]._tr.get_or_add_trPr()
    hdr = OxmlElement('w:tblHeader')
    hdr.set(qn('w:val'), 'true')
    trPr.append(hdr)
    # never break a row across two pages
    for row in t.rows:
        cs = OxmlElement('w:cantSplit')
        cs.set(qn('w:val'), 'true')
        row._tr.get_or_add_trPr().insert(0, cs)
    sp = doc.add_paragraph()
    sp.paragraph_format.space_after = Pt(4)
    return t


# =========================================================================
# Title
# =========================================================================
p = doc.add_paragraph()
p.paragraph_format.space_after = Pt(2)
runs(p, 'FM Demodulator Model: Parameters and Modelling', size=22, bold=True)
p = doc.add_paragraph()
p.paragraph_format.space_after = Pt(2)
runs(p, 'MATLAB fixed-point reference model for the FM_Demod FPGA design', size=12)
p = doc.add_paragraph()
p.paragraph_format.space_after = Pt(14)
runs(p, '12 November 2026', size=11)

# =========================================================================
H(1, '1. Purpose and scope')
Pg('This document describes the MATLAB model of the FM demodulator. It lists every parameter '
   'of the model, explains what each one represents, and describes how each processing stage '
   'is modelled in fixed-point arithmetic. It also describes the test signal, the checks that '
   'the model is run against, and the results.')
Pg('The model is the reference for the hardware. Every operation in it is an integer add, '
   'subtract, multiply or shift, so an RTL implementation that follows this document should '
   'produce the same output values, sample for sample.')
Pg('Status: the model passes all 17 of its checks for both I-16 and I-32 input. It has only '
   'been run on a signal generated in MATLAB, because no real recording is available yet. '
   'Several values are assumptions that should be confirmed against the real transmitter and '
   'recorder; they are listed in section 15.')
Pg('All parameters are defined in one file, `fm_params.m`. The parameter names used in this '
   'document are the field names of the structure `P` that it returns.')

# =========================================================================
H(1, '2. Input signal')
Pg('The model takes a recorded radio signal in complex baseband form. Each sample is a pair '
   'of numbers, I (in-phase) and Q (quadrature), which together give the amplitude and phase '
   'of the signal at that instant.')
Tbl(['Property', 'Value', 'What it means'],
    [['Modulation', 'Narrowband FM',
      'The message is carried by the instantaneous frequency of the carrier. The amplitude is '
      'nominally constant.'],
     ['Sample format', 'I-16 or I-32, interleaved',
      'Each of I and Q is a signed two\'s-complement integer of 16 or 32 bits. The file holds '
      'them alternately: I0, Q0, I1, Q1, and so on.'],
     ['Byte order', 'Little-endian (assumed)',
      'Least significant byte first. This is what PC-based recorders normally write.'],
     ['Sample rate', '48,000 complex samples per second',
      'The recording covers 48 kHz of spectrum, from -24 kHz to +24 kHz around the tuned '
      'centre frequency.'],
     ['Channel filter', '12.5 kHz',
      'Taken to mean a 12.5 kHz wide channel, that is, about +/-6.25 kHz around the centre.'],
     ['File size', '4 bytes per I/Q pair (I-16), 8 bytes per pair (I-32)',
      '192,000 or 384,000 bytes per second of recording.']],
    [3.0, 4.4, 8.5])
Pg('The function `read_iq_interleaved.m` reads such a file and returns I and Q as two vectors.')

# =========================================================================
H(1, '3. Processing chain')
Pg('The demodulator is a chain of five stages. All of them run at the input rate of 48 kS/s; '
   'there is no rate change anywhere in the chain.')
Num(['CORDIC: converts each I/Q pair to a phase angle and a magnitude.',
     'Phase difference (discriminator): subtracts the previous phase from the current phase. '
     'The result is proportional to the instantaneous frequency, which is the demodulated audio.',
     'Squelch: mutes the audio when the signal level is too low, so that receiver noise is not '
     'passed on.',
     'De-emphasis: a one-pole low-pass filter that undoes the treble boost applied at the '
     'transmitter.',
     '300 Hz high-pass and 3 kHz low-pass filters: keep only the voice band.'])
Tbl(['Stage', 'Output', 'Output width', 'Output scaling'],
    [['1. CORDIC', 'Phase', '20 bits, signed', '2^19 represents pi radians (180 degrees)'],
     ['1. CORDIC', 'Magnitude', 'IN_W + 2 bits', 'Input LSBs multiplied by the CORDIC gain, 1.6468'],
     ['2. Phase difference', 'Discriminator output', '16 bits, signed',
      'Full scale (32768) is 6 kHz of deviation; 1 LSB is 0.183 Hz'],
     ['3. Squelch', 'Gated discriminator output', '16 bits, signed',
      'Same as stage 2; zero while the squelch is closed'],
     ['4. De-emphasis', 'De-emphasised audio', '18 bits, signed',
      'Stage 3 scaling with a gain of 4 at DC'],
     ['5. Band filters', 'Audio output', '16 bits, signed',
      'Internal data path is 26 bits; the output is rounded and saturated to 16 bits']],
    [3.2, 3.6, 3.0, 6.1])

# =========================================================================
H(1, '4. Conventions used in the model')
Pg('The fixed-point model (`fm_demod_fixed.m`) holds every value as an integer stored in a '
   'MATLAB double. Doubles represent integers exactly up to 2^53. The widest values in the '
   'model are the 38-bit CORDIC registers in I-32 mode and the 47-bit biquad accumulator, so '
   'all results are exact.')
Tbl(['Term or operation', 'Meaning in this document', 'Hardware equivalent'],
    [['LSB', 'One unit of an integer value (least significant bit).', '-'],
     ['Full scale', 'The largest magnitude a signed word of a given width can hold, 2^(w-1).', '-'],
     ['Q2.16', 'A signed number with 2 integer bits (including sign) and 16 fractional bits: '
               'the stored integer divided by 65536. Range -2 to just under +2.', '18-bit signed word'],
     ['Guard bits', 'Extra fractional bits carried inside a stage so that rounding errors stay '
                    'well below 1 LSB of the output.', 'Wider internal registers'],
     ['`floor(x / 2^k)`', 'Divide by 2^k and round toward minus infinity.',
      'Arithmetic right shift by k'],
     ['`fix(x / 2^k)`', 'Divide by 2^k and round toward zero.',
      'Add 2^k - 1 when x is negative, then arithmetic right shift by k'],
     ['Saturate to w bits', 'Clamp the value to the range -2^(w-1) to 2^(w-1) - 1.',
      'Saturation logic on overflow'],
     ['Wrap to w bits', 'Keep only the low w bits, interpreted as signed.',
      'Natural two\'s-complement overflow of a w-bit register']],
    [3.6, 7.0, 5.3])
Pg('All state (delay registers and accumulators) starts at zero. The model processes one '
   'sample per step, with no pipeline delay. The RTL may add latency, as long as its output is '
   'the model output delayed by a fixed number of samples.')

# =========================================================================
H(1, '5. General parameters')
Tbl(['Parameter', 'Value', 'What it represents'],
    [['`fs`', '48000', 'Sample rate in Hz. Every stage runs at this rate, and all filter '
                       'coefficients are calculated for it.'],
     ['`IN_W`', '16 or 32', 'Word length in bits of each input sample (I and Q separately). It '
                            'is the argument of `fm_params`. It sets the CORDIC register width and the '
                            'squelch thresholds; nothing after the CORDIC depends on it.']],
    [3.0, 2.4, 10.5])

# =========================================================================
H(1, '6. Stage 1: CORDIC (phase and magnitude)')
H(2, '6.1 What it does')
Pg('The CORDIC algorithm in vectoring mode finds the angle and length of the vector (I, Q) '
   'using only shifts and adds. It rotates the vector step by step toward the positive x-axis. '
   'Each step rotates by a fixed angle, atan(2^-i), in whichever direction brings the vector '
   'closer to the axis. The sum of the rotations applied is the phase of the input. The x value '
   'that remains at the end is the magnitude.')
Pg('This is the "phase-wise" form of FM demodulation: the phase is computed first, and the '
   'frequency is obtained afterwards by differencing the phase (section 7).')

H(2, '6.2 Parameters')
Tbl(['Parameter', 'Value', 'What it represents'],
    [['`CORDIC_ITER`', '16', 'Number of rotation steps. Each step adds roughly one bit of angle '
                             'accuracy. After 16 steps the remaining angle error is at most atan(2^-15), '
                             'about 3.05e-5 rad.'],
     ['`CORDIC_GUARD`', '4', 'Fractional guard bits added below the input LSB on the x and y '
                             'registers. They limit the error from the right shifts inside the loop.'],
     ['`XY_W`', '22 (I-16), 38 (I-32)', 'Width of the x and y registers: IN_W + 2 + CORDIC_GUARD. '
                                        'The 2 extra integer bits cover the growth of the vector (see 6.5).'],
     ['`PHASE_W`', '20', 'Width of the phase word. The phase is signed, and 2^19 represents pi. '
                         'One LSB is 5.99e-6 rad (0.00034 degrees).'],
     ['`CORDIC_GAIN`', '1.646760', 'Factor by which the CORDIC stretches the vector: the product of '
                                   'sqrt(1 + 2^(-2i)) for i = 0 to 15. The magnitude output includes this '
                                   'factor; it is not divided out.'],
     ['`ATAN_TAB`', '16 integers (see 6.4)', 'The rotation angle of each step in phase units: '
                                             'round(atan(2^-i) / pi x 2^19).']],
    [3.2, 3.6, 9.1])

H(2, '6.3 How it is modelled')
Pg('For each input sample:')
Num(['Add the guard bits: x = I x 16, y = Q x 16.',
     'Bring the vector into the right half plane. If x is negative, negate both x and y and '
     'start the angle at z = -2^19 (which is -pi, the same angle as +pi). Otherwise start at z = 0.',
     'Run 16 rotation steps, i = 0 to 15. Both shifts use the values from before the step.',
     'Wrap z to 20 bits. This is the phase output.',
     'Remove the guard bits from x: mag = floor(x / 16). This is the magnitude output.'])
Pg('One rotation step:')
Code(['d  = +1 if y >= 0, otherwise -1',
      'x  = x + d * floor(y / 2^i)',
      'y  = y - d * floor(x_old / 2^i)',
      'z  = z + d * ATAN_TAB[i]'])
Pg('When y is positive the vector is above the axis, so it is rotated clockwise and the angle '
   'removed is added to z. When y is negative the opposite is done. After the last step y is '
   'close to zero and z holds the phase of the original vector.')

H(2, '6.4 Angle table')
atan_deg = [45.0, 26.5651, 14.0362, 7.125, 3.5763, 1.7899, 0.8952, 0.4476,
            0.2238, 0.1119, 0.056, 0.028, 0.014, 0.007, 0.0035, 0.0017]
atan_tab = [131072, 77376, 40884, 20753, 10417, 5213, 2607, 1304,
            652, 326, 163, 81, 41, 20, 10, 5]
Tbl(['Step i', 'Angle atan(2^-i), degrees', 'ATAN_TAB[i]', 'Step i', 'Angle atan(2^-i), degrees', 'ATAN_TAB[i]'],
    [[str(i), f'{atan_deg[i]:.4f}', str(atan_tab[i]), str(i + 8), f'{atan_deg[i + 8]:.4f}', str(atan_tab[i + 8])]
     for i in range(8)],
    [1.5, 3.95, 2.5, 1.5, 3.95, 2.5])

H(2, '6.5 Word lengths and accuracy')
Bul(['Vector growth: the longest input vector has I and Q both at full scale, a length of '
     '1.414 x 2^(IN_W-1). The CORDIC multiplies it by 1.6468, giving 2.33 x 2^(IN_W-1). A signed '
     'register needs IN_W + 2 bits to hold this, which is why XY_W has 2 integer bits more than '
     'the input.',
     'Magnitude scaling: the magnitude is left multiplied by 1.6468. Removing the factor would '
     'need a multiplier. Instead, the squelch thresholds are multiplied by the same factor '
     '(section 8), which gives the same comparison at no cost.',
     'Phase accuracy: measured against MATLAB `atan2` on the test signal, the phase error is '
     '5.2e-5 rad at most and 1.9e-5 rad rms. The limit of 16 iterations is 3.05e-5 rad; the rest '
     'is rounding of the table and of the shifts. The measurement uses the samples whose '
     'magnitude is at or above the squelch opening threshold.',
     'Magnitude accuracy: after dividing out the gain, the magnitude is within 0.012 % of the '
     'true value for I-16 input.',
     'Small inputs: the phase of a very small vector (a few LSBs) is inaccurate, because the '
     'input itself has few significant bits. This only affects samples that the squelch mutes.'])
Pg('If the Xilinx CORDIC IP core is used instead of hand-written RTL, its output will agree '
   'with this model only to within a small tolerance, not bit for bit, because its internal '
   'rounding is different.')

# =========================================================================
H(1, '7. Stage 2: phase difference (discriminator)')
H(2, '7.1 What it does')
Pg('Frequency is the rate of change of phase. For a signal at frequency f relative to the '
   'centre, the phase advances by 2 x pi x f / fs radians per sample. Subtracting the previous '
   'phase from the current phase therefore gives a number proportional to the instantaneous '
   'frequency, which in FM is the message.')

H(2, '7.2 Parameters')
Tbl(['Parameter', 'Value', 'What it represents'],
    [['`AUDIO_W`', '16', 'Word length of the discriminator output, the squelch output and the '
                         'final audio output.'],
     ['`DISC_GAIN_LOG2`', '2', 'Gain applied to the phase difference, as a power of two: a gain '
                               'of 4. It sets how much frequency deviation fills the 16-bit word.'],
     ['`DISC_SHIFT`', '2', 'Right shift applied to the 20-bit phase difference: PHASE_W - AUDIO_W - '
                           'DISC_GAIN_LOG2. A shift of 4 would be unity gain; a shift of 2 is a gain of 4.'],
     ['`DISC_FS_HZ`', '6000', 'Frequency deviation in Hz that corresponds to full scale (32768) at '
                              'the discriminator output: (fs / 2) / 4.']],
    [3.4, 1.8, 10.7])

H(2, '7.3 How it is modelled')
Code(['dphi[n] = phase[n] - phase[n-1]              (phase[-1] = 0)',
      'dphi[n] = wrap dphi[n] to 20 bits',
      'disc[n] = saturate( floor(dphi[n] / 4), 16 bits )'])
Bul(['Wrap: phase is an angle, so +pi and -pi are the same point. When the phase crosses that '
     'point the plain difference jumps by a full turn. Because 2^19 represents pi, a full turn is '
     'exactly 2^20, so letting a 20-bit subtractor overflow removes the jump. No separate '
     'unwrapping logic is needed.',
     'Scaling: in the 20-bit phase difference, +/-2^19 corresponds to +/-24 kHz (half the sample '
     'rate), so 1 LSB is 0.0458 Hz. After the shift by 2, 1 LSB is 0.183 Hz and full scale is '
     '6 kHz.',
     'Example: a deviation of 2.5 kHz gives 2500 / 6000 x 32768 = 13,653 LSB, 41.7 % of full scale.',
     'Carrier frequency offset: a constant offset between transmitter and receiver appears as a '
     'constant (DC) value. The 200 Hz offset in the test signal gives 1,092 LSB. The 300 Hz '
     'high-pass filter removes it later.',
     'Saturation: a real signal within the 12.5 kHz channel cannot exceed about 6 kHz, so '
     'saturation occurs only on noise, when no carrier is present and the phase is random.',
     'Truncation: `floor` gives an average error of -0.5 LSB. This is a DC offset and is also '
     'removed by the high-pass filter.'])

# =========================================================================
H(1, '8. Stage 3: squelch')
H(2, '8.1 What it does')
Pg('With no carrier present, the phase of the input is random and the discriminator output is '
   'loud noise at close to full scale. The squelch measures the signal level and passes the '
   'audio only while a signal is present. The level is the CORDIC magnitude, averaged over a '
   'few milliseconds. Two thresholds are used, a higher one to open and a lower one to close '
   '(hysteresis), so that a level near the threshold does not make the squelch switch '
   'repeatedly.')

H(2, '8.2 Parameters')
Tbl(['Parameter', 'Value', 'What it represents'],
    [['`SQ_AVG_LOG2`', '8', 'Averaging length as a power of two. The average has a time constant '
                            'of 2^8 = 256 samples, which is 5.33 ms.'],
     ['`SQ_OPEN_FRAC`', '0.125', 'Opening threshold as a fraction of input full scale '
                                 '(-18.1 dBFS). The squelch opens when the level reaches it.'],
     ['`SQ_CLOSE_FRAC`', '0.0625', 'Closing threshold as a fraction of input full scale '
                                   '(-24.1 dBFS). The squelch closes when the level falls below it.'],
     ['`SQ_TH_OPEN`', '6,745 (I-16); 442,048,841 (I-32)',
      'Opening threshold as the integer the hardware compares against: round(SQ_OPEN_FRAC x '
      '2^(IN_W-1) x CORDIC_GAIN).'],
     ['`SQ_TH_CLOSE`', '3,373 (I-16); 221,024,420 (I-32)',
      'Closing threshold as an integer: round(SQ_CLOSE_FRAC x 2^(IN_W-1) x CORDIC_GAIN).']],
    [3.2, 4.2, 8.5])
Pg('The two integer thresholds include the CORDIC gain because the magnitude they are compared '
   'with includes it.')

H(2, '8.3 How it is modelled')
Code(['acc    = acc + mag[n] - floor(acc / 256)',
      'level  = floor(acc / 256)',
      'if closed and level >= SQ_TH_OPEN   -> open',
      'if open   and level <  SQ_TH_CLOSE  -> closed',
      'sq[n]  = disc[n] if open, otherwise 0'])
Bul(['The first two lines are a one-pole averaging filter, level = level + (mag - level) / 256, '
     'written so that it needs no multiplier. The accumulator `acc` holds the level with 8 '
     'fractional bits and is IN_W + 10 bits wide.',
     'The level and the open/closed state are updated with the current sample before they are '
     'applied to it.',
     'The squelch starts closed.'])

H(2, '8.4 Behaviour on the test signal')
Bul(['The test carrier has an amplitude of half full scale (-6 dBFS); the noise alone gives a '
     'level of about -37 dBFS. The thresholds sit between the two.',
     'The squelch opens 2.4 ms after the carrier appears and closes 11.3 ms after it disappears.',
     'The closing delay is the time the average takes to fall from the carrier level (0.5) to the '
     'closing threshold (0.0625): ln(8) x 5.33 ms = 11.1 ms.',
     'During those 11 ms the discriminator output is noise, and it reaches the audio output. '
     'The burst peaks at 29,884 LSB (91 % of full scale); the wanted audio peaks at 7,476 LSB '
     '(23 %). This noise burst at the end of a transmission is a known property of this simple '
     'form of squelch. It has not been corrected in the model (see section 15).'])

# =========================================================================
H(1, '9. Stage 4: de-emphasis')
H(2, '9.1 What it does')
Pg('In an FM receiver the noise at the discriminator output rises with audio frequency. To '
   'counter this, the transmitter boosts the higher audio frequencies before modulation '
   '(pre-emphasis, +6 dB per octave) and the receiver applies the opposite slope '
   '(de-emphasis, -6 dB per octave). The message comes out flat and the high-frequency noise '
   'is reduced.')
Pg('De-emphasis is a first-order (one-pole) low-pass filter. Its corner frequency is placed '
   'below the voice band so that the -6 dB per octave slope covers the whole band from 300 Hz '
   'to 3 kHz.')

H(2, '9.2 Parameters')
Tbl(['Parameter', 'Value', 'What it represents'],
    [['`DEEMPH_TAU`', '750e-6', 'Time constant of the filter in seconds. The corner frequency is '
                                '1 / (2 x pi x tau) = 212.2 Hz. This value is common for two-way radio but is '
                                'an assumption here.'],
     ['`DEEMPH_FRAC`', '16', 'Number of fractional bits of the coefficient alpha and of the '
                             'filter accumulator.'],
     ['`DEEMPH_ALPHA`', '1795', 'Filter coefficient as an integer: round((1 - exp(-1 / (fs x tau))) x '
                                '2^16). As a fraction it is 0.027390; the exact value is 0.027396. The '
                                'quantised coefficient gives a time constant of 750.17 microseconds.'],
     ['`DEEMPH_GAIN_LOG2`', '2', 'Make-up gain as a power of two: a gain of 4.'],
     ['`DEEMPH_OUT_W`', '18', 'Width of the stage output: AUDIO_W + DEEMPH_GAIN_LOG2.']],
    [3.6, 1.8, 10.5])

H(2, '9.3 How it is modelled')
Pg('The filter equation in real numbers is y[n] = y[n-1] + alpha x (x[n] - y[n-1]). Its transfer '
   'function is H(z) = alpha / (1 - (1 - alpha) z^-1), with a gain of 1 at DC. In the model:')
Code(['acc   = acc + 1795 * ( sq[n] - floor(acc / 65536) )',
      'de[n] = floor(acc / 16384)'])
Bul(['`acc` holds the filter output with 16 fractional bits. It is a 32-bit signed register.',
     'The bracket is the difference between the input and the current output, a 17-bit value. '
     'It is multiplied by the 11-bit coefficient 1795.',
     'The output takes `acc` shifted right by 14 instead of 16. The 2 bits kept are the make-up '
     'gain of 4.',
     'Make-up gain: the one-pole filter alone attenuates a 1 kHz tone to 0.21 of its input level '
     '(-13.7 dB). With the gain of 4 the response at 1 kHz is -1.6 dB, close to unity, so the '
     'audio is not left at a very low level in the 16-bit output word.',
     'Output width: the gain at DC is 4, so the output needs 18 bits. Keeping all 18 bits means '
     'that a DC value from a carrier frequency offset is not clipped here; it is removed by the '
     'high-pass filter that follows.',
     'Rest value: when the input goes to zero, `acc` can stop at a small positive value below '
     '65536, so the output can rest at a constant 0 to 3 LSB instead of exactly 0. On the test '
     'signal it rests at 3. This is DC and the high-pass filter removes it.'])

# =========================================================================
H(1, '10. Stage 5: 300 Hz high-pass and 3 kHz low-pass filters')
H(2, '10.1 What they do')
Bul(['The 300 Hz high-pass filter removes everything below the voice band: the DC value caused '
     'by carrier frequency offset, and sub-audible signalling tones.',
     'The 3 kHz low-pass filter removes noise and any other content above the voice band.'])
Pg('Each filter is a 4th-order Butterworth design, which has a flat passband and its -3 dB '
   'point at the stated frequency. Each is built from two second-order sections (biquads), so '
   'the stage is a cascade of four biquads: two high-pass, then two low-pass. All four use the '
   'same structure, so one RTL module can serve for all of them.')

H(2, '10.2 Parameters')
Tbl(['Parameter', 'Value', 'What it represents'],
    [['`HPF_FC`', '300', 'High-pass cut-off frequency in Hz (-3 dB point).'],
     ['`LPF_FC`', '3000', 'Low-pass cut-off frequency in Hz (-3 dB point).'],
     ['`FILT_ORDER`', '4', 'Order of each filter. Order 4 gives two biquads per filter and a '
                           'slope of 24 dB per octave outside the passband.'],
     ['`BQ_COEF_FRAC`', '16', 'Fractional bits of the biquad coefficients. Coefficients are signed '
                              'Q2.16, an 18-bit word.'],
     ['`BQ_GUARD`', '8', 'Fractional guard bits added to the data inside the biquad cascade.'],
     ['`BQ_DATA_W`', '26', 'Width of the data inside the cascade: DEEMPH_OUT_W + BQ_GUARD.'],
     ['`HPF_SOS`, `HPF_G`', '2 x 6 matrix, 0.949982', 'The ideal (unquantised) high-pass design from '
                                                     'MATLAB `butter` and `zp2sos`, and its overall gain. Used only as the '
                                                     'reference that the quantised design is compared with.'],
     ['`LPF_SOS`, `LPF_G`', '2 x 6 matrix, 0.000933', 'The ideal low-pass design and its overall gain. '
                                                     'Used only as a reference.'],
     ['`SOS_INT`', '4 x 5 integer matrix (see 10.4)', 'The integer coefficients the hardware uses, '
                                                      'one row per biquad: b0, b1, b2, a1, a2.']],
    [3.6, 3.6, 8.7])

H(2, '10.3 How the integer coefficients are derived')
Num(['Design each filter with `butter` and split it into second-order sections with `zp2sos`.',
     'Round the feedback coefficients of each section: a1 = round(a1_ideal x 65536), '
     'a2 = round(a2_ideal x 65536).',
     'Calculate the feed-forward coefficients from the rounded a1 and a2, not from the ideal '
     'design.'])
Code(['High-pass section:  b0 = round((65536 - a1 + a2) / 4),  b1 = -2 * b0,  b2 = b0',
      'Low-pass section:   b0 = round((65536 + a1 + a2) / 4),  b1 = +2 * b0,  b2 = b0'])
Pg('Step 3 has two effects. The numerator keeps the exact form b0 x (1, -2, 1) or '
   'b0 x (1, 2, 1), so the high-pass sections have their zeros exactly at DC and reject it '
   'completely, and the low-pass sections have theirs exactly at half the sample rate. And each '
   'section has a passband gain of 1 for the coefficients actually used, so the signal level '
   'does not change from section to section.')

H(2, '10.4 Coefficient values')
Tbl(['Section', 'b0', 'b1', 'b2', 'a1', 'a2'],
    [['1: high-pass, first', '63218', '-126436', '63218', '-126387', '60948'],
     ['2: high-pass, second', '64541', '-129082', '64541', '-129032', '63596'],
     ['3: low-pass, first', '1843', '3686', '1843', '-89464', '31299'],
     ['4: low-pass, second', '2176', '4352', '2176', '-105626', '48793']],
    [4.4, 2.3, 2.3, 2.3, 2.3, 2.3])
Pg('Each value divided by 65536 is the real coefficient. All values fit in an 18-bit signed '
   'word (range -131072 to 131071). The table below gives the ideal feedback coefficients and '
   'the pole positions of the quantised sections.')
Tbl(['Section', 'Ideal a1', 'Ideal a2', 'Pole frequency, Hz', 'Pole radius'],
    [['1: high-pass, first', '-1.928508', '0.929996', '112.7', '0.9644'],
     ['2: high-pass, second', '-1.968877', '0.970397', '277.9', '0.9851'],
     ['3: low-pass, first', '-1.365117', '0.477592', '1200.8', '0.6911'],
     ['4: low-pass, second', '-1.611727', '0.744521', '2792.2', '0.8629']],
    [4.4, 2.8, 2.8, 3.2, 2.7])
Pg('The poles of the high-pass sections lie very close to the unit circle (radius 0.96 and '
   '0.99) and close to DC. This is what makes the high-pass sections sensitive to rounding, as '
   'described in 10.6.')

H(2, '10.5 How a biquad is modelled')
Pg('Each section is a direct-form-I biquad. It keeps the last two inputs and the last two '
   'outputs.')
Code(['acc  = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]',
      'y[n] = saturate( fix(acc / 65536), 26 bits )'])
Pg('The whole stage:')
Code(['x     = de[n] * 256                         (add 8 guard bits: 18 -> 26 bits)',
      'x     = biquad 1 -> biquad 2 -> biquad 3 -> biquad 4',
      'audio = saturate( floor((x + 128) / 256), 16 bits )   (round off the guard bits)'])
Bul(['Products: 26-bit data times 18-bit coefficient gives a 44-bit product. The sum of five '
     'products needs 47 bits, which fits a 48-bit accumulator.',
     'The division by 65536 removes the 16 fractional bits of the coefficients.',
     'Saturation to 26 bits is a safeguard. On the test signal the largest value in the cascade '
     'is 24 % of the 26-bit range, so it does not occur.',
     'The final step rounds to the nearest integer (adds half an LSB before the shift) and '
     'saturates to 16 bits. This is the only place where the 18-bit range of the de-emphasis '
     'output is reduced to 16 bits, and by then the DC content has been removed.'])

H(2, '10.6 Why the division truncates toward zero')
Pg('The first version of the model rounded `acc / 65536` to the nearest integer. The test '
   'showed a defect: after the squelch closed, the audio output stayed at -1 LSB instead of '
   'returning to 0.')
Pg('The cause is a dead band in the high-pass sections. With a constant or zero input, a '
   'section computes y = round((1 - e) x y), where e = 1 + a1 + a2 is very small because the '
   'poles are close to z = 1 (e is about 0.0015). Whenever e x y is smaller than half an LSB, '
   'rounding gives back the same y, so the value never decays. The section holds any value '
   'below about 0.5 / e, which is 338 internal units for section 1 and 328 for section 2, '
   'about 1.3 LSB of the audio output. In the test the sections stopped at about -300 internal '
   'units, which rounds to -1 LSB at the output.')
Pg('With truncation toward zero (`fix`), the magnitude of the result is never larger than the '
   'exact value, so the state shrinks on every sample until it reaches exactly zero. After the '
   'change, all four sections and the audio output return to exactly 0 when the squelch closes.')
Pg('The cost is slightly more rounding noise: the signal-to-error ratio between the fixed-point '
   'and floating-point models fell from 78.5 dB to 71.4 dB, which is still far above the '
   'quality of the demodulated signal itself. The RTL must use the same rule: when `acc` is '
   'negative, add 65535 before the arithmetic right shift by 16.')

H(2, '10.7 Why 8 guard bits')
Pg('The rounding error made at the output of a biquad is fed back through the section, and the '
   'feedback amplifies it. For the two high-pass sections the amplification of the error power '
   'is 37 dB and 40 dB, because the poles are so close to the unit circle; for the low-pass '
   'sections it is 10 dB and 12 dB. Eight guard bits place the rounding error 48 dB below one '
   'LSB of the audio, which keeps the amplified error below that LSB.')

H(2, '10.8 Frequency response')
Pg('The table gives the gain of each part and of the whole path from the discriminator output '
   'to the audio output, using the quantised coefficients. The de-emphasis column includes its '
   'make-up gain of 4.')
resp = [(100, 11.17, -38.18, 0.00, -27.01), (150, 10.28, -24.12, 0.00, -13.84),
        (250, 8.26, -7.26, 0.00, 1.00), (300, 7.27, -3.01, 0.00, 4.26),
        (400, 5.46, -0.40, 0.00, 5.06), (1000, -1.61, 0.00, 0.00, -1.61),
        (2500, -9.38, 0.00, -0.88, -10.26), (3000, -10.93, 0.00, -3.01, -13.94),
        (4000, -13.38, 0.00, -10.73, -24.11), (6000, -16.77, 0.00, -25.50, -42.26)]
Tbl(['Frequency, Hz', 'De-emphasis, dB', 'High-pass, dB', 'Low-pass, dB', 'Total, dB'],
    [[str(f), f'{a:+.2f}', f'{b:+.2f}', f'{c:+.2f}', f'{d:+.2f}'] for f, a, b, c, d in resp],
    [3.1, 3.2, 3.2, 3.2, 3.2])
Bul(['Inside the 300 Hz to 3 kHz band the total falls by about 6 dB per octave. This is the '
     'de-emphasis slope. It cancels the pre-emphasis of the transmitter, so the response from '
     'the original message to the audio output is flat.',
     'The difference between the quantised and the ideal response is at most 0.014 dB between '
     '300 Hz and 3 kHz.',
     'Rejection just below 300 Hz is limited: at 250 Hz the high-pass filter attenuates by only '
     '7.3 dB. Signalling tones near the top of the sub-audible range would remain audible. A '
     'higher filter order would be needed to remove them.'])

# =========================================================================
H(1, '11. Signal widths')
Pg('Summary of every signal in the fixed-point model. These are the fields of the `dbg` '
   'structure returned by `fm_demod_fixed.m`, which the RTL simulation can be compared with '
   'stage by stage.')
Tbl(['Signal (dbg field)', 'Width, I-16 input', 'Width, I-32 input', 'Scaling and notes'],
    [['I, Q (inputs)', '16, signed', '32, signed', 'Input samples'],
     ['CORDIC x, y registers', '22, signed', '38, signed', 'Input LSB / 16 (4 guard bits)'],
     ['`phase`', '20, signed', '20, signed', '2^19 = pi'],
     ['`mag`', '18', '34', 'Input LSB x 1.6468; never negative'],
     ['`dphi`', '20, signed', '20, signed', '2^19 = 24 kHz; wraps'],
     ['`disc`', '16, signed', '16, signed', '32768 = 6 kHz; saturates'],
     ['Squelch accumulator', '26', '42', 'Level with 8 fractional bits'],
     ['`level`', '18', '34', 'Same units as `mag`'],
     ['`gate`', '1', '1', '1 = squelch open'],
     ['`sq`', '16, signed', '16, signed', 'Same as `disc`, or 0'],
     ['De-emphasis accumulator', '32, signed', '32, signed', 'Output with 16 fractional bits'],
     ['`deemph`', '18, signed', '18, signed', '`sq` scaling x 4 at DC'],
     ['`bq` (4 columns)', '26, signed', '26, signed', '`deemph` scaling with 8 guard bits; one '
                                                      'column per biquad output'],
     ['Biquad accumulator', '47, signed', '47, signed', 'Sum of five 44-bit products'],
     ['`audio`', '16, signed', '16, signed', 'Final output']],
    [4.2, 3.1, 3.1, 5.5])

# =========================================================================
H(1, '12. Test signal generator')
Pg('Because there is no recording, `gen_fm_test_signal.m` creates one. The signal is built so '
   'that each stage of the demodulator has something specific to prove: the squelch has to '
   'open and close, the de-emphasis has to flatten pre-emphasised tones, and the filters have '
   'to remove a carrier offset and a sub-audible tone.')

H(2, '12.1 Parameters')
Tbl(['Option', 'Default', 'What it represents'],
    [['`Duration`', '3.0 s', 'Length of the recording (144,000 samples).'],
     ['`TimeOn`, `TimeOff`', '0.5 s, 2.5 s', 'When the carrier is switched on and off. Before and '
                                             'after, the recording holds noise only.'],
     ['`ToneFreqs`', '400, 1000, 2500 Hz', 'Voice-band test tones. They have equal amplitude before '
                                           'pre-emphasis and random starting phases.'],
     ['`CtcssFreq`', '100 Hz', 'A sub-audible signalling tone, of the kind radios use for selective '
                               'calling. It is not pre-emphasised. The high-pass filter should reject it.'],
     ['`CtcssDev`', '350 Hz', 'Peak deviation of the sub-audible tone.'],
     ['`PeakDev`', '2500 Hz', 'Total peak deviation, the usual limit for a 12.5 kHz channel. The '
                              'voice tones together take 2500 - 350 = 2150 Hz peak.'],
     ['`FreqOffset`', '200 Hz', 'Carrier frequency offset, as from a small tuning error. It appears as '
                                'DC at the discriminator.'],
     ['`CNR_dB`', '30 dB', 'Carrier-to-noise ratio, with the noise measured in a 12.5 kHz bandwidth.'],
     ['`Amplitude`', '0.5', 'Carrier amplitude as a fraction of full scale (-6 dBFS).'],
     ['`Seed`', '1', 'Seed of the random number generator, so the signal is identical on every run.'],
     ['`FileName`', 'data/fm_test_i16.bin or data/fm_test_i32.bin', 'Output file.']],
    [3.4, 4.0, 8.5])

H(2, '12.2 How the signal is generated')
Num(['Message: the three voice tones are summed.',
     'Pre-emphasis: the sum is passed through the exact inverse of the receiver de-emphasis '
     'filter, H(z) = (1 - (1 - alpha) z^-1) / alpha, with alpha = 1 - exp(-1 / (fs x tau)). The '
     'result is scaled to a peak of 2150 Hz, and the 100 Hz tone at 350 Hz deviation is added. '
     'This gives the instantaneous frequency deviation in Hz.',
     'FM modulation: the phase is the running sum of 2 x pi x (offset + deviation) / fs, and the '
     'carrier is exp(j x phase). This is the exact inverse of the phase-difference demodulator.',
     'Keying: the carrier is multiplied by an envelope that is 1 between TimeOn and TimeOff and '
     '0 elsewhere, with 2 ms raised-cosine edges.',
     'Noise: complex white Gaussian noise is added over the whole recording. Its total power is '
     '10^(-CNR/10) x fs / 12500 relative to the carrier, which is 0.00384 for the default values.',
     'Channel filter: carrier plus noise pass through a 161-tap FIR low-pass filter (Kaiser '
     'window, beta 7) with its -6 dB point at 6.25 kHz. This is the 12.5 kHz channel filter. It '
     'delays the signal by 80 samples (1.67 ms), which the test allows for.',
     'Quantisation: the result is scaled by Amplitude x (2^(IN_W-1) - 1), rounded to integers, '
     'and written as interleaved I and Q in little-endian order.'])
Pg('The generator also returns the true deviation waveform and the true carrier on and off '
   'times, which the test uses as the reference.')

# =========================================================================
H(1, '13. Floating-point reference model')
Pg('`fm_demod_float.m` is a second model of the same chain, in floating point. It is used to '
   'measure how much error the fixed-point arithmetic adds.')
Tbl(['Stage', 'Fixed-point model', 'Floating-point reference'],
    [['Phase', 'CORDIC, 16 steps, 20-bit result', 'Exact, from the MATLAB `angle` function'],
     ['Phase difference', '20-bit wrap, shift, 16-bit saturation',
      'Exact wrapped difference, same scaling and clipping, not rounded'],
     ['Squelch', 'Integer average and thresholds',
      'Same average and thresholds, not rounded'],
     ['De-emphasis', 'Integer accumulator, alpha = 1795 / 65536', 'Same alpha, not rounded'],
     ['Band filters', 'Integer biquads, truncation toward zero',
      'Same coefficients (SOS_INT / 65536), not rounded'],
     ['Output', '16-bit integer', 'Real number in the same units']],
    [3.2, 6.2, 6.5])
Pg('The reference uses the same quantised coefficients as the fixed-point model. The difference '
   'between the two outputs is therefore caused only by rounding of the data and by the CORDIC. '
   'The effect of quantising the coefficients is checked separately, by comparing the frequency '
   'response of the quantised filters with the ideal design.')

# =========================================================================
H(1, '14. Verification checks and results')
Pg('`run_fm_demod_test.m` generates the test signal, reads it back from the file, runs both '
   'models and applies the checks below. Measurements on the audio are made while the carrier '
   'is on and the filters have settled (from 0.1 s after carrier on to 0.05 s before carrier '
   'off). Tone levels are measured by a least-squares fit of the four known tone frequencies. '
   'The CORDIC checks use the samples whose magnitude is at or above the squelch opening '
   'threshold. "Muted" means earlier than 10 ms before carrier on, or later than 0.2 s after '
   'carrier off.')
Tbl(['Check', 'Limit', 'I-16 result', 'I-32 result'],
    [['Samples read back from the file differ from those generated', '0', '0', '0'],
     ['CORDIC phase error against atan2, maximum', 'below 1e-4 rad', '5.19e-5 rad', '5.17e-5 rad'],
     ['CORDIC phase error against atan2, rms', 'below 3e-5 rad', '1.91e-5 rad', '1.90e-5 rad'],
     ['CORDIC magnitude error, maximum', 'below 0.1 %', '0.012 %', '2.3e-7 %'],
     ['Number of times the squelch opens', '1', '1', '1'],
     ['Squelch opening delay after carrier on', '0 to 20 ms', '2.44 ms', '2.44 ms'],
     ['Squelch closing delay after carrier off', '0 to 30 ms', '11.29 ms', '11.29 ms'],
     ['Largest audio output value while muted', '0 LSB', '0 LSB', '0 LSB'],
     ['Fixed-point against floating-point audio, signal-to-error ratio', 'above 60 dB', '71.37 dB', '71.31 dB'],
     ['Fixed-point against floating-point audio, largest difference', 'below 8 LSB', '2.21 LSB', '2.19 LSB'],
     ['Quantised filter response against ideal, 300 Hz to 3 kHz, largest difference', 'below 0.1 dB', '0.014 dB', '0.014 dB'],
     ['400 Hz tone, measured gain minus predicted (+5.05 dB)', 'within 0.2 dB', '+0.013 dB', '+0.013 dB'],
     ['1000 Hz tone, measured gain minus predicted (-1.61 dB)', 'within 0.2 dB', '-0.012 dB', '-0.012 dB'],
     ['2500 Hz tone, measured gain minus predicted (-10.26 dB)', 'within 0.2 dB', '-0.017 dB', '-0.017 dB'],
     ['100 Hz sub-audible tone, measured gain minus predicted (-27.00 dB)', 'within 1 dB', '-0.012 dB', '-0.013 dB'],
     ['Audio SINAD of the fixed-point output', 'above 20 dB', '32.81 dB', '32.81 dB'],
     ['SINAD lost by the fixed-point model compared with floating point', 'below 0.1 dB', '0.0003 dB', '0.0005 dB']],
    [7.5, 2.8, 2.8, 2.8])
Bul(['All 17 checks pass for both input widths.',
     'The open/closed state of the squelch is identical, sample for sample, in the fixed-point '
     'and floating-point models (reported as `R.gateMatchesFloat`; it is not one of the 17 checks).',
     'SINAD is the ratio of the voice-tone power to everything else in the output (noise and '
     'distortion). The value of 32.8 dB is set by the 30 dB carrier-to-noise ratio of the test '
     'signal, not by the fixed-point arithmetic, which costs less than 0.001 dB.',
     'The predicted gains are those of the ideal filter design, so these four checks also '
     'confirm that the pre-emphasis and de-emphasis cancel.'])
Pg('The figure shows the I-16 run: the input spectrum, the squelch level with its thresholds, '
   'the discriminator output as the carrier appears, the audio output over the whole recording, '
   'the audio spectrum, and the predicted gain with the four measured tones. The burst at 2.5 s '
   'in the audio output is the noise that passes before the squelch closes.')
doc.add_picture(FIG, width=Cm(TEXT_W))
doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
Pg('Figure 1. Results of the model test with I-16 input.')

# =========================================================================
H(1, '15. Assumptions and open points')
H(2, '15.1 Assumptions about the input')
Bul(['"Interleaved" means that I and Q alternate in the file, starting with I.',
     'The byte order is little-endian.',
     '"Filtered at 12.5 kHz" means a 12.5 kHz wide channel (about +/-6.25 kHz), not a low-pass '
     'cut-off of 12.5 kHz.',
     'The peak deviation is +/-2.5 kHz, the usual value for a 12.5 kHz channel. The discriminator '
     'scaling (6 kHz at full scale) leaves room for more.',
     'The signal is analogue voice. A digital signal in the same channel would demodulate, but '
     'the de-emphasis and voice-band filters would not be appropriate for it.'])
H(2, '15.2 Design choices to confirm')
Bul(['Squelch type: the model uses a signal-level squelch based on the CORDIC magnitude. The '
     'alternative is a noise squelch, which measures the noise above the voice band at the '
     'discriminator output and does not depend on the input level.',
     'Squelch thresholds: -18.1 dBFS to open and -24.1 dBFS to close are placeholders chosen for '
     'the test signal. They must be set from the level of a real recording.',
     'De-emphasis time constant: 750 microseconds is assumed. It should match the pre-emphasis '
     'of the transmitter.',
     'Filter order: 4th-order Butterworth for each of the two filters.'])
H(2, '15.3 Known behaviour not yet addressed')
Bul(['Noise burst when the carrier drops: for about 11 ms, until the squelch closes, noise '
     'reaches the audio output at close to full scale. It can be shortened by a shorter level '
     'average or a higher closing threshold, or removed by delaying the audio by a few '
     'milliseconds before the mute so that the squelch closes first.',
     'Sub-audible tones close to 300 Hz are only partly rejected (7.3 dB at 250 Hz).'])
H(2, '15.4 Points for the hardware implementation')
Bul(['Only a hand-written CORDIC that follows section 6.3 will match the model bit for bit. '
     'The Xilinx CORDIC IP core will match within a tolerance.',
     'The biquad data is 26 bits wide and the coefficients are 18 bits. The multiplier in a '
     '7-series DSP48E1 slice is 25 x 18 bits, so a 26-bit operand needs more than one slice per '
     'product. Reducing BQ_GUARD to 7 would make the data 25 bits; that variant has not been '
     'evaluated.',
     'At 48 kS/s there are thousands of clock cycles per sample, so one CORDIC stage and one '
     'multiplier can be reused for all iterations and all filter products.',
     'The model has been run only on the generated signal. It should be run again on a real '
     'recording when one is available.'])

# =========================================================================
H(1, '16. Files and how to run')
Tbl(['File (in the matlab folder)', 'Purpose'],
    [['`fm_params.m`', 'Defines every parameter described in this document. `fm_params(16)` or '
                       '`fm_params(32)` returns the structure P.'],
     ['`fm_demod_fixed.m`', 'The bit-accurate fixed-point model. Returns the audio and the output '
                            'of every stage.'],
     ['`fm_demod_float.m`', 'The floating-point reference model.'],
     ['`gen_fm_test_signal.m`', 'Generates the test recording and writes it as interleaved I/Q.'],
     ['`read_iq_interleaved.m`', 'Reads an I-16 or I-32 interleaved I/Q file.'],
     ['`run_fm_demod_test.m`', 'Runs the complete test and prints the result of each check.'],
     ['`data/fm_test_i16.bin`, `data/fm_test_i32.bin`', 'The generated test recordings.'],
     ['`results/fm_demod_i16.png`, `results/fm_demod_i32.png`', 'Result figures.'],
     ['`results/audio_out_i16.wav`, `results/audio_out_i32.wav`', 'The demodulated audio, for '
                                                                  'listening.']],
    [6.4, 9.5])
Pg('To run the test, start MATLAB in the `matlab` folder and enter one of:')
Code(['R = run_fm_demod_test(16);     % I-16 input',
      'R = run_fm_demod_test(32);     % I-32 input'])
Pg('`R.pass` is true when every check passes. `R.dbg` holds the output of every stage of the '
   'fixed-point model.')
Pg('To demodulate a real recording:')
Code(["P      = fm_params(16);            % or fm_params(32)",
      "[I, Q] = read_iq_interleaved('recording.bin', 16);",
      "[audio, dbg] = fm_demod_fixed(I, Q, P);",
      "audiowrite('audio.wav', audio / 32768, P.fs);"])

doc.save(OUT)
print('saved', OUT)
