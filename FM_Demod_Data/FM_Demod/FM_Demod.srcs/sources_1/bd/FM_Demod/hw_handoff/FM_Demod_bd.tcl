
################################################################
# This is a generated script based on design: FM_Demod
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2019.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source FM_Demod_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# iir_biquad, iir_biquad, iir_biquad, iir_biquad, round_sat, round_sat, fm_squelch, iir_biquad, iir_biquad, iir_biquad, iir_biquad, round_sat, round_sat

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7k410tlfbg900-2L
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name FM_Demod

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: fm_mod
proc create_hier_cell_fm_mod { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_fm_mod() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir O -from 63 -to 0 m_axis_iq_tdata
  create_bd_pin -dir O m_axis_iq_tvalid
  create_bd_pin -dir I -from 15 -to 0 s_axis_audio_tdata
  create_bd_pin -dir I s_axis_audio_tvalid

  # Create instance: bq0, and set properties
  set block_name iir_biquad
  set block_cell_name bq0
  if { [catch {set bq0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bq0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.A1 {-126387} \
   CONFIG.A2 {60948} \
   CONFIG.B0 {63218} \
   CONFIG.B1 {-126436} \
   CONFIG.B2 {63218} \
   CONFIG.COEF_W {18} \
   CONFIG.DATA_W {24} \
   CONFIG.FRAC {16} \
 ] $bq0

  # Create instance: bq1, and set properties
  set block_name iir_biquad
  set block_cell_name bq1
  if { [catch {set bq1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bq1 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.A1 {-129032} \
   CONFIG.A2 {63596} \
   CONFIG.B0 {64541} \
   CONFIG.B1 {-129082} \
   CONFIG.B2 {64541} \
   CONFIG.COEF_W {18} \
   CONFIG.DATA_W {24} \
   CONFIG.FRAC {16} \
 ] $bq1

  # Create instance: bq2, and set properties
  set block_name iir_biquad
  set block_cell_name bq2
  if { [catch {set bq2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bq2 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.A1 {-89464} \
   CONFIG.A2 {31299} \
   CONFIG.B0 {1843} \
   CONFIG.B1 {3686} \
   CONFIG.B2 {1843} \
   CONFIG.COEF_W {18} \
   CONFIG.DATA_W {24} \
   CONFIG.FRAC {16} \
 ] $bq2

  # Create instance: bq3, and set properties
  set block_name iir_biquad
  set block_cell_name bq3
  if { [catch {set bq3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bq3 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.A1 {-105626} \
   CONFIG.A2 {48793} \
   CONFIG.B0 {2176} \
   CONFIG.B1 {4352} \
   CONFIG.B2 {2176} \
   CONFIG.COEF_W {18} \
   CONFIG.DATA_W {24} \
   CONFIG.FRAC {16} \
 ] $bq3

  # Create instance: bq_guard, and set properties
  set bq_guard [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 bq_guard ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {8} \
   CONFIG.IN1_WIDTH {16} \
   CONFIG.NUM_PORTS {2} \
 ] $bq_guard

  # Create instance: bq_round, and set properties
  set block_name round_sat
  set block_cell_name bq_round
  if { [catch {set bq_round [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bq_round eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.IN_W {24} \
   CONFIG.LIMIT {0} \
   CONFIG.OUT_W {16} \
   CONFIG.ROUND {1} \
   CONFIG.SHIFT {8} \
 ] $bq_round

  # Create instance: bq_zero, and set properties
  set bq_zero [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 bq_zero ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {8} \
 ] $bq_zero

  # Create instance: cordic_tx, and set properties
  set cordic_tx [ create_bd_cell -type ip -vlnv xilinx.com:ip:cordic:6.0 cordic_tx ]
  set_property -dict [ list \
   CONFIG.ARESETN {true} \
   CONFIG.Architectural_Configuration {Word_Serial} \
   CONFIG.Coarse_Rotation {true} \
   CONFIG.Data_Format {SignedFraction} \
   CONFIG.Functional_Selection {Sin_and_Cos} \
   CONFIG.Input_Width {32} \
   CONFIG.Iterations {0} \
   CONFIG.Output_Width {32} \
   CONFIG.Phase_Format {Scaled_Radians} \
   CONFIG.Pipelining_Mode {Maximum} \
   CONFIG.Precision {0} \
   CONFIG.Round_Mode {Nearest_Even} \
   CONFIG.flow_control {NonBlocking} \
 ] $cordic_tx

  # Create instance: dev_limit, and set properties
  set block_name round_sat
  set block_cell_name dev_limit
  if { [catch {set dev_limit [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dev_limit eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.IN_W {31} \
   CONFIG.LIMIT {13981013} \
   CONFIG.OUT_W {25} \
   CONFIG.ROUND {0} \
   CONFIG.SHIFT {0} \
 ] $dev_limit

  # Create instance: phase_acc, and set properties
  set phase_acc [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_accum:12.0 phase_acc ]
  set_property -dict [ list \
   CONFIG.Accum_Mode {Add} \
   CONFIG.Bypass {false} \
   CONFIG.CE {true} \
   CONFIG.Input_Type {Signed} \
   CONFIG.Input_Width {25} \
   CONFIG.Latency {1} \
   CONFIG.Output_Width {28} \
   CONFIG.SCLR {true} \
 ] $phase_acc

  # Create instance: phase_lsb, and set properties
  set phase_lsb [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 phase_lsb ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {2} \
 ] $phase_lsb

  # Create instance: phase_pack, and set properties
  set phase_pack [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 phase_pack ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {2} \
   CONFIG.IN1_WIDTH {28} \
   CONFIG.IN2_WIDTH {1} \
   CONFIG.IN3_WIDTH {1} \
   CONFIG.NUM_PORTS {4} \
 ] $phase_pack

  # Create instance: phase_sign, and set properties
  set phase_sign [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 phase_sign ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {27} \
   CONFIG.DIN_TO {27} \
   CONFIG.DIN_WIDTH {28} \
   CONFIG.DOUT_WIDTH {1} \
 ] $phase_sign

  # Create instance: phase_vld, and set properties
  set phase_vld [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram:12.0 phase_vld ]
  set_property -dict [ list \
   CONFIG.CE {false} \
   CONFIG.Depth {1} \
   CONFIG.Width {1} \
 ] $phase_vld

  # Create instance: pre_emph, and set properties
  set pre_emph [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 pre_emph ]
  set_property -dict [ list \
   CONFIG.Clock_Frequency {100.0} \
   CONFIG.CoefficientSource {Vector} \
   CONFIG.CoefficientVector {9347,-9091} \
   CONFIG.Coefficient_Fractional_Bits {0} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Non_Symmetric} \
   CONFIG.Coefficient_Width {15} \
   CONFIG.Data_Fractional_Bits {0} \
   CONFIG.Data_Sign {Signed} \
   CONFIG.Data_Width {16} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Type {Single_Rate} \
   CONFIG.Has_ARESETn {true} \
   CONFIG.Output_Rounding_Mode {Full_Precision} \
   CONFIG.Quantization {Integer_Coefficients} \
   CONFIG.RateSpecification {Frequency_Specification} \
   CONFIG.S_DATA_Has_FIFO {false} \
   CONFIG.Sample_Frequency {0.048} \
 ] $pre_emph

  # Create instance: pre_sel, and set properties
  set pre_sel [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 pre_sel ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {30} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {32} \
   CONFIG.DOUT_WIDTH {31} \
 ] $pre_sel

  # Create instance: rst_inv, and set properties
  set rst_inv [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 rst_inv ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
 ] $rst_inv

  # Create port connections
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins bq0/aclk] [get_bd_pins bq1/aclk] [get_bd_pins bq2/aclk] [get_bd_pins bq3/aclk] [get_bd_pins bq_round/aclk] [get_bd_pins cordic_tx/aclk] [get_bd_pins dev_limit/aclk] [get_bd_pins phase_acc/CLK] [get_bd_pins phase_vld/CLK] [get_bd_pins pre_emph/aclk]
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins bq0/aresetn] [get_bd_pins bq1/aresetn] [get_bd_pins bq2/aresetn] [get_bd_pins bq3/aresetn] [get_bd_pins bq_round/aresetn] [get_bd_pins cordic_tx/aresetn] [get_bd_pins dev_limit/aresetn] [get_bd_pins pre_emph/aresetn] [get_bd_pins rst_inv/Op1]
  connect_bd_net -net bq0_out_data [get_bd_pins bq0/out_data] [get_bd_pins bq1/in_data]
  connect_bd_net -net bq0_out_valid [get_bd_pins bq0/out_valid] [get_bd_pins bq1/in_valid]
  connect_bd_net -net bq1_out_data [get_bd_pins bq1/out_data] [get_bd_pins bq2/in_data]
  connect_bd_net -net bq1_out_valid [get_bd_pins bq1/out_valid] [get_bd_pins bq2/in_valid]
  connect_bd_net -net bq2_out_data [get_bd_pins bq2/out_data] [get_bd_pins bq3/in_data]
  connect_bd_net -net bq2_out_valid [get_bd_pins bq2/out_valid] [get_bd_pins bq3/in_valid]
  connect_bd_net -net bq3_out_data [get_bd_pins bq3/out_data] [get_bd_pins bq_round/in_data]
  connect_bd_net -net bq3_out_valid [get_bd_pins bq3/out_valid] [get_bd_pins bq_round/in_valid]
  connect_bd_net -net bq_guard_dout [get_bd_pins bq0/in_data] [get_bd_pins bq_guard/dout]
  connect_bd_net -net bq_round_out_data [get_bd_pins bq_round/out_data] [get_bd_pins pre_emph/s_axis_data_tdata]
  connect_bd_net -net bq_round_out_valid [get_bd_pins bq_round/out_valid] [get_bd_pins pre_emph/s_axis_data_tvalid]
  connect_bd_net -net bq_zero_dout [get_bd_pins bq_guard/In0] [get_bd_pins bq_zero/dout]
  connect_bd_net -net cordic_tx_m_axis_dout_tdata [get_bd_pins m_axis_iq_tdata] [get_bd_pins cordic_tx/m_axis_dout_tdata]
  connect_bd_net -net cordic_tx_m_axis_dout_tvalid [get_bd_pins m_axis_iq_tvalid] [get_bd_pins cordic_tx/m_axis_dout_tvalid]
  connect_bd_net -net dev_limit_out_data [get_bd_pins dev_limit/out_data] [get_bd_pins phase_acc/B]
  connect_bd_net -net dev_limit_out_valid [get_bd_pins dev_limit/out_valid] [get_bd_pins phase_acc/CE] [get_bd_pins phase_vld/D]
  connect_bd_net -net phase_acc_Q [get_bd_pins phase_acc/Q] [get_bd_pins phase_pack/In1] [get_bd_pins phase_sign/Din]
  connect_bd_net -net phase_lsb_dout [get_bd_pins phase_lsb/dout] [get_bd_pins phase_pack/In0]
  connect_bd_net -net phase_pack_dout [get_bd_pins cordic_tx/s_axis_phase_tdata] [get_bd_pins phase_pack/dout]
  connect_bd_net -net phase_sign_Dout [get_bd_pins phase_pack/In2] [get_bd_pins phase_pack/In3] [get_bd_pins phase_sign/Dout]
  connect_bd_net -net phase_vld_Q [get_bd_pins cordic_tx/s_axis_phase_tvalid] [get_bd_pins phase_vld/Q]
  connect_bd_net -net pre_emph_m_axis_data_tdata [get_bd_pins pre_emph/m_axis_data_tdata] [get_bd_pins pre_sel/Din]
  connect_bd_net -net pre_emph_m_axis_data_tvalid [get_bd_pins dev_limit/in_valid] [get_bd_pins pre_emph/m_axis_data_tvalid]
  connect_bd_net -net pre_sel_Dout [get_bd_pins dev_limit/in_data] [get_bd_pins pre_sel/Dout]
  connect_bd_net -net rst_inv_Res [get_bd_pins phase_acc/SCLR] [get_bd_pins rst_inv/Res]
  connect_bd_net -net s_axis_audio_tdata_1 [get_bd_pins s_axis_audio_tdata] [get_bd_pins bq_guard/In1]
  connect_bd_net -net s_axis_audio_tvalid_1 [get_bd_pins s_axis_audio_tvalid] [get_bd_pins bq0/in_valid]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: fm_demod
proc create_hier_cell_fm_demod { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_fm_demod() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir O -from 15 -to 0 m_axis_audio_tdata
  create_bd_pin -dir O m_axis_audio_tvalid
  create_bd_pin -dir I -from 63 -to 0 s_axis_iq_tdata
  create_bd_pin -dir I s_axis_iq_tvalid
  create_bd_pin -dir O squelch_open

  # Create instance: bq0, and set properties
  set block_name iir_biquad
  set block_cell_name bq0
  if { [catch {set bq0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bq0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.A1 {-126387} \
   CONFIG.A2 {60948} \
   CONFIG.B0 {63218} \
   CONFIG.B1 {-126436} \
   CONFIG.B2 {63218} \
   CONFIG.COEF_W {18} \
   CONFIG.DATA_W {26} \
   CONFIG.FRAC {16} \
 ] $bq0

  # Create instance: bq1, and set properties
  set block_name iir_biquad
  set block_cell_name bq1
  if { [catch {set bq1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bq1 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.A1 {-129032} \
   CONFIG.A2 {63596} \
   CONFIG.B0 {64541} \
   CONFIG.B1 {-129082} \
   CONFIG.B2 {64541} \
   CONFIG.COEF_W {18} \
   CONFIG.DATA_W {26} \
   CONFIG.FRAC {16} \
 ] $bq1

  # Create instance: bq2, and set properties
  set block_name iir_biquad
  set block_cell_name bq2
  if { [catch {set bq2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bq2 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.A1 {-89464} \
   CONFIG.A2 {31299} \
   CONFIG.B0 {1843} \
   CONFIG.B1 {3686} \
   CONFIG.B2 {1843} \
   CONFIG.COEF_W {18} \
   CONFIG.DATA_W {26} \
   CONFIG.FRAC {16} \
 ] $bq2

  # Create instance: bq3, and set properties
  set block_name iir_biquad
  set block_cell_name bq3
  if { [catch {set bq3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bq3 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.A1 {-105626} \
   CONFIG.A2 {48793} \
   CONFIG.B0 {2176} \
   CONFIG.B1 {4352} \
   CONFIG.B2 {2176} \
   CONFIG.COEF_W {18} \
   CONFIG.DATA_W {26} \
   CONFIG.FRAC {16} \
 ] $bq3

  # Create instance: bq_guard, and set properties
  set bq_guard [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 bq_guard ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {8} \
   CONFIG.IN1_WIDTH {18} \
   CONFIG.NUM_PORTS {2} \
 ] $bq_guard

  # Create instance: bq_zero, and set properties
  set bq_zero [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 bq_zero ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {8} \
 ] $bq_zero

  # Create instance: cordic_rx, and set properties
  set cordic_rx [ create_bd_cell -type ip -vlnv xilinx.com:ip:cordic:6.0 cordic_rx ]
  set_property -dict [ list \
   CONFIG.ARESETN {true} \
   CONFIG.Architectural_Configuration {Word_Serial} \
   CONFIG.Coarse_Rotation {true} \
   CONFIG.Compensation_Scaling {No_Scale_Compensation} \
   CONFIG.Data_Format {SignedFraction} \
   CONFIG.Functional_Selection {Translate} \
   CONFIG.Input_Width {34} \
   CONFIG.Iterations {0} \
   CONFIG.Output_Width {38} \
   CONFIG.Phase_Format {Scaled_Radians} \
   CONFIG.Pipelining_Mode {Maximum} \
   CONFIG.Precision {0} \
   CONFIG.Round_Mode {Truncate} \
   CONFIG.flow_control {NonBlocking} \
 ] $cordic_rx

  # Create instance: de_acc, and set properties
  set de_acc [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_accum:12.0 de_acc ]
  set_property -dict [ list \
   CONFIG.Accum_Mode {Add} \
   CONFIG.Bypass {false} \
   CONFIG.CE {true} \
   CONFIG.Input_Type {Signed} \
   CONFIG.Input_Width {28} \
   CONFIG.Latency {1} \
   CONFIG.Output_Width {32} \
   CONFIG.SCLR {true} \
 ] $de_acc

  # Create instance: de_ce, and set properties
  set de_ce [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram:12.0 de_ce ]
  set_property -dict [ list \
   CONFIG.CE {false} \
   CONFIG.Depth {4} \
   CONFIG.Width {1} \
 ] $de_ce

  # Create instance: de_fb, and set properties
  set de_fb [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 de_fb ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {16} \
   CONFIG.DIN_WIDTH {32} \
   CONFIG.DOUT_WIDTH {16} \
 ] $de_fb

  # Create instance: de_mul, and set properties
  set de_mul [ create_bd_cell -type ip -vlnv xilinx.com:ip:mult_gen:12.0 de_mul ]
  set_property -dict [ list \
   CONFIG.ConstValue {1795} \
   CONFIG.MultType {Constant_Coefficient_Multiplier} \
   CONFIG.PipeStages {1} \
   CONFIG.PortAType {Signed} \
   CONFIG.PortAWidth {17} \
 ] $de_mul

  # Create instance: de_out, and set properties
  set de_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 de_out ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {14} \
   CONFIG.DIN_WIDTH {32} \
   CONFIG.DOUT_WIDTH {18} \
 ] $de_out

  # Create instance: de_sub, and set properties
  set de_sub [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 de_sub ]
  set_property -dict [ list \
   CONFIG.A_Width {16} \
   CONFIG.Add_Mode {Subtract} \
   CONFIG.B_Width {16} \
   CONFIG.CE {false} \
   CONFIG.Latency {1} \
   CONFIG.Out_Width {17} \
 ] $de_sub

  # Create instance: de_vld, and set properties
  set de_vld [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram:12.0 de_vld ]
  set_property -dict [ list \
   CONFIG.CE {false} \
   CONFIG.Depth {1} \
   CONFIG.Width {1} \
 ] $de_vld

  # Create instance: disc_sat, and set properties
  set block_name round_sat
  set block_cell_name disc_sat
  if { [catch {set disc_sat [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $disc_sat eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.IN_W {20} \
   CONFIG.LIMIT {0} \
   CONFIG.OUT_W {16} \
   CONFIG.ROUND {0} \
   CONFIG.SHIFT {2} \
 ] $disc_sat

  # Create instance: disc_vld, and set properties
  set disc_vld [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram:12.0 disc_vld ]
  set_property -dict [ list \
   CONFIG.CE {false} \
   CONFIG.Depth {1} \
   CONFIG.Width {1} \
 ] $disc_vld

  # Create instance: iq_i, and set properties
  set iq_i [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 iq_i ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {64} \
   CONFIG.DOUT_WIDTH {32} \
 ] $iq_i

  # Create instance: iq_i_sign, and set properties
  set iq_i_sign [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 iq_i_sign ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {31} \
   CONFIG.DIN_WIDTH {64} \
   CONFIG.DOUT_WIDTH {1} \
 ] $iq_i_sign

  # Create instance: iq_pack, and set properties
  set iq_pack [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 iq_pack ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {32} \
   CONFIG.IN1_WIDTH {1} \
   CONFIG.IN2_WIDTH {1} \
   CONFIG.IN3_WIDTH {6} \
   CONFIG.IN4_WIDTH {32} \
   CONFIG.IN5_WIDTH {1} \
   CONFIG.IN6_WIDTH {1} \
   CONFIG.IN7_WIDTH {6} \
   CONFIG.NUM_PORTS {8} \
 ] $iq_pack

  # Create instance: iq_pad, and set properties
  set iq_pad [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 iq_pad ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {6} \
 ] $iq_pad

  # Create instance: iq_q, and set properties
  set iq_q [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 iq_q ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {63} \
   CONFIG.DIN_TO {32} \
   CONFIG.DIN_WIDTH {64} \
   CONFIG.DOUT_WIDTH {32} \
 ] $iq_q

  # Create instance: iq_q_sign, and set properties
  set iq_q_sign [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 iq_q_sign ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {63} \
   CONFIG.DIN_TO {63} \
   CONFIG.DIN_WIDTH {64} \
   CONFIG.DOUT_WIDTH {1} \
 ] $iq_q_sign

  # Create instance: mag_reg, and set properties
  set mag_reg [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram:12.0 mag_reg ]
  set_property -dict [ list \
   CONFIG.CE {true} \
   CONFIG.Depth {1} \
   CONFIG.Width {34} \
 ] $mag_reg

  # Create instance: mag_sel, and set properties
  set mag_sel [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mag_sel ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {37} \
   CONFIG.DIN_TO {4} \
   CONFIG.DIN_WIDTH {80} \
   CONFIG.DOUT_WIDTH {34} \
 ] $mag_sel

  # Create instance: out_round, and set properties
  set block_name round_sat
  set block_cell_name out_round
  if { [catch {set out_round [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $out_round eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.IN_W {26} \
   CONFIG.LIMIT {0} \
   CONFIG.OUT_W {16} \
   CONFIG.ROUND {1} \
   CONFIG.SHIFT {8} \
 ] $out_round

  # Create instance: phase_diff, and set properties
  set phase_diff [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 phase_diff ]
  set_property -dict [ list \
   CONFIG.A_Width {20} \
   CONFIG.Add_Mode {Subtract} \
   CONFIG.B_Width {20} \
   CONFIG.CE {true} \
   CONFIG.Latency {1} \
   CONFIG.Out_Width {20} \
 ] $phase_diff

  # Create instance: phase_sel, and set properties
  set phase_sel [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 phase_sel ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {75} \
   CONFIG.DIN_TO {56} \
   CONFIG.DIN_WIDTH {80} \
   CONFIG.DOUT_WIDTH {20} \
 ] $phase_sel

  # Create instance: phase_z1, and set properties
  set phase_z1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram:12.0 phase_z1 ]
  set_property -dict [ list \
   CONFIG.CE {true} \
   CONFIG.Depth {1} \
   CONFIG.Width {20} \
 ] $phase_z1

  # Create instance: rst_inv, and set properties
  set rst_inv [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 rst_inv ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
 ] $rst_inv

  # Create instance: sq_th_close, and set properties
  set sq_th_close [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 sq_th_close ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {156287866} \
   CONFIG.CONST_WIDTH {34} \
 ] $sq_th_close

  # Create instance: sq_th_open, and set properties
  set sq_th_open [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 sq_th_open ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {312575733} \
   CONFIG.CONST_WIDTH {34} \
 ] $sq_th_open

  # Create instance: squelch, and set properties
  set block_name fm_squelch
  set block_cell_name squelch
  if { [catch {set squelch [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $squelch eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.AUDIO_W {16} \
   CONFIG.AVG_LOG2 {8} \
   CONFIG.MAG_W {34} \
 ] $squelch

  # Create port connections
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins bq0/aclk] [get_bd_pins bq1/aclk] [get_bd_pins bq2/aclk] [get_bd_pins bq3/aclk] [get_bd_pins cordic_rx/aclk] [get_bd_pins de_acc/CLK] [get_bd_pins de_ce/CLK] [get_bd_pins de_mul/CLK] [get_bd_pins de_sub/CLK] [get_bd_pins de_vld/CLK] [get_bd_pins disc_sat/aclk] [get_bd_pins disc_vld/CLK] [get_bd_pins mag_reg/CLK] [get_bd_pins out_round/aclk] [get_bd_pins phase_diff/CLK] [get_bd_pins phase_z1/CLK] [get_bd_pins squelch/aclk]
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins bq0/aresetn] [get_bd_pins bq1/aresetn] [get_bd_pins bq2/aresetn] [get_bd_pins bq3/aresetn] [get_bd_pins cordic_rx/aresetn] [get_bd_pins disc_sat/aresetn] [get_bd_pins out_round/aresetn] [get_bd_pins rst_inv/Op1] [get_bd_pins squelch/aresetn]
  connect_bd_net -net bq0_out_data [get_bd_pins bq0/out_data] [get_bd_pins bq1/in_data]
  connect_bd_net -net bq0_out_valid [get_bd_pins bq0/out_valid] [get_bd_pins bq1/in_valid]
  connect_bd_net -net bq1_out_data [get_bd_pins bq1/out_data] [get_bd_pins bq2/in_data]
  connect_bd_net -net bq1_out_valid [get_bd_pins bq1/out_valid] [get_bd_pins bq2/in_valid]
  connect_bd_net -net bq2_out_data [get_bd_pins bq2/out_data] [get_bd_pins bq3/in_data]
  connect_bd_net -net bq2_out_valid [get_bd_pins bq2/out_valid] [get_bd_pins bq3/in_valid]
  connect_bd_net -net bq3_out_data [get_bd_pins bq3/out_data] [get_bd_pins out_round/in_data]
  connect_bd_net -net bq3_out_valid [get_bd_pins bq3/out_valid] [get_bd_pins out_round/in_valid]
  connect_bd_net -net bq_guard_dout [get_bd_pins bq0/in_data] [get_bd_pins bq_guard/dout]
  connect_bd_net -net bq_zero_dout [get_bd_pins bq_guard/In0] [get_bd_pins bq_zero/dout]
  connect_bd_net -net cordic_rx_m_axis_dout_tdata [get_bd_pins cordic_rx/m_axis_dout_tdata] [get_bd_pins mag_sel/Din] [get_bd_pins phase_sel/Din]
  connect_bd_net -net cordic_rx_m_axis_dout_tvalid [get_bd_pins cordic_rx/m_axis_dout_tvalid] [get_bd_pins disc_vld/D] [get_bd_pins mag_reg/CE] [get_bd_pins phase_diff/CE] [get_bd_pins phase_z1/CE]
  connect_bd_net -net de_acc_Q [get_bd_pins de_acc/Q] [get_bd_pins de_fb/Din] [get_bd_pins de_out/Din]
  connect_bd_net -net de_ce_Q [get_bd_pins de_acc/CE] [get_bd_pins de_ce/Q] [get_bd_pins de_vld/D]
  connect_bd_net -net de_fb_Dout [get_bd_pins de_fb/Dout] [get_bd_pins de_sub/B]
  connect_bd_net -net de_mul_P [get_bd_pins de_acc/B] [get_bd_pins de_mul/P]
  connect_bd_net -net de_out_Dout [get_bd_pins bq_guard/In1] [get_bd_pins de_out/Dout]
  connect_bd_net -net de_sub_S [get_bd_pins de_mul/A] [get_bd_pins de_sub/S]
  connect_bd_net -net de_vld_Q [get_bd_pins bq0/in_valid] [get_bd_pins de_vld/Q]
  connect_bd_net -net disc_sat_out_data [get_bd_pins disc_sat/out_data] [get_bd_pins squelch/disc]
  connect_bd_net -net disc_sat_out_valid [get_bd_pins disc_sat/out_valid] [get_bd_pins squelch/in_valid]
  connect_bd_net -net disc_vld_Q [get_bd_pins disc_sat/in_valid] [get_bd_pins disc_vld/Q]
  connect_bd_net -net iq_i_Dout [get_bd_pins iq_i/Dout] [get_bd_pins iq_pack/In0]
  connect_bd_net -net iq_i_sign_Dout [get_bd_pins iq_i_sign/Dout] [get_bd_pins iq_pack/In1] [get_bd_pins iq_pack/In2]
  connect_bd_net -net iq_pack_dout [get_bd_pins cordic_rx/s_axis_cartesian_tdata] [get_bd_pins iq_pack/dout]
  connect_bd_net -net iq_pad_dout [get_bd_pins iq_pack/In3] [get_bd_pins iq_pack/In7] [get_bd_pins iq_pad/dout]
  connect_bd_net -net iq_q_Dout [get_bd_pins iq_pack/In4] [get_bd_pins iq_q/Dout]
  connect_bd_net -net iq_q_sign_Dout [get_bd_pins iq_pack/In5] [get_bd_pins iq_pack/In6] [get_bd_pins iq_q_sign/Dout]
  connect_bd_net -net mag_reg_Q [get_bd_pins mag_reg/Q] [get_bd_pins squelch/mag]
  connect_bd_net -net mag_sel_Dout [get_bd_pins mag_reg/D] [get_bd_pins mag_sel/Dout]
  connect_bd_net -net out_round_out_data [get_bd_pins m_axis_audio_tdata] [get_bd_pins out_round/out_data]
  connect_bd_net -net out_round_out_valid [get_bd_pins m_axis_audio_tvalid] [get_bd_pins out_round/out_valid]
  connect_bd_net -net phase_diff_S [get_bd_pins disc_sat/in_data] [get_bd_pins phase_diff/S]
  connect_bd_net -net phase_sel_Dout [get_bd_pins phase_diff/A] [get_bd_pins phase_sel/Dout] [get_bd_pins phase_z1/D]
  connect_bd_net -net phase_z1_Q [get_bd_pins phase_diff/B] [get_bd_pins phase_z1/Q]
  connect_bd_net -net rst_inv_Res [get_bd_pins de_acc/SCLR] [get_bd_pins rst_inv/Res]
  connect_bd_net -net s_axis_iq_tdata_1 [get_bd_pins s_axis_iq_tdata] [get_bd_pins iq_i/Din] [get_bd_pins iq_i_sign/Din] [get_bd_pins iq_q/Din] [get_bd_pins iq_q_sign/Din]
  connect_bd_net -net s_axis_iq_tvalid_1 [get_bd_pins s_axis_iq_tvalid] [get_bd_pins cordic_rx/s_axis_cartesian_tvalid]
  connect_bd_net -net sq_th_close_dout [get_bd_pins sq_th_close/dout] [get_bd_pins squelch/th_close]
  connect_bd_net -net sq_th_open_dout [get_bd_pins sq_th_open/dout] [get_bd_pins squelch/th_open]
  connect_bd_net -net squelch_audio [get_bd_pins de_sub/A] [get_bd_pins squelch/audio]
  connect_bd_net -net squelch_gate [get_bd_pins squelch_open] [get_bd_pins squelch/gate]
  connect_bd_net -net squelch_out_valid [get_bd_pins de_ce/D] [get_bd_pins squelch/out_valid]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports
  set aclk [ create_bd_port -dir I -type clk aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {aresetn} \
   CONFIG.FREQ_HZ {100000000} \
 ] $aclk
  set aresetn [ create_bd_port -dir I -type rst aresetn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $aresetn
  set rx_audio_tdata [ create_bd_port -dir O -from 15 -to 0 rx_audio_tdata ]
  set rx_audio_tvalid [ create_bd_port -dir O rx_audio_tvalid ]
  set rx_iq_tdata [ create_bd_port -dir I -from 63 -to 0 rx_iq_tdata ]
  set rx_iq_tvalid [ create_bd_port -dir I rx_iq_tvalid ]
  set rx_squelch_open [ create_bd_port -dir O rx_squelch_open ]
  set tx_audio_tdata [ create_bd_port -dir I -from 15 -to 0 tx_audio_tdata ]
  set tx_audio_tvalid [ create_bd_port -dir I tx_audio_tvalid ]
  set tx_iq_tdata [ create_bd_port -dir O -from 63 -to 0 tx_iq_tdata ]
  set tx_iq_tvalid [ create_bd_port -dir O tx_iq_tvalid ]

  # Create instance: fm_demod
  create_hier_cell_fm_demod [current_bd_instance .] fm_demod

  # Create instance: fm_mod
  create_hier_cell_fm_mod [current_bd_instance .] fm_mod

  # Create port connections
  connect_bd_net -net aclk_1 [get_bd_ports aclk] [get_bd_pins fm_demod/aclk] [get_bd_pins fm_mod/aclk]
  connect_bd_net -net aresetn_1 [get_bd_ports aresetn] [get_bd_pins fm_demod/aresetn] [get_bd_pins fm_mod/aresetn]
  connect_bd_net -net fm_demod_m_axis_audio_tdata [get_bd_ports rx_audio_tdata] [get_bd_pins fm_demod/m_axis_audio_tdata]
  connect_bd_net -net fm_demod_m_axis_audio_tvalid [get_bd_ports rx_audio_tvalid] [get_bd_pins fm_demod/m_axis_audio_tvalid]
  connect_bd_net -net fm_demod_squelch_open [get_bd_ports rx_squelch_open] [get_bd_pins fm_demod/squelch_open]
  connect_bd_net -net fm_mod_m_axis_iq_tdata [get_bd_ports tx_iq_tdata] [get_bd_pins fm_mod/m_axis_iq_tdata]
  connect_bd_net -net fm_mod_m_axis_iq_tvalid [get_bd_ports tx_iq_tvalid] [get_bd_pins fm_mod/m_axis_iq_tvalid]
  connect_bd_net -net rx_iq_tdata_1 [get_bd_ports rx_iq_tdata] [get_bd_pins fm_demod/s_axis_iq_tdata]
  connect_bd_net -net rx_iq_tvalid_1 [get_bd_ports rx_iq_tvalid] [get_bd_pins fm_demod/s_axis_iq_tvalid]
  connect_bd_net -net tx_audio_tdata_1 [get_bd_ports tx_audio_tdata] [get_bd_pins fm_mod/s_axis_audio_tdata]
  connect_bd_net -net tx_audio_tvalid_1 [get_bd_ports tx_audio_tvalid] [get_bd_pins fm_mod/s_axis_audio_tvalid]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


