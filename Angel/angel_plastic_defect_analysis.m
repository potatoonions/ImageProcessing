function angel_plastic_defect_analysis()
    clc;
    
    DATASET_DIR = fullfile(fileparts(pwd), "logs", "gloves_dataset");
    GLOVE_TYPE = "Plastic gloves";
    DEFECT_TYPES = ["blood", "burn", "discolouration", "oversized", "plastic"];
    
    OUT_LOGS = fullfile(pwd, "logs");
    IMG_EXTS = [".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp"];
    
    fprintf("\n========== INITIALIZING DIRECTORIES ==========\n");
    for defectType = DEFECT_TYPES
        detDir = fullfile(OUT_LOGS, "angel_detection", GLOVE_TYPE, defectType);
        if ~isfolder(detDir), mkdir(detDir); end
    end
    fprintf("✓ Output directories created\n");
    
    fprintf("\n========== STEP 1: PREPROCESSING ==========\n");
    
    statsRows = {};
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
        fprintf("Processing %s: %d images\n", defectType, numel(imgs));
        
        for i = 1:numel(imgs)
            [~, baseName, ~] = fileparts(imgs(i));
            img = imread(imgs(i));
            
            if size(img, 3) == 1
                img = repmat(img, 1, 1, 3);
            end
            
            originalImg = img;
            
            switch char(defectType)
                case 'blood'
                    overlay = plasticBloodDetection(img);
                    expectedDetector = 'blood';
                case 'burn'
                    overlay = plasticDefectDetection(img);
                    expectedDetector = 'burn';
                case 'discolouration'
                    overlay = plasticDiscolourationDetection(img);
                    expectedDetector = 'discolouration';
                case 'oversized'
                    overlay = zeros(size(img, 1), size(img, 2), 4, 'uint8');
                    expectedDetector = 'oversized';
                case 'plastic'
                    overlay = plasticDefectDetection(img);
                    expectedDetector = 'plastic';
            end
            
            defectDetected = any(overlay(:) ~= 0);
            
            if defectDetected && strcmpi(expectedDetector, char(defectType))
                truePositives = truePositives + 1;
            elseif defectDetected && ~strcmpi(expectedDetector, char(defectType))
                falsePositives = falsePositives + 1;
            elseif ~defectDetected && strcmpi(expectedDetector, char(defectType))
                falseNegatives = falseNegatives + 1;
            else
                trueNegatives = trueNegatives + 1;
            end
            
            statsRows(end+1,:) = {char(GLOVE_TYPE), char(defectType), baseName, char(defectType)};
        end
    end
    
    fprintf("\n✓ Preprocessing completed\n");
    
    fprintf("\n========== STEP 2: SAVING RESULTS ==========\n");
    T = cell2table(statsRows, "VariableNames", ["glove_type", "true_defect_type", "image_name", "detected_defect"]);
    writetable(T, fullfile(OUT_LOGS, "angel_detection", GLOVE_TYPE, "detection_results.csv"));
    fprintf("✓ Detection results saved\n");
    
    fprintf("\n========== STEP 3: ACCURACY EVALUATION ==========\n");
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
        
        accuracyFile = fullfile(OUT_LOGS, "angel_detection", GLOVE_TYPE, "accuracy_summary.csv");
        T_accuracy = table(totalImages, truePositives, falsePositives, trueNegatives, falseNegatives, ...
                     accuracy, precision, recall, f1Score, ...
                     'VariableNames', ["total_images", "true_positives", "false_positives", ...
                         "true_negatives", "false_negatives", "accuracy_pct", "precision_pct", "recall_pct", "f1_score"]);
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
    fprintf("Output directories:\n");
    fprintf("  - logs/angel_detection/Plastic gloves/\n");
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
