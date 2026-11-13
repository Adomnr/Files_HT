function [I, Q] = read_iq_interleaved(fileName, inW)
%READ_IQ_INTERLEAVED  Read an interleaved I/Q file (I0 Q0 I1 Q1 ...).
%
%   [I, Q] = READ_IQ_INTERLEAVED(fileName, 16)   signed 16-bit samples
%   [I, Q] = READ_IQ_INTERLEAVED(fileName, 32)   signed 32-bit samples
%
%   Little-endian. I and Q are returned as integer-valued doubles.

assert(inW == 16 || inW == 32, 'Input width must be 16 or 32 bits.');
fid = fopen(fileName, 'r', 'ieee-le');
assert(fid > 0, 'Cannot open %s', fileName);
closer = onCleanup(@() fclose(fid));

d = fread(fid, [2, Inf], sprintf('int%d=>double', inW));
I = d(1,:).';
Q = d(2,:).';
end
