function GloveDefectDetectionGUI
% GLOVE DEFECT DETECTION GUI
% Interactive system for analyzing cloth glove defects
% - Upload images
% - Process and detect defects
% - Display metrics and results

% Clear previous instances
clc;
persistent appData;

if isempty(appData)
    appData = struct();
end

% ===== CREATE MAIN FIGURE =====
fig = figure('Name', 'Glove Defect Detection System', ...
    'NumberTitle', 'off', ...
    'Position', [100 100 900 900], ...
    'Color', [0.94 0.94 0.94], ...
    'CloseRequestFcn', @(src, evt) closeApp(src, evt, appData), ...
    'Units', 'pixels');

% ===== LEFT CONTROL PANEL =====
leftPanel = uipanel(fig, 'Position', [10, 90, 160, 790], ...
    'Title', 'Control Panel', 'FontSize', 11, 'BackgroundColor', [0.96 0.96 0.96], ...
    'Units', 'pixels');

% Upload Button - Browse Files
uploadBtn = uicontrol(leftPanel, 'Style', 'pushbutton', ...
    'String', 'Upload Image', ...
    'Position', [8, 710, 144, 50], ...
    'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.3 0.6 0.85], 'ForegroundColor', [1 1 1], ...
    'Tooltip', 'Click to browse and select a cloth glove image', ...
    'Callback', @(src, evt) uploadImage(src, evt, appData, fig));

