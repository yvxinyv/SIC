% clc
% clear
 close all

% 自干扰消除

% 接收卫星信号： PRN   1     2       3
%       多普勒： Hz    0     1000   -1000
%     接收功率： dBW   -155  -155   -155

%   自干扰信号模型采用最简单的多径模型，即 x(t) = h_1 * s(t - tua_1) + h_2 * s(t - tua_2) + ... + h_n * s(t - tua_n)
%   相同的体制： PRN：4， 多普勒：0Hz
%     多径个数： 3， 时延 5.1ns  7.5ns  10.3ns
%     接收功率：  dBW     -100  -110   -120
%
disp(' 开始运行 ')
%% 设置通用参数
General_settings.CarrierFreq = 1176.45 * 1e6;       % 卫星信号载波发射频率
General_settings.LocalFreq = 1176.45 * 1e6;         % 本地前端振荡器频率
General_settings.codeFreq        = 10.23e6;       % [Hz]
InterFrq = General_settings.CarrierFreq - General_settings.LocalFreq;                 % 理想中频频率
General_settings.InterFrq=InterFrq;
General_settings.FullTimeofSignal = 501 * 1e-3;      % 生成的总数据长度
General_settings.SampFreq = 50 * 1e6;               % 中频信号采样频率
General_settings.Ts = 1/ General_settings.SampFreq; % 采样间隔
General_settings.SamplingOffset =  0 * General_settings.Ts;     % 初始采样时间偏移值
General_settings.codeLength           = 10230;
General_settings.flagofbandlimited    = 1;              %'1'生成带限信号，'0'生成非带限信号
General_settings.flagofacquisition    = 0;              %'1'生成捕获结果图，'0'不生成捕获结果图
%% 生成信号
Ts = General_settings.Ts;
SamplingOffset = General_settings.SamplingOffset;
General_settings. FullSamplingTimeSeq = SamplingOffset: Ts: General_settings.FullTimeofSignal;              % 采样时间序列
General_settings. FullNumofSampling = length(General_settings.FullSamplingTimeSeq);                         % 总采样点数

% -------- 生成噪声 ---------------
% 噪声序列服从标准正态分布
NoiseSeq = randn(1,General_settings.FullNumofSampling);
NoiseN0 = -232;                                                 % 噪声功率谱密度，单位dBW/Hz
NoisePower = 10 ^ (NoiseN0 / 10) * General_settings.SampFreq;  	% 噪声功率(50MHz,-205dBW/Hz时，等效为-128dBW，-205+77)
NosieAmplitude = sqrt(NoisePower);                              % 噪声幅值

% -------- 生成卫星Sat_1的信号 ------------
Sat_1_settings = General_settings;
Sat_1_settings.CarrierDoppler = 0;                              % 多普勒频偏
Sat_1_settings.delay = 1.235e-3;                                % 时延
Sat_1_settings.Phase_LocalFreq = rand * 2 * pi;                	% 随机相位差
% 生成对应的接收信号
[~,Sat_1_RecSig] = BPSK_SigRecGenerator(1,Sat_1_settings);
% 调整这些信号的幅值
Sat_1_Power = -155;     % 单位 dBW
Sat_1_Amplitude = sqrt( 2 * 10 ^ (Sat_1_Power /10));            % 幅度

% -------- 生成卫星Sat_2的信号 ------------
Sat_2_settings = General_settings;
Sat_2_settings.CarrierDoppler = 1000;                           % 多普勒频偏
Sat_2_settings.delay = 5.420e-3;                                % 时延
Sat_2_settings.Phase_LocalFreq = rand * 2 * pi;                 % 随机相位差
% 生成对应的接收信号
[~,Sat_2_RecSig] = BPSK_SigRecGenerator(2,Sat_2_settings);
% 调整这些信号的幅值
Sat_2_Power = -155;                                             % 单位 dBW
Sat_2_Amplitude = sqrt( 2 * 10 ^ (Sat_2_Power /10));            % 幅度

