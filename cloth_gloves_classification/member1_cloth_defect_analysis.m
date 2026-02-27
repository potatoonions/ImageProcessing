function member1_cloth_defect_analysis
% MEMBER 1 - CLOTH GLOVE DEFECT ANALYSIS PIPELINE
% Unified script for preprocessing and multi-defect detection
%
% Defects analyzed:
%   1. Holes - dark punctures/worn areas
%   2. Snags - pulled/snagged fibers
%   3. Stains - discolored areas

clc; clear;

DATASET_DIR = fullfile(pwd, "gloves_dataset");
GLOVE_TYPE = "cloth gloves";
DEFECT_TYPES = ["Normal", "Hole", "Snags", "Stain"];

OUT_PROC = fullfile(pwd, "processed");
OUT_LOGS = fullfile(pwd, "logs");

TARGET_SIZE = [256 256];
GAUSS_SIGMA = 1.0;
MED_WIN = [3 3];
MIN_BLOB_AREA = 700;
CLOSE_RADIUS = 5;
IMG_EXTS = [".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp"];

HOLE_THRESHOLD = 100;
SNAG_THRESHOLD = 130;
STAIN_THRESHOLD = 140;
STAIN_COLOR_RANGE = 30;

MIN_DEFECT_AREA = 50;
MAX_DEFECT_AREA = 5000;
MORPH_RADIUS = 3;

fprintf("\n========== INITIALIZING DIRECTORIES ==========\n");

if ~isfolder(OUT_PROC), mkdir(OUT_PROC); end
if ~isfolder(OUT_LOGS), mkdir(OUT_LOGS); end

procSubs = ["resized", "gray", "hsv", "filtered_gaussian", "filtered_median", ...
            "masks", "isolated", "hole_detection", "snag_detection", "stain_detection"];
for s = procSubs
    p = fullfile(OUT_PROC, s);
    if ~isfolder(p), mkdir(p); end
    if ~isfolder(fullfile(p, GLOVE_TYPE))
        mkdir(fullfile(p, GLOVE_TYPE));
    end
end

for defectType = DEFECT_TYPES
    for detMethod = ["hole_detection", "snag_detection", "stain_detection"]
        detDir = fullfile(OUT_LOGS, detMethod, GLOVE_TYPE, defectType);
        if ~isfolder(detDir), mkdir(detDir); end
    end
end

fprintf("✓ Output directories created\n");

fprintf("\n========== STEP 1: PREPROCESSING ==========\n");

statsRows = {};
detectionResults = {};

for defectType = DEFECT_TYPES
    folderPath = fullfile(DATASET_DIR, GLOVE_TYPE, defectType);
    
    if ~isfolder(folderPath)
        fprintf("⚠ Folder not found: %s\n", folderPath);
        continue;
    end
    
    imgs = listImages(folderPath, IMG_EXTS);
    fprintf("Processing %s: %d images\n", defectType, numel(imgs));
    
    for i = 1:numel(imgs)
        % Load and preprocess image
        I = imread(imgs(i));
        I = im2uint8(I);
        I = imresize(I, TARGET_SIZE);
        
        % Convert to grayscale and HSV
        if size(I, 3) == 3
            gray = rgb2gray(I);
            hsv01 = rgb2hsv(I);
        else
            gray = I;
            hsv01 = rgb2hsv(repmat(I, [1 1 3]));
        end
        
        % Apply filters
        gauss = im2uint8(imgaussfilt(im2double(gray), GAUSS_SIGMA));
        med = im2uint8(medfilt2(im2double(gray), MED_WIN));
        
        % Create glove mask using HSV saturation
        S = hsv01(:,:,2);
        mask = imbinarize(S, graythresh(S));
        mask = cleanMask(mask, MIN_BLOB_AREA, CLOSE_RADIUS);
        
        % Isolate glove region
        isolated = I;
        if size(I, 3) == 1
            isolated(~mask) = 0;
        else
            for c = 1:3
                tmp = isolated(:,:,c);
                tmp(~mask) = 0;
                isolated(:,:,c) = tmp;
            end
        end
        
        [~, baseName, ~] = fileparts(imgs(i));
        relDir = fullfile(GLOVE_TYPE, defectType);
        
        % Save preprocessed outputs
        saveP(OUT_PROC, "resized", relDir, baseName, I);
        saveP(OUT_PROC, "gray", relDir, baseName, gray);
        saveP(OUT_PROC, "filtered_gaussian", relDir, baseName, gauss);
        saveP(OUT_PROC, "filtered_median", relDir, baseName, med);
        saveP(OUT_PROC, "masks", relDir, baseName, im2uint8(mask));
        saveP(OUT_PROC, "isolated", relDir, baseName, isolated);
        
        hsvVis = im2uint8(hsv2rgb(hsv01));
        saveP(OUT_PROC, "hsv", relDir, baseName, hsvVis);
        
        % Record statistics
        statsRows(end+1,:) = {char(GLOVE_TYPE), char(defectType), baseName}; %#ok<SAGROW>
    end