% Material Type Label
uicontrol(leftPanel, 'Style', 'text', 'String', 'Material Type:', ...
    'Position', [8, 670, 144, 25], 'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.96 0.96 0.96]);

% Cloth Gloves (Only option)
uicontrol(leftPanel, 'Style', 'text', 'String', 'Cloth Gloves', ...
    'Position', [12, 645, 136, 20], 'FontSize', 11, 'FontWeight', 'bold', ...
    'ForegroundColor', [0.2 0.4 0.6], 'BackgroundColor', [0.96 0.96 0.96], ...
    'HorizontalAlignment', 'left');

% Process Button
appData.processBtn = uicontrol(leftPanel, 'Style', 'pushbutton', ...
    'String', 'Process Image', ...
    'Position', [8, 575, 144, 50], ...
    'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2 0.7 0.2], 'ForegroundColor', [1 1 1], ...
    'Enable', 'off', ...
    'Tooltip', 'Analyze the uploaded image for defects', ...
    'Callback', @(src, evt) processImage(src, evt, appData, fig));

% Clear Button
uicontrol(leftPanel, 'Style', 'pushbutton', ...
    'String', 'Clear All', ...
    'Position', [8, 515, 144, 45], ...
    'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.8 0.3 0.3], 'ForegroundColor', [1 1 1], ...
    'Tooltip', 'Clear all data and reset the system', ...
    'Callback', @(src, evt) clearAll(appData, fig));

% Status Label
appData.statusLabel = uicontrol(leftPanel, 'Style', 'text', ...
    'String', 'Ready', ...
    'Position', [8, 385, 144, 110], ...
    'FontSize', 10, 'BackgroundColor', [0.96 0.96 0.96], ...
    'ForegroundColor', [0.2 0.7 0.2], 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

% Close Button
uicontrol(leftPanel, 'Style', 'pushbutton', ...
    'String', 'Exit', ...
    'Position', [8, 320, 144, 45], ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.6 0.2 0.2], 'ForegroundColor', [1 1 1], ...
    'Callback', @(src, evt) closeApp(src, evt, appData));

% ===== CENTER TABBED PANEL =====
centerPanel = uipanel(fig, 'Position', [180, 90, 700, 790], ...
    'BackgroundColor', [0.96 0.96 0.96], 'BorderType', 'none', ...
    'Units', 'pixels');

tabGroup = uitabgroup(centerPanel, 'Position', [0 0 1 1]);

% Tab 1: Original Image
tab1 = uitab(tabGroup, 'Title', 'Uploaded Image');
appData.originalAx = axes(tab1, 'Position', [0.05 0.05 0.9 0.9]);
axis(appData.originalAx, 'image');
title(appData.originalAx, 'Original Glove Image', 'FontSize', 12);

% Tab 2: Processing Pipeline
tab2 = uitab(tabGroup, 'Title', 'Processing Pipeline');

appData.grayAx = subplot(2, 2, 1, 'Parent', tab2);
title(appData.grayAx, 'Step 1: Grayscale Conversion', 'FontSize', 10);
axis(appData.grayAx, 'image');

appData.maskAx = subplot(2, 2, 2, 'Parent', tab2);
title(appData.maskAx, 'Step 2: Raw Color Mask', 'FontSize', 10);
axis(appData.maskAx, 'image');

appData.morphAx = subplot(2, 2, 3, 'Parent', tab2);
title(appData.morphAx, 'Step 3: After Morphology', 'FontSize', 10);
axis(appData.morphAx, 'image');

appData.finalAx = subplot(2, 2, 4, 'Parent', tab2);
title(appData.finalAx, 'Step 4: Final Result', 'FontSize', 10);
axis(appData.finalAx, 'image');

% Tab 3: Results
tab3 = uitab(tabGroup, 'Title', 'Analysis Results');

% Results labels
uicontrol(tab3, 'Style', 'text', 'String', 'Detected Material:', ...
    'Position', [0.02, 0.92, 0.4, 0.05], 'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'BackgroundColor', [0.96 0.96 0.96], ...
    'Units', 'normalized');

appData.materialLabel = uicontrol(tab3, 'Style', 'text', 'String', 'Not Analyzed', ...
    'Position', [0.42, 0.92, 0.5, 0.05], 'FontSize', 14, 'FontWeight', 'bold', ...
    'ForegroundColor', [0.2 0.4 0.6], 'BackgroundColor', [0.96 0.96 0.96], ...
    'Units', 'normalized');

uicontrol(tab3, 'Style', 'text', 'String', 'Detected Defect:', ...
    'Position', [0.02, 0.85, 0.4, 0.05], 'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'BackgroundColor', [0.96 0.96 0.96], ...
    'Units', 'normalized');

appData.defectLabel = uicontrol(tab3, 'Style', 'text', 'String', 'Not Analyzed', ...
    'Position', [0.42, 0.85, 0.5, 0.05], 'FontSize', 14, 'FontWeight', 'bold', ...
    'ForegroundColor', [0.2 0.4 0.6], 'BackgroundColor', [0.96 0.96 0.96], ...
    'Units', 'normalized');

appData.defectCountLabel = uicontrol(tab3, 'Style', 'text', ...
    'String', 'Total Defects Found: 0', ...
    'Position', [0.02, 0.78, 0.9, 0.04], 'FontSize', 11, ...
    'BackgroundColor', [0.96 0.96 0.96], ...
    'Units', 'normalized');

% Metrics Table
appData.metricsTable = uitable(tab3, 'Position', [0.02 0.05 0.96 0.70], ...
    'ColumnName', {'Defect Type', 'Area (px)', 'Perimeter (px)', 'Solidity', 'Eccentricity', 'Mean Intensity'}, ...
    'ColumnWidth', {80, 90, 110, 70, 80, 110}, ...
    'RowName', 'numbered', ...
    'Units', 'normalized', ...
    'FontSize', 9);

% ===== RIGHT INFO PANEL =====
rightPanel = uipanel(fig, 'Position', [890, 90, 0, 790], ...
    'Title', 'Information', 'FontSize', 11, 'BackgroundColor', [0.96 0.96 0.96], ...
    'Units', 'pixels', 'Visible', 'off');

appData.infoText = uicontrol(rightPanel, 'Style', 'text', ...
    'String', sprintf('Glove Defect Detection\n_______________\n\nSteps:\n1. Select material\n2. Upload image\n3. Process\n4. View results\n\nDefect Types:\n• Holes\n• Snags\n• Stains\n\n'), ...
    'Position', [5, 20, 140, 600], ...
    'FontSize', 9, 'BackgroundColor', [0.96 0.96 0.96], ...
    'HorizontalAlignment', 'left', ...
    'FontName', 'Courier New');

% ===== HEADER =====
headerPanel = uipanel(fig, 'Position', [0, 870, 900, 30], ...
    'BackgroundColor', [0.2 0.4 0.6], 'BorderType', 'none', ...
    'Units', 'pixels');

uicontrol(headerPanel, 'Style', 'text', ...
    'String', 'Industrial Cloth Glove Defect Detection System', ...
    'Position', [20, 5, 800, 30], ...
    'FontSize', 16, 'FontWeight', 'bold', ...
    'ForegroundColor', [1 1 1], 'BackgroundColor', [0.2 0.4 0.6]);

% ===== INITIALIZE APP DATA =====
appData.fig = fig;
appData.selectedMaterial = 'Cloth Gloves';
appData.currentImage = [];
appData.currentImagePath = '';
appData.gloveMask = [];
appData.holes = [];
appData.snags = [];
appData.stains = [];
appData.processedImages = struct();
appData.features = struct();

guidata(fig, appData);
end

% ===== CALLBACK FUNCTIONS =====

function uploadImage(~, ~, appData, fig)
[filename, pathname] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff;*.webp', ...
    'Image Files'}, 'Select Glove Image');

