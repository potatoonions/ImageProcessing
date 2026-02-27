%% GLOVE DEFECT DETECTION - CONFIGURATION FILE
% Adjust parameters here. No need to edit GloveDefectDetectionGUI.m

classdef DetectionConfig
    properties (Constant)
        TARGET_IMAGE_SIZE = [256 256]          % Resize all images to this size
        GAUSSIAN_SIGMA = 1.0                   % Gaussian blur sigma parameter
        MEDIAN_FILTER_SIZE = [3 3]             % Median filter kernel size
        
        MIN_BLOB_AREA = 200                    % Minimum blob area for mask
        CLOSE_RADIUS = 5                       % Morphological closing radius
        
        HOLE_INTENSITY_THRESHOLD = 100         % Pixels darker than this are holes
        HOLE_MIN_AREA = 50                     % Minimum hole area (pixels)
        HOLE_MAX_AREA = 5000                   % Maximum hole area (pixels)
        HOLE_MORPH_RADIUS = 2                  % Morphology radius for holes
        
        SNAG_UPPER_THRESHOLD = 130             % Upper intensity boundary
        SNAG_LOWER_THRESHOLD = 70              % Lower intensity boundary
        SNAG_MIN_AREA = 50                     % Minimum snag area (pixels)
        SNAG_MAX_AREA = 5000                   % Maximum snag area (pixels)
        SNAG_MORPH_RADIUS = 2                  % Morphology radius for snags
        
        STAIN_TEXTURE_THRESHOLD = 15           % Local standard deviation threshold
        STAIN_INTENSITY_MIN = 100              % Minimum intensity for stains
        STAIN_INTENSITY_MAX = 200              % Maximum intensity for stains
        STAIN_MIN_AREA = 50                    % Minimum stain area (pixels)
        STAIN_MAX_AREA = 5000                  % Maximum stain area (pixels)
        STAIN_MORPH_RADIUS = 2                 % Morphology radius for stains
        STAIN_TEXTURE_WINDOW = 5               % Local std calculation window
        
        HOLE_COLOR = 'r'                       % Hole boundary color (red)
        SNAG_COLOR = 'y'                       % Snag boundary color (yellow)
        STAIN_COLOR = 'm'                      % Stain boundary color (magenta)
        DEFECT_LINE_WIDTH = 2                  % Defect boundary line width
    end
    
    methods (Static)
        function config = getConfig()
            % Returns current configuration as struct
            config = struct();
            
            % Preprocessing
            config.targetSize = DetectionConfig.TARGET_IMAGE_SIZE;
            config.gaussSigma = DetectionConfig.GAUSSIAN_SIGMA;
            config.medianSize = DetectionConfig.MEDIAN_FILTER_SIZE;
            
            % Mask
            config.minBlobArea = DetectionConfig.MIN_BLOB_AREA;
            config.closeRadius = DetectionConfig.CLOSE_RADIUS;
            
            % Holes
            config.holeThreshold = DetectionConfig.HOLE_INTENSITY_THRESHOLD;
            config.holeMinArea = DetectionConfig.HOLE_MIN_AREA;
            config.holeMaxArea = DetectionConfig.HOLE_MAX_AREA;
            config.holeMorphRadius = DetectionConfig.HOLE_MORPH_RADIUS;
            
            % Snags
            config.snagUpper = DetectionConfig.SNAG_UPPER_THRESHOLD;
            config.snagLower = DetectionConfig.SNAG_LOWER_THRESHOLD;
            config.snagMinArea = DetectionConfig.SNAG_MIN_AREA;
            config.snagMaxArea = DetectionConfig.SNAG_MAX_AREA;
            config.snagMorphRadius = DetectionConfig.SNAG_MORPH_RADIUS;
            
            % Stains
            config.stainTextureThresh = DetectionConfig.STAIN_TEXTURE_THRESHOLD;
            config.stainIntMin = DetectionConfig.STAIN_INTENSITY_MIN;
            config.stainIntMax = DetectionConfig.STAIN_INTENSITY_MAX;
            config.stainMinArea = DetectionConfig.STAIN_MIN_AREA;
            config.stainMaxArea = DetectionConfig.STAIN_MAX_AREA;
            config.stainMorphRadius = DetectionConfig.STAIN_MORPH_RADIUS;
            config.stainTexWindow = DetectionConfig.STAIN_TEXTURE_WINDOW;
            
            % Colors
            config.holeColor = DetectionConfig.HOLE_COLOR;
            config.snagColor = DetectionConfig.SNAG_COLOR;
            config.stainColor = DetectionConfig.STAIN_COLOR;
            config.lineWidth = DetectionConfig.DEFECT_LINE_WIDTH;
        end
        
        function printConfig()
            % Print current configuration to console
            cfg = DetectionConfig.getConfig();
            
            fprintf('\n===== DETECTION CONFIGURATION =====\n\n');
            
            fprintf('IMAGE PREPROCESSING:\n');
            fprintf('  Target Size: %d × %d pixels\n', cfg.targetSize(1), cfg.targetSize(2));
            fprintf('  Gaussian Sigma: %.2f\n', cfg.gaussSigma);
            fprintf('  Median Filter: %d × %d\n', cfg.medianSize(1), cfg.medianSize(2));
            
            fprintf('\nMASK CREATION:\n');
            fprintf('  Min Blob Area: %d pixels\n', cfg.minBlobArea);
            fprintf('  Close Radius: %d\n', cfg.closeRadius);
            
            fprintf('\nHOLE DETECTION:\n');
            fprintf('  Intensity Threshold: < %d\n', cfg.holeThreshold);
            fprintf('  Area Range: %d - %d pixels\n', cfg.holeMinArea, cfg.holeMaxArea);
            fprintf('  Morph Radius: %d\n', cfg.holeMorphRadius);
            
            fprintf('\nSNAG DETECTION:\n');
            fprintf('  Intensity Range: %d - %d\n', cfg.snagLower, cfg.snagUpper);
            fprintf('  Area Range: %d - %d pixels\n', cfg.snagMinArea, cfg.snagMaxArea);
            fprintf('  Morph Radius: %d\n', cfg.snagMorphRadius);
            
            fprintf('\nSTAIN DETECTION:\n');
            fprintf('  Texture Threshold: > %.1f (local std)\n', cfg.stainTextureThresh);
            fprintf('  Intensity Range: %d - %d\n', cfg.stainIntMin, cfg.stainIntMax);
            fprintf('  Area Range: %d - %d pixels\n', cfg.stainMinArea, cfg.stainMaxArea);
            fprintf('  Morph Radius: %d\n', cfg.stainMorphRadius);
            fprintf('  Texture Window: %d × %d\n', cfg.stainTexWindow, cfg.stainTexWindow);
            
            fprintf('\nDISPLAY COLORS:\n');
            fprintf('  Holes: %s (Red)\n', cfg.holeColor);
            fprintf('  Snags: %s (Yellow)\n', cfg.snagColor);
            fprintf('  Stains: %s (Magenta)\n', cfg.stainColor);
            fprintf('  Line Width: %d pixels\n\n', cfg.lineWidth);
        end
    end