end

fprintf("✓ Preprocessing completed\n");

%% ========== STEP 2: MULTI-DEFECT DETECTION ==========
fprintf("\n========== STEP 2: DEFECT DETECTION ==========\n");

holeStats = {};
snagStats = {};
stainStats = {};

for defectType = DEFECT_TYPES
    grayDir = fullfile(OUT_PROC, "gray", GLOVE_TYPE, defectType);
    maskDir = fullfile(OUT_PROC, "masks", GLOVE_TYPE, defectType);
    
    if ~isfolder(grayDir), continue; end
    
    imgs = listImages(grayDir, [".png"]);
    fprintf("Detecting defects in %s images (%d files)\n", defectType, numel(imgs));
    
    for i = 1:numel(imgs)
        [~, baseName, ~] = fileparts(imgs(i));
        grayImg = imread(imgs(i));
        maskFile = fullfile(maskDir, baseName + ".png");
        
        if ~isfile(maskFile), continue; end
        gloveMask = imread(maskFile) > 128;
        
        % ===== HOLE DETECTION =====
        holes = detectDefects(grayImg, gloveMask, HOLE_THRESHOLD, MORPH_RADIUS, ...
                              MIN_DEFECT_AREA, MAX_DEFECT_AREA, "dark");
        if ~isempty(holes)
            features = extractFeatures(grayImg, holes);
            for h = 1:numel(holes)
                F = features(h);
                holeStats(end+1,:) = {char(defectType), baseName, h, F.area, F.perimeter, ...
                    F.solidity, F.eccentricity, F.meanIntensity}; %#ok<SAGROW>
            end
            exportVisualization(grayImg, gloveMask, holes, ...
                fullfile(OUT_LOGS, "hole_detection", GLOVE_TYPE, defectType, ...
                    sprintf("%s_holes.png", baseName)));
        end
        
        % ===== SNAG DETECTION =====
        snags = detectDefects(grayImg, gloveMask, SNAG_THRESHOLD, MORPH_RADIUS, ...
                              MIN_DEFECT_AREA, MAX_DEFECT_AREA, "medium");
        if ~isempty(snags)
            features = extractFeatures(grayImg, snags);
            for s = 1:numel(snags)
                F = features(s);
                snagStats(end+1,:) = {char(defectType), baseName, s, F.area, F.perimeter, ...
                    F.solidity, F.eccentricity, F.meanIntensity}; %#ok<SAGROW>
            end
            exportVisualization(grayImg, gloveMask, snags, ...
                fullfile(OUT_LOGS, "snag_detection", GLOVE_TYPE, defectType, ...
                    sprintf("%s_snags.png", baseName)));
        end
        
        % ===== STAIN DETECTION =====
        stains = detectStains(grayImg, gloveMask, STAIN_THRESHOLD, MORPH_RADIUS, ...
                              MIN_DEFECT_AREA, MAX_DEFECT_AREA);
        if ~isempty(stains)
            features = extractFeatures(grayImg, stains);
            for st = 1:numel(stains)
                F = features(st);
                stainStats(end+1,:) = {char(defectType), baseName, st, F.area, F.perimeter, ...
                    F.solidity, F.eccentricity, F.meanIntensity}; %#ok<SAGROW>
            end
            exportVisualization(grayImg, gloveMask, stains, ...
                fullfile(OUT_LOGS, "stain_detection", GLOVE_TYPE, defectType, ...
                    sprintf("%s_stains.png", baseName)));
        end
    end
