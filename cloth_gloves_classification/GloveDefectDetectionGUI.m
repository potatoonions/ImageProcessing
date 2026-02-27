function GloveDefectDetectionGUI()
% GLOVE DEFECT DETECTION - Upload → 4-Step Pipeline → Results with Defects

persistent appData;
if isempty(appData), appData = struct(); end

fig = figure('Name', 'Glove Defect Detection', 'NumberTitle', 'off', ...
    'Position', [100 100 1000 800], 'Color', [0.94 0.94 0.94], ...
    'CloseRequestFcn', @(src, evt) closeApp());

mainPanel = uipanel(fig, 'Position', [0.05 0.05 0.90 0.90], ...
    'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

appData.welcomeLabel = uicontrol(mainPanel, 'Style', 'text', ...
    'String', 'Welcome to Glove Defect Detection', ...
    'Units', 'normalized', 'Position', [0.1 0.90 0.8 0.07], ...
    'FontSize', 24, 'FontWeight', 'bold', 'ForegroundColor', [0.2 0.4 0.6], ...
    'BackgroundColor', [0.94 0.94 0.94]);

appData.displayPanel = uipanel(mainPanel, 'Position', [0.05 0.35 0.90 0.50], ...
    'BorderType', 'line', 'BackgroundColor', [0.15 0.15 0.15], ...
    'Visible', 'on');

appData.displayAx = axes(appData.displayPanel, 'Position', [0.05 0.05 0.90 0.90], ...
    'Color', [0.15 0.15 0.15]);
axis(appData.displayAx, 'off');

appData.pipelinePanel = uipanel(mainPanel, 'Position', [0.05 0.35 0.90 0.50], ...
    'BorderType', 'line', 'BackgroundColor', [0.96 0.96 0.96], ...
    'Visible', 'off');

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

appData.pipelineInfo = uicontrol(appData.pipelinePanel, 'Style', 'text', ...
    'String', 'Processing pipeline shown above', ...
    'Units', 'normalized', 'Position', [0.05 0.05 0.90 0.30], ...
    'FontSize', 11, 'BackgroundColor', [0.96 0.96 0.96], ...
    'HorizontalAlignment', 'left');

appData.resultsPanel = uipanel(mainPanel, 'Position', [0.05 0.35 0.90 0.50], ...
    'BorderType', 'line', 'BackgroundColor', [0.96 0.96 0.96], ...
    'Visible', 'off');

appData.resultAx = axes('Parent', appData.resultsPanel, 'Position', [0.05 0.15 0.90 0.80]);
axis(appData.resultAx, 'image', 'off');

uicontrol(appData.resultsPanel, 'Style', 'text', 'String', 'Material: Cloth Gloves', ...
    'Units', 'normalized', 'Position', [0.05 0.05 0.4 0.06], ...
    'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', [0.96 0.96 0.96]);

appData.resultClassification = uicontrol(appData.resultsPanel, 'Style', 'text', 'String', '', ...
    'Units', 'normalized', 'Position', [0.50 0.05 0.45 0.06], ...
    'FontSize', 11, 'FontWeight', 'bold', 'ForegroundColor', [0.2 0.4 0.6], ...
    'BackgroundColor', [0.96 0.96 0.96]);

buttonPanel = uipanel(mainPanel, 'Position', [0.05 0.02 0.90 0.12], ...
    'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Upload Image', ...
    'Units', 'normalized', 'Position', [0.25 0.30 0.20 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.3 0.6 0.85], 'ForegroundColor', [1 1 1], ...
    'Callback', @(src, evt) uploadImage(fig));

appData.classifyBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Classify Defects', ...
    'Units', 'normalized', 'Position', [0.50 0.30 0.20 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2 0.7 0.2], 'ForegroundColor', [1 1 1], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) classifyDefects(fig));

