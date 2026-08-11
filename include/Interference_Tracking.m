% 针对此处的BPSK信号仿真跟踪算法

function [trackingResults,finalSignal] = Interference_Tracking(InterFreqSignal,Detect_settings,Interference_Info)
% 定义剩余码相位
% remCodePhase  = Interference_Info.InitialCodePhase;
SampFreq = Detect_settings.SampFreq;
num_steps=Detect_settings.num_steps;
remCodePhase=0.0;
% 定义剩余载波相位
remCarrPhase  = 0.0;
% 初始化存储误差
trackingResults = zeros(num_steps, 13); % 存储每次跟踪的相位误差和幅值
%--- 延迟锁定环路 DLL 变量 --------------------------------------------------------
% 定义早后期偏移量(以码片为单位)
earlyLateSpc = Detect_settings.dllCorrelatorSpacing; %相关器间距
% 求和间隔
PDIcode = 0.001;
% 计算码跟踪环路滤波系数值
[tau1code, tau2code] = calcLoopCoef(Detect_settings.dllNoiseBandwidth, Detect_settings.dllDampingRatio, 1.0);
%--- 相位跟踪环路 PLL 变量 --------------------------------------------------------
% 求和间隔
PDIcarr = 0.001;
% 计算载波跟踪环路滤波系数值
[tau1carr, tau2carr] = calcLoopCoef(Detect_settings.pllNoiseBandwidth, Detect_settings.pllDampingRatio,0.25);

% Get a vector with the B2a pilot code sampled 1x/chip
[~, B2aCode]  = B2aCodeGen_MainCode(Interference_Info.PRN_NUM);
B2aCode =B2aCode';
B2aCode = [B2aCode(10230) B2aCode B2aCode(1)];%首尾相连形成循环
% 代码跟踪循环参数
oldCodeNco   = 0.0;
oldCodeError = 0.0;

%载波/科斯塔斯环参数
oldCarrNco   = 0.0;
oldCarrError = 0.0;
% 定义在整个跟踪周期内使用的载波频率
CarrierFreq = Interference_Info.DopplerFrq+Detect_settings.InterFrq;
% CarrierFreq = Interference_Info.DopplerFrq;
CarrierFreqBasis = Interference_Info.DopplerFrq+Detect_settings.InterFrq;
% CarrierFreqBasis = Interference_Info.DopplerFrq;
% 定义NCO的初始码频基准
codeFreq      = Detect_settings.codeFreq;
%定义截取信号的起始点和终止点
SampleOffset = Interference_Info.Local_offset*Detect_settings.SampFreq;
start_index =  SampleOffset;
%end_index=0;


N_data=zeros(num_steps,1);
%===处理指定的码周期的数量 =================
for tracking_i = 1:num_steps

    % 基于码频(可变)和采样频率(固定)更新相位步长
    codePhaseStep = codeFreq / Detect_settings.SampFreq;   %一个采样点相当于多少码相
    % 求整个采样样本中一个“block”或码周期的size
    blksize = ceil((Detect_settings.codeLength-remCodePhase) / codePhaseStep);
    % 读取的数据的采样点个数
    if tracking_i==1
        N_data(tracking_i) = blksize;
    else
        N_data(tracking_i) = N_data(tracking_i-1)+blksize;
    end


    % 给出信号截取的索引
    end_index = start_index + blksize;
    Signal_InterFrq = InterFreqSignal(start_index+1:end_index);