end

fprintf("✓ Defect detection completed\n");

%% ========== STEP 3: SAVE RESULTS ==========
fprintf("\n========== STEP 3: SAVING RESULTS ==========\n");

% Save dataset statistics
T = cell2table(statsRows, "VariableNames", ["glove_type", "defect_type", "image_name"]);
writetable(T, fullfile(OUT_LOGS, "dataset_stats.csv"));

% Save hole detection statistics
if ~isempty(holeStats)
    T_holes = cell2table(holeStats, "VariableNames", ...
        ["image_class", "image_name", "hole_id", "area_px", "perimeter_px", ...
         "solidity", "eccentricity", "mean_intensity"]);
    writetable(T_holes, fullfile(OUT_LOGS, "hole_detection_stats.csv"));
    fprintf("✓ Hole detection statistics saved\n");
end

% Save snag detection statistics
if ~isempty(snagStats)
    T_snags = cell2table(snagStats, "VariableNames", ...
        ["image_class", "image_name", "snag_id", "area_px", "perimeter_px", ...
         "solidity", "eccentricity", "mean_intensity"]);
    writetable(T_snags, fullfile(OUT_LOGS, "snag_detection_stats.csv"));
    fprintf("✓ Snag detection statistics saved\n");
end

% Save stain detection statistics
if ~isempty(stainStats)
    T_stains = cell2table(stainStats, "VariableNames", ...
        ["image_class", "image_name", "stain_id", "area_px", "perimeter_px", ...
         "solidity", "eccentricity", "mean_intensity"]);
    writetable(T_stains, fullfile(OUT_LOGS, "stain_detection_stats.csv"));
    fprintf("✓ Stain detection statistics saved\n");
end

fprintf("\n========== PIPELINE COMPLETE ==========\n");
fprintf("Output directories:\n");
fprintf("  - processed/ (preprocessed images)\n");
fprintf("  - logs/ (detection results & statistics)\n\n");

end

%% ========== HELPER FUNCTIONS ==========

function imgs = listImages(folderPath, exts)
    d = dir(folderPath);
    imgs = strings(0);
    for k = 1:numel(d)
        if d(k).isdir, continue; end
        [~, ~, e] = fileparts(d(k).name);
        if any(strcmpi(exts, string(e)))
            imgs(end+1) = fullfile(folderPath, d(k).name); %#ok<AGROW>
        end
    end
end

function saveP(root, sub, rel, name, I)
    outDir = fullfile(root, sub, rel);
    if ~isfolder(outDir), mkdir(outDir); end
    imwrite(I, fullfile(outDir, name + ".png"));
end

function m = cleanMask(m, minArea, r)
    m = bwareaopen(m, minArea);
    m = imclose(m, strel("disk", r));
    cc = bwconncomp(m);
    if cc.NumObjects < 1, return; end
    [~, idx] = max(cellfun(@numel, cc.PixelIdxList));
    tmp = false(size(m));
    tmp(cc.PixelIdxList{idx}) = true;
    m = tmp;
end

