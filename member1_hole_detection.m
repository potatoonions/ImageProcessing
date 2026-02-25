function member1_hole_detection
% Member 1 - Hole Detection & Feature Extraction
% Detects holes in glove images using Thresholding + Morphological Operations
% Based on IPPR Chapter 7 (Segmentation) & Chapter 8 (Morphology)
%
% Hole characteristics: Dark regions (low intensity) within glove area
% Detection strategy:
%   1. Apply thresholding on grayscale to find dark regions
%   2. Use morphological operations to refine hole regions
%   3. Extract geometric + texture features
%   4. Filter by size/shape constraints

clc; clear;

%% ========== CONFIG ==========
BASE_PATH = fullfile(pwd, "processed");
OUT_RESULTS = fullfile(pwd, "logs", "hole_detection_results");

% Hole detection thresholds
GRAY_THRESHOLD = 100;        % Dark pixels < 100 (0-255 scale) are potential holes
MIN_HOLE_AREA = 50;          % Minimum hole area (pixels)
MAX_HOLE_AREA = 5000;        % Maximum hole area (to avoid false positives)
MORPH_RADIUS = 3;            % Morphological structuring element radius

GLOVE_TYPES = ["cloth gloves"];
IMG_EXTS = [".png"];

if ~isfolder(OUT_RESULTS), mkdir(OUT_RESULTS); end

%% ========== MAIN PROCESSING ==========
statsRows = {};

for gt = GLOVE_TYPES
    grayPath = fullfile(BASE_PATH, "gray", gt, "Hole");
    maskPath = fullfile(BASE_PATH, "masks", gt, "Hole");
    
    if ~isfolder(grayPath), continue; end
    
    imgs = listImages(grayPath, IMG_EXTS);
    disp(sprintf("Processing %s - %d Hole images", gt, numel(imgs)));
    
    for i = 1:numel(imgs)
        % Load preprocessed data
        [~, baseName, ~] = fileparts(imgs(i));
        grayImg = imread(imgs(i));
        maskFile = fullfile(maskPath, baseName + ".png");
        
        if ~isfile(maskFile)
            warning("Mask not found for: %s", baseName);
            continue;
        end
        
        gloveMask = imread(maskFile) > 128;  % Convert to binary
        
        % ===== HOLE DETECTION =====
        holes = detectHoles(grayImg, gloveMask, GRAY_THRESHOLD, MORPH_RADIUS, ...
                           MIN_HOLE_AREA, MAX_HOLE_AREA);
        
        % ===== EXTRACT HOLE FEATURES =====
        if ~isempty(holes)
            features = extractHoleFeatures(grayImg, holes);
            
            % Log results
            for h = 1:numel(holes)
                F = features(h);
                statsRows(end+1,:) = {char(gt), baseName, h, ...
                    F.area, F.perimeter, F.solidity, F.eccentricity, ...
                    F.meanIntensity, F.stdIntensity, ...
                    F.minIntensity, F.maxIntensity}; %#ok<SAGROW>
            end
        end
        
        % ===== VISUALIZE RESULTS =====
        if mod(i, 3) == 1  % Save every 3rd result to avoid clutter
            exportHoleVisualization(grayImg, gloveMask, holes, ...
                fullfile(OUT_RESULTS, sprintf("%s__%s.png", safeName(gt), baseName)));
        end
    end
end

%% ========== SAVE STATISTICS ==========
if ~isempty(statsRows)
    T = cell2table(statsRows, "VariableNames", ...
        ["glove_type", "image_name", "hole_id", ...
         "area_px", "perimeter_px", "solidity", "eccentricity", ...
         "mean_intensity", "std_intensity", "min_intensity", "max_intensity"]);
    writetable(T, fullfile(OUT_RESULTS, "hole_detection_stats.csv"));
    disp(sprintf("✓ Hole detection completed. Results saved to: %s", OUT_RESULTS));
else
    disp("No holes detected in dataset.");
end

end

