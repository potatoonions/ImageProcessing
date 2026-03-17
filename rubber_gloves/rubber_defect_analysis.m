function rubber_defect_analysis()
% RUBBER GLOVE DEFECT ANALYSIS - Matches rubberDefectDetectionGUI.m exactly
%
% Defects analyzed (as per assignment requirements):
%   1. Missing Fingers - detected via convex hull differences
%   2. Thin Material - detected via bright/translucent spots
%   3. Torn - detected via dark elongated regions (tears/rips)
%
% Evaluation Method: Per-detector evaluation (matches GUI workflow)
% - User uploads image and selects ONE detector to run
% - Each detector evaluated only on its target class + Normal images
% - This reflects actual GUI usage where user chooses which defect to check

    clc;

    DATASET_DIR = fullfile(fileparts(pwd), "logs", "gloves_dataset");
    GLOVE_TYPE = "Rubber gloves";
    % Assignment-required defect types matching dataset folders
    DEFECT_TYPES = ["Missing Fingers", "Thin Material", "Torn"];
    NORMAL_TYPE = "Normal";

    OUT_LOGS = fullfile(pwd, "logs");
    IMG_EXTS = [".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp"];

    fprintf("\n========== INITIALIZING DIRECTORIES ==========\n");
    for defectType = DEFECT_TYPES
        detDir = fullfile(OUT_LOGS, "rubber_detection", GLOVE_TYPE, defectType);
        if ~isfolder(detDir), mkdir(detDir); end
    end
    fprintf("✓ Output directories created\n");

    fprintf("\n========== STEP 1: PROCESSING IMAGES ==========\n");

    statsRows = {};
    detectionResults = {};
    
    % Track per-detector metrics
    missingTP = 0; missingFP = 0; missingFN = 0; missingTN = 0;
    thinTP = 0; thinFP = 0; thinFN = 0; thinTN = 0;
    tornTP = 0; tornFP = 0; tornFN = 0; tornTN = 0;

    % ===== MISSING FINGERS DETECTOR EVALUATION =====
    % Test on Missing Fingers images (should detect) + Normal images (should not detect)
    fprintf("\n--- Evaluating Missing Fingers Detector ---\n");
    
    % Process Missing Fingers images (positive cases)
    folderPath = fullfile(DATASET_DIR, GLOVE_TYPE, "Missing Fingers");
    if isfolder(folderPath)
        imgs = listImages(folderPath, IMG_EXTS);
        fprintf("Processing Missing Fingers: %d images\n", numel(imgs));
        
        for i = 1:numel(imgs)
            [~, baseName, ~] = fileparts(imgs(i));
            img = imread(imgs(i));
            if size(img, 3) == 1, img = repmat(img, 1, 1, 3); end
            img = imresize(img, [400 400]);
            
            missingOverlay = rubberMissingDigitsDetection(img);
            missingDetected = ~isempty(missingOverlay) && any(missingOverlay(:) > 0);
            
            if missingDetected
                missingTP = missingTP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Missing Fingers', baseName, "detected", "TP"};
            else
                missingFN = missingFN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Missing Fingers', baseName, "not_detected", "FN"};
            end
            statsRows(end+1,:) = {char(GLOVE_TYPE), 'Missing Fingers', baseName, ternary(missingDetected, 'detected', 'not_detected')};
        end
    end
    
    % Process Normal images (negative cases for Missing Fingers)
    folderPath = fullfile(DATASET_DIR, GLOVE_TYPE, NORMAL_TYPE);
    if isfolder(folderPath)
        imgs = listImages(folderPath, IMG_EXTS);
        fprintf("Processing Normal (for Missing Fingers eval): %d images\n", numel(imgs));
        
        for i = 1:numel(imgs)
            [~, baseName, ~] = fileparts(imgs(i));
            img = imread(imgs(i));
            if size(img, 3) == 1, img = repmat(img, 1, 1, 3); end
            img = imresize(img, [400 400]);
            
            missingOverlay = rubberMissingDigitsDetection(img);
            missingDetected = ~isempty(missingOverlay) && any(missingOverlay(:) > 0);
            
            if missingDetected
                missingFP = missingFP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Missing Fingers', baseName, "detected", "FP"};
            else
                missingTN = missingTN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Missing Fingers', baseName, "not_detected", "TN"};
            end
        end
    end
    
    % ===== THIN MATERIAL DETECTOR EVALUATION =====
    % Test on Thin Material images (should detect) + Normal images (should not detect)
    fprintf("\n--- Evaluating Thin Material Detector ---\n");
    
    % Process Thin Material images (positive cases)
    folderPath = fullfile(DATASET_DIR, GLOVE_TYPE, "Thin Material");
    if isfolder(folderPath)
        imgs = listImages(folderPath, IMG_EXTS);
        fprintf("Processing Thin Material: %d images\n", numel(imgs));
        
        for i = 1:numel(imgs)
            [~, baseName, ~] = fileparts(imgs(i));
            img = imread(imgs(i));
            if size(img, 3) == 1, img = repmat(img, 1, 1, 3); end
            img = imresize(img, [400 400]);
            
            thinOverlay = rubberThinMaterialDetection(img);
            thinDetected = ~isempty(thinOverlay) && any(thinOverlay(:) > 0);
            
            if thinDetected
                thinTP = thinTP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Thin Material', baseName, "detected", "TP"};
            else
                thinFN = thinFN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Thin Material', baseName, "not_detected", "FN"};
            end
            statsRows(end+1,:) = {char(GLOVE_TYPE), 'Thin Material', baseName, ternary(thinDetected, 'detected', 'not_detected')};
        end
    end
    
    % Process Normal images (negative cases for Thin Material)
    folderPath = fullfile(DATASET_DIR, GLOVE_TYPE, NORMAL_TYPE);
    if isfolder(folderPath)
        imgs = listImages(folderPath, IMG_EXTS);
        fprintf("Processing Normal (for Thin Material eval): %d images\n", numel(imgs));
        
        for i = 1:numel(imgs)
            [~, baseName, ~] = fileparts(imgs(i));
            img = imread(imgs(i));
            if size(img, 3) == 1, img = repmat(img, 1, 1, 3); end
            img = imresize(img, [400 400]);
            
            thinOverlay = rubberThinMaterialDetection(img);
            thinDetected = ~isempty(thinOverlay) && any(thinOverlay(:) > 0);
            
            if thinDetected
                thinFP = thinFP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Thin Material', baseName, "detected", "FP"};
            else
                thinTN = thinTN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Thin Material', baseName, "not_detected", "TN"};
            end
        end
    end
    
    % ===== TORN DETECTOR EVALUATION =====
    % Test on Torn images (should detect) + Normal images (should not detect)
    fprintf("\n--- Evaluating Torn Detector ---\n");
    
    % Process Torn images (positive cases)
    folderPath = fullfile(DATASET_DIR, GLOVE_TYPE, "Torn");
    if isfolder(folderPath)
        imgs = listImages(folderPath, IMG_EXTS);
        fprintf("Processing Torn: %d images\n", numel(imgs));
        
        for i = 1:numel(imgs)
            [~, baseName, ~] = fileparts(imgs(i));
            img = imread(imgs(i));
            if size(img, 3) == 1, img = repmat(img, 1, 1, 3); end
            img = imresize(img, [400 400]);
            
            tornOverlay = rubberTearDetection(img);
            tornDetected = ~isempty(tornOverlay) && any(tornOverlay(:) > 0);
            
            if tornDetected
                tornTP = tornTP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Torn', baseName, "detected", "TP"};
            else
                tornFN = tornFN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Torn', baseName, "not_detected", "FN"};
            end
            statsRows(end+1,:) = {char(GLOVE_TYPE), 'Torn', baseName, ternary(tornDetected, 'detected', 'not_detected')};
        end
    end
    
    % Process Normal images (negative cases for Torn)
    folderPath = fullfile(DATASET_DIR, GLOVE_TYPE, NORMAL_TYPE);
    if isfolder(folderPath)
        imgs = listImages(folderPath, IMG_EXTS);
        fprintf("Processing Normal (for Torn eval): %d images\n", numel(imgs));
        
        for i = 1:numel(imgs)
            [~, baseName, ~] = fileparts(imgs(i));
            img = imread(imgs(i));
            if size(img, 3) == 1, img = repmat(img, 1, 1, 3); end
            img = imresize(img, [400 400]);
            
            tornOverlay = rubberTearDetection(img);
            tornDetected = ~isempty(tornOverlay) && any(tornOverlay(:) > 0);
            
            if tornDetected
                tornFP = tornFP + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Torn', baseName, "detected", "FP"};
            else
                tornTN = tornTN + 1;
                detectionResults(end+1,:) = {char(GLOVE_TYPE), 'Torn', baseName, "not_detected", "TN"};
            end
        end
    end

    fprintf("\n✓ Processing completed\n");

    fprintf("\n========== STEP 2: SAVING RESULTS ==========\n");
    T = cell2table(statsRows);
    T.Properties.VariableNames = {'glove_type', 'defect_type', 'image_name', 'result'};
    writetable(T, fullfile(OUT_LOGS, "rubber_detection", GLOVE_TYPE, "detection_results.csv"));
    fprintf("✓ Detection results saved\n");
    
    T_details = cell2table(detectionResults);
    T_details.Properties.VariableNames = {'glove_type', 'detector', 'image_name', 'result', 'outcome'};
    writetable(T_details, fullfile(OUT_LOGS, "rubber_detection", GLOVE_TYPE, "detection_details.csv"));
    fprintf("✓ Detection details saved\n");

    fprintf("\n========== ACCURACY EVALUATION ==========\n");
    
    % Calculate per-detector accuracy
    missingTotal = missingTP + missingTN + missingFP + missingFN;
    thinTotal = thinTP + thinTN + thinFP + thinFN;
    tornTotal = tornTP + tornTN + tornFP + tornFN;
    
    missingAccuracy = (missingTP + missingTN) / missingTotal * 100;
    thinAccuracy = (thinTP + thinTN) / thinTotal * 100;
    tornAccuracy = (tornTP + tornTN) / tornTotal * 100;
    
    fprintf("\n--- Per-Detector Performance ---\n");
    fprintf("Missing Fingers: %d TP, %d TN, %d FP, %d FN = %.2f%% accuracy (%d images)\n", ...
        missingTP, missingTN, missingFP, missingFN, missingAccuracy, missingTotal);
    fprintf("Thin Material:   %d TP, %d TN, %d FP, %d FN = %.2f%% accuracy (%d images)\n", ...
        thinTP, thinTN, thinFP, thinFN, thinAccuracy, thinTotal);
    fprintf("Torn:            %d TP, %d TN, %d FP, %d FN = %.2f%% accuracy (%d images)\n", ...
        tornTP, tornTN, tornFP, tornFN, tornAccuracy, tornTotal);
    
    % Overall accuracy (all detectors combined)
    totalTP = missingTP + thinTP + tornTP;
    totalTN = missingTN + thinTN + tornTN;
    totalFP = missingFP + thinFP + tornFP;
    totalFN = missingFN + thinFN + tornFN;
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
    fprintf("Total Evaluations: %d (defect + normal images × 3 detectors)\n", totalImages);
    fprintf("True Positives (TP): %d\n", totalTP);
    fprintf("True Negatives (TN): %d\n", totalTN);
    fprintf("False Positives (FP): %d\n", totalFP);
    fprintf("False Negatives (FN): %d\n", totalFN);
    fprintf("\n");
    fprintf("Overall Accuracy: %.2f%%\n", overallAccuracy);
    fprintf("Precision: %.2f%%\n", precision);
    fprintf("Recall: %.2f%%\n", recall);
    fprintf("F1-Score: %.2f%%\n", f1Score);

    accuracyFile = fullfile(OUT_LOGS, "rubber_detection", GLOVE_TYPE, "accuracy_summary.csv");
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
    fprintf("  - logs/rubber_detection/Rubber gloves/\n");
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

function result = ternary(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
