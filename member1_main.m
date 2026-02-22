function member1_main
% MEMBER 1 - COMPLETE IMAGE PROCESSING PIPELINE
% Data Collection, Preprocessing & Hole Detection
%
% This script executes the complete Member 1 workflow:
%   1. Image preprocessing (resizing, filtering, normalization)
%   2. Hole detection using thresholding + morphological operations
%   3. Feature extraction for holes
%   4. Comprehensive validation testing
%
% Based on:
%   - IPPR Chapter 3: Spatial Filtering (preprocessing)
%   - IPPR Chapter 7: Image Segmentation (thresholding)
%   - IPPR Chapter 8: Morphological Image Processing (hole refinement)
%   - IPPR Chapter 9: Color Image Processing (HSV conversion)
%
% Expected delivery date: 5TH MARCH, 2026

clc; clear;


%% ========== STEP 1: IMAGE PREPROCESSING ==========
disp("STEP 1: Image Preprocessing");
disp("==========================");
disp("Processing images through the preprocessing pipeline:");
disp("  • Image resizing to 256x256");
disp("  • Color space conversion (RGB → Grayscale + HSV)");
disp("  • Noise reduction (Gaussian + Median filtering)");
disp("  • Background removal via HSV saturation thresholding");
disp(" ");

try
    member1_preprocess();
    disp("✓ Preprocessing completed successfully");
    disp(" ");
catch ME
    disp("✗ Preprocessing failed!");
    disp(ME.message);
    return;
end

%% ========== STEP 2: HOLE DETECTION & FEATURE EXTRACTION ==========
disp("STEP 2: Hole Detection & Feature Extraction");
disp("==========================================");
disp("Detecting holes using advanced image analysis:");
disp("  • Thresholding: Identifying dark regions (intensity < 100)");
disp("  • Morphological operations: Noise removal + gap filling");
disp("  • Size filtering: Keeping only valid holes (50-5000 px)");
disp("  • Feature extraction: Geometric + intensity statistics");
disp(" ");

try
    member1_hole_detection();
    disp("✓ Hole detection completed successfully");
    disp(" ");
catch ME
    disp("✗ Hole detection failed!");
    disp(ME.message);
    return;
end

%% ========== STEP 3: COMPREHENSIVE TESTING & VALIDATION ==========
disp("STEP 3: Testing & Validation");
disp("============================");
disp("Running comprehensive validation suite:");
disp("  • Detection metrics (holes per image, area statistics)");
disp("  • Feature distribution analysis");
disp("  • Robustness testing (brightness variations)");
disp(" ");

try
    member1_test_holes();
    disp("✓ Validation completed successfully");
    disp(" ");
catch ME
    disp("✗ Testing failed!");
    disp(ME.message);
    return;
end

%% ========== FINAL SUMMARY ==========

disp("Output Files & Directories:");
disp("  • processed/");
disp("    └─ Preprocessed images (8 subdirectories)");
disp("  • logs/hole_detection_results/");
disp("    └─ Hole detection visualizations & statistics");
disp("  • logs/hole_detection_tests/");
disp("    └─ Comprehensive test results & validation");
disp("  • logs/dataset_stats.csv");
disp("    └─ Dataset statistics summary");

disp(" ");
disp("Deliverables Summary:");
disp("  ✓ Preprocessing scripts (member1_preprocess.m)");
disp("  ✓ Hole detection module (member1_hole_detection.m)");
disp("  ✓ Testing framework (member1_test_holes.m)");
disp("  ✓ Processed image dataset");
disp("  ✓ Hole detection statistics & visualizations");
disp("  ✓ Feature extraction results");
disp(" ");

disp("Report Sections Ready:");
disp("  • Data Collection & Organization");
disp("  • Preprocessing Methodology");
disp("  • Color Space & Filtering Justification");
disp("  • Hole Detection Algorithm (Thresholding + Morphology)");
disp("  • Experimental Results & Performance Metrics");
disp("  • Critical Analysis & Future Improvements");
disp(" ");

disp("Next Steps for Team:");
disp("  1. Member 2: Use processed masks for glove segmentation");
disp("  2. Member 3: Use hole features for classification");
disp("  3. Member 4: Integrate completed modules into GUI");
disp(" ");

fprintf("Status: READY FOR HANDOFF TO MEMBER 2\n");
fprintf("Completion Time: %s\n", datetime('now'));

end