if filename == 0
    set(appData.statusLabel, 'String', 'Upload cancelled', 'ForegroundColor', [0.8 0.3 0.3]);
    return;
end

imagePath = fullfile(pathname, filename);
img = imread(imagePath);

if size(img, 3) == 1
    img = repmat(img, [1 1 3]);
end

img = imresize(img, [256 256]);

appData.currentImage = img;
appData.currentImagePath = imagePath;

imshow(img, 'Parent', appData.originalAx);
title(appData.originalAx, sprintf('Original Glove Image - %s', filename));

set(appData.statusLabel, 'String', 'Image loaded ✓', 'ForegroundColor', [0.2 0.7 0.2]);
set(appData.processBtn, 'Enable', 'on');

set(appData.infoText, 'String', sprintf('Image loaded:\n%s\n\nSize: %d × %d pixels\nFormat: RGB', ...
    filename, size(img, 2), size(img, 1)));

guidata(fig, appData);
end

function processImage(~, ~, appData, fig)
if isempty(appData.currentImage)
    set(appData.statusLabel, 'String', 'No image loaded', 'ForegroundColor', [0.8 0.3 0.3]);
    return;
end

set(appData.statusLabel, 'String', 'Processing...', 'ForegroundColor', [0.8 0.7 0.2]);
drawnow;

try
    % STEP 1: Preprocessing
    preprocessImage(appData, fig);
    
    % STEP 2: Detection
    detectDefects(appData, fig);
    
    % STEP 3: Visualization
    updateVisualization(appData, fig);
    
    % STEP 4: Results
    updateResults(appData, fig);
    
    set(appData.statusLabel, 'String', 'Complete ✓', 'ForegroundColor', [0.2 0.7 0.2]);
    
catch ME
    set(appData.statusLabel, 'String', ['Error: ' ME.message], 'ForegroundColor', [0.8 0.3 0.3]);
    msgbox(ME.message, 'Processing Error', 'error');
end

guidata(fig, appData);
end

function preprocessImage(appData, fig)
img = appData.currentImage;
gray = rgb2gray(img);
hsv01 = rgb2hsv(img);
S = hsv01(:, :, 2);

% Create glove mask from saturation
mask = imbinarize(S, graythresh(S));
mask = bwareaopen(mask, 200);
mask = imclose(mask, strel("disk", 5));

% Keep largest object
cc = bwconncomp(mask);
if cc.NumObjects > 0
    [~, idx] = max(cellfun(@numel, cc.PixelIdxList));
    tmp = false(size(mask));
    tmp(cc.PixelIdxList{idx}) = true;
    mask = tmp;
end

appData.gloveMask = mask;

% Filters
gauss = im2uint8(imgaussfilt(im2double(gray), 1.0));
med = im2uint8(medfilt2(im2double(gray), [3 3]));

