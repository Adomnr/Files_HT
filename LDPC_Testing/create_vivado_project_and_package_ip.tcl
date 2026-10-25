# =============================================================================
# Vivado 2019.1 Tcl Script: create_vivado_project_and_package_ip.tcl
# 1. Creates Vivado 2019.1 Project (DVBS2_LDPC_Decoder_Vivado.xpr)
# 2. Adds MATLAB HDL Coder generated Verilog files for DVBS2_LDPC_Decoder_DUT
# 3. Packages DVBS2_LDPC_Decoder_DUT as a Vivado IP Core (component.xml)
# 4. Configures tb_DVBS2_LDPC_Decoder_DUT.sv as Simulation Top
# =============================================================================

set work_dir "d:/HoriTech_Files/LDPC_Testing"
set rtl_dir  "${work_dir}/hdl_ip_verilog/DVBS2_LDPC_Decoder_Model"
set proj_dir "${work_dir}/vivado_project_2019_1"
set proj_name "DVBS2_LDPC_Decoder_Vivado"

puts "=== Creating Vivado 2019.1 Project: ${proj_dir}/${proj_name}.xpr ==="
create_project -force ${proj_name} ${proj_dir} -part xc7vx485tffg1157-1

# Add all generated Verilog RTL files
set rtl_files [glob "${rtl_dir}/*.v"]
add_files -norecurse -fileset [get_filesets sources_1] $rtl_files
set_property top DVBS2_LDPC_Decoder_DUT [get_filesets sources_1]
update_compile_order -fileset sources_1

# Package DVBS2_LDPC_Decoder_DUT as a Vivado 2019.1 IP Core (component.xml)
puts "=== Packaging DVBS2_LDPC_Decoder_DUT as Vivado 2019.1 IP Core ==="
ipx::package_project -root_dir ${rtl_dir} -vendor mathworks.com -library whdl -taxonomy /Wireless_HDL_Toolbox -import_files -set_current false
ipx::unload_core ${rtl_dir}/component.xml

# Add SystemVerilog Testbench to sim_1
puts "=== Adding Testbench tb_DVBS2_LDPC_Decoder_DUT.sv to sim_1 ==="
add_files -fileset sim_1 -norecurse "${work_dir}/tb_DVBS2_LDPC_Decoder_DUT.sv"
set_property top tb_DVBS2_LDPC_Decoder_DUT [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {1000us} -objects [get_filesets sim_1]
update_compile_order -fileset sim_1

close_project
puts "=== Vivado 2019.1 Project & IP Core Packaging Complete! ==="
exit

