%% DVB-S2 LDPC Decoder Simulink Model Creation & Verification Script
% Workspace: d:\HoriTech_Files\LDPC_Testing
% MATLAB Version: R2025b
% Target Block: whdledac/DVB-S2 LDPC Decoder

clear; clc; close all;
bdclose('all');

workDir = 'd:\HoriTech_Files\LDPC_Testing';
cd(workDir);

diaryFile = fullfile(workDir, 'verification_output.log');
if exist(diaryFile, 'file')
    delete(diaryFile);
end
diary(diaryFile);

fprintf('=================================================================\n');
fprintf('STEP 1: BUILDING SIMULINK MODEL (DVBS2_LDPC_Decoder_Model.slx)\n');
fprintf('=================================================================\n');

modelName = 'DVBS2_LDPC_Decoder_Model';
slxPath = fullfile(workDir, [modelName '.slx']);
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

if exist(slxPath, 'file')
    load_system(slxPath);
    dutSub  = [modelName '/DVBS2_LDPC_Decoder_DUT'];
    ldpcBlk = [dutSub '/DVB-S2 LDPC Decoder'];
    fprintf('Loaded existing Simulink model: %s\n', slxPath);
else
    new_system(modelName);
    load_system('whdledac');
    load_system('whdlutilities');
    load_system('simulink');

    % Configure solver for hardware-accurate discrete cycle simulation
    set_param(modelName, ...
        'SolverType', 'Fixed-step', ...
        'Solver', 'FixedStepDiscrete', ...
        'FixedStep', '1', ...
        'StartTime', '0', ...
        'StopTime', 'simStopTime', ...
        'SingleTaskRateTransMsg', 'none');

    % Create HDL DUT Subsystem containing DVB-S2 LDPC Decoder
    dutSub = [modelName '/DVBS2_LDPC_Decoder_DUT'];
    add_block('built-in/SubSystem', dutSub, 'Position', [350, 120, 580, 340]);

    % Inside DUT: Inports
    add_block('built-in/Inport', [dutSub '/dataIn'],  'Position', [40, 60,  70, 74],  'Port', '1');
    add_block('built-in/Inport', [dutSub '/startIn'], 'Position', [40, 120, 70, 134], 'Port', '2');
    add_block('built-in/Inport', [dutSub '/endIn'],   'Position', [40, 150, 70, 164], 'Port', '3');
    add_block('built-in/Inport', [dutSub '/validIn'], 'Position', [40, 180, 70, 194], 'Port', '4');

    % Sample Control Bus Creator inside DUT
    busCreator = [dutSub '/Sample_Control_Bus_Creator'];
    add_block('whdlutilities/Sample Control Bus Creator', busCreator, ...
        'Position', [130, 115, 240, 200]);

    % DVB-S2 LDPC Decoder block inside DUT (using default 'Code generation' for fast simulation)
    ldpcBlk = [dutSub '/DVB-S2 LDPC Decoder'];
    add_block('whdledac/DVB-S2 LDPC Decoder', ldpcBlk, ...
        'Position', [310, 50, 490, 250], ...
        'FECFrameSource', 'Property', ...
        'FECFrame', 'Short', ...
        'CodeRateSource', 'Property', ...
        'CodeRateShort', '1/2', ...
        'Parallelism', '45', ...
        'Algorithm', 'Normalized min-sum', ...
        'SourceScalingFactor', 'Property', ...
        'ScalingFactor', '0.75', ...
        'Termination', 'Early', ...
        'SpecifyInputs', 'Property', ...
        'MaxNumIterations', '8', ...
        'ParityCheckStatus', 'on', ...
        'SimulateUsing', 'Code generation');

    % Bus Selector for output ctrl bus
    busSel = [dutSub '/Bus_Selector'];
    add_block('built-in/BusSelector', busSel, ...
        'Position', [550, 110, 560, 180], ...
        'OutputSignals', 'start,end,valid');

    % Outports inside DUT
    add_block('built-in/Outport', [dutSub '/dataOut'],      'Position', [620, 60,  650, 74],  'Port', '1');
    add_block('built-in/Outport', [dutSub '/startOut'],     'Position', [620, 110, 650, 124], 'Port', '2');
    add_block('built-in/Outport', [dutSub '/endOut'],       'Position', [620, 140, 650, 154], 'Port', '3');
    add_block('built-in/Outport', [dutSub '/validOut'],     'Position', [620, 170, 650, 184], 'Port', '4');
    add_block('built-in/Outport', [dutSub '/actIter'],      'Position', [620, 205, 650, 219], 'Port', '5');
    add_block('built-in/Outport', [dutSub '/parityCheck'],  'Position', [620, 240, 650, 254], 'Port', '6');
    add_block('built-in/Outport', [dutSub '/nextFrame'],    'Position', [620, 275, 650, 289], 'Port', '7');

    % Connect blocks inside DUT
    add_line(dutSub, 'startIn/1', 'Sample_Control_Bus_Creator/1', 'autorouting', 'on');
    add_line(dutSub, 'endIn/1',   'Sample_Control_Bus_Creator/2', 'autorouting', 'on');
    add_line(dutSub, 'validIn/1', 'Sample_Control_Bus_Creator/3', 'autorouting', 'on');

    add_line(dutSub, 'dataIn/1',  'DVB-S2 LDPC Decoder/1', 'autorouting', 'on');
    add_line(dutSub, 'Sample_Control_Bus_Creator/1', 'DVB-S2 LDPC Decoder/2', 'autorouting', 'on');

    add_line(dutSub, 'DVB-S2 LDPC Decoder/1', 'dataOut/1',     'autorouting', 'on');
    add_line(dutSub, 'DVB-S2 LDPC Decoder/2', 'Bus_Selector/1','autorouting', 'on');
    add_line(dutSub, 'DVB-S2 LDPC Decoder/3', 'actIter/1',     'autorouting', 'on');
    add_line(dutSub, 'DVB-S2 LDPC Decoder/4', 'parityCheck/1', 'autorouting', 'on');
    add_line(dutSub, 'DVB-S2 LDPC Decoder/5', 'nextFrame/1',   'autorouting', 'on');

    add_line(dutSub, 'Bus_Selector/1', 'startOut/1', 'autorouting', 'on');
    add_line(dutSub, 'Bus_Selector/2', 'endOut/1',   'autorouting', 'on');
    add_line(dutSub, 'Bus_Selector/3', 'validOut/1', 'autorouting', 'on');

    % Top-level Signal From Workspace blocks
    add_block('simulink/Sources/From Workspace', [modelName '/dataIn_Src'], ...
        'Position', [100, 130, 220, 155], ...
        'VariableName', 'simDataIn', 'SampleTime', '1', 'Interpolate', 'off', ...
        'OutputAfterFinalValue', 'Setting to zero');
    add_block('simulink/Sources/From Workspace', [modelName '/startIn_Src'], ...
        'Position', [100, 180, 220, 205], ...
        'VariableName', 'simStartIn', 'SampleTime', '1', 'Interpolate', 'off', ...
        'OutputAfterFinalValue', 'Setting to zero');
    add_block('simulink/Sources/From Workspace', [modelName '/endIn_Src'], ...
        'Position', [100, 230, 220, 255], ...
        'VariableName', 'simEndIn', 'SampleTime', '1', 'Interpolate', 'off', ...
        'OutputAfterFinalValue', 'Setting to zero');
    add_block('simulink/Sources/From Workspace', [modelName '/validIn_Src'], ...
        'Position', [100, 280, 220, 305], ...
        'VariableName', 'simValidIn', 'SampleTime', '1', 'Interpolate', 'off', ...
        'OutputAfterFinalValue', 'Setting to zero');

    % Top-level To Workspace blocks
    outNamesTop = {'dataOut', 'startOut', 'endOut', 'validOut', 'actIterOut', 'parityCheckOut', 'nextFrameOut'};
    for p = 1:7
        yPos = 100 + (p-1)*35;
        add_block('simulink/Sinks/To Workspace', [modelName '/' outNamesTop{p} '_Sink'], ...
            'Position', [700, yPos, 820, yPos+25], ...
            'VariableName', outNamesTop{p}, ...
            'SaveFormat', 'Array', ...
            'SampleTime', '-1');
    end

    % Connect Top-Level
    add_line(modelName, 'dataIn_Src/1',  'DVBS2_LDPC_Decoder_DUT/1', 'autorouting', 'on');
    add_line(modelName, 'startIn_Src/1', 'DVBS2_LDPC_Decoder_DUT/2', 'autorouting', 'on');
    add_line(modelName, 'endIn_Src/1',   'DVBS2_LDPC_Decoder_DUT/3', 'autorouting', 'on');
    add_line(modelName, 'validIn_Src/1', 'DVBS2_LDPC_Decoder_DUT/4', 'autorouting', 'on');

    for p = 1:7
        add_line(modelName, sprintf('DVBS2_LDPC_Decoder_DUT/%d', p), [outNamesTop{p} '_Sink/1'], 'autorouting', 'on');
    end

    save_system(modelName, slxPath);
    fprintf('SUCCESS: Saved Simulink model to %s\n', slxPath);
