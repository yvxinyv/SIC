%% 捕获模块
% 捕获参数设置
Acquisiton_settings = General_settings;
Acquisiton_settings.acqSatelliteList = [1,2,3,4];         % 卫星通道PRN
Acquisiton_settings.SingleSideNumFrqBins = 8;      
Acquisiton_settings.acqStep = 200;
Acquisiton_settings.StartedTime = 0;                % ** 进行自相关信号的起始时间（在全长信号中，截取从该时间开始的一段信号和本地信号进行相关）

% 进行捕获
acqResults_1 = BPSK_Acquisition(InterFreqSignal,Acquisiton_settings);

% 根据捕获结果，得到其对应的多普勒频率和循环偏移时间、传播时延等
InfoGroup_1 = AcqResult(acqResults_1,Acquisiton_settings);        % 后面1 为画图，0不画图

Sat_1_Info = InfoGroup_1{1,1};


%% -----
%% 跟踪模块
% * 固定其多普勒为零
% 使用1ms的信号进行鉴别
% 初始化跟踪参数
Detect_period = 499e-3;  % 跟踪周期为499ms,略小于整体信号长度
step_size = 1e-3;        % 每次移动1ms
num_steps = Detect_period / step_size; % 步数
Detect_settings = General_settings;
Detect_settings.num_steps=num_steps;
Detect_settings.max_corr=max_corr;
% 码跟踪环路参数
Detect_settings.dllDampingRatio         = 0.7;
Detect_settings.dllNoiseBandwidth       = 2;          % [Hz]
Detect_settings.dllCorrelatorSpacing    = 0.5;        % [chips]
% 载波跟踪环路参数
Detect_settings.pllDampingRatio         = 0.7;
Detect_settings.pllNoiseBandwidth       = 10;         % [Hz]

%对卫星1信号进行跟踪
[trackingResults_Sat_1_1] = BPSK_Tracking(InterFreqSignal,Detect_settings,Sat_1_Info);

% 从跟踪结果中提取误差数据
codeErrors_1(1:num_steps) = trackingResults_Sat_1_1(:, 1);    % 码相位误差
carrErrors_1(1:num_steps) = trackingResults_Sat_1_1(:, 2);    % 载波相位误差

% 计算码相位跟踪精度
init_rmseCode = sqrt(mean(codeErrors_1.^2));
% 计算载波相位跟踪精度
init_rmseCarr = sqrt(mean(carrErrors_1.^2));


%% 自干扰消除模块
%% 初始化循环参数
max_iterations = 3;       % 最大循环次数n
current_iteration = 1;    % 当前迭代次数
IRR_dB = 0;               % 初始干扰抑制比
IRR_threshold = 10;       % 目标抑制比阈值
err_threshold = 0.005;
if (init_rmseCode > err_threshold) || (init_rmseCarr > err_threshold)
    loop_active = true;
    fprintf('启动自干扰消除\n');
