function fish_length = measure_fish_length(data_path,tail_coords,params)
%MEASURE_FISH_LENGTH GUI for measuring fish length after post processing
%   Creates a GUI showing the feeding assay movie and the estimated tail
%   length. The user can then scroll through the movie and find an
%   appropriate frame in which to measure the total fish length using the
%   estimated tail length as a guide.

% First need to load postprocess_out.mat

% This works but... CODE NEEDS A CLEAN-UP

% Find files
files = dir(data_path);
files = files(~ismember({files.name},{'.','..'}));
files = files(contains({files.name},{'.seq'}));

% Get total number of frames in the assay
K = zeros(1,length(files));
for j = 1:length(files)
    file_name = fullfile(files(j).folder, files(j).name);
    header_info = seq_header(file_name);
    K(j) = header_info.numFrames;
end
K = [0, cumsum(K)];

% Initialise frame index
k = 1;

%  Create and then hide the UI as it is being constructed.
hfig = figure('Visible','off', ...
    'units','normalized','outerposition',[0,0,1,1]);
hfig.WindowState = 'maximized';

% Initialise GUI
j = 1;
file_name = fullfile(files(j).folder, files(j).name);
f = seq_read(file_name,k);
y_upper = 250;
y_lower = 100;
ruler = 150;

% Create frame navigation slider
frameNavigator = javax.swing.JSlider;
frameNavigator.setPaintTicks(1)
frameNavigator.setSnapToTicks(1)
frameNavigator.setMajorTickSpacing(100)
frameNavigator.setMinorTickSpacing(1)
frameNavigator.setOrientation(frameNavigator.HORIZONTAL);
frameNavigator.setMinimum(1)
frameNavigator.setMaximum(K(end))
%javacomponent(frameNavigator,'South');
[~,navContainter] = javacomponent(frameNavigator);
set(navContainter,'units','norm', 'position',[0.05,0.05,0.9,0.02])
hNavigator = handle(frameNavigator, 'CallbackProperties');
hNavigator.StateChangedCallback = @navigate_Callback;

% Create tail length guide/ruler slider
lenSlider = javax.swing.JSlider;
lenSlider.setPaintTicks(1)
lenSlider.setSnapToTicks(1)
lenSlider.setMajorTickSpacing(1)
lenSlider.setMinorTickSpacing(0.1)
lenSlider.setOrientation(frameNavigator.VERTICAL);
lenSlider.setMinimum(y_lower)
lenSlider.setMaximum(y_upper)
[~,thrContainter] = javacomponent(lenSlider);
set(thrContainter,'units','norm', 'position',[.96,0.1,0.02,0.25])
hSlider = handle(lenSlider, 'CallbackProperties');
hSlider.StateChangedCallback = @ruler_Callback;

% Create pixel intensity upper bound slider
pxSlider = javax.swing.JSlider;
pxSlider.setPaintTicks(1)
pxSlider.setSnapToTicks(1)
pxSlider.setMajorTickSpacing(10)
pxSlider.setMinorTickSpacing(1)
pxSlider.setOrientation(frameNavigator.VERTICAL);
pxSlider.setMinimum(0)
pxSlider.setMaximum(255)
pxSlider.setValue(255)
[~,thrContainter] = javacomponent(pxSlider);
set(thrContainter,'units','norm', 'position',[0.05,0.4,0.02,0.6])
hSlider = handle(pxSlider, 'CallbackProperties');
hSlider.StateChangedCallback = @px_Callback;

% Create measurement button
uicontrol('Parent',hfig,'Style','pushbutton',...
    'String','Measure tail', ...
    'Units','normalized', ...
    'Position',[0.8,0.5,0.1,0.05], ...
    'Callback',{@measure_Callback}, ...
    'Enable','on');

% Create measurement confirmation button
uicontrol('Parent',hfig,'Style','pushbutton',...
    'String','Confirm length', ...
    'Units','normalized', ...
    'Position',[0.8,0.4,0.1,0.05], ...
    'Callback',{@confirm_Callback}, ...
    'Enable','on');

% Create y_upper text field
h_y_upper = uicontrol('Parent',hfig,'Style','edit',...
    'String',num2str(y_upper), ...
    'Units','normalized', ...
    'Position',[0.01,0.33,0.02,0.02], ...
    'Callback',{@y_upper_Callback}, ...
    'Enable','on');

% Create y_lower text field
h_y_lower = uicontrol('Parent',hfig,'Style','edit',...
    'String',num2str(y_lower), ...
    'Units','normalized', ...
    'Position',[0.01,0.1,0.02,0.02], ...
    'Callback',{@y_lower_Callback}, ...
    'Enable','on');



