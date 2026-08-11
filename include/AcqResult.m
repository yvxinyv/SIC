% 根据捕获得到的内容
% 计算多普勒、循环偏移时间、噪声等信息

% acqResults 是一个 （PRN_N,TotalNumFrqBins + 1） 的cell矩阵
% 每一行前 TotalNumFrqBins 是各个frqBin对应的相关值（数组，维度为采样点数，不同frqbin下采样点数不一定一样）
% 最后一个为进行相关的接收信号采样起始点
% PlotOrNot == 1 时，进行画图，否则不画

function InfoGroup = AcqResult(acqResults,settings)
PRN_N = length(settings.acqSatelliteList);              % 卫星通道个数
FrqBin_N = 2 * settings.SingleSideNumFrqBins +1;        % FrqBin的个数
Ts = settings.Ts;                                       % 采样率
PlotOrNot = settings.flagofacquisition;
if PlotOrNot == 1
        for PRN_i = 1: PRN_N
            PRN_NUM = settings.acqSatelliteList(PRN_i); % PRN号码
            figure
            for fi = 1 : FrqBin_N
                DopplerFrq = -(fi - settings.SingleSideNumFrqBins - 1) * settings.acqStep;   % 对应的多普勒搜索频率
                CorrValues = acqResults{PRN_i,fi};                                  % 相关值
                FFT_N = length(CorrValues);                                         % 总计点数
                Offset_Time = (0:FFT_N-1) * settings.Ts * 1e6;                      % 对应时延, 单位: us

                plot3(DopplerFrq * ones(FFT_N,1), Offset_Time, CorrValues);
                hold on
            end
            xlabel('Doppler Frq [unit: Hz]'); ylabel('delay [unit: us]'); zlabel('Correlation Value');
            title(['PRN-',num2str(PRN_NUM)]);
        end
end

% 找最大值、统计、输出结果等
InfoGroup = cell(PRN_N,1);      % 有多个Info结果
for PRN_i = 1: PRN_N
    Info.PRN_NUM = settings.acqSatelliteList(PRN_i); % PRN号码
    % 统计平均值，标准差，找到最大值
    MeanCorrValue = 0;
    STDCorrValue = 0;
    NumofCorrValue = 0;
    MaxCorrValue = 0;
%     MaxCorrIndex = [mi_frq,mj_delay]; 
    MaxCorrIndex = [-1,-1];
    
    for fi = 1 : FrqBin_N  
        CorrValues = acqResults{PRN_i,fi};                  % 相关值
        NN = length(CorrValues);                            % 当前个数
        [CurrentMax, CurrentIndex] = max(CorrValues);
        if CurrentMax > MaxCorrValue
            MaxCorrValue = CurrentMax;
            MaxCorrIndex = [fi,CurrentIndex];               % 最大值索引
        end
        MeanCorrValue = MeanCorrValue + sum(CorrValues);    % 算术和
        STDCorrValue = STDCorrValue + sum(CorrValues.^2);   % 平方和
        NumofCorrValue = NumofCorrValue + NN;
    end
    Info.MaxCorrIndex = MaxCorrIndex;
    Info.MeanCorrValue = MeanCorrValue/NumofCorrValue;
    Info.STDCorrValue = sqrt(STDCorrValue/NumofCorrValue);    
     
    % 根据MaxCorrIndex 给出对应的频率和循环偏移时间
    mi_frq = MaxCorrIndex(1);   mj_offset = MaxCorrIndex(2);
    Info.DopplerFrq = (mi_frq - settings.SingleSideNumFrqBins - 1) * settings.acqStep;
    Info.Local_offset = Ts * (mj_offset - 1);
    
    % 根据循环偏移时间，计算参考时间点码相位
    % 参考时间点为进行相关信号的起始时间点
    DopplerRatio = 1 - Info.DopplerFrq / settings.CarrierFreq;    % 即码片时间长度都被压缩到原有值乘以压缩比
    Period_Main = 1e-3  * DopplerRatio;                  % 一个主码周期时长    
    Info.InitialCodePhase = Info.Local_offset/Period_Main  * 10230;
    
    % 记录进行相关信号的采样点起始结束序号
    Info.StartEndIndex = acqResults{PRN_i,end};
    
    % 输出结果
    InfoGroup{PRN_i,1} = Info;
end
end