function defects = detectDefects(grayImg, gloveMask, threshold, morphRad, minArea, maxArea, type)
    % Detects defects using intensity-based thresholding with aspect ratio filtering
    % Incorporates Python approaches: aspect ratio filtering, point-in-polygon testing
    % type: 'dark' (holes), 'medium' (snags), etc.
    
    if strcmp(type, 'dark')
        defectPixels = grayImg < threshold;
    else
        defectPixels = grayImg < threshold & grayImg > (threshold - 30);
    end
    
    % Morphological processing
    se = strel("disk", morphRad);
    defectPixels = imopen(defectPixels, se);
    defectPixels = imclose(defectPixels, se);
    
    % Restrict to glove region
    defectRegion = defectPixels & gloveMask;
    
    % Find glove boundary for point-in-polygon testing
    gloveBoundary = bwboundaries(gloveMask);
    
    % Find connected components
    cc = bwconncomp(defectRegion);
    defects = [];
    
    for objIdx = 1:cc.NumObjects
        pixelIdxList = cc.PixelIdxList{objIdx};
        objArea = numel(pixelIdxList);
        
        if objArea >= minArea && objArea <= maxArea
            % Create binary mask for this defect
            defectMask = false(size(grayImg));
            defectMask(pixelIdxList) = true;
            
            % Get bounding box and aspect ratio
            props = regionprops(defectMask, "Centroid", "BoundingBox", "EquivDiameter");
            centroid = props.Centroid;
            bbox = props.BoundingBox;
            
            % Calculate aspect ratio from bounding box
            width = bbox(3);
            height = bbox(4);
            if height > 0
                aspectRatio = width / height;
                if aspectRatio < 1 && aspectRatio > 0
                    aspectRatio = 1 / aspectRatio;
                end
            else
                aspectRatio = 1;
            end
            
            % Filter by aspect ratio (exclude very elongated artifacts)
            % Python uses aspect_ratio < 2.25 for stains, < 2 for holes
            maxAspectRatio = 2.5; % Allow slightly elongated defects
            if aspectRatio > maxAspectRatio
                continue; % Skip this defect
            end
            
            % Point-in-polygon testing: verify defect center is within glove
            if ~isempty(gloveBoundary)
                gloveContour = gloveBoundary{1};
                % inpolygon checks if points are inside polygon
                inGlove = inpolygon(centroid(1), centroid(2), gloveContour(:,2), gloveContour(:,1));
                if ~inGlove
                    continue; % Skip if center not in glove
                end
            end
            
            % Store defect with additional properties
            defect.pixelIdxList = pixelIdxList;
            defect.area = objArea;
            defect.centroid = centroid;
            defect.bbox = bbox;
            defect.aspectRatio = aspectRatio;
            defects = [defects; defect]; %#ok<AGROW>
        end
    end
end

function defects = detectStains(grayImg, gloveMask, threshold, morphRad, minArea, maxArea)
    % Detects stains using texture analysis with aspect ratio filtering
    % Incorporates Python approaches: aspect ratio filtering, point-in-polygon testing
    % Stains appear as regions with different intensity characteristics
    
    % Use local standard deviation to find texture changes
    localStd = stdfilt(double(grayImg), ones(5, 5));
    stainPixels = localStd > 15 & grayImg > threshold;
    
    % Morphological processing
    se = strel("disk", morphRad);
    stainPixels = imopen(stainPixels, se);
    stainPixels = imclose(stainPixels, se);
    
    % Restrict to glove region
    stainRegion = stainPixels & gloveMask;
    
    % Find glove boundary for point-in-polygon testing
    gloveBoundary = bwboundaries(gloveMask);
    
    % Find connected components
    cc = bwconncomp(stainRegion);
    defects = [];
    
    for objIdx = 1:cc.NumObjects
        pixelIdxList = cc.PixelIdxList{objIdx};
        objArea = numel(pixelIdxList);
        
        if objArea >= minArea && objArea <= maxArea
            % Create binary mask for this defect
            defectMask = false(size(grayImg));
            defectMask(pixelIdxList) = true;
            
            % Get bounding box and centroid
            props = regionprops(defectMask, "Centroid", "BoundingBox");
            centroid = props.Centroid;
            bbox = props.BoundingBox;
            
            % Calculate aspect ratio from bounding box
            width = bbox(3);
            height = bbox(4);
            if height > 0
                aspectRatio = width / height;
                if aspectRatio < 1 && aspectRatio > 0
                    aspectRatio = 1 / aspectRatio;
                end
            else
                aspectRatio = 1;
            end
            
            % Filter by aspect ratio (Python uses < 2.25 for stains)
            maxAspectRatio = 2.25;
            if aspectRatio > maxAspectRatio
                continue; % Skip this stain if too elongated
            end
            
            % Point-in-polygon testing: verify stain center is within glove
            if ~isempty(gloveBoundary)
                gloveContour = gloveBoundary{1};
                inGlove = inpolygon(centroid(1), centroid(2), gloveContour(:,2), gloveContour(:,1));
                if ~inGlove
                    continue; % Skip if center not in glove
                end
            end
            
            % Store stain with additional properties
            defect.pixelIdxList = pixelIdxList;
            defect.area = objArea;
            defect.centroid = centroid;
            defect.bbox = bbox;
            defect.aspectRatio = aspectRatio;
            defects = [defects; defect]; %#ok<AGROW>
        end
    end
