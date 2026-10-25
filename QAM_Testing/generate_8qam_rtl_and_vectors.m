%% Generate Verilog RTL for 8-QAM TX & RX and Export Golden Test Vectors for Vivado 2019.1
clear; clc; close all;
bdclose('all');

qamDir = 'D:\HoriTech_Files\QAM_Testing';
exDir  = fullfile(qamDir, 'QAMTxRxHDLExample');
rtlTxDir = fullfile(qamDir, 'hdl_rtl_verilog', 'QAM_Tx_HDL');
rtlRxDir = fullfile(qamDir, 'hdl_rtl_verilog', 'QAM_Rx_HDL');
tvDir    = fullfile(qamDir, 'test_vectors');

if ~exist(rtlTxDir, 'dir'), mkdir(rtlTxDir); end
if ~exist(rtlRxDir, 'dir'), mkdir(rtlRxDir); end
if ~exist(tvDir, 'dir'),    mkdir(tvDir);    end

cd(exDir);
qam_params = comm8qamtxrxhdl_init();
assignin('base', 'qam_params', qam_params);

modelName = 'comm8qamtxrxhdl';
load_system(modelName);
set_param(modelName, 'StopFcn', '');

fprintf('=================================================================\n');
fprintf('STEP 1: GENERATING VERILOG RTL FOR QAM Tx HDL\n');
fprintf('=================================================================\n');
makehdl([modelName '/QAM Tx HDL'], ...
    'TargetLanguage', 'Verilog', ...
    'TargetDirectory', rtlTxDir);

fprintf('\n=================================================================\n');
fprintf('STEP 2: GENERATING VERILOG RTL FOR QAM Rx HDL\n');
fprintf('=================================================================\n');
makehdl([modelName '/QAM Rx HDL'], ...
    'TargetLanguage', 'Verilog', ...
    'TargetDirectory', rtlRxDir);

fprintf('\n=================================================================\n');
fprintf('STEP 3: RUNNING SIMULINK MODEL & EXPORTING GOLDEN TEST VECTORS\n');
fprintf('=================================================================\n');

% Add temporary To Workspace blocks at top level to capture exact fixed-point streams
add_block('simulink/Sinks/To Workspace', [modelName '/Log_TX_Out'], ...
    'VariableName', 'sim_tx_out', 'SaveFormat', 'Array', 'SampleTime', '-1');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_RX_In'], ...
    'VariableName', 'sim_rx_in', 'SaveFormat', 'Array', 'SampleTime', '-1');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_RX_pktStart'], ...
    'VariableName', 'sim_rx_pktStart', 'SaveFormat', 'Array', 'SampleTime', '-1');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_RX_dValid'], ...
    'VariableName', 'sim_rx_dValid', 'SaveFormat', 'Array', 'SampleTime', '-1');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_RX_b1'], ...
    'VariableName', 'sim_rx_b1', 'SaveFormat', 'Array', 'SampleTime', '-1');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_RX_b2'], ...
    'VariableName', 'sim_rx_b2', 'SaveFormat', 'Array', 'SampleTime', '-1');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_RX_b3'], ...
    'VariableName', 'sim_rx_b3', 'SaveFormat', 'Array', 'SampleTime', '-1');

add_line(modelName, 'QAM Tx HDL/1', 'Log_TX_Out/1', 'autorouting', 'on');
add_line(modelName, 'Channel/1',    'Log_RX_In/1',  'autorouting', 'on');
add_line(modelName, 'QAM Rx HDL/1', 'Log_RX_pktStart/1', 'autorouting', 'on');
add_line(modelName, 'QAM Rx HDL/2', 'Log_RX_dValid/1',   'autorouting', 'on');
add_line(modelName, 'QAM Rx HDL/3', 'Log_RX_b1/1',       'autorouting', 'on');
add_line(modelName, 'QAM Rx HDL/4', 'Log_RX_b2/1',       'autorouting', 'on');
add_line(modelName, 'QAM Rx HDL/5', 'Log_RX_b3/1',       'autorouting', 'on');

sim(modelName);

% Close without saving temporary logging blocks
close_system(modelName, 0);

% Export TX Golden Output (first 4000 4-MSPS samples = 1000 symbols)
N_tx = min(4000, length(sim_tx_out));
tx_re_int = storedInteger(real(sim_tx_out(1:N_tx)));
tx_im_int = storedInteger(imag(sim_tx_out(1:N_tx)));
tx_re_u16 = mod(int32(tx_re_int), 65536);
tx_im_u16 = mod(int32(tx_im_int), 65536);

fid_tx_re = fopen(fullfile(tvDir, 'golden_tx_out_re.mem'), 'w');
fid_tx_im = fopen(fullfile(tvDir, 'golden_tx_out_im.mem'), 'w');
for i = 1:N_tx
    fprintf(fid_tx_re, '%04X\n', tx_re_u16(i));
    fprintf(fid_tx_im, '%04X\n', tx_im_u16(i));
end
fclose(fid_tx_re);
fclose(fid_tx_im);
fprintf('Exported %d TX golden complex samples (sfix16_En15).\n', N_tx);

% Export RX Stimulus Input (80000 4-MSPS samples) and Golden Outputs (40000 2-MSPS samples)
N_rx_in  = length(sim_rx_in);
N_rx_out = length(sim_rx_dValid);

rx_in_re_int = storedInteger(real(sim_rx_in));
rx_in_im_int = storedInteger(imag(sim_rx_in));
rx_in_re_u16 = mod(int32(rx_in_re_int), 65536);
rx_in_im_u16 = mod(int32(rx_in_im_int), 65536);

fid_rx_re = fopen(fullfile(tvDir, 'rx_in_re.mem'), 'w');
fid_rx_im = fopen(fullfile(tvDir, 'rx_in_im.mem'), 'w');
for i = 1:N_rx_in
    fprintf(fid_rx_re, '%04X\n', rx_in_re_u16(i));
    fprintf(fid_rx_im, '%04X\n', rx_in_im_u16(i));
end
fclose(fid_rx_re);
fclose(fid_rx_im);

% Pack RX golden outputs: [packetStart, dValid, bit1, bit2, bit3] as 5-bit binary
fid_rx_out = fopen(fullfile(tvDir, 'golden_rx_out.mem'), 'w');
for i = 1:N_rx_out
    fprintf(fid_rx_out, '%d%d%d%d%d\n', ...
        sim_rx_pktStart(i), sim_rx_dValid(i), sim_rx_b1(i), sim_rx_b2(i), sim_rx_b3(i));
end
fclose(fid_rx_out);

fprintf('Exported %d RX input samples and %d RX golden output samples.\n', N_rx_in, N_rx_out);
fprintf('=================================================================\n');
fprintf('ALL RTL & TEST VECTORS GENERATED SUCCESSFULLY!\n');
fprintf('=================================================================\n');

