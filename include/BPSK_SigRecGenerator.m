% 用于仿真接收到的BPSK中频信号，只有一路信号
%   * 使用B2a_Pilot的主码，码率10230，周期性信号，没有子码，没有数据码
%  ** 假设了理想功放、理想无多径信道等等

% 输入：
%      PRNs                     测距码编号             1-63 数字

%      LocalFrequency           本地振荡器频率         Hz
%      Phase_LocalFreq          本地振荡器频率相位差   rads, 即混频输入的波形和载波的相位差
%      CarrierDoppler           载波多普勒             Hz
%      --- PhaseDoppler         码多普勒               Hz (和载波多普勒是对应的可以算出，不进行额外输入)

%      FullTimeofSignal         信号总时长
%      SampFreq                 采样频率
% 输出：
%      BPSK_baseband            基带信号采样序列
%      BPSK_RecSig              上载波的接收信号序列

function [BPSK_baseband, BPSK_RecSig] = BPSK_SigRecGenerator(PRNs,settings)
LocalFrequency = settings.LocalFreq;
Phase_LocalFreq = settings.Phase_LocalFreq;

CarrierDoppler = settings.CarrierDoppler;
CarrierFreq = settings.CarrierFreq;
FullSamplingTimeSeq = settings.FullSamplingTimeSeq;
delay = settings.delay;

% 计算采样时间点
SamplingTimeSeq = FullSamplingTimeSeq - delay;      % *** 注意！时延是减号，代表接收信号是更老的

% 计算中频载波频率
InterFrequency = CarrierFreq + CarrierDoppler - LocalFrequency;

% 计算载波多普勒（计算码片压缩比/计算码多普勒）
DopplerRatio = 1 - CarrierDoppler / CarrierFreq;    % 即码片时间长度都被压缩到原有值乘以压缩比

% 计算采样参数
Period_Main = 1e-3  * DopplerRatio;
% 单个码片宽度
T_codechip = 1e-3/10230  * DopplerRatio;

% 调用生成主码
[~, MainCode_p] = B2aCodeGen_MainCode(PRNs);

% 找到对应值
Pilot_Sig_Main_index_seq = floor(mod(SamplingTimeSeq,Period_Main)/T_codechip) + 1;       % 1 - 10230 导频分量，主码对应位

% 生成信号
BPSK_baseband = MainCode_p(Pilot_Sig_Main_index_seq);
BPSK_RecSig_I = MainCode_p(Pilot_Sig_Main_index_seq).* cos(2*pi*InterFrequency* SamplingTimeSeq - Phase_LocalFreq)';
BPSK_RecSig_Q = MainCode_p(Pilot_Sig_Main_index_seq).* sin(2*pi*InterFrequency* SamplingTimeSeq - Phase_LocalFreq)';

BPSK_RecSig = BPSK_RecSig_I + 1i * BPSK_RecSig_Q;
%     % 绘制基带信号时域波形
%     figure;
%     plot(SamplingTimeSeq(1:1000), BPSK_baseband(1:1000));
%     xlabel('时间 (秒)');
%     ylabel('幅值');
%     title('基带信号时域波形（滤波前）');
%     grid on;
% 
%         figure;
%     plot(SamplingTimeSeq(1:1000), BPSK_RecSig_I(1:1000));
%     xlabel('时间 (秒)');
%     ylabel('幅值');
%     title('中频信号时域波形I');
%     grid on;
%     figure;
%     plot(SamplingTimeSeq(1:1000), BPSK_RecSig_Q(1:1000));
%     xlabel('时间 (秒)');
%     ylabel('幅值');
%     title('中频信号时域波形Q');
%     grid on;
end

