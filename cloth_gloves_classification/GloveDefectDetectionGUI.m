function GloveDefectDetectionGUI()
% GLOVE DEFECT DETECTION - Upload → 4-Step Pipeline → Results with Defects

persistent appData;
if isempty(appData), appData = struct(); end

% Create Figure
fig = figure('Name', 'Glove Defect Detection', 'NumberTitle', 'off', ...
    'Position', [100 100 1000 800], 'Color', [0.94 0.94 0.94], ...
    'CloseRequestFcn', @(src, evt) closeApp());

% Main Panel
mainPanel = uipanel(fig, 'Position', [0.05 0.05 0.90 0.90], ...
    'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

% Welcome Text
appData.welcomeLabel = uicontrol(mainPanel, 'Style', 'text', ...
    'String', 'Welcome to Glove Defect Detection', ...
    'Units', 'normalized', 'Position', [0.1 0.90 0.8 0.07], ...
    'FontSize', 24, 'FontWeight', 'bold', 'ForegroundColor', [0.2 0.4 0.6], ...
    'BackgroundColor', [0.94 0.94 0.94]);

% Display Panel - Initial image
appData.displayPanel = uipanel(mainPanel, 'Position', [0.05 0.35 0.90 0.50], ...
    'BorderType', 'line', 'BackgroundColor', [0.15 0.15 0.15], ...
    'Visible', 'on');

appData.displayAx = axes(appData.displayPanel, 'Position', [0.05 0.05 0.90 0.90], ...
    'Color', [0.15 0.15 0.15]);
axis(appData.displayAx, 'off');

% Pipeline Panel - 4 step processing
appData.pipelinePanel = uipanel(mainPanel, 'Position', [0.05 0.35 0.90 0.50], ...
    'BorderType', 'line', 'BackgroundColor', [0.96 0.96 0.96], ...
    'Visible', 'off');

% Create 4 axes for pipeline steps
appData.step1Ax = axes('Parent', appData.pipelinePanel, 'Position', [0.05 0.55 0.20 0.40]);
title(appData.step1Ax, '1. Original', 'FontSize', 10);
axis(appData.step1Ax, 'image', 'off');

appData.step2Ax = axes('Parent', appData.pipelinePanel, 'Position', [0.30 0.55 0.20 0.40]);
title(appData.step2Ax, '2. Raw Mask', 'FontSize', 10);
axis(appData.step2Ax, 'image', 'off');

appData.step3Ax = axes('Parent', appData.pipelinePanel, 'Position', [0.55 0.55 0.20 0.40]);
title(appData.step3Ax, '3. Morphology', 'FontSize', 10);
axis(appData.step3Ax, 'image', 'off');

appData.step4Ax = axes('Parent', appData.pipelinePanel, 'Position', [0.80 0.55 0.20 0.40]);
title(appData.step4Ax, '4. Final Result', 'FontSize', 10);
axis(appData.step4Ax, 'image', 'off');

% Info text on pipeline panel
appData.pipelineInfo = uicontrol(appData.pipelinePanel, 'Style', 'text', ...
    'String', 'Processing pipeline shown above', ...
    'Units', 'normalized', 'Position', [0.05 0.05 0.90 0.30], ...
    'FontSize', 11, 'BackgroundColor', [0.96 0.96 0.96], ...
    'HorizontalAlignment', 'left');

% Results Panel
appData.resultsPanel = uipanel(mainPanel, 'Position', [0.05 0.35 0.90 0.50], ...
    'BorderType', 'line', 'BackgroundColor', [0.96 0.96 0.96], ...
    'Visible', 'off');

appData.resultAx = axes('Parent', appData.resultsPanel, 'Position', [0.05 0.15 0.90 0.80]);
axis(appData.resultAx, 'image', 'off');

% Results info
uicontrol(appData.resultsPanel, 'Style', 'text', 'String', 'Material: Cloth Gloves', ...
    'Units', 'normalized', 'Position', [0.05 0.05 0.4 0.06], ...
    'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', [0.96 0.96 0.96]);

appData.resultClassification = uicontrol(appData.resultsPanel, 'Style', 'text', 'String', '', ...
    'Units', 'normalized', 'Position', [0.50 0.05 0.45 0.06], ...
    'FontSize', 11, 'FontWeight', 'bold', 'ForegroundColor', [0.2 0.4 0.6], ...
    'BackgroundColor', [0.96 0.96 0.96]);

% Button Panel
buttonPanel = uipanel(mainPanel, 'Position', [0.05 0.02 0.90 0.12], ...
    'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

% Upload Button
uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Upload Image', ...
    'Units', 'normalized', 'Position', [0.25 0.30 0.20 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.3 0.6 0.85], 'ForegroundColor', [1 1 1], ...
    'Callback', @(src, evt) uploadImage(fig));

% Classify Button (hidden initially)
appData.classifyBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Classify Defects', ...
    'Units', 'normalized', 'Position', [0.50 0.30 0.20 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2 0.7 0.2], 'ForegroundColor', [1 1 1], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) classifyDefects(fig));

