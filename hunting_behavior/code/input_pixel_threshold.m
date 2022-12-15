function thr = input_pixel_threshold(data_path,v)
%INPUT_PIXEL_THRESHOLD User selection of pixel intensity threshold
%   thr = input_arena_mask(data_path) outputs pixel intensity threshold thr
%   to capture both pish and all paramecia based on user selection from GUI

% Get total number of frames in the assay
K = zeros(1,length(v));
for j = 1:length(v)
    K(j) = v.NumFrames;
end
K = [0, cumsum(K)];

% Initialise frame index
k = 1;

%  Create and then hide the UI as it is being constructed.
hfig = figure('Visible','off', ...
    'units','normalized','outerposition',[0,0,1,1]);
hfig.WindowState = 'maximized';

% Create frame navigation slider
frameNavigator = javax.swing.JSlider;
frameNavigator.setPaintTicks(1)
frameNavigator.setSnapToTicks(1)
frameNavigator.setMajorTickSpacing(10000)
frameNavigator.setMinorTickSpacing(50)
frameNavigator.setOrientation(frameNavigator.HORIZONTAL);
frameNavigator.setMinimum(1)
frameNavigator.setMaximum(K(end))
javacomponent(frameNavigator,'South');
hNavigator = handle(frameNavigator, 'CallbackProperties');
hNavigator.StateChangedCallback = @navigate_Callback;

% Create threshold slider
thrSlider = javax.swing.JSlider;
thrSlider.setPaintTicks(1)
thrSlider.setSnapToTicks(1)
thrSlider.setMajorTickSpacing(10)
thrSlider.setMinorTickSpacing(1)
thrSlider.setOrientation(frameNavigator.VERTICAL);
thrSlider.setMinimum(0)
thrSlider.setMaximum(255)
[~,thrContainter] = javacomponent(thrSlider);
set(thrContainter,'units','norm', 'position',[0.8,0.2,0.1,0.6])
hSlider = handle(thrSlider, 'CallbackProperties');
hSlider.StateChangedCallback = @thr_Callback;

uicontrol('Parent',hfig,'Style','pushbutton',...
    'String','Confirm threshold', ...
    'Units','normalized', ...
    'Position',[0.8,0.1,0.1,0.05], ...
    'Callback',{@confirm_thr_Callback}, ...
    'Enable','on');

uicontrol('Parent',hfig,'Style','text',...
    'String','Set threshold', ...
    'Units','normalized', ...
    'Position',[0.8,0.8,0.1,0.05], ...
    'Enable','on');

j = 1;
f = v(j).read(k);
thr = thrSlider.getValue;
mask = f>thr;
mask = bwareaopen(mask,16);
g = imfuse(f,mask);
im_handle = imagesc(g,[0 255]);
ax = gca;
ax.Position = [0.01, 0.01, 0.98, 0.98];
axis image
axis off

axis off
hfig.Visible = 'on';
uiwait()
close all

    function navigate_Callback(source,~)
        if isMultipleCall();  return;  end
        k = round(source.Value);
        j = find(k>K,1,'last');
        idx = find((k-K)>0,1,'last');
        k = k-K(idx);
        f = v(j).read(k);
        mask = f>thr;
        mask = bwareaopen(mask,16);
        g = imfuse(f,mask);
        set(im_handle,'CData',g);
        drawnow()
    end

    function thr_Callback(source,~)
        if isMultipleCall();  return;  end
        thr = source.getValue;
        source.Value = thr;
        mask = f>thr;
        mask = bwareaopen(mask,16);
        g = imfuse(f,mask);
        set(im_handle,'CData',g);
        drawnow()
    end

    function confirm_thr_Callback(~,~)
        if isMultipleCall();  return;  end
        uiresume()
    end

end

