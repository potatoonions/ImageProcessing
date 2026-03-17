function cloth_defect_analysis(subsetSize)
% CLOTH GLOVE DEFECT ANALYSIS - Independent Detector Evaluation
%
% Defects analyzed (as per assignment requirements):
%   1. Hole - dark punctures/worn areas
%   2. Snags - pulled/snagged fibers  
%   3. Stains - discolored areas
%
% Evaluation Method: Each detector operates independently
% - Each detector is scored separately (TP/TN/FP/FN)
% - Total evaluations = images × 3 detectors
% - This measures each detector's ability to identify its target defect

    if nargin < 1 || isempty(subsetSize)
        subsetSize = Inf;
    end

    clc;
    set(0, 'DefaultFigureVisible', 'off');

    DATASET_DIR = fullfile(fileparts(pwd), "logs", "gloves_dataset");
    GLOVE_TYPE = "cloth gloves";
    DEFECT_TYPES = ["Hole", "Snags", "Stain"];

    OUT_LOGS = fullfile(pwd, "logs");
    IMG_EXTS = [".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp"];

    % Detection parameters - MUST match GUI exactly
    HOLE_MIN_AREA = 400;
    HOLE_MAX_ASPECT_RATIO = 2;
    
    SNAG_MIN_AREA = 150;
    SNAG_MAX_ASPECT_RATIO = 2.25;
    
    STAIN_MIN_AREA = 80;
    STAIN_MAX_ASPECT_RATIO = 2.5;

    fprintf("\n========== INITIALIZING DIRECTORIES ==========\n");
    for defectType = DEFECT_TYPES
        detDir = fullfile(OUT_LOGS, "cloth_detection", GLOVE_TYPE, defectType);
        if ~isfolder(detDir), mkdir(detDir); end
    end
    fprintf("✓ Output directories created\n");

    fprintf("\n========== STEP 1: PROCESSING IMAGES ==========\n");

    statsRows = {};
    detectionResults = {};
    
    % Independent evaluation: track each detector separately
    holeTP = 0; holeTN = 0; holeFP = 0; holeFN = 0;
    snagTP = 0; snagTN = 0; snagFP = 0; snagFN = 0;
    stainTP = 0; stainTN = 0; stainFP = 0; stainFN = 0;

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
            [~, baseName, ~] = fileparts(imgs(i));
            img = imread(imgs(i));
            
            if size(img, 3) == 1
                img = repmat(img, 1, 1, 3);
            end
            img = imresize(img, [400 400]);
            
            gray = rgb2gray(img);
            
            % Create glove mask - same as GUI
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
            
            gloveMask = mask;
            
            % Get glove contour for point-in-polygon testing
            gloveContour = bwboundaries(gloveMask);
            if isempty(gloveContour)
                % No glove found - skip
                statsRows(end+1,:) = {char(GLOVE_TYPE), char(defectType), baseName, "no_glove"};
                continue;
            end
            gloveContourPoly = gloveContour{1};
            
            % Create contour region (dilated - eroded)
            dilatedMask = imdilate(gloveMask, strel('disk', 5));
            erodedMask = imerode(gloveMask, strel('disk', 2));
            contourRegion = dilatedMask & ~erodedMask;
            
            % Calculate glove statistics
            glovePixels = gray(gloveMask);
            mainIntensity = mean(glovePixels);
            
            % ===== HOLE DETECTION (same as GUI) =====
            holePixels = (gray < (mainIntensity - 30)) & contourRegion;
            [holes, holeCount] = analyzeDefects(holePixels, gloveContourPoly, 'hole', HOLE_MIN_AREA, HOLE_MAX_ASPECT_RATIO);
            
            % ===== SNAG DETECTION (same as GUI) =====
            snagPixels = ((gray >= (mainIntensity - 50)) & (gray <= (mainIntensity - 10))) & contourRegion;
            [snags, snagCount] = analyzeDefects(snagPixels, gloveContourPoly, 'snag', SNAG_MIN_AREA, SNAG_MAX_ASPECT_RATIO);
            
            % ===== STAIN DETECTION (same as GUI - multi-approach) =====
            localStd = stdfilt(double(gray), ones(5, 5));
            
            darkStains = (gray < (mainIntensity - 35)) & (localStd > 8) & contourRegion;
            brightStains = (gray > (mainIntensity + 25)) & (localStd > 8) & contourRegion;
            textureStains = (localStd > 10) & (gray > (mainIntensity - 50)) & (gray < (mainIntensity + 30)) & contourRegion;
            faintStains = ((gray >= (mainIntensity - 30)) & (gray <= (mainIntensity - 5))) & contourRegion;
            
            stainPixels = darkStains | brightStains | textureStains | faintStains;
            
            se = strel("disk", 2);
            stainPixels = imopen(stainPixels, se);
            stainPixels = imclose(stainPixels, se);
            
            [stains, stainCount] = analyzeDefects(stainPixels, gloveContourPoly, 'stain', STAIN_MIN_AREA, STAIN_MAX_ASPECT_RATIO);
            
            % ===== INDEPENDENT EVALUATION =====
            % Each detector is scored separately against ground truth
            
            % Ground truth: is this image a hole image?
            isHoleImage = strcmpi(char(defectType), 'Hole');
            holeDetected = holeCount > 0;
            
            if holeDetected && isHoleImage
                holeTP = holeTP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Hole', baseName, "detected", "TP"};
            elseif holeDetected && ~isHoleImage
                holeFP = holeFP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Hole', baseName, "detected", "FP"};
            elseif ~holeDetected && isHoleImage
                holeFN = holeFN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Hole', baseName, "not_detected", "FN"};
            else
                holeTN = holeTN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Hole', baseName, "not_detected", "TN"};
            end
            
            % Ground truth: is this image a snag image?
            isSnagImage = strcmpi(char(defectType), 'Snags');
            snagDetected = snagCount > 0;
            
            if snagDetected && isSnagImage
                snagTP = snagTP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Snag', baseName, "detected", "TP"};
            elseif snagDetected && ~isSnagImage
                snagFP = snagFP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Snag', baseName, "detected", "FP"};
            elseif ~snagDetected && isSnagImage
                snagFN = snagFN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Snag', baseName, "not_detected", "FN"};
            else
                snagTN = snagTN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Snag', baseName, "not_detected", "TN"};
            end
            
            % Ground truth: is this image a stain image?
            isStainImage = strcmpi(char(defectType), 'Stain');
            stainDetected = stainCount > 0;
            
            if stainDetected && isStainImage
                stainTP = stainTP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Stain', baseName, "detected", "TP"};
            elseif stainDetected && ~isStainImage
                stainFP = stainFP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Stain', baseName, "detected", "FP"};
            elseif ~stainDetected && isStainImage
                stainFN = stainFN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Stain', baseName, "not_detected", "FN"};
            else
                stainTN = stainTN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Stain', baseName, "not_detected", "TN"};
            end
            
            statsRows(end+1,:) = {char(GLOVE_TYPE), char(defectType), baseName, ...
                sprintf('H=%d S=%d St=%d', holeCount, snagCount, stainCount)};
        end
    end

    fprintf("✓ Processing completed\n");

    fprintf("\n========== STEP 2: SAVING RESULTS ==========\n");
    
    T = cell2table(statsRows, "VariableNames", ["glove_type", "defect_type", "image_name", "detection_counts"]);
    writetable(T, fullfile(OUT_LOGS, "cloth_detection", GLOVE_TYPE, "detection_results.csv"));
    fprintf("✓ Detection results saved\n");
    
    T_details = cell2table(detectionResults, "VariableNames", ["glove_type", "detector", "image_name", "result", "outcome"]);
    writetable(T_details, fullfile(OUT_LOGS, "cloth_detection", GLOVE_TYPE, "detection_details.csv"));
    fprintf("✓ Detection details saved\n");

    fprintf("\n========== ACCURACY EVALUATION ==========\n");
    
    % Calculate per-detector accuracy
    holeTotal = holeTP + holeTN + holeFP + holeFN;
    snagTotal = snagTP + snagTN + snagFP + snagFN;
    stainTotal = stainTP + stainTN + stainFP + stainFN;
    
    holeAccuracy = (holeTP + holeTN) / holeTotal * 100;
    snagAccuracy = (snagTP + snagTN) / snagTotal * 100;
    stainAccuracy = (stainTP + stainTN) / stainTotal * 100;
    
    fprintf("\n--- Per-Detector Performance ---\n");
    fprintf("Hole Detector:   %d TP, %d TN, %d FP, %d FN = %.2f%% accuracy (%d images)\n", ...
        holeTP, holeTN, holeFP, holeFN, holeAccuracy, holeTotal);
    fprintf("Snag Detector:   %d TP, %d TN, %d FP, %d FN = %.2f%% accuracy (%d images)\n", ...
        snagTP, snagTN, snagFP, snagFN, snagAccuracy, snagTotal);
    fprintf("Stain Detector:  %d TP, %d TN, %d FP, %d FN = %.2f%% accuracy (%d images)\n", ...
        stainTP, stainTN, stainFP, stainFN, stainAccuracy, stainTotal);
    
    % Overall accuracy (all detectors combined)
    totalTP = holeTP + snagTP + stainTP;
    totalTN = holeTN + snagTN + stainTN;
    totalFP = holeFP + snagFP + stainFP;
    totalFN = holeFN + snagFN + stainFN;
    totalImages = totalTP + totalTN + totalFP + totalFN;
    
    overallAccuracy = (totalTP + totalTN) / totalImages * 100;
    
    if totalTP + totalFP > 0
        precision = totalTP / (totalTP + totalFP) * 100;
    else
        precision = 0;
    end
    if totalTP + totalFN > 0
        recall = totalTP / (totalTP + totalFN) * 100;
    else
        recall = 0;
    end
    if precision + recall > 0
        f1Score = 2 * (precision * recall) / (precision + recall);
    else
        f1Score = 0;
    end

    fprintf("\n--- Overall Performance ---\n");
    fprintf("Total Evaluations: %d (37 images × 3 detectors)\n", totalImages);
    fprintf("True Positives (TP): %d\n", totalTP);
    fprintf("True Negatives (TN): %d\n", totalTN);
    fprintf("False Positives (FP): %d\n", totalFP);
    fprintf("False Negatives (FN): %d\n", totalFN);
    fprintf("\n");
    fprintf("Overall Accuracy: %.2f%%\n", overallAccuracy);
    fprintf("Precision: %.2f%%\n", precision);
    fprintf("Recall: %.2f%%\n", recall);
    fprintf("F1-Score: %.2f%%\n", f1Score);

    accuracyFile = fullfile(OUT_LOGS, "cloth_detection", GLOVE_TYPE, "accuracy_summary.csv");
    T_accuracy = table(totalImages, totalTP, totalTN, totalFP, totalFN, ...
                 overallAccuracy, precision, recall, f1Score);
    T_accuracy.Properties.VariableNames = {'total_evaluations', 'true_positives', 'true_negatives', ...
        'false_positives', 'false_negatives', 'accuracy_pct', 'precision_pct', 'recall_pct', 'f1_score'};
    writetable(T_accuracy, accuracyFile);
    fprintf("\n✓ Accuracy summary saved to: %s\n", accuracyFile);

    if overallAccuracy >= 90
        fprintf("\n🎉 Target accuracy achieved: %.2f%%\n", overallAccuracy);
    else
        fprintf("\n⚠ Accuracy below target: %.2f%% (target: 90%%)\n", overallAccuracy);
    end

    fprintf("\n========== PIPELINE COMPLETE ==========\n");
    fprintf("Output directories:\n");
    fprintf("  - logs/cloth_detection/cloth gloves/\n");
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

