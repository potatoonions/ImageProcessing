function plasticGUI
%PLASTICGUI  simple interface for testing plastic glove defect detectors
%
%   Launches a window where the user can load an image and apply the burn,
%   frosting or discolouration detectors defined in the Angel folder.  The
%   resulting overlay is displayed on top of the original image.

% create figure and axes
hFig = figure('Name','Plastic Defect Tester','NumberTitle','off', ...
    'MenuBar','none','Toolbar','none','Position',[100 100 800 600]);

hAx = axes('Parent',hFig,'Units','normalized', ...
    'Position',[0.05 0.2 0.9 0.75]);
imshow(zeros(10,10,3,'uint8'),'Parent',hAx); %# initialize

% control buttons
uicontrol('Style','pushbutton','String','Load Image', ...
    'Units','normalized','Position',[0.05 0.05 0.15 0.1], ...
    'Callback',@onLoad);

uicontrol('Style','pushbutton','String','Burn', ...
    'Units','normalized','Position',[0.25 0.05 0.1 0.1], ...
    'Callback',@onBurn);

uicontrol('Style','pushbutton','String','Frosting', ...
    'Units','normalized','Position',[0.37 0.05 0.1 0.1], ...
    'Callback',@onFrosting);

uicontrol('Style','pushbutton','String','Discolour', ...
    'Units','normalized','Position',[0.49 0.05 0.1 0.1], ...
    'Callback',@onDiscolour);

% store shared data
data.img = [];
data.overlay = [];
guidata(hFig,data);

%% callback implementations
    function onLoad(~,~)
        [file,path] = uigetfile({'*.png;*.jpg;*.jpeg','Images'});
        if isequal(file,0), return; end
        I = imread(fullfile(path,file));
        data.img = I;
        data.overlay = [];
        guidata(hFig,data);
        imshow(I,'Parent',hAx);
    end

    function applyDetector(detFunc)
        if isempty(data.img)
            errordlg('Load an image first','Error');
            return;
        end
        ov = detFunc(data.img);
        data.overlay = ov;
        guidata(hFig,data);
        % display image and overlay
        imshow(data.img,'Parent',hAx);
        hold(hAx,'on');
        him = imshow(ov,'Parent',hAx);
        set(him,'AlphaData',double(ov(:,:,4))/255);
        hold(hAx,'off');
    end

    function onBurn(~,~)
        applyDetector(@plasticDefectDetection);
    end

    function onFrosting(~,~)
        applyDetector(@plasticFrostingDetection);
    end

    function onDiscolour(~,~)
        applyDetector(@plasticDiscolourationDetection);
    end
end