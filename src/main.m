%{
    仿真中频采样定理
    case1：发射端用了IQ调制
    2023/12/23 11:37
%}
close all;
%% 仿真全局参数
Bandwidth = 1e8;    % 脉冲带宽
T = 30e-6;          % 脉冲持续时间 s
Center_frq = 5e9;   % 中心频率
Fg = 50e9;          % 仿真全局采样率
phase_id = 0;       % 发射端与接收端的相位差，0表示本振同步
lfm_sig_snr = +inf; % 接收端接收到的信号的信噪比

%% LFM信号发生
K = Bandwidth / T;                  % 线性调频因子
N = Fg * T;                         % 采样点数
t_axis = linspace(-T/2,T/2,N);      % 采样时间点
lfm_sig = exp(1i*pi*K.*(t_axis.^2));% 采样得到的信号
% 上变频(IQ调制)
lfm_sig_up = real(lfm_sig) .* cos(2*pi*Center_frq.*t_axis + phase_id);
lfm_sig_up = lfm_sig_up + imag(lfm_sig) .* (-sin(2*pi*Center_frq.*t_axis + phase_id));
% 由于信号还有基带残留，滤除
HP = up_freq_HP(Fg,1.5e8,1e9);
HP = HP.Numerator;
lfm_sig_up = conv(lfm_sig_up,HP,'same');
% 查看发射信号的频谱
fft_x = linspace(-Fg/2,Fg/2,N);
figure('Name','发射信号的频谱');
plot(fft_x,fftshift(abs(fft(lfm_sig_up))));
% 加噪
lfm_sig_up = awgn(lfm_sig_up,lfm_sig_snr);

%% 所有接收机天线的带通滤波
BP_rec = BP_filter(Fg,Center_frq-Bandwidth/1.5,Center_frq-Bandwidth/2,...
    Center_frq+Bandwidth/2,Center_frq+Bandwidth/1.5);
lfm_sig_up = conv(lfm_sig_up,BP_rec.Numerator,'same');

%% 模拟传统IQ解调（零中频模式）
% I通道混频序列
I_df = cos(2*pi*Center_frq.*t_axis);
% Q通道混频系列
Q_df = -sin(2*pi*Center_frq.*t_axis);
% 低通滤波器
LP = Lp_filter(Fg,Bandwidth,Bandwidth*2);
% IQ通道数据
I_ch = conv(lfm_sig_up .* I_df,LP.Numerator,'same');
Q_ch = conv(lfm_sig_up .* Q_df,LP.Numerator,'same');
% 利用插值模拟A/D抽样
% 计算采样率
fs_iq = Bandwidth * 2;
% 计算采样点数
N_iq = floor(fs_iq * T);
t_axis_iq = linspace(-T/2,T/2,N_iq);
% 采样
sample_i = interp1(t_axis,I_ch,t_axis_iq,"linear","extrap");
sample_q = interp1(t_axis,Q_ch,t_axis_iq,"linear","extrap");
% 得到复信号
AD_iq_res = sample_i + 1i .* sample_q;
% 匹配滤波
mf_sig = conj(flip(exp(1i.*pi*K.*(t_axis_iq.^2))));   % 匹配滤波器
ip_mf_sig = conv(mf_sig,AD_iq_res);             % 匹配滤波结果

