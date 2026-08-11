% 周楚昂 2024 11 14

% 用于生成B2a基带信号，B2a包含 B2a_data 和 B2a_pilot 两个分量，均为BPSK
% 构建一个长度为100ms的信号，对该信号进行采样，输出采样的序列

% 输入：
%      PRNs                     测距码编号             1-63 数字
%      Data                     调制的电文数据         0/1 逻辑序列，长度20(数据码片宽度5ms)
%      SampFreq                 采样频率
% 输出：
%      B2a_data_RangingCode     数据分量               
%      B2a_pilot_RangingCode    导频分量          

function [B2a_data_Sig,B2a_pilot_Sig] = B2aSigGen(PRNs,Data,SampFreq)
Ts = 1/SampFreq;                    % 采样间隔
OffSet = 0.5 * Ts;                  % 初始偏移值，避免落在上升/下降沿

TimeDuration = 100 * 1e-3;          % 总时间
SampTimeSeq = OffSet: Ts: TimeDuration; % 采样时刻序列
% Ns = length(SampTimeSeq);               % 总采样点数

% 初始化输出数组
% B2a_data_Sig = zeros(1,Ns);
% B2a_pilot_Sig = zeros(1,Ns);

% 周期
Period_Main = 1e-3;
Period_SubData = 5e-3;
Period_SubPilot = 100e-3;

% 单个宽度
T_codechip = 1e-3/10230;
T_SubData = 1e-3;
T_SubPilot = 1e-3;
T_Data = 5e-3;

% 调用生成主/子码
[SubCode_d,SubCode_p] = B2aCodeGen_SubCode(PRNs);
[MainCode_d, MainCode_p] = B2aCodeGen_MainCode(PRNs);

% 找到对应值
Data_Sig_Main_index_seq = ceil(mod(SampTimeSeq,Period_Main)/T_codechip);        % 1 - 10230 数据分量，主码对应位
Data_Sig_Sub_index_seq = ceil(mod(SampTimeSeq,Period_SubData)/T_SubData);       % 1 - 5     数据分量，子码对应位
Data_Sig_Data_index_seq = ceil(SampTimeSeq/T_Data);                             % 1 - 20    数据分量，数据位

Pilot_Sig_Main_index_seq = ceil(mod(SampTimeSeq,Period_Main)/T_codechip);       % 1 - 10230 导频分量，主码对应位
Pilot_Sig_Sub_index_seq = ceil(mod(SampTimeSeq,Period_SubPilot)/T_SubPilot);    % 1 - 100   导频分量，子码对应位

% 生成信号
B2a_data_Sig = MainCode_d(Data_Sig_Main_index_seq) .* SubCode_d(Data_Sig_Sub_index_seq) .* SigData(Data_Sig_Data_index_seq);
B2a_pilot_Sig = MainCode_p(Pilot_Sig_Main_index_seq) .* SubCode_p(Pilot_Sig_Sub_index_seq);
end