% Morphology
se = strel("disk", 3);
morphology = imopen(gray, se);
morphology = imclose(morphology, se);

appData.processedImages.original = img;
appData.processedImages.gray = gray;
appData.processedImages.mask = mask;
appData.processedImages.gaussian = gauss;
appData.processedImages.median = med;
appData.processedImages.morphology = morphology;

guidata(fig, appData);
end

function detectDefects(appData, fig)
gray = appData.processedImages.gray;
mask = appData.gloveMask;

% Hole detection (very dark)
holePixels = gray < 100;
holePixels = imopen(holePixels, strel("disk", 2));
holePixels = imclose(holePixels, strel("disk", 2));
holeRegion = holePixels & mask;

% Snag detection (medium-dark)
snagPixels = gray < 130 & gray > 70;
snagPixels = imopen(snagPixels, strel("disk", 2));
snagPixels = imclose(snagPixels, strel("disk", 2));
snagRegion = snagPixels & mask;

% Stain detection (texture)
localStd = stdfilt(double(gray), ones(5, 5));
stainPixels = localStd > 15 & gray > 100 & gray < 200;
stainPixels = imopen(stainPixels, strel("disk", 2));
stainPixels = imclose(stainPixels, strel("disk", 2));
stainRegion = stainPixels & mask;

appData.holes = extractDefectRegions(holeRegion, 50, 5000);
appData.snags = extractDefectRegions(snagRegion, 50, 5000);
appData.stains = extractDefectRegions(stainRegion, 50, 5000);

% Extract features
if ~isempty(appData.holes)
    appData.features.holes = extractFeatures(gray, appData.holes);
end
if ~isempty(appData.snags)
    appData.features.snags = extractFeatures(gray, appData.snags);
end
if ~isempty(appData.stains)
    appData.features.stains = extractFeatures(gray, appData.stains);
end

guidata(fig, appData);
end

function updateVisualization(appData, fig)
gray = appData.processedImages.gray;
mask = appData.processedImages.mask;
morphology = appData.processedImages.morphology;

% Processing steps
imshow(gray, 'Parent', appData.grayAx);
title(appData.grayAx, 'Step 1: Grayscale Conversion');

imshow(mask, 'Parent', appData.maskAx);
title(appData.maskAx, 'Step 2: Raw Color Mask');

imshow(morphology, 'Parent', appData.morphAx);
title(appData.morphAx, 'Step 3: After Morphology');

% Final result with overlays
imshow(gray, 'Parent', appData.finalAx);
hold(appData.finalAx, 'on');

if ~isempty(appData.holes)
    drawDefects(appData.finalAx, appData.holes, 'r', 2);
end
if ~isempty(appData.snags)
    drawDefects(appData.finalAx, appData.snags, 'y', 2);
end
if ~isempty(appData.stains)
    drawDefects(appData.finalAx, appData.stains, 'm', 2);
end

hold(appData.finalAx, 'off');
title(appData.finalAx, sprintf('Step 4: Final Result (Area: %d px)', sum(appData.gloveMask(:))));

guidata(fig, appData);
end

function updateResults(appData, fig)
set(appData.materialLabel, 'String', appData.selectedMaterial);

% Determine primary defect
if ~isempty(appData.holes)
    defectType = 'Hole';
    totalDefects = numel(appData.holes);
elseif ~isempty(appData.snags)
    defectType = 'Snag';
    totalDefects = numel(appData.snags);
elseif ~isempty(appData.stains)
    defectType = 'Stain';
    totalDefects = numel(appData.stains);
else
    defectType = 'Normal';
    totalDefects = 0;
end

set(appData.defectLabel, 'String', defectType);
set(appData.defectCountLabel, 'String', sprintf('Total Defects Found: %d', totalDefects));

% Build metrics table
tableData = {};

if ~isempty(appData.holes) && isfield(appData.features, 'holes')
    for i = 1:numel(appData.features.holes)
        f = appData.features.holes(i);
        tableData = [tableData; {'Hole', round(f.area, 1), round(f.perimeter, 1), ...
            round(f.solidity, 2), round(f.eccentricity, 2), round(f.meanIntensity, 1)}];
    end
