% MEMBER 1 - QUICK REFERENCE GUIDE
% ⚡ Fast setup and execution guide

%% ============================================
%  1. RUN COMPLETE PIPELINE (Recommended)
%  ============================================
% Simply execute:
member1_main

% Output: Summary with all results + file locations


%% ============================================
%  2. RUN INDIVIDUAL MODULES
%  ============================================

% 2.1 Preprocessing only
member1_preprocess
% Output: expanded processed/ directory with 8 subdirectories

% 2.2 Hole detection only (requires preprocessing complete)
member1_hole_detection
% Output: logs/hole_detection_results/ directory

% 2.3 Testing only (requires preprocessing + hole detection)
member1_test_holes
% Output: logs/hole_detection_tests/ directory


%% ============================================
%  3. OUTPUT FILES EXPLAINED
%  ============================================

% Preprocessing outputs:
%   processed/resized/          → 256×256 original images
%   processed/gray/             → Grayscale converted
%   processed/hsv/              → HSV color space
%   processed/filtered_gaussian/→ Gaussian smoothed (σ=1.0)
%   processed/filtered_median/  → Median filtered (3×3)
%   processed/masks/            → Glove segmentation binary masks
%   processed/isolated/         → Glove region isolated
%   processed/samples_for_report/→ 2x4 panel visualizations

% Hole detection outputs:
%   logs/hole_detection_results/hole_detection_stats.csv
%   logs/hole_detection_results/*.png (visualization samples)

% Testing outputs:
%   logs/hole_detection_tests/HOLE_DETECTION_SUMMARY.txt
%   logs/hole_detection_tests/ (all test metrics)


%% ============================================
%  4. KEY ALGORITHM PARAMETERS
%  ============================================

% FILE: member1_preprocess.m
  TARGET_SIZE = [256 256];      % Resize to this dimension
  GAUSS_SIGMA = 1.0;            % Gaussian smoothing parameter
  MED_WIN = [3 3];              % Median filter window
  MIN_BLOB_AREA = 700;          % Min pixels for valid glove
  CLOSE_RADIUS = 5;             % Morphological closing radius

% FILE: member1_hole_detection.m
  GRAY_THRESHOLD = 100;         % Intensity threshold for holes
  MIN_HOLE_AREA = 50;           % Min hole size (pixels)
  MAX_HOLE_AREA = 5000;         % Max hole size (pixels)
  MORPH_RADIUS = 3;             % Morphological SE radius


%% ============================================
%  5. INTERPRETING RESULTS
%  ============================================

% Preprocessing success = 1,352 images in processed/ directories
% Hole detection success = CSV with hole statistics

% Key statistics in hole_detection_stats.csv:
% - area_px: Size of hole (pixels)
% - perimeter_px: Boundary length
% - solidity: Ratio area/convex_hull (1.0 = solid, <1 = irregular)
% - eccentricity: Elongation (0=circle, 1=line)
% - mean_intensity: Average brightness (0-255)
% - std_intensity: Brightness variation
% - min/max_intensity: Darkest/brightest pixels in hole


%% ============================================
%  6. TROUBLESHOOTING
%  ============================================

% Problem: "Missing folder: ..." error
% Solution: Ensure gloves_dataset/ has correct structure:
%   gloves_dataset/
%   ├── cloth gloves/
%   │   ├── Hole/
%   │   ├── Normal/
%   │   └── Stain/
%   ├── Nitrile gloves/
%   └── Rubber gloves/

% Problem: No holes detected
% Solution: Adjust GRAY_THRESHOLD in member1_hole_detection.m

% Problem: Too many false positives
% Solution: Adjust MIN_HOLE_AREA and MAX_HOLE_AREA parameters

% Problem: Glove isolation poor
% Solution: Adjust MIN_BLOB_AREA and CLOSE_RADIUS in preprocessing


%% ============================================
%  7. SAMPLE USAGE FOR REPORT
%  ============================================

% Show preprocessing results:
% Show 4 sample panels from:
% processed/samples_for_report/*.png

% Show hole detection results:
% Show 3-4 visualization PNGs from:
% logs/hole_detection_results/*.png

% Show statistics:
% Include hole_detection_stats.csv excerpt
% Include hole_detection_summary.txt key findings


%% ============================================
%  8. PASSING TO NEXT TEAM MEMBERS
%  ============================================

% For Member 2 (Segmentation):
% Use: processed/masks/*.png
%      processed/gray/*.png
% Purpose: Refine masks and detect stains

% For Member 3 (Classification):
% Use: logs/hole_detection_results/hole_detection_stats.csv
% Purpose: Extract patterns, build classifier

% For Member 4 (GUI):
% Use: All processed/* outputs + hole detection results
% Purpose: Build integrated visualization + statistics


%% ============================================
%  9. ESTIMATED EXECUTION TIME
%  ============================================

% member1_preprocess: ~5-10 minutes (1,352 images)
% member1_hole_detection: ~3-5 minutes 
% member1_test_holes: ~2-3 minutes
% 
% Total: ~15-20 minutes for complete pipeline


%% ============================================
%  10. METHODOLOGY REFERENCE
%  ============================================

% Course Materials Used:
% - IPPR Chapter 3: Spatial Filtering (Gaussian, Median)
% - IPPR Chapter 7: Image Segmentation (Thresholding)
% - IPPR Chapter 8: Morphological Image Processing (opening, closing)
% - IPPR Chapter 9: Color Image Processing (RGB→HSV/Gray)

% Key Techniques:
% 1. Color space conversion for robust glove detection
% 2. Morphological operations for boundary refinement  
% 3. Intensity thresholding for hole identification
% 4. Connected components for individual hole isolation
% 5. Feature extraction for downstream classification
