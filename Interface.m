classdef Interface < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        TextArea               matlab.ui.control.TextArea
        Label_3                matlab.ui.control.Label
        Image                  matlab.ui.control.Image
        Panel                  matlab.ui.container.Panel
        IRR_EditField          matlab.ui.control.NumericEditField
        Label_2                matlab.ui.control.Label
        CodeRMSE_EditField     matlab.ui.control.NumericEditField
        RMSELabel_2            matlab.ui.control.Label
        CarrRMSE_EditField     matlab.ui.control.NumericEditField
        RMSELabel              matlab.ui.control.Label
        Plot_Button            matlab.ui.control.Button
        cancellation_Button_2  matlab.ui.control.Button
        Title_Label            matlab.ui.control.Label
        cancellation_Button    matlab.ui.control.Button
    end

    
    properties (Access = private)
            SFreq        % 采样率
            Interf       %自干扰信号
            fi           %重构的干扰信号
            Interf_res   %消除后残留的干扰信号
            SOffset      %偏移量
            app2Handle   % 用于存储 app2 实例的句柄
    end

    
    methods (Access = private)
        
        
        
        function  run_simulation(app)
                 Signal_Init;
                 app.TextArea.Value = '信号生成完成，开始自干扰消除...';
                 drawnow;
                 Interference_Cancellation;
                 app.CodeRMSE_EditField.Value = rmseCode;
                 app.CarrRMSE_EditField.Value = rmseCarr;
                 app.IRR_EditField.Value = IRR_dB;
                 app.SFreq = General_settings.SampFreq;
                 app.Interf =  Interference;
                 app.fi = fiSignal;
                 app.Interf_res = Interference_1_res;
                 app.SOffset  = SampleOffset;

        end
    end
    

    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.UIFigure.Name='仿真平台';
        end

        % Button pushed function: cancellation_Button
        function cancellation_ButtonPushed(app, event)
            % 立即更新界面
            app.TextArea.Value = '启动程序，开始信号生成...';
            app.cancellation_Button.Enable = 'off';
            app.cancellation_Button_2.Enable = 'off';
            app.Plot_Button.Enable = 'off';
            app.CodeRMSE_EditField.Value = 0;
            app.CarrRMSE_EditField.Value = 0;
            app.IRR_EditField.Value = 0;
            drawnow; % 强制刷新界面

            % 执行耗时任务
            run_simulation(app);

            % 任务完成后更新
            app.TextArea.Value = '自干扰消除完成！';
            app.cancellation_Button.Enable = 'on';
            app.cancellation_Button_2.Enable = 'on';
            app.Plot_Button.Enable = 'on';
        end

        % Button pushed function: cancellation_Button_2
        function cancellation_Button_2Pushed(app, event)
            app.TextArea.Value='程序结束';
            % 如果 app2 存在，则关闭它
            if ~isempty(app.app2Handle)
                try
                    delete(app.app2Handle.UIFigure); % 尝试关闭 app2 的窗口
                catch
                    % 如果 app2Handle 不是 App 实例，或者 UIFigure 不存在，则忽略错误
                end
            end
            delete(app);

            % 清空工作区和命令行窗口
            clear ;  % 清除工作区所有变量
            clc;        % 清空命令行窗口
        end

        % Button pushed function: Plot_Button
        function Plot_ButtonPushed(app, event)
            app.TextArea.Value = '开始绘图!';
            drawnow; % 强制刷新界面
            % 创建 app2 实例并传入数据
            app.app2Handle = SubInterface; % 启动 子界面
            app.app2Handle.SFreq = app.SFreq;
            app.app2Handle.Interf = app.Interf;
            app.app2Handle.fi = app.fi;
            app.app2Handle.Interf_res = app.Interf_res;
            app.app2Handle.SOffset = app.SOffset;
            app.app2Handle.plotSignal();
%             app2Instance.UIFigure.Visible = 'on'; % 显示窗口
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 817 676];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';

            % Create cancellation_Button
            app.cancellation_Button = uibutton(app.UIFigure, 'push');
            app.cancellation_Button.ButtonPushedFcn = createCallbackFcn(app, @cancellation_ButtonPushed, true);
            app.cancellation_Button.WordWrap = 'on';
            app.cancellation_Button.Position = [173 516 120 40];
            app.cancellation_Button.Text = '启动';

            % Create Title_Label
            app.Title_Label = uilabel(app.UIFigure);
            app.Title_Label.BackgroundColor = [0.0745 0.6235 1];
            app.Title_Label.HorizontalAlignment = 'center';
            app.Title_Label.FontName = '微软雅黑';
            app.Title_Label.FontSize = 24;
            app.Title_Label.FontWeight = 'bold';
            app.Title_Label.Position = [1 604 817 73];
            app.Title_Label.Text = '同时同频段自干扰消除算法软件仿真平台';

            % Create cancellation_Button_2
            app.cancellation_Button_2 = uibutton(app.UIFigure, 'push');
            app.cancellation_Button_2.ButtonPushedFcn = createCallbackFcn(app, @cancellation_Button_2Pushed, true);
            app.cancellation_Button_2.Position = [565 516 120 40];
            app.cancellation_Button_2.Text = '结束';

            % Create Panel
            app.Panel = uipanel(app.UIFigure);
            app.Panel.TitlePosition = 'centertop';
            app.Panel.Title = '干扰消除结果显示';
            app.Panel.Position = [173 145 512 282];

            % Create Plot_Button
            app.Plot_Button = uibutton(app.Panel, 'push');
            app.Plot_Button.ButtonPushedFcn = createCallbackFcn(app, @Plot_ButtonPushed, true);
            app.Plot_Button.Position = [178 29 141 36];
            app.Plot_Button.Text = '结果绘图';

            % Create RMSELabel
            app.RMSELabel = uilabel(app.Panel);
            app.RMSELabel.HorizontalAlignment = 'right';
            app.RMSELabel.Position = [125 204 138 22];
            app.RMSELabel.Text = '码相位差RMSE(码片）   ';

            % Create CarrRMSE_EditField
            app.CarrRMSE_EditField = uieditfield(app.Panel, 'numeric');
            app.CarrRMSE_EditField.Position = [287 204 90 22];

            % Create RMSELabel_2
            app.RMSELabel_2 = uilabel(app.Panel);
            app.RMSELabel_2.HorizontalAlignment = 'right';
            app.RMSELabel_2.Position = [127 151 136 22];
            app.RMSELabel_2.Text = '载波相位差RMSE(π rad)';

            % Create CodeRMSE_EditField
            app.CodeRMSE_EditField = uieditfield(app.Panel, 'numeric');
            app.CodeRMSE_EditField.Position = [285 150 90 22];

            % Create Label_2
            app.Label_2 = uilabel(app.Panel);
            app.Label_2.HorizontalAlignment = 'right';
            app.Label_2.Position = [127 89 121 22];
            app.Label_2.Text = '干扰抑制比(dB)          ';

            % Create IRR_EditField
            app.IRR_EditField = uieditfield(app.Panel, 'numeric');
            app.IRR_EditField.Position = [285 89 90 22];

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.Position = [716 1 100 100];
            app.Image.ImageSource = 'logo.jpg';

            % Create Label_3
            app.Label_3 = uilabel(app.UIFigure);
            app.Label_3.HorizontalAlignment = 'right';
            app.Label_3.Position = [272 459 77 24];
            app.Label_3.Text = '程序运行提示';

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.HorizontalAlignment = 'center';
            app.TextArea.Position = [391 459 194 24];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Interface

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end