end

if ~isempty(appData.snags) && isfield(appData.features, 'snags')
    for i = 1:numel(appData.features.snags)
        f = appData.features.snags(i);
        tableData = [tableData; {'Snag', round(f.area, 1), round(f.perimeter, 1), ...
            round(f.solidity, 2), round(f.eccentricity, 2), round(f.meanIntensity, 1)}];
    end
end

if ~isempty(appData.stains) && isfield(appData.features, 'stains')
    for i = 1:numel(appData.features.stains)
        f = appData.features.stains(i);
        tableData = [tableData; {'Stain', round(f.area, 1), round(f.perimeter, 1), ...
            round(f.solidity, 2), round(f.eccentricity, 2), round(f.meanIntensity, 1)}];
    end
end

set(appData.metricsTable, 'Data', tableData);

set(appData.infoText, 'String', sprintf('Analysis Complete\n_______________\n\nMaterial: %s\nDefect: %s\nTotal Found: %d\n\nProcessing pipeline:\n1. Grayscale\n2. Color mask\n3. Morphology\n4. Detection', ...
    appData.selectedMaterial, defectType, totalDefects));

guidata(fig, appData);
end

function clearAll(appData, fig)
cla(appData.originalAx);
cla(appData.grayAx);
cla(appData.maskAx);
cla(appData.morphAx);
cla(appData.finalAx);

appData.currentImage = [];
appData.currentImagePath = '';
appData.gloveMask = [];
appData.holes = [];
appData.snags = [];
appData.stains = [];
appData.processedImages = struct();
appData.features = struct();

set(appData.processBtn, 'Enable', 'off');
set(appData.statusLabel, 'String', 'Cleared', 'ForegroundColor', [0.2 0.7 0.2]);
set(appData.materialLabel, 'String', 'Not Analyzed');
set(appData.defectLabel, 'String', 'Not Analyzed');
set(appData.defectCountLabel, 'String', 'Total Defects Found: 0');
set(appData.metricsTable, 'Data', {});
set(appData.infoText, 'String', 'System cleared. Ready for new image.');

guidata(fig, appData);
end

function closeApp(~, ~, ~)
delete(gcbf);
end

% ===== HELPER FUNCTIONS =====

function defects = extractDefectRegions(binaryImage, minArea, maxArea)
cc = bwconncomp(binaryImage);
defects = [];

for i = 1:cc.NumObjects
    area = numel(cc.PixelIdxList{i});
    if area >= minArea && area <= maxArea
        defect.pixelIdxList = cc.PixelIdxList{i};
        defect.area = area;
        defects = [defects; defect];
    end
end
end

function features = extractFeatures(grayImg, defects)
features = struct();

for d = 1:numel(defects)
    defect = defects(d);
    pixelIdxList = defect.pixelIdxList;
    
    defectMask = false(size(grayImg));
    defectMask(pixelIdxList) = true;
    
    props = regionprops(defectMask, "Perimeter", "Solidity", "Eccentricity");
    
    features(d).area = defect.area;
    features(d).perimeter = props.Perimeter;
    features(d).solidity = props.Solidity;
    features(d).eccentricity = props.Eccentricity;
    
    defectIntensities = grayImg(pixelIdxList);
    features(d).meanIntensity = mean(double(defectIntensities));
end
end

function drawDefects(ax, defects, color, width)
for d = 1:numel(defects)
    pixelIdxList = defects(d).pixelIdxList;
    [rows, cols] = ind2sub(size(get(ax, 'CData')), pixelIdxList);
    
    defectMask = false(256, 256);
    defectMask(pixelIdxList) = true;
    
    boundaries = bwboundaries(defectMask);
    for k = 1:length(boundaries)
        boundary = boundaries{k};
        plot(ax, boundary(:, 2), boundary(:, 1), 'Color', color, 'LineWidth', width);
    end
end
end
