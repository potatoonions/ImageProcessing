function GloveDefectDetectionGUI()
% GLOVE DEFECT DETECTION - Simple Upload & Classify

persistent appData;
if isempty(appData), appData = struct(); end

% Create Figure
fig = figure('Name', 'Glove Defect Detection', 'NumberTitle', 'off', ...
    'Position', [100 100 900 700], 'Color', [0.94 0.94 0.94], ...
    'CloseRequestFcn', @(src, evt) closeApp());

% Main Panel
mainPanel = uipanel(fig, 'Position', [0.05 0.05 0.90 0.90], ...
    'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

% Welcome Text
welcomeLabel = uicontrol(mainPanel, 'Style', 'text', ...
    'String', 'Welcome to Glove Defect Detection', ...
    'Units', 'normalized', 'Position', [0.1 0.75 0.8 0.12], ...
    'FontSize', 28, 'FontWeight', 'bold', 'ForegroundColor', [0.2 0.4 0.6], ...
    'BackgroundColor', [0.94 0.94 0.94]);

appData.welcomeLabel = welcomeLabel;

% Image Display Panel
appData.imagePanel = uipanel(mainPanel, 'Position', [0.1 0.35 0.8 0.40], ...
    'BorderType', 'line', 'BackgroundColor', [0.15 0.15 0.15], ...
    'Visible', 'off');

appData.imageAx = axes(appData.imagePanel, 'Position', [0.05 0.05 0.9 0.9], ...
    'Color', [0.15 0.15 0.15]);
axis(appData.imageAx, 'off');

% Results Panel
appData.resultsPanel = uipanel(mainPanel, 'Position', [0.1 0.35 0.8 0.40], ...
    'BorderType', 'line', 'BackgroundColor', [0.96 0.96 0.96], ...
    'Visible', 'off');

uicontrol(appData.resultsPanel, 'Style', 'text', 'String', 'Material Type:', ...
    'Units', 'normalized', 'Position', [0.05 0.85 0.4 0.1], ...
    'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.96 0.96 0.96]);

appData.materialResult = uicontrol(appData.resultsPanel, 'Style', 'text', 'String', 'Cloth Gloves', ...
    'Units', 'normalized', 'Position', [0.50 0.85 0.45 0.1], ...
    'FontSize', 14, 'FontWeight', 'bold', 'ForegroundColor', [0.2 0.4 0.6], ...
    'BackgroundColor', [0.96 0.96 0.96]);

uicontrol(appData.resultsPanel, 'Style', 'text', 'String', 'Classification:', ...
    'Units', 'normalized', 'Position', [0.05 0.70 0.4 0.1], ...
    'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.96 0.96 0.96]);

appData.classificationResult = uicontrol(appData.resultsPanel, 'Style', 'text', 'String', 'Processing...', ...
    'Units', 'normalized', 'Position', [0.50 0.70 0.45 0.1], ...
    'FontSize', 14, 'FontWeight', 'bold', 'ForegroundColor', [0.8 0.3 0.3], ...
    'BackgroundColor', [0.96 0.96 0.96]);

uicontrol(appData.resultsPanel, 'Style', 'text', 'String', 'Status:', ...
    'Units', 'normalized', 'Position', [0.05 0.50 0.4 0.1], ...
    'FontSize', 12, 'ForegroundColor', [0.2 0.4 0.6], ...
    'BackgroundColor', [0.96 0.96 0.96]);

appData.statusResult = uicontrol(appData.resultsPanel, 'Style', 'text', 'String', '', ...
    'Units', 'normalized', 'Position', [0.05 0.10 0.90 0.35], ...
    'FontSize', 11, 'BackgroundColor', [0.96 0.96 0.96], ...
    'HorizontalAlignment', 'left');

% Upload Button
appData.uploadBtn = uicontrol(mainPanel, 'Style', 'pushbutton', ...
    'String', 'Upload Image', 'Units', 'normalized', ...
    'Position', [0.35 0.15 0.30 0.12], 'FontSize', 14, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.3 0.6 0.85], 'ForegroundColor', [1 1 1], ...
    'Callback', @(src, evt) uploadImage(fig));

% Process Button (hidden initially)
appData.processBtn = uicontrol(mainPanel, 'Style', 'pushbutton', ...
    'String', 'Classify Defects', 'Units', 'normalized', ...
    'Position', [0.20 0.15 0.25 0.12], 'FontSize', 14, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2 0.7 0.2], 'ForegroundColor', [1 1 1], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) processImage(fig));

