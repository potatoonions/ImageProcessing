function member3_nitrile_defect_analysis(subsetSize)
    if nargin < 1 || isempty(subsetSize)
        subsetSize = Inf;
    end
    
    clc;
    
    DATASET_DIR = fullfile(fileparts(pwd), "logs", "gloves_dataset");
    GLOVE_TYPE = "Nitrile gloves";
    DEFECT_TYPES = ["Normal", "inside out", "improper roll", "not worn"];
    
    OUT_PROC = fullfile(pwd, "processed");
    OUT_LOGS = fullfile(pwd, "logs");
    
    TARGET_SIZE = [256 256];
    GAUSS_SIGMA = 1.0;
    MED_WIN = [3 3];
    MIN_BLOB_AREA = 500;
    CLOSE_RADIUS = 5;
    IMG_EXTS = [".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp"];
    
    NOT_WORN_MIN_BOUNDARIES = 2;
    IMPROPER_ROLL_CONVEXITY_THRESHOLD = 0.82;
    INSIDE_OUT_PERIMETER_RATIO_THRESHOLD = 3.5;
    
    MIN_DEFECT_AREA = 100;
    MAX_DEFECT_AREA = 8000;
    MORPH_RADIUS = 3;
    
    fprintf("\n========== INITIALIZING DIRECTORIES ==========\n");
    
    if ~isfolder(OUT_PROC), mkdir(OUT_PROC); end
    if ~isfolder(OUT_LOGS), mkdir(OUT_LOGS); end
    
    procSubs = ["resized", "gray", "filtered_gaussian", "filtered_median", ...
                "masks", "isolated"];
    for s = procSubs
        p = fullfile(OUT_PROC, s);
        if ~isfolder(p), mkdir(p); end
        if ~isfolder(fullfile(p, GLOVE_TYPE))
            mkdir(fullfile(p, GLOVE_TYPE));
        end
    end
    
    for defectType = DEFECT_TYPES
        for detMethod = ["notworn_detection", "improperroll_detection", "insideout_detection"]
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
        numToProcess = min(numel(imgs), subsetSize);
        fprintf("Processing %s: %d images (limited from %d total)\n", defectType, numToProcess, numel(imgs));
        
        for i = 1:numToProcess
            I = imread(imgs(i));
            if ~isa(I, 'uint8')
                I = im2uint8(I);
            end
            I = imresize(I, TARGET_SIZE);
            
            if size(I, 3) == 3
                gray = rgb2gray(I);
                hsv01 = rgb2hsv(I);
            else
                gray = I;
                hsv01 = rgb2hsv(repmat(I, [1 1 3]));
            end
            
            try
                gauss = im2uint8(imgaussfilt(im2double(gray), GAUSS_SIGMA));
            catch
                gauss = gray;
            end
            
            try
                med = im2uint8(medfilt2(im2double(gray), MED_WIN));
            catch
                med = gray;
            end
            
            S = hsv01(:,:,2);
            try
                mask = imbinarize(S, graythresh(S));
            catch
                thresh = 0.3;
                mask = S > thresh;
            end
            mask = cleanMask(mask, MIN_BLOB_AREA, CLOSE_RADIUS);
            
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
            
            saveP(OUT_PROC, "resized", relDir, baseName, I);
            saveP(OUT_PROC, "gray", relDir, baseName, gray);
            saveP(OUT_PROC, "filtered_gaussian", relDir, baseName, gauss);
            saveP(OUT_PROC, "filtered_median", relDir, baseName, med);
            if isa(mask, 'logical')
                mask = uint8(mask * 255);
            else
                mask = im2uint8(mask);
            end
            saveP(OUT_PROC, "masks", relDir, baseName, mask);
            saveP(OUT_PROC, "isolated", relDir, baseName, isolated);
            
            statsRows(end+1,:) = {char(GLOVE_TYPE), char(defectType), baseName};
        end
    end
    
    fprintf("✓ Preprocessing completed\n");
    
    fprintf("\n========== STEP 2: DEFECT DETECTION ==========\n");
    
    notwornStats = {};
    improperrollStats = {};
    insideoutStats = {};
    
    for defectType = DEFECT_TYPES
        grayDir = fullfile(OUT_PROC, "gray", GLOVE_TYPE, defectType);
        maskDir = fullfile(OUT_PROC, "masks", GLOVE_TYPE, defectType);
        
        if ~isfolder(grayDir), continue; end
        
        imgs = listImages(grayDir, [".png"]);
        numToDetect = min(numel(imgs), subsetSize);
        fprintf("Detecting defects in %s images (processing %d of %d)\n", defectType, numToDetect, numel(imgs));
        
        for i = 1:numToDetect
            [~, baseName, ~] = fileparts(imgs(i));
            grayImg = imread(imgs(i));
            maskFile = fullfile(maskDir, baseName + ".png");
            
            if ~isfile(maskFile), continue; end
            gloveMask = imread(maskFile) > 128;
            
            notworn = detectNotWorn(grayImg, gloveMask, NOT_WORN_MIN_BOUNDARIES);
            if notworn.detected
                notwornStats(end+1,:) = {char(defectType), baseName, notworn.boundaryCount, ...
                    notworn.convexity, notworn.perimeterAreaRatio};
                exportVisualization(grayImg, gloveMask, notworn, "Not Worn", ...
                    fullfile(OUT_LOGS, "notworn_detection", GLOVE_TYPE, defectType, ...
                        sprintf("%s_notworn.png", baseName)));
            end
            
            improperroll = detectImproperRoll(grayImg, gloveMask, IMPROPER_ROLL_CONVEXITY_THRESHOLD, ...
                MORPH_RADIUS, MIN_DEFECT_AREA, MAX_DEFECT_AREA);
            if improperroll.detected
                features = extractFeatures(grayImg, improperroll.regions);
                for r = 1:numel(improperroll.regions)
                    F = features(r);
                    improperrollStats(end+1,:) = {char(defectType), baseName, r, F.area, F.perimeter, ...
                        F.solidity, F.eccentricity, F.meanIntensity};
                end
                exportVisualization(grayImg, gloveMask, improperroll.regions, "Improper Roll", ...
                    fullfile(OUT_LOGS, "improperroll_detection", GLOVE_TYPE, defectType, ...
                        sprintf("%s_improperroll.png", baseName)));
            end
            
            insideout = detectInsideOut(grayImg, gloveMask, INSIDE_OUT_PERIMETER_RATIO_THRESHOLD, ...
                MORPH_RADIUS, MIN_DEFECT_AREA, MAX_DEFECT_AREA);
            if insideout.detected
                features = extractFeatures(grayImg, insideout.regions);
                for r = 1:numel(insideout.regions)
                    F = features(r);
                    insideoutStats(end+1,:) = {char(defectType), baseName, r, F.area, F.perimeter, ...
                        F.solidity, F.eccentricity, F.meanIntensity};
                end
                exportVisualization(grayImg, gloveMask, insideout.regions, "Inside Out", ...
                    fullfile(OUT_LOGS, "insideout_detection", GLOVE_TYPE, defectType, ...
                        sprintf("%s_insideout.png", baseName)));
            end
        end
    end
    
    fprintf("✓ Defect detection completed\n");
    
    fprintf("\n========== STEP 3: SAVING RESULTS ==========\n");
    
    if ~isempty(statsRows)
        T = cell2table(statsRows, "VariableNames", ["glove_type", "defect_type", "image_name"]);
        writetable(T, fullfile(OUT_LOGS, "dataset_stats.csv"));
        fprintf("✓ Dataset statistics saved\n");
    else
        fprintf("⚠ No images processed, skipping dataset statistics\n");
    end
    
    if ~isempty(notwornStats)
        T_notworn = cell2table(notwornStats, "VariableNames", ...
            ["image_class", "image_name", "boundary_count", "convexity", "perimeter_area_ratio"]);
        writetable(T_notworn, fullfile(OUT_LOGS, "notworn_detection_stats.csv"));
        fprintf("✓ Not worn detection statistics saved\n");
    end
    
    if ~isempty(improperrollStats)
        T_improper = cell2table(improperrollStats, "VariableNames", ...
            ["image_class", "image_name", "region_id", "area_px", "perimeter_px", ...
             "solidity", "eccentricity", "mean_intensity"]);
        writetable(T_improper, fullfile(OUT_LOGS, "improperroll_detection_stats.csv"));
        fprintf("✓ Improper roll detection statistics saved\n");
    end
    
    if ~isempty(insideoutStats)
        T_insideout = cell2table(insideoutStats, "VariableNames", ...
            ["image_class", "image_name", "region_id", "area_px", "perimeter_px", ...
             "solidity", "eccentricity", "mean_intensity"]);
        writetable(T_insideout, fullfile(OUT_LOGS, "insideout_detection_stats.csv"));
        fprintf("✓ Inside out detection statistics saved\n");
    end
    
    fprintf("\n========== PIPELINE COMPLETE ==========\n");