% Show Results Button (hidden initially)
appData.showResultBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Show Results', ...
    'Units', 'normalized', 'Position', [0.50 0.30 0.20 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.8 0.5 0.2], 'ForegroundColor', [1 1 1], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) showResults(fig));

% Reset Button
uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Reset', ...
    'Units', 'normalized', 'Position', [0.75 0.30 0.20 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.8 0.3 0.3], 'ForegroundColor', [1 1 1], ...
    'Callback', @(src, evt) resetGUI(fig));

% Initialize
appData.fig = fig;
appData.currentImage = [];
appData.grayImage = [];
appData.mask = [];
appData.morphology = [];

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
    
    % Show uploaded image
    imshow(img, 'Parent', appData.displayAx);
    
    % Update UI
    set(appData.welcomeLabel, 'String', sprintf('Image: %s', filename), ...
        'ForegroundColor', [0.2 0.4 0.6]);
    set(appData.displayPanel, 'Visible', 'on');
    set(appData.pipelinePanel, 'Visible', 'off');
    set(appData.resultsPanel, 'Visible', 'off');
    set(appData.classifyBtn, 'Visible', 'on');
    set(appData.showResultBtn, 'Visible', 'off');
    
    guidata(fig, appData);
    
catch ME
    msgbox(['Error: ' ME.message], 'Error', 'error');
end
end

function classifyDefects(fig)
appData = guidata(fig);

if isempty(appData.currentImage)
    return;
end

try
    img = appData.currentImage;
    gray = rgb2gray(img);
    appData.grayImage = gray;
    
    % STEP 1: Original (grayscale)
    imshow(gray, 'Parent', appData.step1Ax);
    
    % STEP 2: Create binary mask - glove outline
    % For white cloth gloves: use grayscale intensity
    % White glove = high intensity, dark background = low intensity
    mask = gray > 150;  % Pixels brighter than 150 are likely the glove
    
    % Clean up the mask - fill holes and smooth edges
    mask = imfill(mask, 'holes');
    mask = bwareaopen(mask, 100);
    
    % Morphological operations to clean
    se = strel("disk", 3);
    mask = imopen(mask, se);
    mask = imclose(mask, se);
    
    % Keep only the largest object (the main glove)
    cc = bwconncomp(mask);
    if cc.NumObjects > 0
        sizes = cellfun(@numel, cc.PixelIdxList);
        [~, idx] = max(sizes);
        clean_mask = false(size(mask));
        clean_mask(cc.PixelIdxList{idx}) = true;
        mask = clean_mask;
    end
    
    appData.mask = mask;
    
    imshow(mask, 'Parent', appData.step2Ax);
    
    % STEP 3: Morphology
    se = strel("disk", 3);
    morphology = imclose(imopen(mask, se), se);
    appData.morphology = morphology;
    
    imshow(morphology, 'Parent', appData.step3Ax);
    
    % STEP 4: Display original with mask overlay
    imshow(gray, 'Parent', appData.step4Ax);
    
    % Update UI
    set(appData.displayPanel, 'Visible', 'off');
    set(appData.pipelinePanel, 'Visible', 'on');
    set(appData.classifyBtn, 'Visible', 'off');
    set(appData.showResultBtn, 'Visible', 'on');
    set(appData.pipelineInfo, 'String', 'Processing complete! Click "Show Results" to see detected defects with markers.');
    
    guidata(fig, appData);
    
