function [CNo]= CNoVSM(I,Q,T)

%用方差和法计算CNo
%
%[CNo]= CNoVSM(I,Q)
%
%   Inputs:
%       I           - 提示在跟踪信号的相位值
%       Q           - 提示来自跟踪的信号的正交相位值
%       T          - 跟踪累计间隔(s)
%   Outputs:
%       CNo         - 对于给定的I和Q值估计C/No
%
%
%计算能量
Z=I.^2+Q.^2;
%计算能量的平均值和方差
Zm=mean(Z);
Zv=var(Z);
%计算平均载波能量
Pav=sqrt(Zm^2-Zv);
%计算噪声方差
Nv=0.5*(Zm-Pav);
%计算 C/No
CNo=10*log10(abs((1/T)*Pav/(2*Nv)));