%     Signal_InterFrq_Exp = Interference_1_RecSig(start_index+1:end_index);
    start_index =  end_index;

    %% 设置所有码相跟踪信息 -------------------------
    % Define index into early code vector
    tcode_E       = (remCodePhase-earlyLateSpc) : codePhaseStep : ...
        ((blksize-1)*codePhaseStep+remCodePhase-earlyLateSpc);
    tcode2_E      = ceil(tcode_E) + 1;
    earlyCode   = B2aCode(tcode2_E);

    % Define index into late code vector
    tcode_L       = (remCodePhase+earlyLateSpc) : codePhaseStep : ...
        ((blksize-1)*codePhaseStep+remCodePhase+earlyLateSpc);
    tcode2_L      = ceil(tcode_L) + 1;
    lateCode    = B2aCode(tcode2_L);

    % Define index into prompt code vector
    tcode_P       = remCodePhase : codePhaseStep : ...
        ((blksize-1)*codePhaseStep+remCodePhase);
    tcode2_P      = ceil(tcode_P) + 1;
    promptCode  = B2aCode(tcode2_P);


    remCodePhase = (tcode_P(blksize) + codePhaseStep) - Detect_settings.codeLength; %更新残余码相
    %% 产生载波频率，将信号混合到基带 -----------
    time    = (0:blksize) ./ Detect_settings.SampFreq;   %将一整个blocksize时间化
    % 得到sin/cos函数的参数
    trigarg = ((CarrierFreq * 2.0 * pi) .* time) + remCarrPhase;
    remCarrPhase = rem(trigarg(blksize+1), (2 * pi));
    % 最后计算信号，将采集到的数据混合到基带中
    carrsig = exp(-1i .* trigarg(1:blksize));
    %% 生成六个标准基带值 ---------------------------
    % 中频信号转基带
    Signal_baseband = carrsig  .* Signal_InterFrq' ;
%     InterfSignal_baseband = carrsig  .* Signal_InterFrq_Exp';
    % 计算当前基带信号的幅值
    rmsAmplitude = sqrt(mean(abs(Signal_baseband).^2));  % 计算均方根幅值
    % 分离 I/Q 分量
    I_signal = real(Signal_baseband); % I 分量
    Q_signal = imag(Signal_baseband); % Q 分量
%     I_Interfsignal = real(InterfSignal_baseband); % I 分量
%     Q_Interfsignal = imag(InterfSignal_baseband); % Q 分量

    % 现在获取early、late和prompt的I、Q路信号的值
    I_E = sum(earlyCode .* I_signal);
    Q_E = sum(earlyCode .* Q_signal);
    I_P = sum(promptCode .* I_signal);
    Q_P = sum(promptCode .* Q_signal);
    I_L = sum(lateCode .* I_signal);
    Q_L = sum(lateCode .* Q_signal);
%    rmsAmplitude =  sqrt(I_P^2 + Q_P^2) / blksize;
    rmsAmplitude_1 =  rmsAmplitude/Detect_settings.max_corr;
%     I_E_Interf = sum(earlyCode .* I_Interfsignal);
%     Q_E_Interf = sum(earlyCode .* Q_Interfsignal);
%     I_P_Interf = sum(promptCode .* I_Interfsignal);
%     Q_P_Interf = sum(promptCode .* Q_Interfsignal);
%     I_L_Interf = sum(lateCode .* I_Interfsignal);
%     Q_L_Interf = sum(lateCode .* Q_Interfsignal);

    %     AutoR = ifft(fft(promptCode).*conj(fft(I_signal)));
    %     plot(AutoR)
    %     hold on
    %% 计算相位误差
    % 实现载波环路鉴别器(鉴相器)
    CarrPhaseErr = atan2(Q_P , I_P) / (2.0 * pi);
%     CarrPhaseErr_Interf= atan2(Q_P_Interf , I_P_Interf) / (2.0 * pi);
    % DLL: 码误差
    CodePhaseErr = (sqrt(I_E * I_E + Q_E * Q_E) - sqrt(I_L * I_L + Q_L * Q_L)) / ...
        (sqrt(I_E * I_E + Q_E * Q_E) + sqrt(I_L * I_L + Q_L * Q_L));

