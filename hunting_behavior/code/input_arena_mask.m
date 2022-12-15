function mask = input_arena_mask(data_path,v)
%INPUT_ARENA_MASK User selection of an elliptical mask for arena
%   mask = input_arena_mask(data_path) outputs logical mask for the first
%   sequence file found in folder given by string data_path based on user
%   selection from GUI

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
ellipse = drawellipse(ax, ...
    'Center', size(f)/2, ...
    'SemiAxes',[256,256],...
    'LineWidth',0.1, ...
    'DrawingArea','unlimited');
mask = true(size(f));

% On screen insctructions
inst = ['Adjust dish mask with mouse or key commands then confirm', newline, newline, ...
    'Key commands:', newline, newline, ...
    'w              move up', newline, ...
    'a              move left', newline, ...
    's              move down', newline, ...
    'd              move right', newline, ...
    'up arrow       enlarge y', newline, ...
    'down arrow     shrink y', newline, ...
    'right arrow    enlarge x', newline, ...
    'left arrow     shrink x'];
    
annotation('textbox', [0.75, 0.5, 0.2, 0.35], 'string', inst,'fontsize',14)

% Set up keypress callbacks
set(hfig, 'KeyPressFcn', @keyPressCallback);
hfig.Visible = 'on';
figure(hfig)

uicontrol('Parent',hfig,'Style','pushbutton',...
    'String','Confirm mask', ...
    'Units','normalized', ...
    'Position',[0.8,0.25,0.1,0.05], ...
    'Callback',{@confirm_mask_Callback}, ...
    'Enable','on');
axis off
hfig.Visible = 'on';
uiwait()
close all

% Callbacks
    function confirm_mask_Callback(~,~)
        mask = createMask(ellipse);
        uiresume()
    end

 function keyPressCallback(~,eventdata)
            switch eventdata.Key
                case 'd'
                   ellipse.Center(1) = ellipse.Center(1)+1;
                case 'w'
                    ellipse.Center(2) = ellipse.Center(2)-1;
                case 'a'
                    ellipse.Center(1) = ellipse.Center(1)-1;
                case 's'
                    ellipse.Center(2) = ellipse.Center(2)+1;
                case 'rightarrow'
                   ellipse.SemiAxes(1) = ellipse.SemiAxes(1)+1;
                case 'uparrow'
                    ellipse.SemiAxes(2) = ellipse.SemiAxes(2)+1;
                case 'leftarrow'
                    ellipse.SemiAxes(1) = ellipse.SemiAxes(1)-1;
                case 'downarrow'
                    ellipse.SemiAxes(2) = ellipse.SemiAxes(2)-1;
            end
 end


end

