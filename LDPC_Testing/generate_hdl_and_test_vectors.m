%% Generate HDL IP (Verilog) for DVB-S2 LDPC Decoder & Export Test Vectors for Vivado 2019.1
% Workspace: d:\HoriTech_Files\LDPC_Testing
% Target Block: DVBS2_LDPC_Decoder_Model/DVBS2_LDPC_Decoder_DUT

clear; clc; close all;
bdclose('all');

workDir = 'd:\HoriTech_Files\LDPC_Testing';
cd(workDir);

tvDir  = fullfile(workDir, 'test_vectors');
hdlDir = fullfile(workDir, 'hdl_ip_verilog');
if ~exist(tvDir, 'dir')
    mkdir(tvDir);
end
if ~exist(hdlDir, 'dir')
    mkdir(hdlDir);
end

fprintf('=================================================================\n');
fprintf('STEP 1: GENERATING MATLAB STIMULUS & GOLDEN TEST VECTORS\n');
fprintf('=================================================================\n');

rng(42); % Reproducible seed matching Simulink verification

N_ldpc = 16200;
H_short_1_2 = dvbsLDPCPCM("1/2", "short");
encCfg = ldpcEncoderConfig(H_short_1_2);
decCfgRef = ldpcDecoderConfig(H_short_1_2, 'norm-min-sum');
K_ldpc = encCfg.NumInformationBits; % 7200

txBits = randi([0 1], K_ldpc, 1, 'int8');
codeword = ldpcEncode(txBits, encCfg);

% BPSK modulate (0 -> +1, 1 -> -1) and add AWGN (Es/N0 = 2.0 dB)
txSym = 1 - 2*double(codeword);
snr_dB = 2.0;
noiseVar = 10^(-snr_dB/10);
rxSym = txSym + sqrt(noiseVar/2)*randn(size(txSym));
llrFloat = 2 * rxSym / noiseVar;

% Quantize LLRs to signed fixed-point sfix6_En2 (WordLength=6, FractionLength=2)
llrFi = fi(llrFloat, 1, 6, 2);