% -------- 生成卫星Sat_3的信号 ------------
Sat_3_settings = General_settings;
Sat_3_settings.CarrierDoppler = -1000;                          % 多普勒频偏
Sat_3_settings.delay = 100.732e-3;                              % 时延
Sat_3_settings.Phase_LocalFreq = rand * 2 * pi;                 % 随机相位差
% 生成 100ms 信号对应的接收信号
[~,Sat_3_RecSig] = BPSK_SigRecGenerator(3,Sat_3_settings);
% 调整这些信号的幅值
Sat_3_Power = -155;     % 单位 dBW
Sat_3_Amplitude = sqrt( 2 * 10 ^ (Sat_3_Power /10));    % 幅度

% ========== 生成自干扰信号 ============
% 有多条自干扰路径，时延和相差无关，多普勒均为零. PRN = 4
Interference_1_settings = General_settings;
Interference_1_settings.CarrierDoppler = 0;                     % 多普勒频偏
Interference_2_settings = General_settings;
Interference_2_settings.CarrierDoppler = 0;
Interference_3_settings = General_settings;
Interference_3_settings.CarrierDoppler = 0;
Phase_LocalFreq  = rand * 2 * pi;                             % 随机相位差
Interference_1_settings.Phase_LocalFreq = Phase_LocalFreq ;      
Interference_2_settings.Phase_LocalFreq = Phase_LocalFreq ;      
Interference_3_settings.Phase_LocalFreq = Phase_LocalFreq ;      

Interference_1_settings.delay = 5e-9;      % 时延
Interference_2_settings.delay = 10e-9;      % 时延
Interference_3_settings.delay = 15e-9;      % 时延

[~,Interference_1_RecSig] = BPSK_SigRecGenerator(4,Interference_1_settings);
[~,Interference_2_RecSig] = BPSK_SigRecGenerator(4,Interference_1_settings);
[~,Interference_3_RecSig] = BPSK_SigRecGenerator(4,Interference_1_settings);

% 调整这些信号的幅值
Interference_1_Power = -125;     % 单位 dBW
Interference_2_Power = -140;     % 单位 d
Interference_3_Power = -155;     % 单位 dBW

Interference_1_Amplitude = sqrt( 2 * 10 ^ (Interference_1_Power /10));    % 幅度
Interference_2_Amplitude = sqrt( 2 * 10 ^ (Interference_2_Power /10));    % 幅度
Interference_3_Amplitude = sqrt( 2 * 10 ^ (Interference_3_Power /10));    % 幅度

% 叠加信号
InterFreqSignal = Sat_1_RecSig * Sat_1_Amplitude + Sat_2_RecSig * Sat_2_Amplitude + Sat_3_RecSig * Sat_3_Amplitude...
    + NoiseSeq' * NosieAmplitude...
    + Interference_1_RecSig * Interference_1_Amplitude...
    + Interference_2_RecSig * Interference_2_Amplitude...
    + Interference_3_RecSig * Interference_3_Amplitude;
Interference=Interference_1_RecSig * Interference_1_Amplitude...
    + Interference_2_RecSig * Interference_2_Amplitude...
    + Interference_3_RecSig * Interference_3_Amplitude;
%  生成带限信号
if (General_settings.flagofbandlimited == 1)
cutoffFrequency = 15e6;  % 设置截止频率
filterOrder = 100;       % 设置滤波器阶数 (根据需要调整)
% 使用fir1设计FIR滤波器
lowPassFilter = fir1(filterOrder, cutoffFrequency / (General_settings.SampFreq / 2));
% 进行滤波生成带限信号
InterFreqSignal = filter(lowPassFilter, 1, InterFreqSignal);
Interference_before= Interference;
Interference = filter(lowPassFilter, 1, Interference_before);
[max_corr, max_idx] = max_xcorr(Interference_before, Interference);
General_settings.lowPassFilter=lowPassFilter;
end
clear  Interference_2_RecSig Interference_3_RecSig Sat_1_RecSig Sat_2_RecSig Sat_3_RecSig NoiseSeq
% % disp(' 仿真信号生成完成 ')
% % Start = input('输入 "1" 开始执行自干扰消除，输入 "0" 退出 : ');
% % 
% % if (Start == 1)
% %     disp(' ');
%     Interference_Cancellation;
% % end