function Hd = BP_filter(Fs,Fstop1,Fpass1,Fpass2,Fstop2)
%BP_REDER_FILTER 返回离散时间滤波器对象。

% MATLAB Code
% Generated by MATLAB(R) 23.2 and DSP System Toolbox 23.2.
% Generated on: 24-Dec-2023 17:36:57

% FIR Window Bandpass filter designed using the FIR1 function.

% All frequency values are in Hz.
% Fs = 50000000000;  % Sampling Frequency

% Fstop1 = 10000000;        % First Stopband Frequency
% Fpass1 = 50000000;        % First Passband Frequency
% Fpass2 = 150000000;       % Second Passband Frequency
% Fstop2 = 190000000;       % Second Stopband Frequency
Dstop1 = 0.001;           % First Stopband Attenuation
Dpass  = 0.057501127785;  % Passband Ripple
Dstop2 = 0.0001;          % Second Stopband Attenuation
flag   = 'scale';         % Sampling Flag

% Calculate the order from the parameters using KAISERORD.
[N,Wn,BETA,TYPE] = kaiserord([Fstop1 Fpass1 Fpass2 Fstop2]/(Fs/2), [0 ...
                             1 0], [Dstop1 Dpass Dstop2]);

% Calculate the coefficients using the FIR1 function.
b  = fir1(N, Wn, TYPE, kaiser(N+1, BETA), flag);
Hd = dfilt.dffir(b);

% [EOF]
