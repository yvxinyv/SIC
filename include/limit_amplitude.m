function cleaned_signal = limit_amplitude(signal, threshold, window_size)
    % signal: 输入的长序列信号
    % threshold: 异常值判断的阈值
    % window_size: 每段的窗口大小
    n = length(signal);
    cleaned_signal = zeros(size(signal)); % 预分配内存
    
    % 计算需要处理的段数
    num_segments = ceil(n / window_size);
    
    for i = 1:num_segments
        % 确定当前段的起始和结束索引
        start_idx = (i-1)*window_size + 1;
        end_idx = min(i*window_size, n);
        
        % 提取当前段的信号
        segment = signal(start_idx:end_idx);
        
        % 计算当前段的中位数和标准差
        median_val = median(segment);
        std_val = std(segment);
        
        % 确定上下限
        upper = median_val + threshold * std_val;
        lower = median_val - threshold * std_val;
        
        % 遍历当前段的每个点，判断是否为异常值
        for j = start_idx:end_idx
            if signal(j) > upper || signal(j) < lower
                cleaned_signal(j) = median_val; % 异常值替换为中位数
            else
                cleaned_signal(j) = signal(j); % 非异常值保持原值
            end
        end
    end
end