end

%% PRESET CONFIGURATIONS
% Use these for different glove types or detection profiles

function cfg = getSensitiveConfig()
    % More sensitive detection - finds smaller, fainter defects
    % Use for: Critical quality control
    cfg = struct();
    cfg.holeThreshold = 120;          % Higher = detects lighter holes
    cfg.snagLower = 50;               % Lower = detects lighter snags
    cfg.snagUpper = 150;
    cfg.stainTextureThresh = 10;      % Lower = more sensitive to texture
    cfg.stainIntMin = 80;
    cfg.stainIntMax = 220;
    cfg.holeMinArea = 30;             % Smaller = finds tiny defects
    cfg.snagMinArea = 30;
    cfg.stainMinArea = 30;
end

function cfg = getBalancedConfig()
    % Balanced detection - good for most images
    % Use for: General quality control
    cfg = DetectionConfig.getConfig();
end

function cfg = getStrictConfig()
    % Strict detection - only finds obvious defects
    % Use for: High-quality production (minimal false positives)
    cfg = struct();
    cfg.holeThreshold = 80;           % Lower = only very dark holes
    cfg.snagLower = 100;              % Higher = only obvious snags
    cfg.snagUpper = 120;
    cfg.stainTextureThresh = 25;      % Higher = only obvious texture changes
    cfg.stainIntMin = 120;
    cfg.stainIntMax = 180;
    cfg.holeMinArea = 100;            % Larger = requires bigger defects
    cfg.snagMinArea = 100;
    cfg.stainMinArea = 100;
end

%% EXAMPLE USAGE
% To use different presets, modify GloveDefectDetectionGUI.m:
%
% Instead of hard-coded values, call:
%   cfg = DetectionConfig.getConfig();   % Default/balanced
%   cfg = getSensitiveConfig();          % For critical inspection
%   cfg = getStrictConfig();             % For high-quality production
%
% Then use: cfg.holeThreshold, cfg.snagLower, etc. in detection functions

%% TUNING GUIDE
% 
% TO REDUCE FALSE POSITIVES (too many detections):
%   - Increase THRESHOLD values (detect only darker/more obvious defects)
%   - Increase MIN_AREA values (require larger defects)
%   - Decrease TEXTURE_THRESHOLD for stains
%
% TO INCREASE SENSITIVITY (detect smaller defects):
%   - Decrease THRESHOLD values
%   - Decrease MIN_AREA values
%   - Increase TEXTURE_THRESHOLD for stains
%
% MATERIAL-SPECIFIC TIPS:
%   Cloth Gloves: Higher thresholds (darker defects more visible)
%   Nitrile: Medium thresholds (darker appearance)
%   Rubber: Adjust for shiny surface (may need stricter thresholds)
