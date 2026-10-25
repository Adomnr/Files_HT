function SimParams = comm8qamtxrxhdl_init

% 8-QAM Configuration (Option A):
% Using 56 symbol packet, with 14 symbol preamble and 42 symbols of data.
% At 3 bits/symbol (8-QAM), this gives 42 bits for preamble and 126 bits
% for data in each packet, which equates to 18 7-bit ASCII characters.

% Create data packet
no_packets = 100;
index = 0:1:(no_packets-1);       % Packet number to be included in each packet
data_bits_per_packet = 42*3;      % 126 bits per packet (42 symbols * 3 bits/symbol)
SimParams.total_data_bits = data_bits_per_packet * no_packets;
% 18 character string giving 126 bits of data
base_bits = de2bi(int8(sprintf('Hello! ~8-QAM~ %03i',index)),7,'left-msb').';
base_bits = base_bits(:);
SimParams.tx_data_bits = zeros(2^15,1);     % Make LUT size a power of 2
SimParams.tx_data_bits(1:SimParams.total_data_bits) = base_bits;

% Create preamble (14 symbols, first 13 correspond to Barker code)
preambleBits = [1 1 1 1 1 0 0 1 1 0 1 0 1 1].';

% Preamble inserted into each transmit packet
% For 8-QAM Gray mapping: symbol 1 is (-3-1j) and symbol 4 is (+3+1j)
preambleTxMap = [1 4].'; % integer constellation point mapping
preamble = preambleTxMap(preambleBits+1);
SimParams.preambleTx = preamble;

base_bits = de2bi(preamble, 3, 'left-msb');
bits_row = double(reshape(base_bits.',1,[]));
SimParams.preamble_bits = zeros(2^7,1);     % Make LUT size a power of 2
SimParams.preamble_bits(1:3*14) = bits_row(:);

% Preamble for cross correlation and 1-Tap DLMS reference in receiver
% With TX MinDist = 0.5, symbol 1 is (-0.75 - 0.25j) and symbol 4 is (+0.75 + 0.25j)
preambleRxMap = [-3-1j 3+1j].';
SimParams.preambleRx = 0.25 * preambleRxMap(preambleBits+1);

% Channel Parameters
SimParams.frequencyOffset = 1000;     % Hz
SimParams.phaseOffset = 30;           % Degrees
SimParams.EbNo = 14;                  % Channel noise Eb/N0
SimParams.channelGain = 0.75;         % Should be an attenuation, <= 1
SimParams.channelDelay = 1.5;         % Can be a fractional number

symbolRate = 1e6;
SimParams.symbolPeriod = 1/symbolRate;
SimParams.sampleRate = 4 * symbolRate;
SimParams.bitRate = symbolRate*3;     % 3 bits per symbol for 8-QAM

packetLength = 56;           % symbols
targetPacketRotationDeg = 4; % target rotation across a packet in degrees
targetPacketRotationNorm = targetPacketRotationDeg/360;
targetSymbolRotationNorm = targetPacketRotationNorm/packetLength;
SimParams.f_delta = symbolRate * targetSymbolRotationNorm;

% RRC Filter Parameters
SimParams.RaisedCosineFilterSpan = 10; % Filter span of Raised Cosine Tx Rx filters (in symbols)
SimParams.Rolloff = 0.5;
SimParams.Upsampling = 4;

% Square root raised cosine transmit filter
SimParams.TransmitterFilterCoefficients = ...
  rcosdesign(SimParams.Rolloff, SimParams.RaisedCosineFilterSpan, ...
  SimParams.Upsampling);

% Square root raised cosine receive filter
ReceiverFilterCoefficients = ...
  rcosdesign(SimParams.Rolloff, SimParams.RaisedCosineFilterSpan, ...
  SimParams.Upsampling);
% Normalize receive RRC filter coefficients to give filter gain of 1
SimParams.ReceiverFilterCoefficients = ...
    ReceiverFilterCoefficients/sum(ReceiverFilterCoefficients);