end

function imgs = listImages(folderPath, exts)
    d = dir(folderPath);
    imgs = strings(0);
    for k = 1:numel(d)
        if d(k).isdir, continue; end
        [~, ~, e] = fileparts(d(k).name);
        if any(strcmpi(exts, string(e)))
            imgs(end+1) = fullfile(folderPath, d(k).name);
        end
    end
end

function saveP(root, sub, rel, name, I)
    outDir = fullfile(root, sub, rel);
    if ~isfolder(outDir), mkdir(outDir); end
    imwrite(I, fullfile(outDir, name + ".png"));
end

function m = cleanMask(m, minArea, r)
    try
        m = bwareaopen(m, minArea);
    catch
        m = m;
    end
    
    try
        m = imclose(m, strel("disk", r));
    catch
        try
            se = ones(r*2+1, r*2+1);
            m = imerode(m, se);
            m = imdilate(m, se);
        catch
            m = m;
        end
    end
    
    try
        cc = bwconncomp(m);
        if cc.NumObjects < 1, return; end
        [~, idx] = max(cellfun(@numel, cc.PixelIdxList));
        tmp = false(size(m));
        tmp(cc.PixelIdxList{idx}) = true;
        m = tmp;
    catch
        m = m;
    end
end

function result = detectNotWorn(grayImg, gloveMask, minBoundaries)
    result.detected = false;
    result.boundaryCount = 0;
    result.convexity = 0;
    result.perimeterAreaRatio = 0;
    
    try
        boundaries = bwboundaries(gloveMask);
        result.boundaryCount = numel(boundaries);
    catch
        result.boundaryCount = 1;
    end
    
    if result.boundaryCount < minBoundaries
        result.detected = true;
        
        try
            props = regionprops(gloveMask, "Area", "Perimeter", "Solidity");
            if ~isempty(props)
                area = props.Area;
                perimeter = props.Perimeter;
                convexity = props.Solidity;
                
                if area > 0
                    perimeterAreaRatio = perimeter / sqrt(area);
                else
                    perimeterAreaRatio = 0;
                end
                
                result.convexity = convexity;
                result.perimeterAreaRatio = perimeterAreaRatio;
            end
        catch
            result.convexity = 0;
            result.perimeterAreaRatio = 0;
        end
    end