%% 模拟中频采样定理
% 计算采样率
m = 4;
fs_m = 4 * Center_frq / (2*m+1);
% A/D采样
Nm = floor(fs_m * T);
t_axis_m = linspace(-T/2,T/2,Nm);
sample_m = interp1(t_axis,lfm_sig_up,t_axis_m,"linear","extrap");
% 奇偶抽取
sample_even = sample_m(1:2:Nm);
sample_odd = sample_m(2:2:Nm);
% 相乘
sample_even = sample_even .* ((-1).^(0:length(sample_even)-1));
sample_odd = sample_odd .* (-(-1).^((0:length(sample_odd)-1)+m));
% Q通道相移
len = length(sample_odd);
sample_odd_fft = fft(sample_odd) .* fftshift(exp(-1i*pi/len.*linspace(-len/2,len/2,len)));
sample_odd = real(ifft(sample_odd_fft));
% 得到复信号
AD_m_res = sample_even + 1i.*sample_odd;
% 匹配滤波
% 由于进行了奇偶抽取，等效采样率降低了
t_axis_mf = linspace(-T/2,T/2,Nm/2);
mf_sig = conj(flip(exp(1i.*pi*K.*(t_axis_mf.^2))));   % 匹配滤波器
m_mf_sig = conv(mf_sig,AD_m_res);               % 匹配滤波结果

%% 模拟Rader法
% 下变频
Rader_dp = cos(2*pi*(Center_frq-Bandwidth).*t_axis);
reder_sig = lfm_sig_up .* Rader_dp;
% 带通滤波
bp_lowp = 0.5 * Bandwidth;      % 通带下限
bp_upp = 1.5 * Bandwidth;       % 通带上限
bp_interim = 0.1 * Bandwidth;   % 过度带宽
B_raderP = BP_filter(Fg,bp_lowp-bp_interim,bp_lowp,bp_upp,bp_upp+bp_interim);
reder_sig = conv(reder_sig,B_raderP.Numerator,'same');
% 模拟A/D采样(采样率为4beita)
fs_rad = 4 * Bandwidth;
N_rad = floor(fs_rad * T);
t_axis_rader = linspace(-T/2,T/2,N_rad);
sample_rader = interp1(t_axis,reder_sig,t_axis_rader,"linear","extrap");
% 通过复数系统，抹掉负半部分的频率，等效于希尔伯特变换
sample_rader = hilbert(sample_rader);
% 频谱搬移，乘上(-j)^n
sample_rader = sample_rader .* (-1i).^(0:N_rad-1);
% 1/4降采样
sample_rader = sample_rader(1:4:N_rad);
% 匹配滤波
% 进行了1/4降采样，匹配模板也要
t_axis_rader_mf = linspace(-T/2,T/2,N_rad/4);
mf_sig = conj(flip(exp(1i.*pi*K.*(t_axis_rader_mf.^2))));   % 匹配滤波器
rader_mf_sig = conv(mf_sig,sample_rader);                   % 匹配滤波结果

%% 模拟Shaw&Pohlig法
% 下变频
sp_dp = cos(2*pi*(Center_frq-0.625*Bandwidth).*t_axis);
sp_sig = lfm_sig_up .* sp_dp;
% 带通滤波
bp_lowp = 0.125 * Bandwidth;    % 通带下限
bp_upp = 1.625 * Bandwidth;     % 通带上限
bp_interim = 0.1 * Bandwidth;   % 过渡带宽
BP_sp = BP_filter(Fg,bp_lowp-bp_interim,bp_lowp,bp_upp,bp_upp+bp_interim);
sp_dp = conv(sp_sig,BP_sp.Numerator,'same');
% AD采样
fs_sp = 2.5 * Bandwidth;
N_sp = floor(fs_sp * T);
t_sp_axis = linspace(-T/2,T/2,N_sp);
sample_sp = interp1(t_axis,sp_dp,t_sp_axis,"linear","extrap");
% 复调制，乘上j^n
sample_sp = sample_sp .* (1i).^(0:N_sp-1);
% 低通滤波
LP_sp = Lp_filter(1,0.2,0.25);
sample_sp = conv(sample_sp,LP_sp.Numerator,'same');
% 1/2降采样
sample_sp = sample_sp(1:2:N_sp);
% 匹配滤波
% 进行了1/2降采样，匹配模板也要
t_sp_axis_mf = linspace(-T/2,T/2,N_sp/2);
% !!由于Shaw&Pohlig接收机得到的虚部已取反，匹配模板不需要取共轭
mf_sig = flip(exp(1i.*pi*K.*(t_sp_axis_mf.^2)));   % 匹配滤波器
sp_mf_sig = conv(mf_sig,sample_sp);          % 匹配滤波结果


