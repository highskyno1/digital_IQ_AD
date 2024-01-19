function Hd = HP_Filter(Fs,Fstop,Fpass)
%UP_FREQ_HP 返回离散时间滤波器对象。

% MATLAB Code
% Generated by MATLAB(R) 23.2 and Signal Processing Toolbox 23.2.
% Generated on: 25-Dec-2023 21:30:02

% FIR Window Highpass filter designed using the FIR1 function.

% All frequency values are in Hz.
% Fs = 50000000000;  % Sampling Frequency

% Fstop = 150000000;       % Stopband Frequency
% Fpass = 1000000000;      % Passband Frequency
Dstop = 0.0001;          % Stopband Attenuation
Dpass = 0.057501127785;  % Passband Ripple
flag  = 'scale';         % Sampling Flag

% Calculate the order from the parameters using KAISERORD.
[N,Wn,BETA,TYPE] = kaiserord([Fstop Fpass]/(Fs/2), [0 1], [Dpass Dstop]);

% Calculate the coefficients using the FIR1 function.
b  = fir1(N, Wn, TYPE, kaiser(N+1, BETA), flag);
Hd = dfilt.dffir(b);

% [EOF]