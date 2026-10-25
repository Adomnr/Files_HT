# ==============================================================================
# create_vivado_project.tcl
# Creates a Vivado 2019.1 project containing the generated 8-QAM TX & RX
# Verilog RTL files and SystemVerilog testbenches (tb_QAM_Tx_HDL, tb_QAM_Rx_HDL)
# ==============================================================================

set proj_name "QAM8_TxRx_HDL_Vivado"
set proj_dir  "D:/HoriTech_Files/QAM_Testing/vivado_project_2019_1"

# Target part: Xilinx Zynq-7000 xc7z020clg484-1 (standard SDR FPGA target)
create_project -force $proj_name $proj_dir -part xc7z020clg484-1

# Add TX & RX Verilog RTL source files
add_files -fileset sources_1 [glob D:/HoriTech_Files/QAM_Testing/hdl_rtl_verilog/QAM_Tx_HDL/comm8qamtxrxhdl/*.v]
add_files -fileset sources_1 [glob D:/HoriTech_Files/QAM_Testing/hdl_rtl_verilog/QAM_Rx_HDL/comm8qamtxrxhdl/*.v]

# Add SystemVerilog Testbenches to sim_1
add_files -fileset sim_1 D:/HoriTech_Files/QAM_Testing/tb_QAM_Tx_HDL.sv
add_files -fileset sim_1 D:/HoriTech_Files/QAM_Testing/tb_QAM_Rx_HDL.sv

# Set default top modules
set_property top QAM_Rx_HDL [get_filesets sources_1]
set_property top tb_QAM_Rx_HDL [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "========================================================================"
puts " Successfully created Vivado 2019.1 project:"
puts "   $proj_dir/$proj_name.xpr"
puts "========================================================================"
exit