end

function result = detectImproperRoll(grayImg, gloveMask, convexityThreshold, morphRad, minArea, maxArea)
    result.detected = false;
    result.regions = [];
    
    try
        boundaries = bwboundaries(gloveMask);
        if isempty(boundaries), return; end
        boundary = boundaries{1};
        gloveArea = sum(gloveMask(:));
        glovePerimeter = sum(sqrt(sum(diff([boundary; boundary(1,:)]).^2, 2)));
    catch
        gloveArea = sum(gloveMask(:));
        glovePerimeter = 0;
    end
    
    if gloveArea > 0
        try
            convexHull = bwconvhull(gloveMask);
            hullArea = sum(convexHull(:));
            
            if hullArea > 0
                convexity = gloveArea / hullArea;
            else
                convexity = 0;
            end
        catch
            convexity = 1;
        end
        
        if convexity < convexityThreshold
            cuffMask = extractCuffRegion(gloveMask);
            if sum(cuffMask(:)) >= minArea && sum(cuffMask(:)) <= maxArea
                defect.pixelIdxList = find(cuffMask);
                defect.area = sum(cuffMask(:));
                defect.centroid = regionprops(cuffMask, "Centroid").Centroid;
                defect.bbox = regionprops(cuffMask, "BoundingBox").BoundingBox;
                defect.aspectRatio = defect.bbox(3) / max(defect.bbox(4), 1);
                result.regions = [result.regions; defect];
                result.detected = true;
            end
        end
    end
end

