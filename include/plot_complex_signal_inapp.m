function plot_complex_signal_inapp( signal, name, targetAxes)

    
    % 创建平铺布局
    t = tiledlayout(targetAxes.Parent, 4, 1);
    
    % 第一个子图：实部
    ax1 = nexttile(t);
    plot(ax1, real(signal), 'b', 'LineWidth', 1);
    title(ax1, [name '实部']);
    xlabel(ax1, '样本点'); ylabel(ax1, 'Amplitude');
    grid(ax1, 'on');

    % 第二个子图：虚部
    ax2 = nexttile(t);
    plot(ax2, imag(signal), 'r', 'LineWidth', 1);
    title(ax2, [name '虚部']);
    xlabel(ax2, '样本点'); ylabel(ax2, 'Amplitude');
    grid(ax2, 'on');
    
    % 第三个子图：幅值
    ax3 = nexttile(t);
    plot(ax3, abs(signal), 'k', 'LineWidth', 1.5);
    title(ax3, [name '幅值']);
    xlabel(ax3, '样本点'); ylabel(ax3, 'Magnitude');
    grid(ax3, 'on');
    
    % 第四个子图：相位
    ax4 = nexttile(t);
    plot(ax4, rad2deg(angle(signal)), 'm', 'LineWidth', 1);
    title(ax4, [name '相位']);
    xlabel(ax4, '样本点'); ylabel(ax4, 'Phase (degrees)');
    grid(ax4, 'on');
end