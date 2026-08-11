    start_idx = round(286.99* 1e-3* General_settings.SampFreq+1);
    end_idx = round(287* 1e-3* General_settings.SampFreq);  % 0.01ms对应的采样点数

    % 截取各信号的长序列
    Interference_long = Interference(start_idx:end_idx);
    fiSignal_long = fiSignal(start_idx+SampleOffset:end_idx+SampleOffset);
    residual_long = Interference_1_res(start_idx:end_idx);
    n = 1:length(Interference_long); % 时间序列（根据实际采样点定义）
    t = linspace(286.99e-3, 287e-3, length(Interference_long)) * 1e3;
    % 绘制时域波形
    figure;
    plot(t, real(Interference_long), 'b-', 'LineWidth', 1.5);       % 蓝色实线表示fiSignal
    hold on;
    plot(t, real(fiSignal_long), 'r--', 'LineWidth', 1.5);    % 红色虚线表示Interference
    hold off;

    % 设置图形属性
    title('时域波形对比 (0.01ms窗口)', 'FontSize', 12);
    xlabel('时间 (ms)', 'FontSize', 10);
    ylabel('幅度 (实部)', 'FontSize', 10);
    grid on;
    legend('Interference', 'fiSignal', 'Location', 'best');
    % 绘制Interference的四个分量
    plot_complex_signal(Interference_long, '自干扰信号');

    % 绘制fiSignal的四个分量
    plot_complex_signal(fiSignal_long, '重建的干扰信号');

    % 绘制residual的四个分量
    plot_complex_signal(residual_long, '残留干扰信号');