% Subplot for assay
pos = [0.1,0.4,0.4,0.6];
subplot_assay = subplot('Position',pos);
im_handle = imagesc(f,[0 255]);
im_ax = gca;
colormap(gray)
axis image
axis off

% Subplot for tail length estimate
pos = [0.05,0.1,0.9,0.25];
subplot_tail = subplot('Position',pos);
tail_len = zeros(K(end),1);
for j = 1:length(files)
   tail_len((K(j)+1):(K(j)+size(tail_coords{j},1))) = sum(vecnorm(diff(tail_coords{j},1,3),2,2),3);
end
tail_len_smooth = medfilt1(tail_len,500);
plot_tail = plot(1:K(end),tail_len,'k','LineWidth',0.05);
plot_tail.Color(4) = 0.05;
hold on
plot_tail_smooth = plot(1:K(end),tail_len_smooth,'b');
plot(k*ones(500,1),1:500,'r')
plot(1:K(end),ruler*ones(K(end),1),'g')
hold off
ax_len = gca;
ax_len.XLim = [1,K(end)];
ax_len.YLim = [y_lower,y_upper];
ax_len.YLabel.String = 'tail length';

hfig.Visible = 'on';
uiwait()
close all

% Navigator
    function navigate_Callback(source,~)
        if isMultipleCall();  return;  end
        k = round(source.Value);
        subplot(subplot_tail)
        plot_tail = plot(1:K(end),tail_len,'k','LineWidth',0.05);
        plot_tail.Color(4) = 0.05;
        hold on
        plot_tail_smooth = plot(1:K(end),tail_len_smooth,'b');
        plot(k*ones(500,1),1:500,'r')
        plot(1:K(end),ruler*ones(K(end),1),'g')
        hold off
        ax_len = gca;
        ax_len.XLim = [1,K(end)];
        ax_len.YLim = [y_lower,y_upper];
        ax_len.YLabel.String = 'tail length';
        j = find(k>K,1,'last');
        file_name = fullfile(files(j).folder, files(j).name);
        idx = find((k-K)>0,1,'last');
        km = k-K(idx);
        f = seq_read(file_name,km);
        set(im_handle,'CData',f);
        drawnow()
    end

% Pixel intensity cutoff
    function px_Callback(s1,~)
        if isMultipleCall();  return;  end
        px = s1.getValue;
        s1.Value = px;
        caxis(im_ax,[0,px]);
        drawnow()
    end

% Pixel intensity cutoff
    function ruler_Callback(s2,~)
        if isMultipleCall();  return;  end
        ruler = s2.getValue;
        subplot(subplot_tail)
        plot_tail = plot(1:K(end),tail_len,'k','LineWidth',0.05);
        plot_tail.Color(4) = 0.05;
        hold on
        plot_tail_smooth = plot(1:K(end),tail_len_smooth,'b');
        plot(k*ones(500,1),1:500,'r')
        plot(1:K(end),ruler*ones(K(end),1),'g')
        hold off
        ax_len = gca;
        ax_len.XLim = [1,K(end)];
        ax_len.YLim = [y_lower,y_upper];
        ax_len.YLabel.String = 'tail length';
        drawnow()
    end

% Tail length y-axis upper
    function y_upper_Callback(~,~)
        if isMultipleCall();  return;  end
        if isempty(str2num(h_y_upper.String))
            h_y_upper.String = num2str(y_upper);
        end
        y_upper = round(str2num(h_y_upper.String));
        ax_len.YLim = [y_lower, y_upper];
        lenSlider.setMaximum(y_upper)
        drawnow()
    end
% Tail length y-axis lower
    function y_lower_Callback(~,~)
        if isMultipleCall();  return;  end
        if isempty(str2num(h_y_lower.String))
            h_y_lower.String = num2str(y_lower);
        end
        y_lower = round(str2num(h_y_lower.String));
        ax_len.YLim = [y_lower, y_upper];
        lenSlider.setMinimum(y_lower)
        drawnow()
    end

% Measure fish
    function measure_Callback(~,~)
        if isMultipleCall();  return;  end
        subplot(subplot_assay);
        pts = drawline(gca,'Color','r','Linewidth',1);
        coords = pts.Position;
        fish_length = norm(diff(coords))/params.image_scale;
        uiwait()
    end

% Confirm measurement and exit
    function confirm_Callback(~,~)
        if isMultipleCall();  return;  end
        uiresume()
    end
end