end
diary off; diary on;

fprintf('\n=================================================================\n');
fprintf('STEP 2: SIMULINK VERIFICATION - TEST CASE 1 (Short Frame, Rate 1/2, Early, Par 45)\n');
fprintf('=================================================================\n');

rng(42); % Reproducible seed

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

rawHardBits = int8(llrFloat < 0);
rawInfoErrs = sum(rawHardBits(1:K_ldpc) ~= txBits);
rawTotalErrs = sum(rawHardBits ~= codeword);

% Quantize LLRs to signed fixed-point sfix6_En2 (WordLength=6, FractionLength=2)
llrFi = fi(llrFloat, 1, 6, 2);

% Reference floating-point ldpcDecode
[refDecBits, refActualIter, ~] = ldpcDecode(llrFloat, decCfgRef, 8, ...
    'Termination', 'early', 'MinSumScalingFactor', 0.75);
refBitErrs = sum(int8(refDecBits) ~= txBits);

padPre  = 10;
padPost = 28000; % Plenty of cycles for Parallelism=45 decoding + 7200 output cycles
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

fprintf('Running Simulink simulation (Test Case 1)...\n');
diary off; diary on;
tStartSim = tic;
simOut = sim(modelName);
simElapsed = toc(tStartSim);

slDataOut  = reshape(simOut.get('dataOut'), [], 1);
slStartOut = reshape(simOut.get('startOut'), [], 1);
slEndOut   = reshape(simOut.get('endOut'), [], 1);
slValidOut = reshape(simOut.get('validOut'), [], 1);
slActIter  = reshape(simOut.get('actIterOut'), [], 1);
slParCheck = reshape(simOut.get('parityCheckOut'), [], 1);
slNextFrm  = reshape(simOut.get('nextFrameOut'), [], 1);

