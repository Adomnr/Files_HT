# =============================================================================
# build_bd.tcl - populate block design "FM_Demod" with the FM demodulator and
#                FM modulator chains (Vivado 2019.1).
#
#   vivado -mode batch -source build_bd.tcl -tclargs <IN_W>
#   or, with the project open in the GUI:   set IN_W 16 ; source build_bd.tcl
#
#   IN_W = 16 (I-16 samples, default) or 32 (I-32 samples)
#
# The script deletes whatever is in the block design and rebuilds it, so it can
# be re-run after changing a parameter below. The numbers mirror
# matlab/fm_params.m, which stays the single source of truth.
# =============================================================================

# Load IP Integrator before anything else: in batch mode Vivado 2019.1 otherwise
# fails with "Failed to load feature 'ipintegrator'" once the project has sources.
catch { load_features ipintegrator }

if {![info exists IN_W]} { set IN_W 16 }
if {[info exists argv] && [llength $argv] >= 1} { set IN_W [lindex $argv 0] }
if {$IN_W != 16 && $IN_W != 32} { error "IN_W must be 16 or 32" }

# ---- parameters (see matlab/fm_params.m) ------------------------------------
set FS_HZ        48000
set CLK_HZ       100000000          ;# block design clock; any clock above ~5 MHz works
set PHASE_W      20                 ;# demodulator phase word, 2^19 = pi
set AUDIO_W      16
set DISC_SHIFT   2                  ;# discriminator full scale = 6 kHz
set SQ_AVG_LOG2  8
set SQ_OPEN_FRAC  0.125
set SQ_CLOSE_FRAC 0.0625
set DEEMPH_ALPHA 1795               ;# 750 us at 48 kS/s, Q0.16
set DEEMPH_FRAC  16
set DEEMPH_GAIN_LOG2 2
set BQ_GUARD     8
set BQ_FRAC      16
#               b0     b1      b2     a1      a2
set SOS {
    { 63218 -126436 63218 -126387 60948 }
    { 64541 -129082 64541 -129032 63596 }
    {  1843    3686  1843  -89464 31299 }
    {  2176    4352  2176 -105626 48793 }
}
# modulator
set MOD_ACC_W    28                 ;# phase accumulator, 2^28 = one cycle
set PRE_COEFS    {9347 -9091}       ;# 256 * (1 - (1-a) z^-1) / a, a = 1795/65536
set MAX_DEV_HZ   2500               ;# deviation limiter

# ---- derived ------------------------------------------------------------------
# Gain of the Xilinx CORDIC IP in vector-translate mode without scale
# compensation. Its coarse rotation brings the vector within +/-45 degrees, so
# the micro-rotations start at i = 1 and the gain is 1.1644 - not the 1.6468 of
# the MATLAB model's CORDIC, which starts at i = 0. The squelch thresholds are
# in CORDIC magnitude units, so they use the gain of the CORDIC that is built.
set gain 1.0
for {set i 1} {$i < 24} {incr i} { set gain [expr {$gain * sqrt(1.0 + pow(2.0, -2*$i))}] }
set SQ_TH_OPEN  [expr {wide(round($SQ_OPEN_FRAC  * pow(2, $IN_W-1) * $gain))}]
set SQ_TH_CLOSE [expr {wide(round($SQ_CLOSE_FRAC * pow(2, $IN_W-1) * $gain))}]
set DEV_LIMIT   [expr {round(double($MAX_DEV_HZ) / $FS_HZ * pow(2, $MOD_ACC_W))}]

set IQ_W     [expr {2*$IN_W}]
set CI_W     [expr {$IN_W + 2}]                 ;# CORDIC input: two sign-extension bits
set CI_F     [expr {(($CI_W + 7) / 8) * 8}]     ;# its byte-aligned field
set CO_W     [expr {$IN_W + 6}]                 ;# CORDIC output: pi = 2^(CO_W-3)
set CO_F     [expr {(($CO_W + 7) / 8) * 8}]
set MAG_W    [expr {$CO_W - 4}]                 ;# magnitude in input LSBs * 1.1644
set PH_LSB   [expr {$CO_F + $CO_W - 3 - ($PHASE_W - 1)}]
set DE_ACC_W [expr {$AUDIO_W + $DEEMPH_FRAC}]
set DE_W     [expr {$AUDIO_W + $DEEMPH_GAIN_LOG2}]
set BQ_RX_W  [expr {$DE_W + $BQ_GUARD}]
set BQ_TX_W  [expr {$AUDIO_W + $BQ_GUARD}]