% Reset Button (hidden initially)
appData.resetBtn = uicontrol(mainPanel, 'Style', 'pushbutton', ...
    'String', 'Reset', 'Units', 'normalized', ...
    'Position', [0.55 0.15 0.25 0.12], 'FontSize', 14, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.8 0.3 0.3], 'ForegroundColor', [1 1 1], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) resetGUI(fig));

% Initialize
appData.fig = fig;
appData.currentImage = [];

guidata(fig, appData);
end

function uploadImage(fig)
appData = guidata(fig);

[filename, pathname] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff;*.webp', ...
    'Image Files'}, 'Select Cloth Glove Image');

if filename == 0, return; end

try
    img = imread(fullfile(pathname, filename));
    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    end
    img = imresize(img, [400 400]);
    
    appData.currentImage = img;
    appData.uploadedFilename = filename;
    
    % Show image
    imshow(img, 'Parent', appData.imageAx);
    
    % Update UI
    set(appData.welcomeLabel, 'String', sprintf('Image: %s', filename), ...
        'ForegroundColor', [0.2 0.4 0.6]);
    set(appData.imagePanel, 'Visible', 'on');
    set(appData.resultsPanel, 'Visible', 'off');
    set(appData.uploadBtn, 'Visible', 'on');
    set(appData.processBtn, 'Visible', 'on');
    set(appData.resetBtn, 'Visible', 'on');
    
    guidata(fig, appData);
    
catch ME
    msgbox(['Error loading image: ' ME.message], 'Error', 'error');
end
end

function processImage(fig)
appData = guidata(fig);

if isempty(appData.currentImage)
    return;
end

set(appData.processBtn, 'Enable', 'off');
set(appData.classificationResult, 'String', 'Analyzing...');
drawnow;

try
    img = appData.currentImage;
    gray = rgb2gray(img);
    
    % Simple defect detection
    holePixels = gray < 100;
    snagPixels = (gray >= 70) & (gray <= 130);
    stainPixels = (gray >= 100) & (gray <= 200);
    
    holeCounts = sum(holePixels(:));
    snagCounts = sum(snagPixels(:));
    stainCounts = sum(stainPixels(:));
    
    % Classify
    if holeCounts > snagCounts && holeCounts > stainCounts && holeCounts > 500
        classification = 'DEFECT: Holes Found';
        color = [0.8 0.3 0.3];
        status = sprintf('Holes detected: %d pixels\nRecommendation: Check for damages', holeCounts);
    elseif snagCounts > holeCounts && snagCounts > stainCounts && snagCounts > 500
        classification = 'DEFECT: Snags Found';
        color = [0.8 0.5 0.2];
        status = sprintf('Snags detected: %d pixels\nRecommendation: Surface wear observed', snagCounts);
    elseif stainCounts > holeCounts && stainCounts > snagCounts && stainCounts > 500
        classification = 'DEFECT: Stains Found';
        color = [0.8 0.3 0.6];
        status = sprintf('Stains detected: %d pixels\nRecommendation: Clean or replace', stainCounts);
    else
        classification = 'NORMAL - No Major Defects';
        color = [0.2 0.7 0.2];
        status = 'Glove condition: Good\nNo significant defects found';
    end
    
    % Update results
    set(appData.imagePanel, 'Visible', 'off');
    set(appData.resultsPanel, 'Visible', 'on');
    set(appData.classificationResult, 'String', classification, 'ForegroundColor', color);
    set(appData.statusResult, 'String', status);
    set(appData.processBtn, 'Visible', 'off');
    set(appData.processBtn, 'Enable', 'on');
    
    guidata(fig, appData);
    
catch ME
    msgbox(['Error processing image: ' ME.message], 'Error', 'error');
    set(appData.processBtn, 'Enable', 'on');
end
end

function resetGUI(fig)
appData = guidata(fig);

imshow([], 'Parent', appData.imageAx);

set(appData.welcomeLabel, 'String', 'Welcome to Glove Defect Detection', ...
    'ForegroundColor', [0.2 0.4 0.6]);
set(appData.imagePanel, 'Visible', 'off');
set(appData.resultsPanel, 'Visible', 'off');
set(appData.uploadBtn, 'Visible', 'on');
set(appData.processBtn, 'Visible', 'off');
set(appData.resetBtn, 'Visible', 'off');

appData.currentImage = [];

guidata(fig, appData);
end

function closeApp()
delete(gcbf);
end