%% 画图
% 采样结果
figure('Name','采样结果');
subplot(411);
plot(real(AD_iq_res));
hold on
plot(imag(AD_iq_res));
title('传统的IQ解调');
subplot(412);
plot(real(AD_m_res));
hold on
plot(imag(AD_m_res));
title('中频采样定理-IQ解调');
subplot(413);
plot(real(sample_rader));
hold on
plot(imag(sample_rader));
title('Rader数字IQ解调');
subplot(414);
plot(real(sample_sp));
hold on
plot(imag(sample_sp));
title('Shaw&Pohlig数字IQ解调');

% 采样结果(abs)
figure('Name','采样结果(abs)');
title('采样结果')
subplot(411);
plot(abs(AD_iq_res));
title('传统的IQ解调');
subplot(412);
plot(abs(AD_m_res));
title('中频采样定理-IQ解调');
subplot(413);
plot(abs(sample_rader));
title('Rader数字IQ解调');
subplot(414);
plot(abs(sample_sp));
title('Shaw&Pohlig数字IQ解调');

% 采样结果的频域比较
figure('Name','采样结果的频域');
subplot(411);
foo_fft = fft(AD_iq_res);
x_fft = linspace(-1,1,length(foo_fft));
fft_abs = fftshift(abs(foo_fft));
fft_phase = fftshift(phase(foo_fft));
yyaxis left
plot(x_fft,fft_abs);
yyaxis right
plot(x_fft,fft_phase);
title('传统的IQ解调');
subplot(412);
foo_fft = fft(AD_m_res);
x_fft = linspace(-1,1,length(foo_fft));
fft_abs = fftshift(abs(foo_fft));
fft_phase = fftshift(phase(foo_fft));
yyaxis left
plot(x_fft,fft_abs);
yyaxis right
plot(x_fft,fft_phase);
title('中频采样定理-IQ解调');
subplot(413);
foo_fft = fft(sample_rader);
x_fft = linspace(-1,1,length(foo_fft));
fft_abs = fftshift(abs(foo_fft));
fft_phase = fftshift(phase(foo_fft));
yyaxis left
plot(x_fft,fft_abs);
yyaxis right
plot(x_fft,fft_phase);
title('Rader数字IQ解调');
subplot(414);
foo_fft = fft(sample_sp);
x_fft = linspace(-1,1,length(foo_fft));
fft_abs = fftshift(abs(foo_fft));
fft_phase = fftshift(phase(foo_fft));
yyaxis left
plot(x_fft,fft_abs);
yyaxis right
plot(x_fft,fft_phase);
title('Shaw&Pohlig数字IQ解调');

% 匹配滤波结果
figure('Name','匹配滤波结果');
subplot(411);
plot(real(ip_mf_sig));
hold on
plot(imag(ip_mf_sig));
title('传统的IQ解调');
subplot(412);
plot(real(m_mf_sig));
hold on
plot(imag(m_mf_sig));
title('中频采样定理-IQ解调');
subplot(413);
plot(real(rader_mf_sig));
hold on
plot(imag(rader_mf_sig));
title('Rader数字IQ解调');
subplot(414);
plot(real(sp_mf_sig));
hold on
plot(imag(sp_mf_sig));
title('Shaw&Pohlig数字IQ解调');

% 匹配滤波结果(abs)
figure('Name','匹配滤波结果(abs)');
subplot(411);
plot(abs(ip_mf_sig));
title('传统的IQ解调');
subplot(412);
plot(abs(m_mf_sig));
title('中频采样定理-IQ解调');
subplot(413);
plot(abs(rader_mf_sig));
title('Rader数字IQ解调');
subplot(414);
plot(abs(sp_mf_sig));
title('Shaw&Pohlig数字IQ解调');
