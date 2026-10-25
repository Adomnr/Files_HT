function SimParams = commqamtxrxhdl_init

% Using 56 symbol packet, with 14 symbol preamble and 42 symbols of data.
% This gives 252 bits for data in each packet which equates to 36 7-bit
% characters.

% Create data packet
no_packets = 100;
index = 0:1:(no_packets-1);       % Packet number to be included in each packet
data_bits_per_packet = 42*6;
SimParams.total_data_bits = data_bits_per_packet * no_packets;
% 36 character string giving 252 bits of data
base_bits = de2bi(int8(sprintf('Hello world! ~64QAM test string~ %03i',index)),7,'left-msb').';
base_bits = base_bits(:);
SimParams.tx_data_bits = zeros(2^15,1);     % Make LUT size a power of 2
SimParams.tx_data_bits(1:SimParams.total_data_bits) = base_bits;

% Create preamble
preamble = [32 32 32 32 32 4 4 32 32 4 32 4 32 32].';
base_bits = de2bi(preamble, 6, 'left-msb');
bits_row = double(reshape(base_bits.',1,[]));
SimParams.preamble_bits = zeros(2^7,1);     % Make LUT size a power of 2
SimParams.preamble_bits(1:6*14) = bits_row(:);

% preamble is 14 symbols long, the first 13 correspond to the
% Barker code
preambleBits = [1 1 1 1 1 0 0 1 1 0 1 0 1 1].';

% Preamble inserted into each transmit packet
preambleTxMap = [4 32].'; % integer constellation point mapping
SimParams.preambleTx = preambleTxMap(preambleBits+1);

% Preamble for cross correlation in receiver
preambleRxMap = [-1-1j 1+1j].';
SimParams.preambleRx = .85 * preambleRxMap(preambleBits+1);

% Channel Parameters
SimParams.frequencyOffset = 1000;     % Hz
SimParams.phaseOffset = 30;           % Degrees
SimParams.EbNo = 14;                  % Channel noise Eb/N0
SimParams.channelGain = 0.75;         % Should be an attenuation, <= 1
SimParams.channelDelay = 1.5;           % Can be a fractional number

symbolRate = 1e6;
SimParams.symbolPeriod = 1/symbolRate;
SimParams.sampleRate = 4 * symbolRate;
SimParams.bitRate = symbolRate*6;

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
