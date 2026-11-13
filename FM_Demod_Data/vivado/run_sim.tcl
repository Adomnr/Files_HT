# =============================================================================
# run_sim.tcl - behavioural simulation of block design FM_Demod with tb_fm.sv.
#
#   vivado -mode batch -source run_sim.tcl -tclargs <IN_W>
#
# Before: matlab  hw_export_vectors(<IN_W>)   (writes the stimulus)
# After:  matlab  hw_compare(<IN_W>)          (checks the results)
# The block design must have been built for the same IN_W (build_bd.tcl).
# =============================================================================
catch { load_features ipintegrator }

set IN_W 16
if {[info exists argv] && [llength $argv] >= 1} { set IN_W [lindex $argv 0] }

set script_dir [file dirname [file normalize [info script]]]
set proj_dir   [file normalize $script_dir/../FM_Demod]
set vec_dir    [file normalize $script_dir/../matlab/data/hw_i$IN_W]
if {![file exists $vec_dir/rx_iq.txt]} { error "no stimulus in $vec_dir - run hw_export_vectors($IN_W) in MATLAB" }

if {[llength [get_projects -quiet]] == 0} { open_project $proj_dir/FM_Demod.xpr }

set tb $proj_dir/FM_Demod.srcs/sim_1/new/tb_fm.sv
if {[llength [get_files -quiet $tb]] == 0} { add_files -fileset sim_1 -norecurse $tb }
set_property top tb_fm [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property generic "IN_W=$IN_W" [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.xsim.more_options} -value "-testplusarg DIR=$vec_dir" -objects [get_filesets sim_1]
update_compile_order -fileset sim_1

generate_target simulation [get_files FM_Demod.bd]
# Second argument "scripts": only write compile/elaborate/simulate .bat files to
# FM_Demod.sim/sim_1/behav/xsim (run them by hand, with the Vivado bin folder on
# PATH). Useful when Vivado cannot spawn the simulator itself.
if {[info exists argv] && [lindex $argv 1] eq "scripts"} {
    launch_simulation -scripts_only
} else {
    launch_simulation
    close_sim -quiet
}