%% ========== HOLE DETECTION FUNCTION ==========
function holes = detectHoles(grayImg, gloveMask, threshold, morphRad, minArea, maxArea)
% Detects holes using THRESHOLDING + MORPHOLOGICAL OPERATIONS
% 
% Methodology:
%   1. Threshold grayscale image (dark pixels = potential holes)
%   2. Apply morphological closing to fill small gaps
%   3. Apply morphological opening to remove noise
%   4. Keep only objects within size constraints

% Step 1: Thresholding (find dark regions)
darkPixels = grayImg < threshold;

% Step 2: Morphological preprocessing
se = strel("disk", morphRad);
darkPixels = imopen(darkPixels, se);   % Remove noise (opening)
darkPixels = imclose(darkPixels, se);  % Fill gaps (closing)

% Step 3: Restrict to glove region only
holeRegion = darkPixels & gloveMask;

% Step 4: Find connected components (individual holes)
cc = bwconncomp(holeRegion);
holes = [];

for objIdx = 1:cc.NumObjects
    pixelIdxList = cc.PixelIdxList{objIdx};
    objArea = numel(pixelIdxList);
    
    % Filter by area constraints
    if objArea >= minArea && objArea <= maxArea
        hole.pixelIdxList = pixelIdxList;
        hole.area = objArea;
        holes = [holes; hole]; %#ok<AGROW>
    end
end
end

%% ========== FEATURE EXTRACTION ==========
function features = extractHoleFeatures(grayImg, holes)
% Extracts geometric and textual features for each hole
%
% Features:
%   - Geometric: area, perimeter, solidity, eccentricity
%   - Intensity: mean, std, min, max (texture-based)

features = struct();

for h = 1:numel(holes)
    hole = holes(h);
    pixelIdxList = hole.pixelIdxList;
    
    % Create binary mask for this hole
    holeMask = false(size(grayImg));
    holeMask(pixelIdxList) = true;
    
    % Geometric properties
    props = regionprops(holeMask, "Perimeter", "Solidity", "Eccentricity");
    
    features(h).area = hole.area;
    features(h).perimeter = props.Perimeter;
    features(h).solidity = props.Solidity;
    features(h).eccentricity = props.Eccentricity;
    
    % Intensity statistics (texture)
    holeIntensities = grayImg(pixelIdxList);
    features(h).meanIntensity = mean(holeIntensities);
    features(h).stdIntensity = std(double(holeIntensities));
    features(h).minIntensity = min(holeIntensities);
    features(h).maxIntensity = max(holeIntensities);
    
    % Shape circularity (compact = 1, elongated < 1)
    features(h).circularity = 4 * pi * hole.area / (features(h).perimeter^2);
end
end

%% ========== VISUALIZATION ==========
function exportHoleVisualization(grayImg, gloveMask, holes, outPath)
% Creates a 2x2 panel showing:
%   [1] Original grayscale
%   [2] Glove mask
%   [3] Detected holes
%   [4] Holes overlaid on glove

f = figure("Visible", "off", "Position", [0 0 800 800]);
t = tiledlayout(2, 2, "TileSpacing", "compact");

% Panel 1: Grayscale
nexttile; imshow(grayImg); title("Grayscale Image");

% Panel 2: Glove Mask
nexttile; imshow(gloveMask); title("Glove Mask");

% Panel 3: Hole Detection (binary)
holeMask = false(size(grayImg));
for h = 1:numel(holes)
    holeMask(holes(h).pixelIdxList) = true;
end
nexttile; imshow(holeMask); title(sprintf("Detected Holes (n=%d)", numel(holes)));

% Panel 4: Overlay holes on original
nexttile; 
imshow(grayImg);
hold on;
for h = 1:numel(holes)
    holeMaskH = false(size(grayImg));
    holeMaskH(holes(h).pixelIdxList) = true;
    boundaries = bwboundaries(holeMaskH);
    for k = 1:length(boundaries)
        boundary = boundaries{k};
        plot(boundary(:, 2), boundary(:, 1), 'r-', 'LineWidth', 2);
    end
end
hold off;
title(sprintf("Holes Overlaid (n=%d)", numel(holes)));

exportgraphics(t, outPath, "Resolution", 150);
close(f);
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

function n = safeName(s)
n = regexprep(string(s), "\s+", "_");
n = regexprep(n, "[^\w\-]", "");
end
