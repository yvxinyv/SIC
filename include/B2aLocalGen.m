function [B2aLocal_Data,B2aLocal_Pilot] = B2aLocalGen(PRN,settings)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% B2a码

%生成数据分量主码和导频分量主码
[B2aMainCode_Data, B2aMainCode_Pilot] = B2aCodeGen_MainCode(PRN);


%采样间隔
ts = 1/settings.SampFreq;

% 每个码周期的采样数
samplesPerCode = round(settings.SampFreq / (settings.CodeFreq/settings.CodeLength));

% 一个码片的时间长度
T_CodeChip = 1/settings.CodeFreq;

%数据码的采样
CodeIndexData = ceil(ts*(1:samplesPerCode)/T_CodeChip);
CodeIndexData(end) = settings.CodeLength;
CodeIndexData(1) = 1;
B2aLocal_Data = B2aMainCode_Data(CodeIndexData);

%导频码的采样
CodeIndexPilot = ceil(ts.*(1:samplesPerCode)/T_CodeChip);
CodeIndexPilot(end) = settings.CodeLength;
CodeIndexPilot(1) = 1;
B2aLocal_Pilot = B2aMainCode_Pilot(CodeIndexPilot);



end

