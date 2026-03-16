function member3_nitrile_defect_analysis(subsetSize)
    if nargin < 1 || isempty(subsetSize)
        subsetSize = Inf;
    end
    
    clc;
    
    set(0, 'DefaultFigureVisible', 'off');
    
    DATASET_DIR = fullfile(fileparts(pwd), "logs", "gloves_dataset");
    GLOVE_TYPE = "Nitrile gloves";
    DEFECT_TYPES = ["inside out", "improper roll", "not worn"];
    
    OUT_PROC = fullfile(pwd, "processed");
    OUT_LOGS = fullfile(pwd, "logs");
    
    TARGET_SIZE = [256 256];
    GAUSS_SIGMA = 1.0;
    MED_WIN = [3 3];
    MIN_BLOB_AREA = 800;
    CLOSE_RADIUS = 7;
    
    NOT_WORN_MIN_BOUNDARIES = 1;
    IMPROPER_ROLL_CONVEXITY_THRESHOLD = 0.93;
    INSIDE_OUT_PERIMETER_RATIO_THRESHOLD = 4.5;
    
    MIN_DEFECT_AREA = 100;
    MAX_DEFECT_AREA = 8000;
    MORPH_RADIUS = 3;
    
    IMG_EXTS = [".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp"];
    
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
    
    truePositives = 0;
    falsePositives = 0;
    trueNegatives = 0;
    falseNegatives = 0;
    
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
            
            gauss = imgaussfilt(im2double(gray), GAUSS_SIGMA);
            med = medfilt2(im2double(gray), MED_WIN);
            
            S = hsv01(:,:,2);
            mask = imbinarize(S, graythresh(S));
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
            
            isDefectType = 0;
            if strcmpi(defectType, "not worn")
                isDefectType = 1;
            elseif strcmpi(defectType, "improper roll")
                isDefectType = 1;
            elseif strcmpi(defectType, "inside out")
                isDefectType = 1;
            end
            
            if notworn.detected
                if isDefectType
                    truePositives = truePositives + 1;
                else
                    falsePositives = falsePositives + 1;
                end
                notwornStats(end+1,:) = {char(defectType), baseName, notworn.boundaryCount, ...
                    notworn.convexity, notworn.perimeterAreaRatio, "TP"};
            else
                if isDefectType
                    falseNegatives = falseNegatives + 1;
                else
                    trueNegatives = trueNegatives + 1;
                end
                notwornStats(end+1,:) = {char(defectType), baseName, notworn.boundaryCount, ...
                    notworn.convexity, notworn.perimeterAreaRatio, "TN"};
            end
            
            improperroll = detectImproperRoll(grayImg, gloveMask, IMPROPER_ROLL_CONVEXITY_THRESHOLD, ...
                MORPH_RADIUS, MIN_DEFECT_AREA, MAX_DEFECT_AREA);
            if improperroll.detected
                features = extractFeatures(grayImg, improperroll.regions);
                for r = 1:numel(improperroll.regions)
                    F = features(r);
                    if strcmpi(defectType, "improper roll")
                        truePositives = truePositives + 1;
                    else
                        falsePositives = falsePositives + 1;
                    end
                    improperrollStats(end+1,:) = {char(defectType), baseName, r, F.area, F.perimeter, ...
                        F.solidity, F.eccentricity, F.meanIntensity, "TP"};
                end
            else
                if strcmpi(defectType, "improper roll")
                    falseNegatives = falseNegatives + 1;
                else
                    trueNegatives = trueNegatives + 1;
                end
            end
            
            insideout = detectInsideOut(grayImg, gloveMask, INSIDE_OUT_PERIMETER_RATIO_THRESHOLD, ...
                MORPH_RADIUS, MIN_DEFECT_AREA, MAX_DEFECT_AREA);
            if insideout.detected
                features = extractFeatures(grayImg, insideout.regions);
                for r = 1:numel(insideout.regions)
                    F = features(r);
                    if strcmpi(defectType, "inside out")
                        truePositives = truePositives + 1;
                    else
                        falsePositives = falsePositives + 1;
                    end
                    insideoutStats(end+1,:) = {char(defectType), baseName, r, F.area, F.perimeter, ...
                        F.solidity, F.eccentricity, F.meanIntensity, "TP"};
                end
            else
                if strcmpi(defectType, "inside out")
                    falseNegatives = falseNegatives + 1;
                else
                    trueNegatives = trueNegatives + 1;
                end
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
            ["image_class", "image_name", "boundary_count", "convexity", "perimeter_area_ratio", "result"]);
        writetable(T_notworn, fullfile(OUT_LOGS, "notworn_detection_stats.csv"));
        fprintf("✓ Not worn detection statistics saved\n");
    end
    
    if ~isempty(improperrollStats)
        T_improper = cell2table(improperrollStats, "VariableNames", ...
            ["image_class", "image_name", "region_id", "area_px", "perimeter_px", ...
             "solidity", "eccentricity", "mean_intensity", "result"]);
        writetable(T_improper, fullfile(OUT_LOGS, "improperroll_detection_stats.csv"));
        fprintf("✓ Improper roll detection statistics saved\n");
    end
    
    if ~isempty(insideoutStats)
        T_insideout = cell2table(insideoutStats, "VariableNames", ...
            ["image_class", "image_name", "region_id", "area_px", "perimeter_px", ...
             "solidity", "eccentricity", "mean_intensity", "result"]);
        writetable(T_insideout, fullfile(OUT_LOGS, "insideout_detection_stats.csv"));
        fprintf("✓ Inside out detection statistics saved\n");
    end
    
    fprintf("\n========== ACCURACY EVALUATION ==========\n");
    totalImages = truePositives + falsePositives + trueNegatives + falseNegatives;
    
    if totalImages > 0
        accuracy = (truePositives + trueNegatives) / totalImages * 100;
        if (truePositives + falsePositives) > 0
            precision = truePositives / (truePositives + falsePositives) * 100;
        else
            precision = 0;
        end
        if (truePositives + falseNegatives) > 0
            recall = truePositives / (truePositives + falseNegatives) * 100;
        else
            recall = 0;
        end
        if (precision + recall) > 0
            f1Score = 2 * (precision * recall) / (precision + recall);
        else
            f1Score = 0;
        end
        
        fprintf("Total Images: %d\n", totalImages);
        fprintf("True Positives (TP): %d\n", truePositives);
        fprintf("False Positives (FP): %d\n", falsePositives);
        fprintf("True Negatives (TN): %d\n", trueNegatives);
        fprintf("False Negatives (FN): %d\n", falseNegatives);
        fprintf("\n");
        fprintf("Overall Accuracy: %.2f%%\n", accuracy);
        fprintf("Precision: %.2f%%\n", precision);
        fprintf("Recall: %.2f%%\n", recall);
        fprintf("F1-Score: %.2f%%\n", f1Score);
        
        accuracyFile = fullfile(OUT_LOGS, "accuracy_summary.csv");
        T_accuracy = table(totalImages, truePositives, falsePositives, trueNegatives, falseNegatives, ...
                     accuracy, precision, recall, f1Score, ...
                     'VariableNames', ["total_images", "true_positives", "false_positives", ...
                         "true_negatives", "false_negatives", "accuracy_pct", ...
                         "precision_pct", "recall_pct", "f1_score"]);
        writetable(T_accuracy, accuracyFile);
        fprintf("\n✓ Accuracy summary saved to: %s\n", accuracyFile);
        
        if accuracy >= 90
            fprintf("\n🎉 Target accuracy achieved: %.2f%%\n", accuracy);
        else
            fprintf("\n⚠ Accuracy below target: %.2f%% (target: 90%%)\n", accuracy);
        end
    else
        fprintf("⚠ No images processed, skipping accuracy calculation\n");
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
    m = bwareaopen(m, minArea);
    m = imclose(m, strel("disk", r));
    cc = bwconncomp(m);
    if cc.NumObjects < 1, return; end
    [~, idx] = max(cellfun(@numel, cc.PixelIdxList));
    tmp = false(size(m));
    tmp(cc.PixelIdxList{idx}) = true;
    m = tmp;
