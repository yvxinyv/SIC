classdef SubInterface < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure  matlab.ui.Figure
        TabGroup  matlab.ui.container.TabGroup
        Tab1      matlab.ui.container.Tab
        UIAxes    matlab.ui.control.UIAxes
        Tab2      matlab.ui.container.Tab
        UIAxes2   matlab.ui.control.UIAxes
        Tab3      matlab.ui.container.Tab
        UIAxes3   matlab.ui.control.UIAxes
        Tab4      matlab.ui.container.Tab
        UIAxes4   matlab.ui.control.UIAxes
    end

    
    properties (Access = public)
            SFreq        % 采样率
            Interf       %自干扰信号
            fi           %重构的干扰信号
            Interf_res   %消除后残留的干扰信号
            SOffset      %偏移量

    end
    

    

    
    methods (Access = public)
        
        function plotSignal(app)
            % 清空坐标系并重置属性
            app.UIAxes.Visible = 'on';
            app.UIAxes.XLim = [286.99, 287];
            app.UIAxes.XLabel.String = '时间 (ms)';
            app.UIAxes.YLabel.String = '幅度';
            start_idx = round(286.99* 1e-3* app.SFreq+1);
            end_idx = round(287* 1e-3* app.SFreq);  % 0.01ms对应的采样点数
            % 截取各信号的长序列
            Interference_long = app.Interf(start_idx:end_idx);
            fiSignal_long = app.fi(start_idx+app.SOffset:end_idx+app.SOffset);
            residual_long = app.Interf_res (start_idx:end_idx);
            t = linspace(286.99e-3, 287e-3, length(Interference_long)) * 1e3;

            % 绘制时域波形
            % 自动设置刻度
            app.UIAxes.XTickMode = 'auto';
            app.UIAxes.YTickMode = 'auto';
            % 绘制信号
            plot(app.UIAxes, t, real(Interference_long), 'b-', 'LineWidth', 1.5, 'DisplayName', '原始干扰');
            hold(app.UIAxes, "on");
            plot(app.UIAxes, t, real(fiSignal_long), 'r--', 'LineWidth', 1.5, 'DisplayName', '重构干扰');
            hold(app.UIAxes, "off");
            plot_complex_signal_inapp(Interference_long, '自干扰信号', app.UIAxes2);
            plot_complex_signal_inapp(fiSignal_long, '重建干扰信号', app.UIAxes3);
            plot_complex_signal_inapp(residual_long, '残留干扰信号', app.UIAxes4);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % 初始化标签页的坐标轴
            cla(app.UIAxes);
            cla(app.UIAxes2);
            cla(app.UIAxes3);
            cla(app.UIAxes4);
            app.UIFigure.Name='绘图界面';
        end

        % Button down function: Tab1
        function Tab1ButtonDown(app, event)
% %             % 清空坐标系并重置属性
% %             cla(app.UIAxes);
% %             app.UIAxes.XLim = [286.99, 287];
% %             app.UIAxes.XLabel.String = '时间 (ms)';
% %             app.UIAxes.YLabel.String = '幅度';
% %             start_idx = round(286.99* 1e-3* app.SFreq+1);
% %             end_idx = round(287* 1e-3* app.SFreq);  % 0.01ms对应的采样点数
% %             % 截取各信号的长序列
% %             Interference_long = app.Interf(start_idx:end_idx);
% %             fiSignal_long = app.fi(start_idx+app.SOffset:end_idx+app.SOffset);
% %             % residual_long = Interference_1_res(start_idx:end_idx);
% %             t = linspace(286.99e-3, 287e-3, length(Interference_long)) * 1e3;
% %             % 绘制时域波形
% %             
% %             plot(app.UIAxes,t, real(Interference_long), 'b-', 'LineWidth', 1.5);       % 蓝色实线表示fiSignal
% %             hold(app.UIAxes,"on");
% %             plot(app.UIAxes,t, real(conj(fiSignal_long)), 'r--', 'LineWidth', 1.5);    % 红色虚线表示Interference
% %             hold(app.UIAxes,"off");
        end

        % Selection change function: TabGroup
        function TabGroupSelectionChanged(app, event)
            selectedTab = app.TabGroup.SelectedTab;
%             % 隐藏所有坐标区
%             app.UIAxes.Visible = 'off';
%             app.UIAxes2.Visible = 'off';
%             app.UIAxes3.Visible = 'off';
%             app.UIAxes4.Visible = 'off';
%             % 根据选中 Tab 动态创建坐标轴
%             switch selectedTab
%                 case app.Tab1
%                     app.UIAxes.Visible = 'on';
%                 case app.Tab2
%                     app.UIAxes2.Visible = 'on';
%                 case app.Tab3
%                     app.UIAxes3.Visible = 'on';
%                 case app.Tab4
%                     app.UIAxes4.Visible = 'on';
% 
% % %                     app.ax4.Position = [1,1,693,513];
% 
%             
%             end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 695 593];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.SelectionChangedFcn = createCallbackFcn(app, @TabGroupSelectionChanged, true);
            app.TabGroup.Position = [1 1 695 593];

            % Create Tab1
            app.Tab1 = uitab(app.TabGroup);
            app.Tab1.Title = 'Tab1';
            app.Tab1.ButtonDownFcn = createCallbackFcn(app, @Tab1ButtonDown, true);

            % Create UIAxes
            app.UIAxes = uiaxes(app.Tab1);
            title(app.UIAxes, '自干扰信号与重建干扰信号对比图')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [1 0 694 560];

            % Create Tab2
            app.Tab2 = uitab(app.TabGroup);
            app.Tab2.Title = 'Tab2';

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.Tab2);
            title(app.UIAxes2, 'Title')
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Position = [1 5 694 560];

            % Create Tab3
            app.Tab3 = uitab(app.TabGroup);
            app.Tab3.Title = 'Tab3';

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.Tab3);
            title(app.UIAxes3, 'Title')
            xlabel(app.UIAxes3, 'X')
            ylabel(app.UIAxes3, 'Y')
            zlabel(app.UIAxes3, 'Z')
            app.UIAxes3.Position = [1 0 694 560];

            % Create Tab4
            app.Tab4 = uitab(app.TabGroup);
            app.Tab4.Title = 'Tab4';

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.Tab4);
            title(app.UIAxes4, 'Title')
            xlabel(app.UIAxes4, 'X')
            ylabel(app.UIAxes4, 'Y')
            zlabel(app.UIAxes4, 'Z')
            app.UIAxes4.Position = [1 5 694 560];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SubInterface

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