end
while loop_active &&(IRR_dB < IRR_threshold) && (current_iteration <= max_iterations)
    fprintf('--- 开始第%d次自干扰消除 ---\n', current_iteration);
    if current_iteration > 1
        InterFreqSignal = cleanedSignal;  % 更新输入信号为上次处理结果
    end
    %对自干扰信号进行跟踪
    Interference_Info = InfoGroup_1{4,1};%获取捕获结果
    SampleOffset = Interference_Info.Local_offset*General_settings.SampFreq;
    [trackingResults_1,finalSignal] = Interference_Tracking(InterFreqSignal,Detect_settings,Interference_Info);
    fiSignal = zeros(length(finalSignal), 1);
    N_data = trackingResults_1(:, 13);
    for tracking_i = 1:num_steps
        Interf_1_Amplitude=trackingResults_1(tracking_i, 3);
        if tracking_i==1
            fiSignal(1:N_data(tracking_i)) = finalSignal(1:N_data(tracking_i)).'*Interf_1_Amplitude;
        else
            fiSignal(N_data(tracking_i-1)+1:N_data(tracking_i)) = finalSignal(N_data(tracking_i-1)+1:N_data(tracking_i)).'*Interf_1_Amplitude;
        end

    end

    % 叠加当前信号到最终信号
    cleanedSignal = InterFreqSignal(SampleOffset+1:SampleOffset+length(finalSignal)) - fiSignal;
    cleanedSignal = limit_amplitude(cleanedSignal, 1,50000);
    cleanedSignal(length(finalSignal)+1:length(InterFreqSignal)-SampleOffset) = InterFreqSignal(SampleOffset+length(finalSignal)+1:end);
    Interference_1_res= Interference(SampleOffset+1:SampleOffset+length(finalSignal))- fiSignal;
    Interference_1_res(length(finalSignal)+1:length(Interference)-SampleOffset) = Interference(SampleOffset+length(finalSignal)+1:end);
    %重新捕获信号
    Acquisiton_settings.StartedTime =  50* 1e-3;
    Acquisiton_settings.acqSatelliteList = [1,2,3,4];
    acqResults_2 = BPSK_Acquisition(cleanedSignal,Acquisiton_settings);
    
    % 根据捕获结果，得到其对应的多普勒频率和循环偏移时间、传播时延等
    InfoGroup_2 = AcqResult(acqResults_2,Acquisiton_settings);        % 后面1 为画图，0不画图
    Sat_1_Info_1 = InfoGroup_2{1,1};
    SampleOffset = Sat_1_Info_1.Local_offset*General_settings.SampFreq+Acquisiton_settings.StartedTime*General_settings.SampFreq;

    %对卫星1信号进行进行跟踪
    Detect_period = 499e-3-Acquisiton_settings.StartedTime;  % 跟踪周期为500ms
    step_size = 1e-3;        % 每次移动1ms
    num_steps = round(Detect_period / step_size); % 步数
    Detect_settings.num_steps=num_steps;
    [trackingResults_Sat_1_2] = BPSK_Tracking(cleanedSignal,Detect_settings,Sat_1_Info_1);

    % 从跟踪结果中提取误差数据
    codeErrors_2 = trackingResults_Sat_1_2(:, 1);    % 码相位误差
    carrErrors_2 = trackingResults_Sat_1_2(:, 2);    % 载波相位误差
    start_idx = 495* 1e-3* General_settings.SampFreq+1;
    end_idx = 499* 1e-3* General_settings.SampFreq;
    Interference_1_res_sample=Interference_1_res(start_idx:end_idx);
    %平滑信号，去除异常值
    Interference_1_res_sample = limit_amplitude(Interference_1_res_sample, 0.5,50000);
    P_interference_after = mean(abs(Interference_1_res_sample).^2);
    P_interference_before = mean(abs(Interference).^2); % 干扰信号信号功率（W）
    IRR_dB =IRR_dB+ 10 * log10(P_interference_before / P_interference_after); % 计算干扰抑制比
    % 计算码相位跟踪精度
    rmseCode = sqrt(mean(codeErrors_2.^2));
    % 计算载波相位跟踪精度
    rmseCarr = sqrt(mean(carrErrors_2.^2));

    fprintf('码相位RMSE: %.4f 码片\n', rmseCode);
    fprintf('载波相位RMSE: %.4f π弧度\n', rmseCarr);
    fprintf('干扰抑制比: %.2f dB\n', IRR_dB);
    fprintf('--- 结束第%d次自干扰消除 ---\n', current_iteration);
    current_iteration=current_iteration+1;
end
disp(' 自干扰消除完成 ')
%% 波形对比分析模块（示例：截取前0.01ms秒的数据）
% Start_plot = input('输入 "1" 开始绘制波形，输入 "0" 结束程序 : ');

% % if (Start_plot == 1)
%     start_idx = round(286.99* 1e-3* General_settings.SampFreq+1);
%     end_idx = round(287* 1e-3* General_settings.SampFreq);  % 0.01ms对应的采样点数
% 
%     % 截取各信号的长序列
%     Interference_long = Interference(start_idx:end_idx);
%     fiSignal_long = fiSignal(start_idx+SampleOffset:end_idx+SampleOffset);
%     residual_long = Interference_1_res(start_idx:end_idx);
%     n = 1:length(Interference_long); % 时间序列（根据实际采样点定义）
%     t = linspace(286.99e-3, 287e-3, length(Interference_long)) * 1e3;
%     % 绘制时域波形
%     figure;
%     plot(t, real(Interference_long), 'b-', 'LineWidth', 1.5);       % 蓝色实线表示fiSignal
%     hold on;
%     plot(t, real(conj(fiSignal_long)), 'r--', 'LineWidth', 1.5);    % 红色虚线表示Interference
%     hold off;
% 
%     % 设置图形属性
%     title('时域波形对比 (0.01ms窗口)', 'FontSize', 12);
%     xlabel('时间 (ms)', 'FontSize', 10);
%     ylabel('幅度 (实部)', 'FontSize', 10);
%     grid on;
%     legend('Interference', 'fiSignal', 'Location', 'best');
%     % 绘制Interference的四个分量
%     plot_complex_signal(Interference_long, '自干扰信号');
% 
%     % 绘制fiSignal的四个分量
%     plot_complex_signal(fiSignal_long, '重建的干扰信号');
% 
%     % 绘制residual的四个分量
%     plot_complex_signal(residual_long, '残留干扰信号');
% end
% disp(' ');
% disp(' 程序结束 ')