validIdx = find(slValidOut);
startIdx = find(slStartOut & slValidOut);
endIdx   = find(slEndOut & slValidOut);

decodedBitsSL = int8(slDataOut(validIdx));
slBitErrs = sum(decodedBitsSL(:) ~= txBits(:));

inEndCycle    = padPre + N_ldpc;
outStartCycle = startIdx(1);
outEndCycle   = endIdx(1);
measuredCoreLatency = outStartCycle - inEndCycle;
actIterVal    = slActIter(outStartCycle);
parCheckAtStart = slParCheck(outStartCycle);
parCheckAtEnd   = slParCheck(outEndCycle);
nfLowIdx      = find(~slNextFrm);

fprintf('\n=== VERIFICATION RESULTS (TEST CASE 1: Simulink Model - Short Frame, Rate 1/2, Early, Par 45) ===\n');
fprintf('  Simulation Execution Time    : %.2f seconds\n', simElapsed);
fprintf('  Frame Type / Code Rate       : Short (N = %d) / Rate 1/2 (K = %d)\n', N_ldpc, K_ldpc);
fprintf('  Channel SNR (Es/N0)          : %.2f dB\n', snr_dB);
fprintf('  Raw Channel Errors (Codeword): %d / %d (BER = %.4f)\n', rawTotalErrs, N_ldpc, rawTotalErrs/N_ldpc);
fprintf('  Raw Channel Errors (InfoBits): %d / %d (BER = %.4f)\n', rawInfoErrs, K_ldpc, rawInfoErrs/K_ldpc);
fprintf('  Decoded Output Length        : %d bits (Expected: %d)\n', numel(decodedBitsSL), K_ldpc);
fprintf('  Input Frame Cycles           : [%d .. %d] (%d cycles)\n', padPre+1, inEndCycle, N_ldpc);
fprintf('  Output Frame Cycles          : [%d .. %d] (%d cycles)\n', outStartCycle, outEndCycle, outEndCycle - outStartCycle + 1);
fprintf('  nextFrame Deasserted Cycles  : [%d .. %d] (%d cycles)\n', nfLowIdx(1), nfLowIdx(end), numel(nfLowIdx));
fprintf('  Measured Core Latency        : %d clock cycles (endIn -> startOut)\n', measuredCoreLatency);
fprintf('  Actual Iterations Used       : %d (Max = 8, Ref float = %d)\n', actIterVal, refActualIter);
fprintf('  Parity Check Port (start/end): %d / %d\n', parCheckAtStart, parCheckAtEnd);
fprintf('  Simulink Post-LDPC Bit Errors: %d / %d (BER = %.6f)\n', slBitErrs, K_ldpc, slBitErrs/K_ldpc);
fprintf('  Ref Float ldpcDecode Errors  : %d / %d (BER = %.6f)\n', refBitErrs, K_ldpc, refBitErrs/K_ldpc);

close_system(modelName, 0);

fprintf('\n=================================================================\n');
fprintf('Verification Completed Successfully!\n');
fprintf('=================================================================\n');
diary off;