appData.showResultBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Show Results', ...
    'Units', 'normalized', 'Position', [0.50 0.30 0.20 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.8 0.5 0.2], 'ForegroundColor', [1 1 1], ...
    'Visible', 'off', ...
    'Callback', @(src, evt) showResults(fig));

uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Reset', ...
    'Units', 'normalized', 'Position', [0.75 0.30 0.20 0.60], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.8 0.3 0.3], 'ForegroundColor', [1 1 1], ...
    'Callback', @(src, evt) resetGUI(fig));

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
    
    imshow(gray, 'Parent', appData.step1Ax);
    
    mask = gray > 150;
    mask = imfill(mask, 'holes');
    mask = bwareaopen(mask, 100);
    
    se = strel("disk", 3);
    mask = imopen(mask, se);
    mask = imclose(mask, se);
    
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
    
    se = strel("disk", 3);
    morphology = imclose(imopen(mask, se), se);
    appData.morphology = morphology;
    imshow(morphology, 'Parent', appData.step3Ax);
    
    imshow(gray, 'Parent', appData.step4Ax);
    
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
    gloveMask = appData.morphology;
    
    glovePixels = gray(gloveMask);
    mainIntensity = mean(glovePixels);
    intensityStd = std(double(glovePixels));
    
    gloveContour = bwboundaries(gloveMask);
    if isempty(gloveContour)
        error('Could not find glove contour');
    end
    gloveContourPoly = gloveContour{1};
    
    dilatedMask = imdilate(gloveMask, strel('disk', 5));
    erodedMask = imerode(gloveMask, strel('disk', 2));
    contourRegion = dilatedMask & ~erodedMask;
    
    % Hole detection: very dark regions
    holePixels = (gray < (mainIntensity - 30)) & contourRegion;
    
    % Snag detection: medium dark regions
    snagPixels = ((gray >= (mainIntensity - 50)) & (gray <= (mainIntensity - 10))) & contourRegion;
    
    % Stain detection: Use texture-based detection for visible dirt/discoloration
    % Stains appear as regions with different texture (higher local std deviation)
    % and darker than expected
    localStd = stdfilt(double(gray), ones(5, 5));
    stainPixels = (localStd > 12) & (gray < (mainIntensity + 20)) & (gray > (mainIntensity - 40)) & contourRegion;
    
    % Also detect very faint stains using intensity deviation alone
    stainPixels2 = ((gray >= (mainIntensity - 25)) & (gray <= (mainIntensity + 5))) & contourRegion;
    stainPixels = stainPixels | stainPixels2;
    
    % Clean stain pixels with morphological operations
    se = strel("disk", 2);
    stainPixels = imopen(stainPixels, se);
    stainPixels = imclose(stainPixels, se);
    
    [holes, holeCount] = analyzeDefects(holePixels, gloveContourPoly, 'hole', 400, 2);
    [snags, snagCount] = analyzeDefects(snagPixels, gloveContourPoly, 'snag', 150, 2.25);
    [stains, stainCount] = analyzeDefects(stainPixels, gloveContourPoly, 'stain', 80, 2.5);
    
    defects = [holes; snags; stains];
    
    if holeCount > 0 && holeCount >= snagCount && holeCount >= stainCount
        classification = sprintf('DEFECT: Holes (%d detected)', holeCount);
        defectType = 'hole';
    elseif snagCount > 0 && snagCount > holeCount && snagCount >= stainCount
        classification = sprintf('DEFECT: Snags (%d detected)', snagCount);
        defectType = 'snag';
    elseif stainCount > 0 && stainCount > holeCount && stainCount > snagCount
        classification = sprintf('DEFECT: Stains (%d detected)', stainCount);
        defectType = 'stain';
    else
        classification = 'NORMAL: No Major Defects';
        defectType = 'none';
    end
    
    imshow(gray, 'Parent', appData.resultAx);
    hold(appData.resultAx, 'on');
    
    plot(appData.resultAx, gloveContourPoly(:,2), gloveContourPoly(:,1), 'Color', [0.7 0.7 0.7], 'LineWidth', 2);
    
    for i = 1:length(defects)
        defect = defects(i);
        if ~isempty(defect.box)
            x = defect.box(1);
            y = defect.box(2);
            w = defect.box(3);
            h = defect.box(4);
            
            if strcmp(defect.type, 'hole')
                color = [1 0 0];
            elseif strcmp(defect.type, 'snag')
                color = [1 1 0];
            else
                color = [1 0 1];
            end
            
            rectangle(appData.resultAx, 'Position', [x, y, w, h], 'EdgeColor', color, 'LineWidth', 2);
            text(appData.resultAx, x + w/2, y - 5, defect.type, ...
                'Color', color, 'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
        end
    end
    
    hold(appData.resultAx, 'off');
    
    set(appData.displayPanel, 'Visible', 'off');
    set(appData.pipelinePanel, 'Visible', 'off');
    set(appData.resultsPanel, 'Visible', 'on');
    set(appData.resultClassification, 'String', sprintf('%s (Color: %d±%d)', classification, uint8(mainIntensity), uint8(intensityStd)));
    set(appData.showResultBtn, 'Visible', 'off');
    
    guidata(fig, appData);
    
catch ME
    msgbox(['Error: ' ME.message], 'Error', 'error');
end
end

function [defectsOut, count] = analyzeDefects(defectMap, gloveContour, defectType, minArea, maxAspectRatio)
% Analyze defects using contour analysis similar to Python example
    defectsOut = [];
    count = 0;
    
    % Find connected components
    cc = bwconncomp(defectMap);
    
    for i = 1:cc.NumObjects
        pixelIdxList = cc.PixelIdxList{i};
        area = numel(pixelIdxList);
        
        % Filter by minimum area
        if area < minArea
            continue;
        end
        
        % Get bounding box
        [rows, cols] = ind2sub(size(defectMap), pixelIdxList);
        box = [min(cols), min(rows), max(cols) - min(cols), max(rows) - min(rows)];
        
        % Calculate aspect ratio
        w = box(3);
        h = box(4);
        aspectRatio = w / h;
        if aspectRatio < 1
            aspectRatio = 1 / aspectRatio;
        end
        
        % Filter by aspect ratio
        if aspectRatio > maxAspectRatio
            continue;
        end
        
        % Check if center is within glove contour using point-in-polygon test
        cx = box(1) + w/2;
        cy = box(2) + h/2;
        
        [dist, ~] = point2curve([cy, cx], gloveContour);
        isWithinGlove = dist <= 0;
        
        if ~isWithinGlove
            continue;
        end
        
        % Passed all filters - add to results
        count = count + 1;
        defect.type = defectType;
        defect.box = box;
        defect.area = area;
        defect.aspectRatio = aspectRatio;
        defectsOut = [defectsOut; defect];
    end
end

function [distance, location] = point2curve(point, curve)
% Simple point-to-boundary distance
    distances = sqrt((curve(:,1) - point(1)).^2 + (curve(:,2) - point(2)).^2);
    [distance, idx] = min(distances);
    
    % Determine if point is inside contour (simple approximation)
    % Count crossings to estimate if inside
    x = point(2);
    y = point(1);
    crossings = 0;
    for j = 1:size(curve, 1)
        next_j = mod(j, size(curve, 1)) + 1;
        y1 = curve(j, 1);
        y2 = curve(next_j, 1);
        x1 = curve(j, 2);
        x2 = curve(next_j, 2);
        
        if ((y1 <= y && y < y2) || (y2 <= y && y < y1))
            xinters = x1 + (y - y1) * (x2 - x1) / (y2 - y1);
            if x < xinters
                crossings = crossings + 1;
            end
        end
    end
    
    if mod(crossings, 2) == 1
        distance = -distance;  % Inside = negative
    end
    
    location = curve(idx, :);
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
