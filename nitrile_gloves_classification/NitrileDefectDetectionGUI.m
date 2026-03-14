function NitrileDefectDetectionGUI(varargin)
    persistent appData;
    if isempty(appData), appData = struct(); end

    fig = figure('Name', 'Nitrile Glove Defect Detection', 'NumberTitle', 'off', ...
        'Position', [50 50 1400 850], 'Color', [0.94 0.94 0.94], ...
        'CloseRequestFcn', @(src, evt) closeApp());

    mainPanel = uipanel(fig, 'Position', [0.005 0.005 0.99 0.99], ...
        'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

    appData.welcomeLabel = uicontrol(mainPanel, 'Style', 'text', ...
        'String', 'Nitrile Glove Defect Detection - Enhanced', ...
        'Units', 'normalized', 'Position', [0.02 0.94 0.96 0.04], ...
        'FontSize', 18, 'FontWeight', 'bold', 'ForegroundColor', [0.1 0.4 0.7], ...
        'BackgroundColor', [0.94 0.94 0.94], 'HorizontalAlignment', 'center');

    leftPanel = uipanel(mainPanel, 'Position', [0.01 0.30 0.48 0.63], ...
        'Title', 'Detection Results', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BorderType', 'line', 'BackgroundColor', [0.96 0.96 0.96]);

    appData.displayAx = axes(leftPanel, 'Position', [0.05 0.05 0.90 0.90], ...
        'Color', [0.15 0.15 0.15]);
    axis(appData.displayAx, 'off');

    rightPanel = uipanel(mainPanel, 'Position', [0.51 0.30 0.48 0.63], ...
        'Title', 'Preprocessing Visualization', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BorderType', 'line', 'BackgroundColor', [0.96 0.96 0.96]);

    visLayout = tiledlayout(rightPanel, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    appData.visGray = nexttile(visLayout);
    appData.visHSV = nexttile(visLayout);
    appData.visMask = nexttile(visLayout);
    appData.visIso = nexttile(visLayout);
    
    axis(appData.visGray, 'off'); title(appData.visGray, 'Grayscale', 'FontSize', 8);
    axis(appData.visHSV, 'off'); title(appData.visHSV, 'HSV Saturation', 'FontSize', 8);
    axis(appData.visMask, 'off'); title(appData.visMask, 'Binary Mask', 'FontSize', 8);
    axis(appData.visIso, 'off'); title(appData.visIso, 'Isolated Glove', 'FontSize', 8);

    settingsPanel = uipanel(mainPanel, 'Position', [0.01 0.01 0.98 0.28], ...
        'Title', 'Settings & Controls', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BorderType', 'line', 'BackgroundColor', [0.94 0.94 0.94]);

    col1 = uipanel(settingsPanel, 'Position', [0.01 0.15 0.32 0.80], ...
        'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);
    
    uicontrol(col1, 'Style', 'text', 'String', 'NOT WORN SETTINGS', ...
        'Units', 'normalized', 'Position', [0.02 0.92 0.96 0.05], ...
        'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.85 0.85]);
    
    uicontrol(col1, 'Style', 'text', 'String', 'Min Boundaries:', ...
        'Units', 'normalized', 'Position', [0.02 0.83 0.45 0.08], ...
        'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94]);
    
    appData.notWornBoundaries = uicontrol(col1, 'Style', 'edit', ...
        'String', '2', 'Units', 'normalized', 'Position', [0.55 0.83 0.25 0.08], ...
        'FontSize', 10, 'BackgroundColor', 'white', 'Callback', @(src,evt) updateParams());

    uicontrol(col1, 'Style', 'text', 'String', 'IMPROPER ROLL SETTINGS', ...
        'Units', 'normalized', 'Position', [0.02 0.70 0.96 0.05], ...
        'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.85 0.85]);
    
    uicontrol(col1, 'Style', 'text', 'String', 'Convexity Threshold:', ...
        'Units', 'normalized', 'Position', [0.02 0.61 0.45 0.08], ...
        'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94]);
    
    appData.improperConvexity = uicontrol(col1, 'Style', 'edit', ...
        'String', '0.82', 'Units', 'normalized', 'Position', [0.55 0.61 0.25 0.08], ...
        'FontSize', 10, 'BackgroundColor', 'white', 'Callback', @(src,evt) updateParams());

    uicontrol(col1, 'Style', 'text', 'String', 'INSIDE OUT SETTINGS', ...
        'Units', 'normalized', 'Position', [0.02 0.48 0.96 0.05], ...
        'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.85 0.85]);
    
    uicontrol(col1, 'Style', 'text', 'String', 'Perimeter/Area Ratio:', ...
        'Units', 'normalized', 'Position', [0.02 0.39 0.45 0.08], ...
        'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94]);
    
    appData.insideOutRatio = uicontrol(col1, 'Style', 'edit', ...
        'String', '3.5', 'Units', 'normalized', 'Position', [0.55 0.39 0.25 0.08], ...
        'FontSize', 10, 'BackgroundColor', 'white', 'Callback', @(src,evt) updateParams());

    col2 = uipanel(settingsPanel, 'Position', [0.34 0.15 0.32 0.80], ...
        'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);
    
    uicontrol(col2, 'Style', 'text', 'String', 'PREPROCESSING SETTINGS', ...
        'Units', 'normalized', 'Position', [0.02 0.92 0.96 0.05], ...
        'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.85 0.85]);
    
    uicontrol(col2, 'Style', 'text', 'String', 'Min Blob Area:', ...
        'Units', 'normalized', 'Position', [0.02 0.83 0.45 0.08], ...
        'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94]);
    
    appData.minBlobArea = uicontrol(col2, 'Style', 'edit', ...
        'String', '500', 'Units', 'normalized', 'Position', [0.55 0.83 0.25 0.08], ...
        'FontSize', 10, 'BackgroundColor', 'white', 'Callback', @(src,evt) updateParams());
    
    uicontrol(col2, 'Style', 'text', 'String', 'Close Radius:', ...
        'Units', 'normalized', 'Position', [0.02 0.70 0.45 0.08], ...
        'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94]);
    
    appData.closeRadius = uicontrol(col2, 'Style', 'edit', ...
        'String', '5', 'Units', 'normalized', 'Position', [0.55 0.70 0.25 0.08], ...
        'FontSize', 10, 'BackgroundColor', 'white', 'Callback', @(src,evt) updateParams());

    col3 = uipanel(settingsPanel, 'Position', [0.67 0.15 0.32 0.80], ...
        'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);
    
    uicontrol(col3, 'Style', 'text', 'String', 'ACCURACY TESTING', ...
        'Units', 'normalized', 'Position', [0.02 0.92 0.96 0.05], ...
        'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.85 0.85]);
    
    uicontrol(col3, 'Style', 'text', 'String', 'Ground Truth:', ...
        'Units', 'normalized', 'Position', [0.02 0.83 0.45 0.08], ...
        'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94]);
    
    appData.groundTruth = uicontrol(col3, 'Style', 'popupmenu', ...
        'String', {'Normal', 'Not Worn', 'Improper Roll', 'Inside Out'}, ...
        'Units', 'normalized', 'Position', [0.50 0.83 0.48 0.08], ...
        'FontSize', 10, 'BackgroundColor', 'white');
    
    appData.accuracyDisplay = uicontrol(col3, 'Style', 'text', ...
        'String', 'Correct: 0 | Incorrect: 0 | Accuracy: N/A', ...
        'Units', 'normalized', 'Position', [0.02 0.70 0.96 0.10], ...
        'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', [0.96 0.96 0.96], ...
        'HorizontalAlignment', 'center', 'ForegroundColor', [0.1 0.4 0.7]);

    buttonPanel = uipanel(settingsPanel, 'Position', [0.01 0.02 0.98 0.12], ...
        'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

    uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Upload Image', ...
        'Units', 'normalized', 'Position', [0.05 0.30 0.15 0.60], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.3 0.6 0.85], 'ForegroundColor', [1 1 1], ...
        'Callback', @(src, evt) uploadImage(fig));

    appData.classifyBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Classify', ...
        'Units', 'normalized', 'Position', [0.22 0.30 0.15 0.60], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.7 0.2], 'ForegroundColor', [1 1 1], ...
        'Visible', 'off', 'Callback', @(src, evt) classifyDefects(fig));

    uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Verify Result', ...
        'Units', 'normalized', 'Position', [0.39 0.30 0.15 0.60], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.8 0.6 0.2], 'ForegroundColor', [1 1 1], ...
        'Visible', 'off', 'Callback', @(src, evt) verifyAccuracy(fig));

    uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Reset', ...
        'Units', 'normalized', 'Position', [0.56 0.30 0.15 0.60], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.8 0.3 0.3], 'ForegroundColor', [1 1 1], ...
        'Callback', @(src, evt) resetGUI(fig));

    uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Run Batch', ...
        'Units', 'normalized', 'Position', [0.05 0.30 0.20 0.60], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.6 0.4 0.2], 'ForegroundColor', [1 1 1], ...
        'Callback', @(src, evt) runBatchProcessing(fig));
    
    uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Save Settings', ...
        'Units', 'normalized', 'Position', [0.73 0.30 0.15 0.60], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.5 0.5 0.5], 'ForegroundColor', [1 1 1], ...
        'Callback', @(src, evt) saveSettings());

    appData.resultText = uicontrol(leftPanel, 'Style', 'text', ...
        'String', '', 'Units', 'normalized', 'Position', [0.05 0.01 0.90 0.03], ...
        'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.96 0.96 0.96], ...
        'HorizontalAlignment', 'center');

    appData.fig = fig;
    appData.currentImage = [];
    appData.grayImg = [];
    appData.hsvImg = [];
    appData.mask = [];
    appData.isolatedImg = [];
    appData.classificationResult = '';
    appData.correctCount = 0;
    appData.incorrectCount = 0;
    appData.totalCount = 0;

    updateParams();

    function uploadImage(fig)
        [filename, pathname] = uigetfile(...
            {'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff', 'Image Files (*.jpg, *.png, *.bmp, *.tif)'; ...
            '*.*', 'All Files (*.*)'}, ...
            'Select Nitrile Glove Image');
        
        if isequal(filename, 0)
            return;
        end
        
        try
            imgPath = fullfile(pathname, filename);
            appData.currentImage = imread(imgPath);
            
            if size(appData.currentImage, 3) == 1
                appData.currentImage = repmat(appData.currentImage, [1 1 3]);
            end
            
            appData.currentImage = imresize(appData.currentImage, [256 256]);
            
            axes(appData.displayAx);
            imshow(appData.currentImage);
            axis(appData.displayAx, 'off');
            title(appData.displayAx, ['Uploaded: ', filename], 'Color', 'black', 'FontSize', 10);
            
            set(appData.resultText, 'String', 'Image loaded. Click "Classify" to detect defects.');
            appData.classifyBtn.Visible = 'on';
            
            cla(appData.visGray);
            cla(appData.visHSV);
            cla(appData.visMask);
            cla(appData.visIso);
            
            appData.grayImg = [];
            appData.hsvImg = [];
            appData.mask = [];
            appData.isolatedImg = [];
            appData.classificationResult = '';
            
        catch ME
            errordlg(['Error loading image: ', ME.message], 'Upload Error');
        end
    end

    function classifyDefects(fig)
        if isempty(appData.currentImage)
            errordlg('Please upload an image first.', 'No Image');
            return;
        end
        
        try
            img = appData.currentImage;
            
            if size(img, 3) == 3
                gray = rgb2gray(img);
                hsv01 = rgb2hsv(img);
            else
                gray = img;
                hsv01 = rgb2hsv(repmat(img, [1 1 3]));
            end
            
            appData.grayImg = gray;
            appData.hsvImg = hsv01;
            
            minBlobArea = str2double(get(appData.minBlobArea, 'String'));
            closeRadius = str2double(get(appData.closeRadius, 'String'));
            
            S = hsv01(:,:,2);
            try
                mask = imbinarize(S, graythresh(S));
            catch
                thresh = 0.3;
                mask = S > thresh;
            end
            mask = cleanMask(mask, minBlobArea, closeRadius);
            appData.mask = mask;
            
            isolated = img;
            if size(img, 3) == 1
                isolated(~mask) = 0;
            else
                for c = 1:3
                    tmp = isolated(:,:,c);
                    tmp(~mask) = 0;
                    isolated(:,:,c) = tmp;
                end
            end
            appData.isolatedImg = isolated;
            
            visualizePreprocessed();
            
            notWornBoundaries = str2double(get(appData.notWornBoundaries, 'String'));
            improperConvexity = str2double(get(appData.improperConvexity, 'String'));
            insideOutRatio = str2double(get(appData.insideOutRatio, 'String'));
            
            detectionResult = detectAllDefects(gray, mask, notWornBoundaries, improperConvexity, insideOutRatio);
            
            axes(appData.displayAx);
            rgbImg = repmat(gray, [1 1 3]);
            imshow(rgbImg);
            hold on;
            
            if detectionResult.notWorn
                rectangle('Position', [50 50 156 156], 'EdgeColor', 'red', 'LineWidth', 3);
                text(128, 20, 'NOT WORN', 'Color', 'red', 'FontSize', 14, ...
                    'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
                    'BackgroundColor', 'white');
            end
            
            if ~isempty(detectionResult.improperRoll)
                for i = 1:numel(detectionResult.improperRoll)
                    bbox = detectionResult.improperRoll(i).bbox;
                    rectangle('Position', bbox, 'EdgeColor', 'yellow', 'LineWidth', 2);
                    text(bbox(1) + bbox(3)/2, bbox(2) - 10, 'IMPROPER ROLL', ...
                        'Color', 'black', 'FontSize', 10, 'FontWeight', 'bold', ...
                        'HorizontalAlignment', 'center', 'BackgroundColor', 'yellow');
                end
            end
            
            if ~isempty(detectionResult.insideOut)
                for i = 1:numel(detectionResult.insideOut)
                    bbox = detectionResult.insideOut(i).bbox;
                    rectangle('Position', bbox, 'EdgeColor', 'magenta', 'LineWidth', 2);
                    text(bbox(1) + bbox(3)/2, bbox(2) - 10, 'INSIDE OUT', ...
                        'Color', 'white', 'FontSize', 10, 'FontWeight', 'bold', ...
                        'HorizontalAlignment', 'center', 'BackgroundColor', 'magenta');
                end
            end
            
            hold off;
            axis(appData.displayAx, 'off');
            
            resultText = 'Normal';
            if detectionResult.notWorn
                resultText = 'Not Worn';
            elseif ~isempty(detectionResult.improperRoll)
                resultText = 'Improper Roll';
            elseif ~isempty(detectionResult.insideOut)
                resultText = 'Inside Out';
            end
            appData.classificationResult = resultText;
            
            featureInfo = sprintf('Features: Boundaries=%d, Convexity=%.3f, Perim/Area=%.2f', ...
                detectionResult.boundaryCount, detectionResult.convexity, detectionResult.perimeterAreaRatio);
            set(appData.resultText, 'String', ['Classification: ', resultText, ' | ', featureInfo]);
            
            appData.verifyBtn.Visible = 'on';
            
        catch ME
            errordlg(['Error during classification: ', ME.message], 'Classification Error');
        end
    end

    function visualizePreprocessed()
        axes(appData.visGray);
        imshow(appData.grayImg);
        axis(appData.visGray, 'off');
        title(appData.visGray, 'Grayscale', 'FontSize', 8);
        
        axes(appData.visHSV);
        imshow(appData.hsvImg(:,:,2));
        axis(appData.visHSV, 'off');
        title(appData.visHSV, 'HSV Saturation', 'FontSize', 8);
        
        axes(appData.visMask);
        imshow(appData.mask);
        axis(appData.visMask, 'off');
        title(appData.visMask, 'Binary Mask', 'FontSize', 8);
        
        axes(appData.visIso);
        imshow(appData.isolatedImg);
        axis(appData.visIso, 'off');
        title(appData.visIso, 'Isolated Glove', 'FontSize', 8);
    end

    function verifyAccuracy(fig)
        if isempty(appData.classificationResult)
            errordlg('Please classify the image first.', 'No Classification');
            return;
        end
        
        gtIdx = get(appData.groundTruth, 'Value');
        gtLabels = {'Normal', 'Not Worn', 'Improper Roll', 'Inside Out'};
        groundTruthLabel = gtLabels{gtIdx};
        
        detectedLabel = appData.classificationResult;
        
        isCorrect = strcmpi(detectedLabel, groundTruthLabel) || ...
            (strcmpi(detectedLabel, 'Normal') && strcmpi(groundTruthLabel, 'Normal'));
        
        appData.totalCount = appData.totalCount + 1;
        
        if isCorrect
            appData.correctCount = appData.correctCount + 1;
            msg = sprintf('Correct! Detection: %s | Ground Truth: %s', detectedLabel, groundTruthLabel);
            msgbox(msg, 'Result', 'help');
        else
            appData.incorrectCount = appData.incorrectCount + 1;
            msg = sprintf('Incorrect. Detection: %s | Ground Truth: %s', detectedLabel, groundTruthLabel);
            errordlg(msg, 'Result');
        end
        
        if appData.totalCount > 0
            accuracy = (appData.correctCount / appData.totalCount) * 100;
            set(appData.accuracyDisplay, 'String', ...
                sprintf('Correct: %d | Incorrect: %d | Accuracy: %.1f%%', ...
                appData.correctCount, appData.incorrectCount, accuracy));
        end
    end

    function updateParams()
        if isfield(appData, 'minBlobArea')
            minArea = str2double(get(appData.minBlobArea, 'String'));
            closeR = str2double(get(appData.closeRadius, 'String'));
            notWornB = str2double(get(appData.notWornBoundaries, 'String'));
            impC = str2double(get(appData.improperConvexity, 'String'));
            ioR = str2double(get(appData.insideOutRatio, 'String'));
        end
    end

    function saveSettings()
        settings = struct();
        settings.notWornMinBoundaries = str2double(get(appData.notWornBoundaries, 'String'));
        settings.improperRollConvexity = str2double(get(appData.improperConvexity, 'String'));
        settings.insideOutPerimeterRatio = str2double(get(appData.insideOutRatio, 'String'));
        settings.minBlobArea = str2double(get(appData.minBlobArea, 'String'));
        settings.closeRadius = str2double(get(appData.closeRadius, 'String'));
        settings.correctCount = appData.correctCount;
        settings.incorrectCount = appData.incorrectCount;
        settings.totalCount = appData.totalCount;
        
        [filename, pathname] = uiputfile('*.mat', 'Save Settings');
        if ~isequal(filename, 0)
            save(fullfile(pathname, filename), 'settings');
            msgbox('Settings saved successfully!', 'Success');
        end
    end

    function resetGUI(fig)
        appData.currentImage = [];
        appData.grayImg = [];
        appData.hsvImg = [];
        appData.mask = [];
        appData.isolatedImg = [];
        appData.classificationResult = '';
        
        appData.classifyBtn.Visible = 'off';
        appData.verifyBtn.Visible = 'off';
        
        set(appData.resultText, 'String', '');
        
        cla(appData.displayAx);
        axis(appData.displayAx, 'off');
        
        cla(appData.visGray);
        cla(appData.visHSV);
        cla(appData.visMask);
        cla(appData.visIso);
        
        title(appData.visGray, 'Grayscale', 'FontSize', 8);
        title(appData.visHSV, 'HSV Saturation', 'FontSize', 8);
        title(appData.visMask, 'Binary Mask', 'FontSize', 8);
        title(appData.visIso, 'Isolated Glove', 'FontSize', 8);
    end

    function closeApp()
        if isfield(appData, 'fig') && ishandle(appData.fig)
            delete(appData.fig);
        end
    end

    function runBatchProcessing(fig)
        batchSize = inputdlg('Enter number of images per class to process (or leave blank for all):', ...
            'Batch Processing', 1, {'10', '20', '50', ''}, 'on');
        
        if isempty(batchSize) || batchSize{1} == ''
            subsetSize = Inf;
        else
            subsetSize = str2double(batchSize{1});
        end
        
        set(appData.resultText, 'String', 'Running batch processing...');
        drawnow;
        
        try
            addpath(pwd);
            member3_nitrile_defect_analysis(subsetSize);
            set(appData.resultText, 'String', 'Batch processing complete. Check logs/accuracy_summary.csv');
            msgbox('Batch processing complete. Results saved to logs/accuracy_summary.csv', 'Batch Complete', 'help');
        catch ME
            set(appData.resultText, 'String', ['Batch error: ', ME.message]);
            errordlg(['Batch processing error: ', ME.message], 'Batch Error');
        end
    end

    function mask = cleanMask(mask, minArea, r)
        try
            mask = bwareaopen(mask, minArea);
        catch
            mask = mask;
        end
        
        try
            mask = imclose(mask, strel('disk', r));
        catch
            try
                se = ones(r*2+1, r*2+1);
                mask = imerode(mask, se);
                mask = imdilate(mask, se);
            catch
                mask = mask;
            end
        end
        
        try
            cc = bwconncomp(mask);
            if cc.NumObjects < 1, return; end
            [~, idx] = max(cellfun(@numel, cc.PixelIdxList));
            tmp = false(size(mask));
            tmp(cc.PixelIdxList{idx}) = true;
            mask = tmp;
        catch
            mask = mask;
        end
    end

    function result = detectAllDefects(grayImg, gloveMask, notWornMinBoundaries, improperConvexity, insideOutRatio)
        result = struct();
        result.notWorn = false;
        result.improperRoll = [];
        result.insideOut = [];
        result.boundaryCount = 0;
        result.convexity = 0;
        result.perimeterAreaRatio = 0;
        
        try
            boundaries = bwboundaries(gloveMask);
            boundaryCount = numel(boundaries);
        catch
            boundaryCount = 1;
        end
        
        result.boundaryCount = boundaryCount;
        
        if boundaryCount < notWornMinBoundaries
            result.notWorn = true;
            return;
        end
        
        try
            props = regionprops(gloveMask, 'Area', 'Perimeter', 'Solidity');
            if ~isempty(props)
                gloveArea = props.Area;
                glovePerimeter = props.Perimeter;
                convexity = props.Solidity;
                
                if gloveArea > 0
                    perimeterAreaRatio = glovePerimeter / sqrt(gloveArea);
                else
                    perimeterAreaRatio = 0;
                end
                
                result.convexity = convexity;
                result.perimeterAreaRatio = perimeterAreaRatio;
                
                try
                    convexHull = bwconvhull(gloveMask);
                    hullArea = sum(convexHull(:));
                    if hullArea > 0
                        convexity = gloveArea / hullArea;
                    else
                        convexity = 1;
                    end
                catch
                    convexity = 1;
                end
                
                if convexity < improperConvexity
                    cuffMask = extractCuffRegion(gloveMask);
                    if sum(cuffMask(:)) >= 100 && sum(cuffMask(:)) <= 8000
                        defect.pixelIdxList = find(cuffMask);
                        defect.area = sum(cuffMask(:));
                        try
                            defect.centroid = regionprops(cuffMask, 'Centroid').Centroid;
                            defect.bbox = regionprops(cuffMask, 'BoundingBox').BoundingBox;
                        catch
                            defect.centroid = [0 0];
                            defect.bbox = [0 0 0 0];
                        end
                        result.improperRoll = [result.improperRoll; defect];
                    end
                end
                
                try
                    if ~isempty(boundaries)
                        glovePerimeter = size(boundaries{1}, 1);
                        if gloveArea > 0
                            perimeterAreaRatio = glovePerimeter / sqrt(gloveArea);
                            if perimeterAreaRatio > insideOutRatio
                                defect.pixelIdxList = find(gloveMask);
                                defect.area = gloveArea;
                                try
                                    defect.centroid = regionprops(gloveMask, 'Centroid').Centroid;
                                    defect.bbox = regionprops(gloveMask, 'BoundingBox').BoundingBox;
                                catch
                                    defect.centroid = [0 0];
                                    defect.bbox = [0 0 0 0];
                                end
                                result.insideOut = [result.insideOut; defect];
                            end
                        end
                    end
                catch
                end
            end
        catch
        end
    end

    function cuffMask = extractCuffRegion(gloveMask)
        [rows, cols] = size(gloveMask);
        cuffHeight = floor(rows * 0.2);
        cuffMask = false(size(gloveMask));
        cuffMask(1:cuffHeight, :) = gloveMask(1:cuffHeight, :);
        
        try
            se = strel('disk', 2);
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
end