puts "FM build: IN_W=$IN_W  SQ_TH_OPEN=$SQ_TH_OPEN  SQ_TH_CLOSE=$SQ_TH_CLOSE  DEV_LIMIT=$DEV_LIMIT"

# ---- project / design ---------------------------------------------------------
set script_dir [file dirname [file normalize [info script]]]
set proj_dir   [file normalize $script_dir/../FM_Demod]
if {[llength [get_projects -quiet]] == 0} { open_project $proj_dir/FM_Demod.xpr }

set rtl_dir $proj_dir/FM_Demod.srcs/sources_1/new
foreach f {iir_biquad.v fm_squelch.v round_sat.v} {
    if {[llength [get_files -quiet $rtl_dir/$f]] == 0} { add_files -norecurse $rtl_dir/$f }
}
update_compile_order -fileset sources_1

# Vivado 2019.1 in batch mode sometimes fails to initialise IP integrator on the
# first attempt ("couldn't read file board_utils.tcl"); a second attempt works.
for {set try 1} {$try <= 3} {incr try} {
    if {![catch { open_bd_design [get_files FM_Demod.bd] } msg]} { break }
    puts "open_bd_design attempt $try failed: $msg"
    if {$try == 3} { error "cannot open block design FM_Demod" }
    after 3000
}
current_bd_design FM_Demod
delete_bd_objs -quiet [get_bd_nets -quiet -hier *] [get_bd_intf_nets -quiet -hier *] \
                      [get_bd_cells -quiet *] [get_bd_ports -quiet *] [get_bd_intf_ports -quiet *]

