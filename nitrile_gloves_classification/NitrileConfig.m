classdef NitrileConfig
    properties (Constant)
        TARGET_IMAGE_SIZE = [256 256]
        GAUSSIAN_SIGMA = 1.0
        MEDIAN_FILTER_SIZE = [3 3]
        
        MIN_BLOB_AREA = 500
        CLOSE_RADIUS = 5
        
        NOT_WORN_MIN_BOUNDARIES = 2
        NOT_WORN_CONVEXITY_THRESHOLD = 0.9
        
        IMPROPER_ROLL_CONVEXITY_THRESHOLD = 0.82
        IMPROPER_ROLL_MIN_AREA = 100
        IMPROPER_ROLL_MAX_AREA = 8000
        IMPROPER_ROLL_MORPH_RADIUS = 3
        
        INSIDE_OUT_PERIMETER_RATIO_THRESHOLD = 3.5
        INSIDE_OUT_MIN_AREA = 100
        INSIDE_OUT_MAX_AREA = 8000
        INSIDE_OUT_MORPH_RADIUS = 3
        
        NOT_WORN_COLOR = 'r'
        IMPROPER_ROLL_COLOR = 'y'
        INSIDE_OUT_COLOR = 'm'
        DEFECT_LINE_WIDTH = 2
    end
    
    methods (Static)
        function config = getConfig()
            config = struct();
            config.targetSize = NitrileConfig.TARGET_IMAGE_SIZE;
            config.gaussSigma = NitrileConfig.GAUSSIAN_SIGMA;
            config.medianSize = NitrileConfig.MEDIAN_FILTER_SIZE;
            config.minBlobArea = NitrileConfig.MIN_BLOB_AREA;
            config.closeRadius = NitrileConfig.CLOSE_RADIUS;
            
            config.notWornMinBoundaries = NitrileConfig.NOT_WORN_MIN_BOUNDARIES;
            config.notWornConvexity = NitrileConfig.NOT_WORN_CONVEXITY_THRESHOLD;
            
            config.improperRollConvexity = NitrileConfig.IMPROPER_ROLL_CONVEXITY_THRESHOLD;
            config.improperRollMinArea = NitrileConfig.IMPROPER_ROLL_MIN_AREA;
            config.improperRollMaxArea = NitrileConfig.IMPROPER_ROLL_MAX_AREA;
            config.improperRollMorphRadius = NitrileConfig.IMPROPER_ROLL_MORPH_RADIUS;
            
            config.insideOutPerimeterRatio = NitrileConfig.INSIDE_OUT_PERIMETER_RATIO_THRESHOLD;
            config.insideOutMinArea = NitrileConfig.INSIDE_OUT_MIN_AREA;
            config.insideOutMaxArea = NitrileConfig.INSIDE_OUT_MAX_AREA;
            config.insideOutMorphRadius = NitrileConfig.INSIDE_OUT_MORPH_RADIUS;
            
            config.notWornColor = NitrileConfig.NOT_WORN_COLOR;
            config.improperRollColor = NitrileConfig.IMPROPER_ROLL_COLOR;
            config.insideOutColor = NitrileConfig.INSIDE_OUT_COLOR;
            config.lineWidth = NitrileConfig.DEFECT_LINE_WIDTH;
        end
        
        function printConfig()
            cfg = NitrileConfig.getConfig();
            
            fprintf('\n===== NITRILE DETECTION CONFIGURATION =====\n\n');
            
            fprintf('IMAGE PREPROCESSING:\n');
            fprintf('  Target Size: %d × %d pixels\n', cfg.targetSize(1), cfg.targetSize(2));
            fprintf('  Gaussian Sigma: %.2f\n', cfg.gaussSigma);
            fprintf('  Median Filter: %d × %d\n', cfg.medianSize(1), cfg.medianSize(2));
            
            fprintf('\nMASK CREATION:\n');
            fprintf('  Min Blob Area: %d pixels\n', cfg.minBlobArea);
            fprintf('  Close Radius: %d\n', cfg.closeRadius);
            
            fprintf('\nNOT WORN DETECTION:\n');
            fprintf('  Min Boundaries: < %d\n', cfg.notWornMinBoundaries);
            fprintf('  Convexity Threshold: %.2f\n', cfg.notWornConvexity);
            
            fprintf('\nIMPROPER ROLL DETECTION:\n');
            fprintf('  Convexity Threshold: < %.2f\n', cfg.improperRollConvexity);
            fprintf('  Area Range: %d - %d pixels\n', cfg.improperRollMinArea, cfg.improperRollMaxArea);
            fprintf('  Morph Radius: %d\n', cfg.improperRollMorphRadius);
            
            fprintf('\nINSIDE OUT DETECTION:\n');
            fprintf('  Perimeter/Area Ratio: > %.2f\n', cfg.insideOutPerimeterRatio);
            fprintf('  Area Range: %d - %d pixels\n', cfg.insideOutMinArea, cfg.insideOutMaxArea);
            fprintf('  Morph Radius: %d\n', cfg.insideOutMorphRadius);
            
            fprintf('\nDISPLAY COLORS:\n');
            fprintf('  Not Worn: %s (Red)\n', cfg.notWornColor);
            fprintf('  Improper Roll: %s (Yellow)\n', cfg.improperRollColor);
            fprintf('  Inside Out: %s (Magenta)\n', cfg.insideOutColor);
            fprintf('  Line Width: %d pixels\n\n', cfg.lineWidth);
    end
end

function cfg = getSensitiveConfig()
    cfg = struct();
    cfg.notWornMinBoundaries = 3;
    cfg.improperRollConvexity = 0.88;
    cfg.insideOutPerimeterRatio = 3.0;
    cfg.improperRollMinArea = 50;
    cfg.insideOutMinArea = 50;
end

function cfg = getStrictConfig()
    cfg = struct();
    cfg.notWornMinBoundaries = 1;
    cfg.improperRollConvexity = 0.75;
    cfg.insideOutPerimeterRatio = 4.0;
    cfg.improperRollMinArea = 150;
    cfg.insideOutMaxArea = 6000;
    cfg.insideOutMinArea = 150;
    cfg.insideOutMaxArea = 6000;
end