catch ME
    msgbox(['Error: ' ME.message], 'Error', 'error');
end
end

function showResults(fig)
appData = guidata(fig);

if isempty(appData.currentImage)
    return;
end

try
    gray = appData.grayImage;
    gloveMask = appData.morphology;  % Binary glove outline
    
    % Detect defects ONLY within glove region
    holePixels = (gray < 100) & gloveMask;
    snagPixels = ((gray >= 70) & (gray <= 120)) & gloveMask;  % Narrower range for snags
    stainPixels = ((gray >= 130) & (gray <= 200)) & gloveMask;  % Higher range for stains
    
    holeCounts = sum(holePixels(:));
    snagCounts = sum(snagPixels(:));
    stainCounts = sum(stainPixels(:));
    
    % Classify based on defect counts inside glove
    if holeCounts > snagCounts && holeCounts > stainCounts && holeCounts > 300
        classification = 'DEFECT: Holes Detected';
        defectMap = holePixels;
    elseif snagCounts > holeCounts && snagCounts > stainCounts && snagCounts > 300
        classification = 'DEFECT: Snags Detected';
        defectMap = snagPixels;
    elseif stainCounts > holeCounts && stainCounts > snagCounts && stainCounts > 300
        classification = 'DEFECT: Stains Detected';
        defectMap = stainPixels;
    else
        classification = 'NORMAL: No Major Defects';
        defectMap = false(size(gray));
    end
    
    % Show result with red circles marking defects (only within glove)
    imshow(gray, 'Parent', appData.resultAx);
    hold(appData.resultAx, 'on');
    
    % Draw glove contour in light gray
    bw_boundary = bwboundaries(gloveMask);
    if ~isempty(bw_boundary)
        for k = 1:length(bw_boundary)
            boundary = bw_boundary{k};
            plot(appData.resultAx, boundary(:,2), boundary(:,1), 'Color', [0.7 0.7 0.7], 'LineWidth', 2);
        end
    end
    
    % Find connected components (defects) and draw red circles
    cc = bwconncomp(defectMap);
    for i = 1:min(cc.NumObjects, 25)
        pixelIdxList = cc.PixelIdxList{i};
        if numel(pixelIdxList) > 5  % Only draw if defect is significant
            [rows, cols] = ind2sub(size(defectMap), pixelIdxList);
            
            % Center and radius of defect
            center_row = mean(rows);
            center_col = mean(cols);
            radius = sqrt(numel(pixelIdxList) / pi);
            
            % Draw red circle
            theta = linspace(0, 2*pi, 50);
            circle_x = center_col + radius * cos(theta);
            circle_y = center_row + radius * sin(theta);
            plot(appData.resultAx, circle_x, circle_y, 'r-', 'LineWidth', 3);
        end
    end
    
    hold(appData.resultAx, 'off');
    
    % Update UI
    set(appData.displayPanel, 'Visible', 'off');
    set(appData.pipelinePanel, 'Visible', 'off');
    set(appData.resultsPanel, 'Visible', 'on');
    set(appData.resultClassification, 'String', classification);
    set(appData.showResultBtn, 'Visible', 'off');
    
    guidata(fig, appData);
    
catch ME
    msgbox(['Error: ' ME.message], 'Error', 'error');
end
end

function resetGUI(fig)
appData = guidata(fig);

cla(appData.displayAx);
cla(appData.step1Ax);
cla(appData.step2Ax);
cla(appData.step3Ax);
cla(appData.step4Ax);
cla(appData.resultAx);

set(appData.welcomeLabel, 'String', 'Welcome to Glove Defect Detection', ...
    'ForegroundColor', [0.2 0.4 0.6]);
set(appData.displayPanel, 'Visible', 'on');
set(appData.pipelinePanel, 'Visible', 'off');
set(appData.resultsPanel, 'Visible', 'off');
set(appData.classifyBtn, 'Visible', 'off');
set(appData.showResultBtn, 'Visible', 'off');

appData.currentImage = [];
appData.grayImage = [];
appData.mask = [];
appData.morphology = [];

guidata(fig, appData);
end

function closeApp()
delete(gcbf);
end