end

function features = extractFeatures(grayImg, defects)
    % Extract geometric and intensity features with shape analysis
    % Includes aspect ratio and ellipse fitting from Python approach
    
    features = struct();
    
    for d = 1:numel(defects)
        defect = defects(d);
        pixelIdxList = defect.pixelIdxList;
        
        % Create binary mask
        defectMask = false(size(grayImg));
        defectMask(pixelIdxList) = true;
        
        % Geometric properties
        props = regionprops(defectMask, "Perimeter", "Solidity", "Eccentricity", ...
                           "MajorAxisLength", "MinorAxisLength");
        
        features(d).area = defect.area;
        features(d).perimeter = props.Perimeter;
        features(d).solidity = props.Solidity;
        features(d).eccentricity = props.Eccentricity;
        
        % Shape features (from Python ellipse fitting)
        features(d).aspectRatio = defect.aspectRatio;
        if features(d).aspectRatio > 0
            features(d).shapeCircularity = props.MinorAxisLength / props.MajorAxisLength;
        else
            features(d).shapeCircularity = 1;
        end
        
        % Bounding box information
        features(d).bboxWidth = defect.bbox(3);
        features(d).bboxHeight = defect.bbox(4);
        
        % Intensity statistics
        defectIntensities = grayImg(pixelIdxList);
        features(d).meanIntensity = mean(double(defectIntensities));
        features(d).stdIntensity = std(double(defectIntensities));
        features(d).minIntensity = min(defectIntensities);
        features(d).maxIntensity = max(defectIntensities);
    end
end

function exportVisualization(grayImg, gloveMask, defects, outPath)
    % Create visualization of detected defects with labeled bounding boxes
    % Enhanced with Python approach: bounding box drawing + text labels
    
    if ~isfolder(fileparts(outPath))
        mkdir(fileparts(outPath));
    end
    
    f = figure("Visible", "off", "Position", [0 0 1000 800]);
    t = tiledlayout(2, 2, "TileSpacing", "compact");
    
    % Panel 1: Grayscale
    nexttile; imshow(grayImg); title("Grayscale Image");
    
    % Panel 2: Glove Mask
    nexttile; imshow(gloveMask); title("Glove Mask");
    
    % Panel 3: Defect Binary
    defectMask = false(size(grayImg));
    for d = 1:numel(defects)
        defectMask(defects(d).pixelIdxList) = true;
    end
    nexttile; imshow(defectMask); title(sprintf("Detected Defects (n=%d)", numel(defects)));
    
    % Panel 4: Overlay with labeled bounding boxes (Python approach)
    nexttile;
    rgbImg = repmat(grayImg, [1 1 3]); % Convert to RGB for colored boxes
    imshow(rgbImg);
    hold on;
    
    % Define colors for different defect types
    colors = [255 0 0;   % Red for holes
              0 255 0;   % Green for snags
              0 0 255];  % Blue for stains
    colorIdx = 1;
    
    for d = 1:numel(defects)
        % Draw bounding box (Python approach)
        bbox = defects(d).bbox;
        x = bbox(1);
        y = bbox(2);
        w = bbox(3);
        h = bbox(4);
        
        % Draw rectangle
        rectangle("Position", [x y w h], "EdgeColor", "red", "LineWidth", 2);
        
        % Add label text (similar to Python code)
        label = sprintf("D%d", d);
        textX = x + w/2;
        textY = y + h + 15;
        
        text(textX, textY, label, "Color", "red", "FontSize", 10, ...
            "HorizontalAlignment", "center", "FontWeight", "bold", ...
            "BackgroundColor", "white");
    end
    hold off;
    title(sprintf("Defects with Bounding Boxes (n=%d)", numel(defects)));
    
    exportgraphics(t, outPath, "Resolution", 150);
    close(f);
end