%     CodePhaseErr_Interf = (sqrt(I_E_Interf * I_E_Interf + Q_E_Interf * Q_E_Interf) - sqrt(I_L_Interf * I_L_Interf + Q_L_Interf * Q_L_Interf)) / ...
%         (sqrt(I_E_Interf * I_E_Interf + Q_E_Interf * Q_E_Interf) + sqrt(I_L_Interf * I_L_Interf + Q_L_Interf * Q_L_Interf));
 
    clear I_E Q_E I_L Q_L I_E_Interf Q_E_Interf I_P_Interf Q_P_Interf I_L_Interf Q_L_Interf
    %% 更新NCO
    % 更新码NCO
    codeNco = oldCodeNco + (tau2code/tau1code) * ...
        (CodePhaseErr - oldCodeError) + CodePhaseErr * (PDIcode/tau1code);
    oldCodeNco   = codeNco;
    oldCodeError = CodePhaseErr;

    % 更新载波NCO
    carrNco = oldCarrNco + (tau2carr/tau1carr) * ...
        (CarrPhaseErr - oldCarrError) + CarrPhaseErr * (PDIcarr/tau1carr);
    oldCarrNco   = carrNco;
    oldCarrError = CarrPhaseErr;
    % 更新载波和码的频率
    CarrierFreq = CarrierFreqBasis + carrNco;
    codeFreq = Detect_settings.codeFreq - codeNco;
    % 记录每次跟踪的相位误差
    CodePhaseErr_Interf = 0;
    CarrPhaseErr_Interf = 0;
    trackingResults(tracking_i, :) = [CodePhaseErr, CarrPhaseErr, rmsAmplitude_1, I_P, Q_P, blksize, remCodePhase, remCarrPhase, codeFreq, CarrierFreq, CodePhaseErr_Interf,CarrPhaseErr_Interf,N_data(tracking_i)];
    
    %% 还原信号
    carrsig_recon = exp(-1i .* trigarg(1:blksize));
    BPSK_RecSig = promptCode.*carrsig_recon;

    if (Detect_settings.flagofbandlimited == 1)
    [impulse_response, ~] = impz(Detect_settings.lowPassFilter);
    Signal_InterFrq_1=Signal_InterFrq/max(abs(Signal_InterFrq));
    % 1. 互相关运算
    [corr_seq, lags] = xcorr(Signal_InterFrq_1, BPSK_RecSig, 'coeff');
    % 2. 找到最大相关值及其位置
    [max_corr, max_idx] = max(abs(corr_seq));
    optimal_lag = lags(max_idx);
    phase_diff = angle(corr_seq(max_idx));
    % 3. 计算幅值比例
    amp_ratio = rms(Signal_InterFrq_1) / rms(BPSK_RecSig);
    % 4. 信号优化
    optimized_BPSK_RecSig = zeros(size(BPSK_RecSig));
    if optimal_lag >= 0
        % 需要右移
        optimized_BPSK_RecSig(1:end-optimal_lag) = BPSK_RecSig(optimal_lag+1:end);
        optimized_BPSK_RecSig(end-optimal_lag+1:end) = BPSK_RecSig(1:optimal_lag);
    else
        % 需要左移
        optimized_BPSK_RecSig(-optimal_lag+1:end) = BPSK_RecSig(1:end+optimal_lag);
        optimized_BPSK_RecSig(1:-optimal_lag) = BPSK_RecSig(end+optimal_lag+1:end);
    end
    % 相位和幅值校正
    optimized_BPSK_RecSig = optimized_BPSK_RecSig * amp_ratio * exp(1i * phase_diff);
    % 对齐后的重构信号进行归一化处理
    aligned_BPSK_RecSig_normalized = optimized_BPSK_RecSig / max(abs(optimized_BPSK_RecSig));
    %% 执行线性卷积
    corr_windowed = aligned_BPSK_RecSig_normalized;
    conv_result = conv(corr_windowed, impulse_response, 'full');
    % 计算卷积延迟
    filterDelay = (length(Detect_settings.lowPassFilter) - 1) / 2;  % 滤波器延迟（单位：样本数）
    % 调整时间轴以对齐
    aligned_conv_result = conv_result(filterDelay + 1 : end - filterDelay);

    BPSK_RecSig=aligned_conv_result;
    end
    % 叠加当前信号到最终信号
    if tracking_i==1
        finalSignal(1:N_data(tracking_i)) = BPSK_RecSig;
    else
        finalSignal(N_data(tracking_i-1)+1:N_data(tracking_i)) = BPSK_RecSig;
    end

end
end