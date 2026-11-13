@echo off
rem ---------------------------------------------------------------------------
rem xsim_batch.bat - compile, elaborate and run test bench tb_fm with the Vivado
rem simulator from the command line (no GUI, no waveform database, so it runs
rem faster than "Run Simulation" in the GUI).
rem
rem   xsim_batch.bat [IN_W] [clocks per sample]        defaults: 16 64
rem
rem Before:  matlab  hw_export_vectors(IN_W)
rem          vivado -mode batch -source run_sim.tcl -tclargs IN_W scripts
rem After:   matlab  hw_compare(IN_W)
rem
rem The library list below is the one Vivado writes to elaborate.bat for this
rem block design; update it from there if IP cores are added.
rem ---------------------------------------------------------------------------
setlocal
set VIVADO_BIN=C:\Xilinx\Vivado\2019.1\bin
set IN_W=%1
if "%IN_W%"=="" set IN_W=16
set SPACING=%2
if "%SPACING%"=="" set SPACING=64

set HERE=%~dp0
for %%i in ("%HERE%..\matlab\data\hw_i%IN_W%") do set VEC=%%~fi
set VEC=%VEC:\=/%
if not exist "%VEC%/rx_iq.txt" (echo no stimulus in %VEC% - run hw_export_vectors(%IN_W%^) in MATLAB & exit /b 1)

cd /d "%HERE%..\FM_Demod\FM_Demod.sim\sim_1\behav\xsim" || (echo no simulation scripts - run run_sim.tcl with "scripts" first & exit /b 1)

call "%VIVADO_BIN%\xvlog.bat" --incr --relax -prj tb_fm_vlog.prj -log xvlog.log
if errorlevel 1 exit /b 1
call "%VIVADO_BIN%\xvhdl.bat" --incr --relax -prj tb_fm_vhdl.prj -log xvhdl.log
if errorlevel 1 exit /b 1
call "%VIVADO_BIN%\xelab.bat" --debug off --relax --mt 2 -generic_top "IN_W=%IN_W%" ^
 -L xil_defaultlib -L util_vector_logic_v2_0_1 -L xlslice_v1_0_2 -L xlconstant_v1_1_6 -L xlconcat_v2_1_3 ^
 -L xbip_utils_v3_0_10 -L c_reg_fd_v12_0_6 -L xbip_dsp48_wrapper_v3_0_4 -L xbip_pipe_v3_0_6 ^
 -L xbip_dsp48_addsub_v3_0_6 -L xbip_addsub_v3_0_6 -L c_addsub_v12_0_13 -L xbip_bram18k_v3_0_6 ^
 -L mult_gen_v12_0_15 -L axi_utils_v2_0_6 -L cordic_v6_0_15 -L c_mux_bit_v12_0_6 -L c_shift_ram_v12_0_13 ^
 -L xbip_dsp48_acc_v3_0_6 -L xbip_accum_v3_0_6 -L c_accum_v12_0_13 -L fir_compiler_v7_2_12 ^
 -L unisims_ver -L unimacro_ver -L secureip -L xpm ^
 --snapshot tb_fm_fast xil_defaultlib.tb_fm xil_defaultlib.glbl -log elaborate.log
if errorlevel 1 exit /b 1
call "%VIVADO_BIN%\xsim.bat" tb_fm_fast -R -log simulate.log -testplusarg "DIR=%VEC%" -testplusarg "SPACING=%SPACING%"
echo xsim exit code %errorlevel%