# ---- helpers ------------------------------------------------------------------
proc ip {name ipname cfg} {
    set vlnv [lindex [lsort [get_ipdefs -filter "NAME == $ipname"]] end]
    set c [create_bd_cell -type ip -vlnv $vlnv $name]
    foreach {k v} $cfg { set_property CONFIG.$k $v $c }
    return $c
}
proc rtl {name module cfg} {
    set c [create_bd_cell -type module -reference $module $name]
    foreach {k v} $cfg { set_property CONFIG.$k $v $c }
    return $c
}
proc slice {name w from to} {
    ip $name xlslice [list DIN_WIDTH $w DIN_FROM $from DIN_TO $to DOUT_WIDTH [expr {$from-$to+1}]]
}
proc const {name w val} { ip $name xlconstant [list CONST_WIDTH $w CONST_VAL $val] }
proc concat_ip {name widths} {
    set cfg [list NUM_PORTS [llength $widths]]
    set i 0
    foreach w $widths { lappend cfg IN${i}_WIDTH $w; incr i }
    ip $name xlconcat $cfg
}
proc reg {name w} { ip $name c_shift_ram [list Width $w Depth 1 CE true] }      ;# register with enable
proc dly {name n} { ip $name c_shift_ram [list Width 1 Depth $n CE false] }     ;# strobe delay
proc cn {args} {
    set pins {}
    foreach p $args {
        set o [get_bd_pins -quiet $p]
        if {[llength $o] != 1} { error "pin not found: $p" }
        lappend pins $o
    }
    connect_bd_net {*}$pins
}
proc hpin {path dir {w 1} {type ""}} {
    set a [list -dir $dir]
    if {$w > 1}      { lappend a -from [expr {$w-1}] -to 0 }
    if {$type ne ""} { lappend a -type $type }
    create_bd_pin {*}$a $path
}
proc clock_and_reset {h} {
    connect_bd_net [get_bd_pins $h/aclk] \
        [get_bd_pins -of_objects [get_bd_cells $h/*] -filter {DIR == I && (NAME == CLK || NAME == aclk)}]
    connect_bd_net [get_bd_pins $h/aresetn] \
        [get_bd_pins -of_objects [get_bd_cells $h/*] -filter {DIR == I && NAME == aresetn}] \
        [get_bd_pins $h/rst_inv/Op1]
    connect_bd_net [get_bd_pins $h/rst_inv/Res] \
        [get_bd_pins -of_objects [get_bd_cells $h/*] -filter {DIR == I && NAME == SCLR}]
}
proc biquad_chain {h w sos frac vin din} {
    set k 0
    foreach s $sos {
        foreach {b0 b1 b2 a1 a2} $s {}
        rtl $h/bq$k iir_biquad [list DATA_W $w COEF_W [expr {$frac+2}] FRAC $frac \
                                     B0 $b0 B1 $b1 B2 $b2 A1 $a1 A2 $a2]
        cn $vin $h/bq$k/in_valid
        cn $din $h/bq$k/in_data
        set vin $h/bq$k/out_valid
        set din $h/bq$k/out_data
        incr k
    }
    return [list $vin $din]
}

# =============================================================================
# Demodulator:  I/Q -> CORDIC (phase, magnitude) -> phase difference -> squelch
#               -> de-emphasis -> 300 Hz HPF -> 3 kHz LPF -> audio
# =============================================================================
set h fm_demod
create_bd_cell -type hier $h
hpin $h/aclk I 1 clk
hpin $h/aresetn I 1 rst
hpin $h/s_axis_iq_tdata  I $IQ_W
hpin $h/s_axis_iq_tvalid I
hpin $h/m_axis_audio_tdata  O $AUDIO_W
hpin $h/m_axis_audio_tvalid O
hpin $h/squelch_open O
ip $h/rst_inv util_vector_logic {C_SIZE 1 C_OPERATION not}

# -- input: split {Q, I}, sign-extend each by two bits, pack for the CORDIC
slice $h/iq_i      $IQ_W [expr {$IN_W-1}] 0
slice $h/iq_i_sign $IQ_W [expr {$IN_W-1}] [expr {$IN_W-1}]
slice $h/iq_q      $IQ_W [expr {$IQ_W-1}] $IN_W
slice $h/iq_q_sign $IQ_W [expr {$IQ_W-1}] [expr {$IQ_W-1}]
set pad [expr {$CI_F - $CI_W}]
const $h/iq_pad $pad 0
concat_ip $h/iq_pack [list $IN_W 1 1 $pad $IN_W 1 1 $pad]
foreach s {iq_i iq_i_sign iq_q iq_q_sign} { cn $h/s_axis_iq_tdata $h/$s/Din }
cn $h/iq_i/Dout      $h/iq_pack/In0
cn $h/iq_i_sign/Dout $h/iq_pack/In1 $h/iq_pack/In2
cn $h/iq_q/Dout      $h/iq_pack/In4
cn $h/iq_q_sign/Dout $h/iq_pack/In5 $h/iq_pack/In6
cn $h/iq_pad/dout    $h/iq_pack/In3 $h/iq_pack/In7

# -- CORDIC, vector translate: magnitude (IP gain 1.1644 kept) and phase (pi = 2^(CO_W-3))
ip $h/cordic_rx cordic [list \
    Functional_Selection Translate  Architectural_Configuration Word_Serial \
    Pipelining_Mode Maximum         Data_Format SignedFraction \
    Phase_Format Scaled_Radians     Input_Width $CI_W  Output_Width $CO_W \
    Round_Mode Truncate             Iterations 0       Precision 0 \
    Coarse_Rotation true            Compensation_Scaling No_Scale_Compensation \
    flow_control NonBlocking        ARESETN true]
cn $h/iq_pack/dout      $h/cordic_rx/s_axis_cartesian_tdata
cn $h/s_axis_iq_tvalid  $h/cordic_rx/s_axis_cartesian_tvalid

slice $h/mag_sel   [expr {2*$CO_F}] [expr {$CO_W-1}] 4
slice $h/phase_sel [expr {2*$CO_F}] [expr {$PH_LSB+$PHASE_W-1}] $PH_LSB
cn $h/cordic_rx/m_axis_dout_tdata $h/mag_sel/Din $h/phase_sel/Din

# -- discriminator: phase[n] - phase[n-1], wraps in PHASE_W bits, then /4 and saturate
reg $h/phase_z1 $PHASE_W
reg $h/mag_reg  $MAG_W
ip  $h/phase_diff c_addsub [list A_Width $PHASE_W B_Width $PHASE_W Out_Width $PHASE_W \
                                 Add_Mode Subtract Latency 1 CE true]
dly $h/disc_vld 1
rtl $h/disc_sat round_sat [list IN_W $PHASE_W SHIFT $DISC_SHIFT ROUND 0 OUT_W $AUDIO_W LIMIT 0]
cn $h/phase_sel/Dout $h/phase_z1/D $h/phase_diff/A
cn $h/phase_z1/Q     $h/phase_diff/B
cn $h/mag_sel/Dout   $h/mag_reg/D
cn $h/cordic_rx/m_axis_dout_tvalid $h/phase_z1/CE $h/mag_reg/CE $h/phase_diff/CE $h/disc_vld/D
cn $h/phase_diff/S   $h/disc_sat/in_data
cn $h/disc_vld/Q     $h/disc_sat/in_valid

# -- squelch (replaceable RTL block), thresholds as constants
rtl   $h/squelch fm_squelch [list MAG_W $MAG_W AUDIO_W $AUDIO_W AVG_LOG2 $SQ_AVG_LOG2]
const $h/sq_th_open  $MAG_W $SQ_TH_OPEN
const $h/sq_th_close $MAG_W $SQ_TH_CLOSE
cn $h/disc_sat/out_valid $h/squelch/in_valid
cn $h/disc_sat/out_data  $h/squelch/disc
cn $h/mag_reg/Q          $h/squelch/mag
cn $h/sq_th_open/dout    $h/squelch/th_open
cn $h/sq_th_close/dout   $h/squelch/th_close
cn $h/squelch/gate       $h/squelch_open

# -- de-emphasis: acc += alpha * (x - acc/2^16) ; y = acc / 2^14
ip $h/de_sub c_addsub [list A_Width $AUDIO_W B_Width $AUDIO_W Add_Mode Subtract Latency 1 CE false \
                            Out_Width [expr {$AUDIO_W+1}]]     ;# Out_Width last, or it is reset
puts "FM build: de_sub S width [expr {[get_property LEFT [get_bd_pins $h/de_sub/S]] + 1}]"
ip $h/de_mul mult_gen [list MultType Constant_Coefficient_Multiplier PortAType Signed \
                            PortAWidth [expr {$AUDIO_W+1}] ConstValue $DEEMPH_ALPHA PipeStages 1]
set de_p_w [expr {[get_property LEFT [get_bd_pins $h/de_mul/P]] + 1}]
ip $h/de_acc c_accum [list Input_Type Signed Input_Width $de_p_w Output_Width $DE_ACC_W \
                           Accum_Mode Add Latency 1 CE true SCLR true Bypass false]
slice $h/de_fb  $DE_ACC_W [expr {$DE_ACC_W-1}] $DEEMPH_FRAC
slice $h/de_out $DE_ACC_W [expr {$DE_ACC_W-1}] [expr {$DEEMPH_FRAC-$DEEMPH_GAIN_LOG2}]
dly $h/de_ce  4
dly $h/de_vld 1
cn $h/squelch/audio     $h/de_sub/A
cn $h/de_fb/Dout        $h/de_sub/B
cn $h/de_sub/S          $h/de_mul/A
cn $h/de_mul/P          $h/de_acc/B
cn $h/de_acc/Q          $h/de_fb/Din $h/de_out/Din
cn $h/squelch/out_valid $h/de_ce/D
cn $h/de_ce/Q           $h/de_acc/CE $h/de_vld/D

# -- band filters: guard bits, 2 x HPF section, 2 x LPF section, round to 16 bits
const     $h/bq_zero $BQ_GUARD 0
concat_ip $h/bq_guard [list $BQ_GUARD $DE_W]
cn $h/bq_zero/dout $h/bq_guard/In0
cn $h/de_out/Dout  $h/bq_guard/In1
foreach {v d} [biquad_chain $h $BQ_RX_W $SOS $BQ_FRAC $h/de_vld/Q $h/bq_guard/dout] {}
rtl $h/out_round round_sat [list IN_W $BQ_RX_W SHIFT $BQ_GUARD ROUND 1 OUT_W $AUDIO_W LIMIT 0]
cn $v $h/out_round/in_valid
cn $d $h/out_round/in_data
cn $h/out_round/out_data  $h/m_axis_audio_tdata
cn $h/out_round/out_valid $h/m_axis_audio_tvalid
clock_and_reset $h

# =============================================================================
# Modulator:  audio -> 300 Hz HPF -> 3 kHz LPF -> pre-emphasis -> deviation
#             limiter -> phase accumulator -> CORDIC (sin, cos) -> I/Q
# =============================================================================
set h fm_mod
create_bd_cell -type hier $h
hpin $h/aclk I 1 clk
hpin $h/aresetn I 1 rst
hpin $h/s_axis_audio_tdata  I $AUDIO_W
hpin $h/s_axis_audio_tvalid I
hpin $h/m_axis_iq_tdata  O $IQ_W
hpin $h/m_axis_iq_tvalid O
ip $h/rst_inv util_vector_logic {C_SIZE 1 C_OPERATION not}

# -- band filters
const     $h/bq_zero $BQ_GUARD 0
concat_ip $h/bq_guard [list $BQ_GUARD $AUDIO_W]
cn $h/bq_zero/dout         $h/bq_guard/In0
cn $h/s_axis_audio_tdata   $h/bq_guard/In1
foreach {v d} [biquad_chain $h $BQ_TX_W $SOS $BQ_FRAC $h/s_axis_audio_tvalid $h/bq_guard/dout] {}
rtl $h/bq_round round_sat [list IN_W $BQ_TX_W SHIFT $BQ_GUARD ROUND 1 OUT_W $AUDIO_W LIMIT 0]
cn $v $h/bq_round/in_valid
cn $d $h/bq_round/in_data

# -- pre-emphasis: 2-tap FIR, exact inverse of the de-emphasis; output = frequency word
ip $h/pre_emph fir_compiler [list \
    CoefficientSource Vector  CoefficientVector [join $PRE_COEFS ,] \
    Coefficient_Sign Signed   Quantization Integer_Coefficients  Coefficient_Width 15 \
    Coefficient_Fractional_Bits 0  Coefficient_Structure Non_Symmetric \
    Filter_Type Single_Rate   Filter_Architecture Systolic_Multiply_Accumulate \
    RateSpecification Frequency_Specification \
    Sample_Frequency [expr {$FS_HZ/1.0e6}]  Clock_Frequency [expr {$CLK_HZ/1.0e6}] \
    Data_Sign Signed  Data_Width $AUDIO_W  Data_Fractional_Bits 0 \
    Output_Rounding_Mode Full_Precision  S_DATA_Has_FIFO false  Has_ARESETn true]
cn $h/bq_round/out_data  $h/pre_emph/s_axis_data_tdata
cn $h/bq_round/out_valid $h/pre_emph/s_axis_data_tvalid
set fir_w  [get_property CONFIG.Output_Width [get_bd_cells $h/pre_emph]]
set fir_tw [expr {[get_property LEFT [get_bd_pins $h/pre_emph/m_axis_data_tdata]] + 1}]
puts "FM build: pre-emphasis FIR output width $fir_w (tdata $fir_tw)"

# -- deviation limiter
set lim_w 1
while {(1 << ($lim_w-1)) <= $DEV_LIMIT} { incr lim_w }
slice $h/pre_sel $fir_tw [expr {$fir_w-1}] 0
rtl $h/dev_limit round_sat [list IN_W $fir_w SHIFT 0 ROUND 0 OUT_W $lim_w LIMIT $DEV_LIMIT]
cn $h/pre_emph/m_axis_data_tdata  $h/pre_sel/Din
cn $h/pre_sel/Dout                $h/dev_limit/in_data
cn $h/pre_emph/m_axis_data_tvalid $h/dev_limit/in_valid

# -- phase accumulator (wraps at one cycle)
ip $h/phase_acc c_accum [list Input_Type Signed Input_Width $lim_w Output_Width $MOD_ACC_W \
                              Accum_Mode Add Latency 1 CE true SCLR true Bypass false]
dly $h/phase_vld 1
cn $h/dev_limit/out_data  $h/phase_acc/B
cn $h/dev_limit/out_valid $h/phase_acc/CE $h/phase_vld/D

# -- CORDIC, sin/cos. Phase format: 3 integer bits, so sign-extend by two bits
set ph_w  32
set ph_lo [expr {$ph_w - 2 - $MOD_ACC_W}]
slice     $h/phase_sign $MOD_ACC_W [expr {$MOD_ACC_W-1}] [expr {$MOD_ACC_W-1}]
const     $h/phase_lsb  $ph_lo 0
concat_ip $h/phase_pack [list $ph_lo $MOD_ACC_W 1 1]
ip $h/cordic_tx cordic [list \
    Functional_Selection Sin_and_Cos  Architectural_Configuration Word_Serial \
    Pipelining_Mode Maximum           Data_Format SignedFraction \
    Phase_Format Scaled_Radians       Input_Width $ph_w  Output_Width $IN_W \
    Round_Mode Nearest_Even           Iterations 0       Precision 0 \
    Coarse_Rotation true              flow_control NonBlocking  ARESETN true]
cn $h/phase_acc/Q       $h/phase_sign/Din $h/phase_pack/In1
cn $h/phase_lsb/dout    $h/phase_pack/In0
cn $h/phase_sign/Dout   $h/phase_pack/In2 $h/phase_pack/In3
cn $h/phase_pack/dout   $h/cordic_tx/s_axis_phase_tdata
cn $h/phase_vld/Q       $h/cordic_tx/s_axis_phase_tvalid
cn $h/cordic_tx/m_axis_dout_tdata  $h/m_axis_iq_tdata
cn $h/cordic_tx/m_axis_dout_tvalid $h/m_axis_iq_tvalid
clock_and_reset $h

# =============================================================================
# Top level ports
# =============================================================================
create_bd_port -dir I -type clk aclk
set_property CONFIG.FREQ_HZ $CLK_HZ [get_bd_ports aclk]
create_bd_port -dir I -type rst aresetn
set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_ports aresetn]
set_property CONFIG.ASSOCIATED_RESET aresetn [get_bd_ports aclk]
connect_bd_net [get_bd_ports aclk]    [get_bd_pins fm_demod/aclk]    [get_bd_pins fm_mod/aclk]
connect_bd_net [get_bd_ports aresetn] [get_bd_pins fm_demod/aresetn] [get_bd_pins fm_mod/aresetn]

proc port {name dir w pin} {
    if {$w > 1} { create_bd_port -dir $dir -from [expr {$w-1}] -to 0 $name } else { create_bd_port -dir $dir $name }
    connect_bd_net [get_bd_ports $name] [get_bd_pins $pin]
}
port rx_iq_tdata     I $IQ_W    fm_demod/s_axis_iq_tdata
port rx_iq_tvalid    I 1        fm_demod/s_axis_iq_tvalid
port rx_audio_tdata  O $AUDIO_W fm_demod/m_axis_audio_tdata
port rx_audio_tvalid O 1        fm_demod/m_axis_audio_tvalid
port rx_squelch_open O 1        fm_demod/squelch_open
port tx_audio_tdata  I $AUDIO_W fm_mod/s_axis_audio_tdata
port tx_audio_tvalid I 1        fm_mod/s_axis_audio_tvalid
port tx_iq_tdata     O $IQ_W    fm_mod/m_axis_iq_tdata
port tx_iq_tvalid    O 1        fm_mod/m_axis_iq_tvalid

# =============================================================================
# Finish
# =============================================================================
regenerate_bd_layout
validate_bd_design
save_bd_design

set bd_file [get_files FM_Demod.bd]
generate_target all $bd_file
set wrapper [make_wrapper -files $bd_file -top -force]
if {[llength [get_files -quiet $wrapper]] == 0} { add_files -norecurse $wrapper }
set_property top FM_Demod_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1
puts "FM build: block design done, [llength [get_bd_cells -hier -filter {TYPE == ip}]] cells"