% Extract stored integer representation (-32 to +31) and 6-bit two's complement hex
llrStoredInt = storedInteger(llrFi);
llrUint6     = mod(int32(llrStoredInt), 64); % 0..63 (6-bit two's complement)

% 1. Write input_llr_6bit_hex.mem for Verilog $readmemh
hexFile = fullfile(tvDir, 'input_llr_6bit_hex.mem');
fid = fopen(hexFile, 'w');
for i = 1:N_ldpc
    fprintf(fid, '%02X\n', llrUint6(i));
end
fclose(fid);
fprintf('Wrote %d 6-bit hex LLR samples to: %s\n', N_ldpc, hexFile);

% 2. Write input_llr_6bit_bin.mem for Verilog $readmemb
binFile = fullfile(tvDir, 'input_llr_6bit_bin.mem');
fid = fopen(binFile, 'w');
for i = 1:N_ldpc
    fprintf(fid, '%s\n', dec2bin(llrUint6(i), 6));
end
fclose(fid);
fprintf('Wrote %d 6-bit binary LLR samples to: %s\n', N_ldpc, binFile);

% 3. Write human-readable CSV/TXT table of input LLRs
csvFile = fullfile(tvDir, 'input_llr_details.csv');
fid = fopen(csvFile, 'w');
fprintf(fid, 'SampleIdx,CodewordBit,FloatLLR,FixedPointLLR_sfix6_En2,StoredInt,Hex6Bit\n');
for i = 1:N_ldpc
    fprintf(fid, '%d,%d,%.6f,%.2f,%d,%02X\n', ...
        i-1, codeword(i), llrFloat(i), double(llrFi(i)), llrStoredInt(i), llrUint6(i));
end
fclose(fid);
fprintf('Wrote detailed LLR table to: %s\n', csvFile);

% 4. Write golden_output_bits.mem for Verilog $readmemb
goldFile = fullfile(tvDir, 'golden_output_bits.mem');
fid = fopen(goldFile, 'w');
for i = 1:K_ldpc
    fprintf(fid, '%d\n', txBits(i));
end
fclose(fid);
fprintf('Wrote %d golden decoded output bits to: %s\n', K_ldpc, goldFile);

% 5. Write golden_metadata.txt
metaFile = fullfile(tvDir, 'golden_metadata.txt');
fid = fopen(metaFile, 'w');
fprintf(fid, 'FECFrame          = Short\n');
fprintf(fid, 'CodeRate          = 1/2 (Effective 4/9)\n');
fprintf(fid, 'N_ldpc            = %d\n', N_ldpc);
fprintf(fid, 'K_ldpc            = %d\n', K_ldpc);
fprintf(fid, 'Algorithm         = Normalized min-sum (ScalingFactor = 0.75)\n');
fprintf(fid, 'Termination       = Early (MaxNumIterations = 8)\n');
fprintf(fid, 'Parallelism       = 45\n');
fprintf(fid, 'InputDataType     = sfix6_En2 (6-bit signed, 2 fractional bits)\n');
fprintf(fid, 'ChannelSNR_EsN0   = %.2f dB\n', snr_dB);
fprintf(fid, 'RawCodewordErrors = %d / %d\n', sum(int8(llrFloat < 0) ~= codeword), N_ldpc);
fprintf(fid, 'RawInfoBitErrors  = %d / %d\n', sum(int8(llrFloat(1:K_ldpc) < 0) ~= txBits), K_ldpc);
fprintf(fid, 'ExpectedActIter   = 3\n');
fprintf(fid, 'ExpectedParCheck  = 1\n');
fprintf(fid, 'ExpectedCoreLat   = 12492\n');
fprintf(fid, 'ExpectedBitErrors = 0\n');
fclose(fid);

% Also set up workspace variables required by DVBS2_LDPC_Decoder_Model.slx compilation
padPre  = 10;
padPost = 28000;
totalCycles = padPre + N_ldpc + padPost;
simStopTime = totalCycles - 1;

dataVec  = fi(zeros(totalCycles, 1), 1, 6, 2);
validVec = false(totalCycles, 1);
startVec = false(totalCycles, 1);
endVec   = false(totalCycles, 1);

dataVec(padPre+1 : padPre+N_ldpc)  = llrFi;
validVec(padPre+1 : padPre+N_ldpc) = true;
startVec(padPre+1)                 = true;
endVec(padPre+N_ldpc)              = true;

tVec = (0:totalCycles-1).';
simDataIn.time = tVec;  simDataIn.signals.values = dataVec;  simDataIn.signals.dimensions = 1;
simValidIn.time = tVec; simValidIn.signals.values = validVec; simValidIn.signals.dimensions = 1;
simStartIn.time = tVec; simStartIn.signals.values = startVec; simStartIn.signals.dimensions = 1;
simEndIn.time = tVec;   simEndIn.signals.values = endVec;   simEndIn.signals.dimensions = 1;

fprintf('\n=================================================================\n');
fprintf('STEP 2: GENERATING VERILOG HDL IP FROM SIMULINK MODEL (makehdl)\n');
fprintf('=================================================================\n');

modelName = 'DVBS2_LDPC_Decoder_Model';
slxPath   = fullfile(workDir, [modelName '.slx']);
load_system(slxPath);

dutSub = [modelName '/DVBS2_LDPC_Decoder_DUT'];

% Generate Verilog RTL IP directly via makehdl
makehdl(dutSub, ...
    'TargetLanguage', 'Verilog', ...
    'TargetDirectory', hdlDir);

save_system(modelName, slxPath);
close_system(modelName, 0);

fprintf('\n=================================================================\n');
fprintf('SUCCESS: Verilog HDL IP & Test Vectors Generated!\n');
fprintf('=================================================================\n');

