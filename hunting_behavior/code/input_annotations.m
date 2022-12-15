function ann = input_annotations(data_path,N,v)
%INPUT_ANNOTATIONS User annotation of training frames
%   annotations = input_annotations(data_path,N) constructs a GUI for a
%   user to annotate a set of N randomly selected training frames for the
%   movies in the data_path. Each annotation comprises the movie name,
%   frame number and the pixel coordinates of the desired tracking points

% Get total number of frames in the assay
K = zeros(1,length(v));
for j = 1:length(v)
    K(j) = v.NumFrames;
end
K = [0, cumsum(K)];

% Create UI
hfig = figure('Visible','off', ...
    'units','normalized','outerposition',[0,0,1,1]);
hfig.WindowState = 'maximized';
axes('Parent',hfig,'Units','normalized','Position',[0.01, 0.01, 0.98, 0.98]);
axis off
zx = gca;
ax.Toolbar.Visible = 'off';

% Initialise shared variables
f = zeros(0,'uint8');
n = 1;
coords = [];
ann = table('Size',[N,7], ...
    'VariableTypes', {'char','double','double','double','double','double', ...
    'double'}, ...
    'VariableNames', {'file_name','movie_number','frame','swim_bladder_x', ...
    'swim_bladder_y','eye_midpoint_x','eye_midpoint_y'});
draw_lock = false;
k = 1;

% On screen insctructions
inst = ['Key commands:', newline, newline, ...
    'g        Get random frame', newline, ...
    'z        Enable zoom tool', newline, ...
    'x        Annotate tool [draw a line from the', newline, ...
    '          centre of the swim bladder to the', newline, ...
    '          midpoint between the eyes]', newline, ...
    'c        Confirm annotations as displayed'];
    
annotation('textbox', [0.75, 0.5, 0.2, 0.25], 'string', inst,'fontsize',14)

% Set up keypress callbacks
set(hfig, 'KeyPressFcn', @keyPressCallback);
hfig.Visible = 'on';
figure(hfig)

% Import java engine
import java.awt.*;
import java.awt.event.*;
rob = Robot;

while n<=N
uiwait()
end


    function keyPressCallback(~,eventdata)
        if ~draw_lock
            switch eventdata.Key
                case 'g'
                    zoom off
                    k = randi(K(end));
                    while any(k==ann.frame(1:n)) % frames cannot be reused
                        k = randi(K(end));
                    end
                    j = find(k>K,1,'last');
                    idx = find((k-K)>0,1,'last');
                    k = k-K(idx);
                    f = v(j).read(k);
                    % Show the fish
                    imagesc(f,[0 255])
                    axis image
                    axis off
                    colormap(gray)
                    drawnow
                case 'z'
                    imagesc(f,[0 255])
                    axis image
                    axis off
                    colormap(gray)
                    drawnow
                    zoom on
                    % Enable keypress during zoom
                    hManager = uigetmodemanager(hfig);
                    try
                        set(hManager.WindowListenerHandles, 'Enable', 'off');
                    catch
                        [hManager.WindowListenerHandles.Enabled] = deal(false);
                    end
                    set(hfig, 'WindowKeyPressFcn', []);
                    set(hfig, 'KeyPressFcn', @(source,eventdata) keyPressCallback(source,eventdata));
                case 'x'
                    draw_lock = true;
                    zoom off
                    ax = gca;
                    xlim = ax.XLim;
                    ylim = ax.YLim;
                    imagesc(f,[0 255])
                    axis image
                    axis off
                    set(gca,'XLim',xlim,'YLim',ylim)
                    drawnow
                    pts = drawline(gca);
                    coords = pts.Position;
                    % Show and confirm
                    ax = gca;
                    xlim = ax.XLim;
                    ylim = ax.YLim;
                    labels = {'Swim bladder','Eye midpoint'};
                    frame = insertText(mat2gray(f), ...
                        coords, labels, ...
                        'FontSize',6, ...
                        'BoxOpacity',0.25);
                    image(frame)
                    hold on
                    scatter(coords(:,1),coords(:,2),1000,'+','g','MarkerEdgeAlpha',0.5);
                    axis image
                    axis off
                    set(gca,'XLim',xlim,'YLim',ylim)
                    hold off
                    drawnow
                    draw_lock = false;
                case 'c'
                    if ~isempty(coords)
                        ann.file_name(n) = {v(j).filename};
                        ann.movie_number(n) = j;
                        ann.frame(n) = k;
                        ann.swim_bladder_x(n) = coords(1,1);
                        ann.swim_bladder_y(n) = coords(1,2);
                        ann.eye_midpoint_x(n) = coords(2,1);
                        ann.eye_midpoint_y(n) = coords(2,2);
                        coords = [];
                        n = n+1;
                        if n<=N
                            rob.keyPress(java.awt.event.KeyEvent.VK_G)
                            rob.keyRelease(java.awt.event.KeyEvent.VK_G)
                        else
                            uiresume()
                            close all
                        end
                    end
            end
        end
    end

end