end

function result = detectNotWorn(grayImg, gloveMask, minBoundaries)
    result.detected = false;
    result.boundaryCount = 0;
    result.convexity = 0;
    result.perimeterAreaRatio = 0;
    
    boundaries = bwboundaries(gloveMask);
    result.boundaryCount = numel(boundaries);
    
    if result.boundaryCount < minBoundaries
        result.detected = true;
        
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
    end
end

function result = detectImproperRoll(grayImg, gloveMask, convexityThreshold, morphRad, minArea, maxArea)
    result.detected = false;
    result.regions = [];
    
    boundaries = bwboundaries(gloveMask);
    if isempty(boundaries), return; end
    boundary = boundaries{1};
    gloveArea = sum(gloveMask(:));
    glovePerimeter = sum(sqrt(sum(diff([boundary; boundary(1,:)]).^2, 2)));
    
    if gloveArea > 0
        convexHull = bwconvhull(gloveMask);
        hullArea = sum(convexHull(:));
        
        if hullArea > 0
            convexity = gloveArea / hullArea;
        else
            convexity = 0;
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
    
    boundaries = bwboundaries(gloveMask);
    
    if ~isempty(boundaries)
        boundary = boundaries{1};
        glovePerimeter = size(boundary, 1);
    else
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
    
    se = strel("disk", 2);
    cuffMask = imopen(cuffMask, se);
    cuffMask = imclose(cuffMask, se);
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
