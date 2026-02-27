function PlasticDefectDetectionGUI()
% PLASTIC DEFECT DETECTION - Polyethene Glove Analysis GUI
% Upload → Defect Detection (Burn, Frosting, Discoloration) → Results

persistent appData;
if isempty(appData), appData = struct(); end

% Ensure Angel folder is on path
angelPath = fileparts(mfilename('fullpath'));
if ~isempty(angelPath) && ~contains(path, angelPath)
    addpath(angelPath);
end

fig = figure('Name', 'Plastic Glove Defect Detection', 'NumberTitle', 'off', ...
    'Position', [100 100 1000 800], 'Color', [0.94 0.94 0.94], ...
    'CloseRequestFcn', @(src, evt) closeApp());

mainPanel = uipanel(fig, 'Position', [0.05 0.05 0.90 0.90], ...
    'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

appData.welcomeLabel = uicontrol(mainPanel, 'Style', 'text', ...
    'String', 'Welcome to Plastic Glove Defect Detection', ...
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

uicontrol(appData.resultsPanel, 'Style', 'text', 'String', 'Material: Polyethene Plastic Gloves', ...
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
    'BackgroundColor', [0.3 0.6 0.85], 'ForegroundColor', [1 1 1], ...
    'Callback', @(src, evt) uploadImage(fig));

appData.burnBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Detect Burn', ...
    'Units', 'normalized', 'Position', [0.33 0.30 0.12 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.8 0.2 0.2], 'ForegroundColor', [1 1 1], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) detectDefect(fig, 'burn'));

appData.bloodBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Detect Blood', ...
    'Units', 'normalized', 'Position', [0.48 0.30 0.12 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.7 0.2 0.2], 'ForegroundColor', [1 1 1], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) detectDefect(fig, 'blood'));

appData.discolBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Detect Discoloration', ...
    'Units', 'normalized', 'Position', [0.63 0.30 0.15 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.8 0.5 0.2], 'ForegroundColor', [1 1 1], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) detectDefect(fig, 'discoloration'));

uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Reset', ...
    'Units', 'normalized', 'Position', [0.81 0.30 0.12 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.8 0.3 0.3], 'ForegroundColor', [1 1 1], ...
    'Callback', @(src, evt) resetGUI(fig));

appData.fig = fig;
appData.currentImage = [];
appData.grayImage = [];

guidata(fig, appData);
end

function uploadImage(fig)
appData = guidata(fig);

[filename, pathname] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff;*.webp', ...
    'Image Files'}, 'Select Polyethene Glove Image');

if filename == 0, return; end

try
    img = imread(fullfile(pathname, filename));
    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    end
    img = imresize(img, [400 400]);
    
    appData.currentImage = img;
    appData.grayImage = rgb2gray(img);
    
    % Show uploaded image
    imshow(img, 'Parent', appData.displayAx);
    
    % Update UI
    set(appData.welcomeLabel, 'String', sprintf('Image: %s', filename), ...
        'ForegroundColor', [0.2 0.4 0.6]);
    set(appData.displayPanel, 'Visible', 'on');
    set(appData.resultsPanel, 'Visible', 'off');
    set(appData.burnBtn, 'Visible', 'on');
    set(appData.bloodBtn, 'Visible', 'on');
    set(appData.discolBtn, 'Visible', 'on');
    
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
    
    % Call appropriate detector function
    switch defectType
        case 'burn'
            overlay = plasticDefectDetection(img);
            defectLabel = 'BURN';
            defectColor = [1 0 0]; % Red
        case 'blood'
            overlay = plasticBloodDetection(img);
            defectLabel = 'BLOOD';
            defectColor = [0.8 0 0]; % Dark Red
        case 'discoloration'
            overlay = plasticDiscolourationDetection(img);
            defectLabel = 'DISCOLORATION';
            defectColor = [1 1 0]; % Yellow
        otherwise
            error('Unknown defect type');
    end
    
    % Display result
    imshow(img, 'Parent', appData.resultAx);
    hold(appData.resultAx, 'on');
    
    % If overlay exists and contains data, display it
    if ~isempty(overlay) && any(overlay(:) > 0)
        if ndims(overlay) == 3 && size(overlay, 3) == 4
            overlayRGB = overlay(:, :, 1:3);
            alphaData = double(overlay(:, :, 4)) / 255;
        elseif ndims(overlay) == 2
            overlayRGB = cat(3, overlay, overlay, overlay);
            alphaData = ones(size(overlay));
        else
            overlayRGB = overlay(:, :, 1:min(end, 3));
            alphaData = ones(size(overlayRGB, 1), size(overlayRGB, 2));
        end
        
        him = imshow(overlayRGB, 'Parent', appData.resultAx);
        try
            set(him, 'AlphaData', alphaData);
        catch
            % AlphaData may not be supported in all MATLAB versions
        end
        classification = sprintf('DEFECT DETECTED: %s', defectLabel);
    else
        classification = sprintf('NO %s DETECTED', defectLabel);
    end
    
    hold(appData.resultAx, 'off');
    
    % Update classification
    set(appData.displayPanel, 'Visible', 'off');
    set(appData.resultsPanel, 'Visible', 'on');
    set(appData.resultClassification, 'String', classification, 'ForegroundColor', defectColor);
    
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

set(appData.welcomeLabel, 'String', 'Welcome to Plastic Glove Defect Detection', ...
    'ForegroundColor', [0.2 0.4 0.6]);
set(appData.displayPanel, 'Visible', 'on');
set(appData.resultsPanel, 'Visible', 'off');
set(appData.burnBtn, 'Visible', 'off');
set(appData.bloodBtn, 'Visible', 'off');
set(appData.discolBtn, 'Visible', 'off');

appData.currentImage = [];
appData.grayImage = [];

guidata(fig, appData);
end

function closeApp()
delete(gcbf);
end