function [defectsOut, count] = analyzeDefects(defectMap, gloveContour, defectType, minArea, maxAspectRatio)
% Analyze defects using contour analysis - same as GUI
    defectsOut = [];
    count = 0;

    cc = bwconncomp(defectMap);

    for i = 1:cc.NumObjects
        pixelIdxList = cc.PixelIdxList{i};
        area = numel(pixelIdxList);

        if area < minArea
            continue;
        end

        [rows, cols] = ind2sub(size(defectMap), pixelIdxList);
        box = [min(cols), min(rows), max(cols) - min(cols), max(rows) - min(rows)];

        w = box(3);
        h = box(4);
        aspectRatio = w / h;
        if aspectRatio < 1
            aspectRatio = 1 / aspectRatio;
        end

        if aspectRatio > maxAspectRatio
            continue;
        end

        cx = box(1) + w/2;
        cy = box(2) + h/2;

        [dist, ~] = point2curve([cy, cx], gloveContour);
        isWithinGlove = dist <= 0;

        if ~isWithinGlove
            continue;
        end

        count = count + 1;
        defect.type = defectType;
        defect.box = box;
        defect.area = area;
        defect.aspectRatio = aspectRatio;
        defectsOut = [defectsOut; defect];
    end
end

function [distance, location] = point2curve(point, curve)
% Simple point-to-boundary distance - same as GUI
    distances = sqrt((curve(:,1) - point(1)).^2 + (curve(:,2) - point(2)).^2);
    [distance, idx] = min(distances);

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
        distance = -distance;
    end

    location = curve(idx, :);
end
