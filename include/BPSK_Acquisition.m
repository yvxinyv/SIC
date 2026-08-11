% 针对此处的BPSK信号仿真捕获算法

function acqResults = BPSK_Acquisition(SamplingSignal,settings)
% 初始化相关参数
IF = settings.CarrierFreq - settings.LocalFreq;                                 % 中频频率
Ts = settings.Ts;

Index = - settings.SingleSideNumFrqBins : 1 : settings.SingleSideNumFrqBins;
FrqBinsSeq = Index * settings.acqStep + IF;                                     % 频率序列
TotalNumFrqBins = 2 * settings.SingleSideNumFrqBins + 1;                        % 总计频率搜索个数

PRN_N = length(settings.acqSatelliteList);                                      % 需要搜索的卫星个数
% NumofLocalSignalPeriod = settings.LocalSignalPeriod;                          % 使用几个周期的信号进行自相关
NumofLocalSignalPeriod = 1;                                                     % ** 固定使用一个周期的
StartedTime = settings.StartedTime;                                             % 信号截取开始时间

% 初始化输出结果
acqResults = cell(PRN_N, TotalNumFrqBins + 1);   % 每个卫星1 + TotalNumFrqBins个cell, 前面TotalNumFrqBins个不同频率的相关结果，最后一个是对应的采样点序号起始点

% 先在频率下搜寻，固定的FFT减少运算量
for frqBinIndex = 1:TotalNumFrqBins
    Freq_Search = FrqBinsSeq(frqBinIndex);      % 搜索频率
    pseudo_doppler = Freq_Search - IF;                              % 该搜索频率对应的载波多普勒
    DopplerRatio = 1 - pseudo_doppler / settings.CarrierFreq;       % 即码片时间长度都被压缩到原有值乘以压缩比
    
    % 计算在该频率下本地复制信号长度和采样序列
    LocalSignalTime = NumofLocalSignalPeriod * 1e-3 * DopplerRatio;  
    SamplingTimeSeq = 0: Ts: LocalSignalTime - Ts;
    NumofSamplingTimeSeq = length(SamplingTimeSeq);
    
    % 生成复载波信号,长度和本地复制信号长度一样       
    Carrier_complex = exp(-1i * SamplingTimeSeq * 2 * pi * Freq_Search);
    
    % ** 接收信号总时长很长，截取其中一部分长度和本地信号一致的进行相关
    StartedSamplingIndex = floor(StartedTime / Ts) + 1;
    EndedSamplingIndex = StartedSamplingIndex + NumofSamplingTimeSeq - 1;
    CorrRecSignal = SamplingSignal(StartedSamplingIndex: EndedSamplingIndex);

    % 与接收信号相乘后进行傅里叶变换
    I1      = real(Carrier_complex .* CorrRecSignal');
    Q1      = imag(Carrier_complex .* CorrRecSignal');
    IQfreqDom1 = fft(I1 + 1i*Q1);
    
    % 在不同PRN下进行搜索
    for PRN_i = 1:PRN_N
        PRN_NUM = settings.acqSatelliteList(PRN_i);             % PRN号码
        
        % 生成本地一个主码的信号采样序列
        [~, MainCode_p] = B2aCodeGen_MainCode(PRN_NUM);         % 长度为10230    
    
        Period_Main = 1e-3  * DopplerRatio;                                             % 一个主码周期时长
        Ts = 1/settings.SampFreq;                                                    	% 采样间隔
%         OffSet = 0 * Ts;                                                                % 初始偏移值，避免落在上升/下降沿
%         LocalSignalSampTimeSeq = OffSet: Ts: Period_Main * NumofLocalSignalPeriod;   	% 对主码的采样时间序列   
        LocalSignalSampTimeSeq = SamplingTimeSeq;
        T_codechip = 1e-3/10230  * DopplerRatio;                                        % 单个码片时长

        % 主码对应的index
        Sig_index_seq = floor(mod(LocalSignalSampTimeSeq,Period_Main)/T_codechip)+1;        % 1 - 10230 导频分量，主码对应位

        % 得到本地基带信号
        Base_Sig_local =  MainCode_p(Sig_index_seq)';

        % 求共轭FFT
        SigFreqDom = conj(fft(Base_Sig_local));
        
        % 频域相乘即为时域相关
        ConvResult = IQfreqDom1 .* SigFreqDom;

        % DFT得到结果
        % *不同频率下的相关点数是不一样的，输出结果点数也不同
        acqResults{PRN_i,frqBinIndex} = (abs(ifft(ConvResult)))/length(Base_Sig_local);
        acqResults{PRN_i,frqBinIndex+1} = [StartedSamplingIndex, EndedSamplingIndex];
    end
end






