% 定义通用绘图函数
function plot_complex_signal(signal, name)
    figure;

    % 实部
    subplot(4,1,1);
    plot(real(signal), 'b', 'LineWidth', 1);
    title([name '实部']);
    xlabel('样本点'); ylabel('Amplitude');
    grid on;
    
    % 虚部
    subplot(4,1,2);
    plot( imag(signal), 'r', 'LineWidth', 1);
    title([name '虚部']);
    xlabel('样本点'); ylabel('Amplitude');
    grid on;
    
    % 幅值
    subplot(4,1,3);
    plot( abs(signal), 'k', 'LineWidth', 1.5);
    title([name '幅值']);
    xlabel('样本点'); ylabel('Magnitude');
    grid on;
    
    % 相位（解卷绕后以度为单位）
    subplot(4,1,4);
    plot( rad2deg(angle(signal)), 'm', 'LineWidth', 1);
    title([name '相位']);
    xlabel('样本点'); ylabel('Phase (degrees)');
    grid on;
    
    set(gcf, 'Position', [100 100 1000 800]); % 调整图形窗口尺寸
end