function result = detectInsideOut(grayImg, gloveMask, perimeterRatioThreshold, morphRad, minArea, maxArea)
    result.detected = false;
    result.regions = [];
    
    gloveArea = sum(gloveMask(:));
    
    try
        boundaries = bwboundaries(gloveMask);
        
        if ~isempty(boundaries)
            boundary = boundaries{1};
            glovePerimeter = size(boundary, 1);
        else
            glovePerimeter = 0;
        end
    catch
        glovePerimeter = 0;
    end
    
    if gloveArea > 0 && glovePerimeter > 0
        perimeterAreaRatio = glovePerimeter / sqrt(gloveArea);
        
        if perimeterAreaRatio > perimeterRatioThreshold
            defect.pixelIdxList = find(gloveMask);
            defect.area = gloveArea;
            defect.centroid = regionprops(gloveMask, "Centroid").Centroid;
            defect.bbox = regionprops(gloveMask, "BoundingBox").BoundingBox;
            defect.aspectRatio = defect.bbox(3) / max(defect.bbox(4), 1);
            result.regions = [result.regions; defect];
            result.detected = true;
        end
    end
end

function cuffMask = extractCuffRegion(gloveMask)
    [rows, cols] = size(gloveMask);
    cuffHeight = floor(rows * 0.2);
    cuffMask = false(size(gloveMask));
    cuffMask(1:cuffHeight, :) = gloveMask(1:cuffHeight, :);
    
    try
        se = strel("disk", 2);
        cuffMask = imopen(cuffMask, se);
        cuffMask = imclose(cuffMask, se);
    catch
        try
            se = ones(5, 5);
            cuffMask = imerode(cuffMask, se);
            cuffMask = imdilate(cuffMask, se);
            cuffMask = imdilate(cuffMask, se);
            cuffMask = imerode(cuffMask, se);
        catch
            cuffMask = cuffMask;
        end
    end
end

function features = extractFeatures(grayImg, regions)
    features = struct();
    
    for d = 1:numel(regions)
        region = regions(d);
        pixelIdxList = region.pixelIdxList;
        
        regionMask = false(size(grayImg));
        regionMask(pixelIdxList) = true;
        
        props = regionprops(regionMask, "Perimeter", "Solidity", "Eccentricity");
        
        features(d).area = region.area;
        features(d).perimeter = props.Perimeter;
        features(d).solidity = props.Solidity;
        features(d).eccentricity = props.Eccentricity;
        features(d).aspectRatio = region.aspectRatio;
        features(d).bboxWidth = region.bbox(3);
        features(d).bboxHeight = region.bbox(4);
        
        regionIntensities = grayImg(pixelIdxList);
        features(d).meanIntensity = mean(double(regionIntensities));
        features(d).stdIntensity = std(double(regionIntensities));
        features(d).minIntensity = min(regionIntensities);
        features(d).maxIntensity = max(regionIntensities);
    end
end

function exportVisualization(grayImg, gloveMask, data, label, outPath)
    if ~isfolder(fileparts(outPath))
        mkdir(fileparts(outPath));
    end
    
    f = figure("Visible", "off", "Position", [0 0 1000 800]);
    t = tiledlayout(2, 2, "TileSpacing", "compact");
    
    nexttile; imshow(grayImg); title("Grayscale Image");
    
    nexttile; imshow(gloveMask); title("Glove Mask");
    
    nexttile;
    
    if isfield(data, 'regions') && ~isempty(data.regions)
        regionMask = false(size(grayImg));
        for d = 1:numel(data.regions)
            regionMask(data.regions(d).pixelIdxList) = true;
        end
        imshow(regionMask);
        title(sprintf("Detected %s (n=%d)", label, numel(data.regions)));
    else
        imshow(gloveMask);
        title(sprintf("Detected %s", label));
    end
    
    nexttile;
    rgbImg = repmat(grayImg, [1 1 3]);
    imshow(rgbImg);
    hold on;
    
    if isfield(data, 'regions') && ~isempty(data.regions)
        for d = 1:numel(data.regions)
            bbox = data.regions(d).bbox;
            x = bbox(1);
            y = bbox(2);
            w = bbox(3);
            h = bbox(4);
            
            rectangle("Position", [x y w h], "EdgeColor", "red", "LineWidth", 2);
            
            txt = sprintf("D%d", d);
            textX = x + w/2;
            textY = y + h + 15;
            text(textX, textY, txt, "Color", "red", "FontSize", 10, ...
                "HorizontalAlignment", "center", "FontWeight", "bold", ...
                "BackgroundColor", "white");
        end
    else
        text(10, 20, sprintf("%s Detected", label), "Color", "red", "FontSize", 12, ...
            "FontWeight", "bold", "BackgroundColor", "white");
    end
    hold off;
    
    title(sprintf("%s Visualization", label));
    
    exportgraphics(t, outPath, "Resolution", 150);
    close(f);
end


