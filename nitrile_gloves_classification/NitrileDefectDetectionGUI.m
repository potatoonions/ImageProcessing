function NitrileDefectDetectionGUI(varargin)
    if nargin == 1 && strcmp(func2str(varargin{1}), 'batch')
        return;
    end
    
    persistent appData;
    if isempty(appData), appData = struct(); end

    fig = figure('Name', 'Nitrile Glove Defect Detection', 'NumberTitle', 'off', ...
        'Position', [100 100 1000 700], 'Color', [0.94 0.94 0.94], ...
        'CloseRequestFcn', @(src, evt) closeApp());

    mainPanel = uipanel(fig, 'Position', [0.05 0.05 0.90 0.90], ...
        'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

    appData.welcomeLabel = uicontrol(mainPanel, 'Style', 'text', ...
        'String', 'Nitrile Glove Defect Detection', ...
        'Units', 'normalized', 'Position', [0.1 0.88 0.8 0.08], ...
        'FontSize', 22, 'FontWeight', 'bold', 'ForegroundColor', [0.1 0.4 0.7], ...
        'BackgroundColor', [0.94 0.94 0.94]);

    appData.displayPanel = uipanel(mainPanel, 'Position', [0.05 0.30 0.90 0.55], ...
        'BorderType', 'line', 'BackgroundColor', [0.15 0.15 0.15], ...
        'Visible', 'on');

    appData.displayAx = axes(appData.displayPanel, 'Position', [0.05 0.05 0.90 0.90], ...
        'Color', [0.15 0.15 0.15]);
    axis(appData.displayAx, 'off');

    appData.resultsPanel = uipanel(mainPanel, 'Position', [0.05 0.30 0.90 0.55], ...
        'BorderType', 'line', 'BackgroundColor', [0.96 0.96 0.96], ...
        'Visible', 'off');

    appData.resultAx = axes('Parent', appData.resultsPanel, 'Position', [0.05 0.15 0.90 0.80]);
    axis(appData.resultAx, 'image', 'off');

    uicontrol(appData.resultsPanel, 'Style', 'text', 'String', 'Material: Nitrile Gloves', ...
        'Units', 'normalized', 'Position', [0.05 0.05 0.4 0.06], ...
        'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', [0.96 0.96 0.96]);

    appData.resultClassification = uicontrol(appData.resultsPanel, 'Style', 'text', 'String', '', ...
        'Units', 'normalized', 'Position', [0.50 0.05 0.45 0.06], ...
        'FontSize', 11, 'FontWeight', 'bold', 'ForegroundColor', [0.1 0.4 0.7], ...
        'BackgroundColor', [0.96 0.96 0.96]);

    buttonPanel = uipanel(mainPanel, 'Position', [0.05 0.02 0.90 0.12], ...
        'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);

    uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Upload Image', ...
        'Units', 'normalized', 'Position', [0.25 0.25 0.20 0.60], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.3 0.6 0.85], 'ForegroundColor', [1 1 1], ...
        'Callback', @(src, evt) uploadImage(fig));

    appData.classifyBtn = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Classify Defects', ...
        'Units', 'normalized', 'Position', [0.50 0.25 0.20 0.60], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.7 0.2], 'ForegroundColor', [1 1 1], ...
        'Visible', 'off', ...
        'Callback', @(src, evt) classifyDefects(fig));

    uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', 'Reset', ...
        'Units', 'normalized', 'Position', [0.75 0.25 0.20 0.60], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.8 0.3 0.3], 'ForegroundColor', [1 1 1], ...
        'Callback', @(src, evt) resetGUI(fig));

    appData.fig = fig;
    appData.currentImage = [];
    appData.processedImage = [];
    appData.classificationResult = '';

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
            
            appData.displayPanel.Visible = 'on';
            appData.resultsPanel.Visible = 'off';
            appData.classifyBtn.Visible = 'on';
            
            axes(appData.displayAx);
            imshow(appData.currentImage);
            axis(appData.displayAx, 'off');
            title(appData.displayAx, ['Uploaded: ', filename], 'Color', 'white', 'FontSize', 10);
            
            appData.processedImage = [];
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
            img = im2uint8(img);
            img = imresize(img, [256 256]);
            
            if size(img, 3) == 3
                gray = rgb2gray(img);
                hsv01 = rgb2hsv(img);
            else
                gray = img;
                hsv01 = rgb2hsv(repmat(img, [1 1 3]));
            end
            
            gauss = im2uint8(imgaussfilt(im2double(gray), 1.0));
            med = im2uint8(medfilt2(im2double(gray), [3 3]));
            
            S = hsv01(:,:,2);
            mask = imbinarize(S, graythresh(S));
            mask = cleanMask(mask, 500, 5);
            
            detectionResult = detectAllDefects(gray, mask);
            
            appData.resultsPanel.Visible = 'on';
            appData.displayPanel.Visible = 'off';
            appData.classifyBtn.Visible = 'off';
            
            axes(appData.resultAx);
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
            axis(appData.resultAx, 'off');
            
            resultText = 'Normal';
            if detectionResult.notWorn
                resultText = 'Not Worn';
            elseif ~isempty(detectionResult.improperRoll)
                resultText = 'Improper Roll';
            elseif ~isempty(detectionResult.insideOut)
                resultText = 'Inside Out';
            end
            set(appData.resultClassification, 'String', ['Classification: ', resultText]);
            
        catch ME
            errordlg(['Error during classification: ', ME.message], 'Classification Error');
        end
    end

    function resetGUI(fig)
        appData.currentImage = [];
        appData.processedImage = [];
        appData.classificationResult = '';
        
        appData.displayPanel.Visible = 'on';
        appData.resultsPanel.Visible = 'off';
        appData.classifyBtn.Visible = 'off';
        
        set(appData.resultClassification, 'String', '');
        
        axes(appData.displayAx);
        cla;
        axis(appData.displayAx, 'off');
    end

    function closeApp()
        if isfield(appData, 'fig') && ishandle(appData.fig)
            delete(appData.fig);
        end
    end

    function mask = cleanMask(mask, minArea, r)
        mask = bwareaopen(mask, minArea);
        mask = imclose(mask, strel('disk', r));
        cc = bwconncomp(mask);
        if cc.NumObjects < 1, return; end
        [~, idx] = max(cellfun(@numel, cc.PixelIdxList));
        tmp = false(size(mask));
        tmp(cc.PixelIdxList{idx}) = true;
        mask = tmp;
    end

    function result = detectAllDefects(grayImg, gloveMask)
        result = struct();
        result.notWorn = false;
        result.improperRoll = [];
        result.insideOut = [];
        
        boundaries = bwboundaries(gloveMask);
        boundaryCount = numel(boundaries);
        
        if boundaryCount < 2
            result.notWorn = true;
            return;
        end
        
        props = regionprops(gloveMask, 'Area', 'Perimeter', 'Solidity');
        if ~isempty(props)
            convexity = props.Solidity;
            
            if convexity < 0.82
                cuffMask = extractCuffRegion(gloveMask);
                if sum(cuffMask(:)) >= 100 && sum(cuffMask(:)) <= 8000
                    defect.pixelIdxList = find(cuffMask);
                    defect.area = sum(cuffMask(:));
                    defect.centroid = regionprops(cuffMask, 'Centroid').Centroid;
                    defect.bbox = regionprops(cuffMask, 'BoundingBox').BoundingBox;
                    result.improperRoll = [result.improperRoll; defect];
                end
            end
            
            gloveArea = sum(gloveMask(:));
            if ~isempty(boundaries)
                glovePerimeter = size(boundaries{1}, 1);
                if gloveArea > 0
                    perimeterAreaRatio = glovePerimeter / sqrt(gloveArea);
                    if perimeterAreaRatio > 3.5
                        defect.pixelIdxList = find(gloveMask);
                        defect.area = gloveArea;
                        defect.centroid = regionprops(gloveMask, 'Centroid').Centroid;
                        defect.bbox = regionprops(gloveMask, 'BoundingBox').BoundingBox;
                        result.insideOut = [result.insideOut; defect];
                    end
                end
            end
        end
    end

    function cuffMask = extractCuffRegion(gloveMask)
        [rows, cols] = size(gloveMask);
        cuffHeight = floor(rows * 0.2);
        cuffMask = false(size(gloveMask));
        cuffMask(1:cuffHeight, :) = gloveMask(1:cuffHeight, :);
        
        se = strel('disk', 2);
        cuffMask = imopen(cuffMask, se);
        cuffMask = imclose(cuffMask, se);
    end
end
