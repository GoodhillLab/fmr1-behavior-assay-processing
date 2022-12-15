function image_scale = input_image_scale(data_path,v)
%INPUT_ARENA_MASK User measurement of image scale
%   image_scale = nput_image_scale(data_path) outputs the image scale of a
%   sequence file found in folder given by string data_path based on user
%   selection from GUI. Output is in pixels/mm

%  Create and then hide the UI as it is being constructed.
hfig = figure('Visible','off', ...
    'units','normalized','outerposition',[0,0,1,1]);
hfig.WindowState = 'maximized';
f = v.read(1);
imagesc(f,[0 255])
ax = gca;
ax.Position = [0.01, 0.01, 0.98, 0.98];
axis image
axis off
colormap(gray)

% On screen insctructions
inst = ['Click and drag to draw line to measure dish size. ',...
    'Adjust as neccessary then confirm.'];

annotation('textbox', [0.75, 0.65, 0.2, 0.075], 'string', inst,'fontsize',14)
pts = drawline(gca);
uicontrol('Parent',hfig,'Style','pushbutton',...
    'String','Confirm measurement', ...
    'Units','normalized', ...
    'Position',[0.8,0.5,0.1,0.05], ...
    'Callback',{@confirm_mask_Callback}, ...
    'Enable','on');
axis off
hfig.Visible = 'on';
uiwait()
close all

% Callbacks
    function confirm_mask_Callback(~,~)
        coords = pts.Position;
        image_scale = norm(diff(coords))/20;
        uiresume()
    end

end

