function [max_corr, max_idx] = max_xcorr(Interference_before, Interference)
% MAX_NORMALIZED_XCORR 计算归一化信号的最大互相关系数
%   输入：
%       Interference_before : 基准信号（向量）
%       Interference        : 待比较信号（向量）
%   输出：
%       max_corr  : 最大互相关系数（范围[-1,1]）
%       max_idx   : 最大相关值对应的时移索引


% 输入验证
assert(isvector(Interference_before) && isvector(Interference),...
    '输入必须为向量');
assert(length(Interference_before) == length(Interference),...
    '信号长度必须一致');

% 中心化处理（去除直流分量）[1](@ref)
Interference_before_norm = Interference_before - mean(Interference_before);
Interference_norm = Interference - mean(Interference);

% 最大绝对值归一化[3,6](@ref)
Interference_before_norm = Interference_before_norm / max(abs(Interference_before_norm));
Interference_norm = Interference_norm / max(abs(Interference_norm));

% 计算归一化互相关系数[5](@ref)
[xcorr_interference, ~] = xcorr(Interference_norm, Interference_before_norm, 'coeff');

% 寻找最大相关值及索引
[max_corr, max_idx] = max(abs(xcorr_interference));
end