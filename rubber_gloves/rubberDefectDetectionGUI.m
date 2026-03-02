function rubberDefectDetectionGUI()
% RUBBER DEFECT DETECTION - Rubber Glove Analysis GUI
% Upload → Defect Detection (Missing Digit, Thin Material, Tear) → Results

persistent appData;
if isempty(appData), appData = struct(); end

% Ensure rubber_gloves folder is on path
rubberPath = fileparts(mfilename('fullpath'));
if ~isempty(rubberPath) && ~contains(path, rubberPath)
    addpath(rubberPath);
end

fig = figure('Name', 'Rubber Glove Defect Detection', 'NumberTitle', 'off', ...
    'Position', [100 100 1000 800], 'Color', [0.94 0.94 0.94], ...
    'CloseRequestFcn', @(src, evt) closeApp());

mainPanel = uipanel(fig, 'Position', [0.05 0.05 0.90 0.90], ...
    'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

appData.welcomeLabel = uicontrol(mainPanel, 'Style', 'text', ...
    'String', 'Welcome to Rubber Glove Defect Detection', ...
    'Units', 'normalized', 'Position', [0.1 0.90 0.8 0.07], ...
    'FontSize', 24, 'FontWeight', 'bold', 'ForegroundColor', [0.2 0.4 0.6], ...
    'BackgroundColor', [0.94 0.94 0.94]);

appData.displayPanel = uipanel(mainPanel, 'Position', [0.05 0.35 0.90 0.50], ...
    'BorderType', 'line', 'BackgroundColor', [0.15 0.15 0.15], ...
    'Visible', 'on');

appData.displayAx = axes(appData.displayPanel, 'Position', [0.05 0.05 0.90 0.90], ...
    'Color', [0.15 0.15 0.15]);
axis(appData.displayAx, 'off');

appData.resultsPanel = uipanel(mainPanel, 'Position', [0.05 0.35 0.90 0.50], ...
    'BorderType', 'line', 'BackgroundColor', [0.96 0.96 0.96], ...
    'Visible', 'off');

appData.resultAx = axes('Parent', appData.resultsPanel, 'Position', [0.05 0.15 0.90 0.80]);
axis(appData.resultAx, 'image', 'off');

uicontrol(appData.resultsPanel, 'Style', 'text', 'String', 'Material: Rubber Gloves', ...
    'Units', 'normalized', 'Position', [0.05 0.05 0.4 0.06], ...
    'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', [0.96 0.96 0.96]);

appData.resultClassification = uicontrol(appData.resultsPanel, 'Style', 'text', 'String', '', ...
    'Units', 'normalized', 'Position', [0.50 0.05 0.45 0.06], ...
    'FontSize', 11, 'FontWeight', 'bold', 'ForegroundColor', [0.2 0.4 0.6], ...
    'BackgroundColor', [0.96 0.96 0.96]);

buttonPanel = uipanel(mainPanel, 'Position', [0.05 0.02 0.90 0.12], ...
    'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Upload Image', ...
    'Units', 'normalized', 'Position', [0.15 0.30 0.15 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.5569, 0.8118, 0.9412], 'ForegroundColor', [0 0 0], ...
    'Callback', @(src, evt) uploadImage(fig));

appData.missingBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Detect Missing Digit', ...
    'Units', 'normalized', 'Position', [0.33 0.30 0.16 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.86, 0.68, 0.59], 'ForegroundColor', [0 0 0], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) detectDefect(fig, 'missing'));

appData.thinBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Detect Thin Material', ...
    'Units', 'normalized', 'Position', [0.51 0.30 0.16 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.78, 0.87, 0.65], 'ForegroundColor', [0 0 0], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) detectDefect(fig, 'thin'));

appData.tearBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Detect Tear', ...
    'Units', 'normalized', 'Position', [0.69 0.30 0.12 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.89, 0.68, 0.71], 'ForegroundColor', [0 0 0], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) detectDefect(fig, 'tear'));

uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Reset', ...
    'Units', 'normalized', 'Position', [0.87 0.30 0.10 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.5647 0.9333 0.5647], 'ForegroundColor', [0 0 0], ...
    'Callback', @(src, evt) resetGUI(fig));

appData.fig = fig;
appData.currentImage = [];
appData.grayImage = [];

guidata(fig, appData);
end

function uploadImage(fig)
appData = guidata(fig);

[filename, pathname] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff;*.webp', ...
    'Image Files'}, 'Select Rubber Glove Image');

if filename == 0, return; end

try
    img = imread(fullfile(pathname, filename));
    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    end
    img = imresize(img, [400 400]);
    
    appData.currentImage = img;
    appData.grayImage = rgb2gray(img);
    
    imshow(img, 'Parent', appData.displayAx);
    
    set(appData.welcomeLabel, 'String', sprintf('Image: %s', filename), ...
        'ForegroundColor', [0.2 0.4 0.6]);
    set(appData.displayPanel, 'Visible', 'on');
    set(appData.resultsPanel, 'Visible', 'off');
    set(appData.missingBtn, 'Visible', 'on');
    set(appData.thinBtn, 'Visible', 'on');
    set(appData.tearBtn, 'Visible', 'on');
    
    guidata(fig, appData);
    
catch ME
    msgbox(['Error: ' ME.message], 'Error', 'error');
end
end

function detectDefect(fig, defectType)
appData = guidata(fig);

if isempty(appData.currentImage)
    return;
end

try
    img = appData.currentImage;
    overlay = [];
    
    switch defectType
        case 'missing'
            overlay = rubberMissingDigitsDetection(img);
            defectLabel = 'MISSING DIGIT';
            defectColor = [0.8 0 0];
        case 'thin'
            overlay = rubberThinMaterialDetection(img);
            defectLabel = 'THIN MATERIAL';
            defectColor = [0 0.5 0];
        case 'tear'
            overlay = rubberTearDetection(img);
            defectLabel = 'TEAR';
            defectColor = [0 0 0.8];
        otherwise
            error('Unknown defect type');
    end
    
    imshow(img, 'Parent', appData.resultAx);
    hold(appData.resultAx,'on');
    
    if ~isempty(overlay) && any(overlay(:) > 0)
        if ndims(overlay) == 3 && size(overlay,3) == 4
            overlayRGB = overlay(:,:,1:3);
            alphaData = double(overlay(:,:,4))/255;
        else
            overlayRGB = overlay(:,:,1:min(end,3));
            alphaData = ones(size(overlayRGB,1), size(overlayRGB,2));
        end
        him = imshow(overlayRGB,'Parent',appData.resultAx);
        try
            set(him,'AlphaData',alphaData);
        catch
        end
        classification = sprintf('DEFECT DETECTED: %s', defectLabel);
    else
        classification = sprintf('NO %s DETECTED', defectLabel);
    end
    
    hold(appData.resultAx,'off');
    
    set(appData.displayPanel,'Visible','off');
    set(appData.resultsPanel,'Visible','on');
    set(appData.resultClassification,'String',classification,'ForegroundColor',defectColor);
    
    guidata(fig, appData);
    
catch ME
    msgbox(['Error: ' ME.message], 'Error', 'error');
    fprintf('Debug - Error message: %s\n', ME.message);
    fprintf('Debug - Error identifier: %s\n', ME.identifier);
end
end

function resetGUI(fig)
appData = guidata(fig);

cla(appData.displayAx);
cla(appData.resultAx);

set(appData.welcomeLabel, 'String', 'Welcome to Rubber Glove Defect Detection', ...
    'ForegroundColor', [0.2 0.4 0.6]);
set(appData.displayPanel,'Visible','on');
set(appData.resultsPanel,'Visible','off');
set(appData.missingBtn,'Visible','off');
set(appData.thinBtn,'Visible','off');
set(appData.tearBtn,'Visible','off');

appData.currentImage = [];
appData.grayImage = [];

guidata(fig, appData);
end

function closeApp()
delete(gcbf);
end